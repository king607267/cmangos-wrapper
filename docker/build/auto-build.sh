#!/bin/bash
set -eo pipefail

HUB_DOCKER_USERNAME="king607267"
EXTRACTORS_FLAG=$3

function initGitRepo() {
  local SERVER=""
  local DB=""
  if [[ "$1" == *classic* ]]; then
    SERVER="mangos-classic"
    DB="classic-db"
  elif [[ "$1" == *tbc* ]]; then
    SERVER="mangos-tbc"
    DB="tbc-db"
  else
    SERVER="mangos-wotlk"
    DB="wotlk-db"
  fi
  if [ ! -d "$SERVER" ]; then
    git clone https://github.com/cmangos/${SERVER}.git --recursive --depth=1
  fi
  if [ ! -d "$DB" ]; then
    git clone https://github.com/cmangos/${DB}.git --recursive --depth=1
  fi
}

function getRepoCurrentMasterCommit() {
  echo $(git log -1 --pretty=format:'%h')
}

function buildImage() {
  #构建
  DOCKER_FILE_NAME=""
  TARGET=""
  if [[ $1 =~ "-db" ]]; then
    DOCKER_FILE_NAME="Dockerfile-db"
  elif [[ $1 =~ "-server" ]]; then
    TARGET="--target mangosd"
    DOCKER_FILE_NAME="Dockerfile-server"
  elif [[ $1 =~ "-extractors" ]]; then
    TARGET="--target extractors"
    DOCKER_FILE_NAME="Dockerfile-server"
  else
    TARGET="--target realmd"
    DOCKER_FILE_NAME="Dockerfile-server"
  fi
  #https://stackoverflow.com/questions/22179301/how-do-you-run-apt-get-in-a-dockerfile-behind-a-proxy
  #export DOCKER_CONFIG=~/.docker
  if [[ "aarch64" == "${ARCHITECTURE}" ]]; then
    local buildx_var=`docker buildx ls --format "{{.Name}}" | grep cmangos_buildx | head -n 1`
    if [[ ${buildx_var} != "cmangos_buildx" ]]; then
      #if use proxy https://stackoverflow.com/questions/73210141/running-buildkit-using-docker-buildx-behind-a-proxy
      echo "docker buildx create --name cmangos_buildx --platform linux/amd64,linux/arm64"
      docker buildx create --name cmangos_buildx --platform linux/amd64,linux/arm64
    fi
    echo "buildx use cmangos_buildx"
    docker buildx use cmangos_buildx
    echo " docker buildx build --platform linux/amd64,linux/arm64 --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} ."
    docker buildx build --platform linux/amd64,linux/arm64  --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} .
  else
    echo " docker build --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} ."
    docker build --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} .
  fi

}

declare -A DOCKER_REPO_NAMES
DOCKER_REPO_NAMES["mangos-classic"]="classic-server,classic-realmd,classic-extractors"
DOCKER_REPO_NAMES["mangos-tbc"]="tbc-server,tbc-realmd,tbc-extractors"
DOCKER_REPO_NAMES["mangos-wotlk"]="wotlk-server,wotlk-realmd,wotlk-extractors"
DOCKER_REPO_NAMES["classic-db"]="classic-db"
DOCKER_REPO_NAMES["tbc-db"]="tbc-db"
DOCKER_REPO_NAMES["wotlk-db"]="wotlk-db"

declare -A GLOBAL_MASTER_COMMIT
GLOBAL_MASTER_COMMIT["mangos-classic"]=""
GLOBAL_MASTER_COMMIT["mangos-tbc"]=""
GLOBAL_MASTER_COMMIT["mangos-wotlk"]=""
GLOBAL_MASTER_COMMIT["classic-db"]=""
GLOBAL_MASTER_COMMIT["tbc-db"]=""
GLOBAL_MASTER_COMMIT["wotlk-db"]=""

function autoBuildGitMaster() {
  for key in ${!DOCKER_REPO_NAMES[*]}; do
    cd /tmp/autoBuildContext
    initGitRepo ${key}
    CURRENT_MASTER_COMMIT=""
    if [ "${GLOBAL_MASTER_COMMIT["${key}"]}" == "" ]; then
      cd ${key}
      CURRENT_MASTER_COMMIT=$(getRepoCurrentMasterCommit)
      cd ..
      GLOBAL_MASTER_COMMIT["${key}"]="${CURRENT_MASTER_COMMIT}"
    else
      CURRENT_MASTER_COMMIT="${GLOBAL_MASTER_COMMIT["${key}"]}"
    fi
    #获取SERVER和realmd的docker repo
    NAMES=($(echo ${DOCKER_REPO_NAMES[$key]} | sed "s/,/\n/g"))
    for NAME in ${NAMES[*]}; do
      if [[ "${NAME}" =~ "-extractors" ]] && [ "${EXTRACTORS_FLAG}" != "true" ]; then
        echo "skip build extractors"
        continue
      fi
      buildImage "${NAME}" "${CURRENT_MASTER_COMMIT}"
    done
  done
}

function modifyImageTag() {
  for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter=reference="${HUB_DOCKER_USERNAME}/*"); do
    REPO=${key%:*}
    if [ "${key#*:}" == "latest" ]; then
      continue
    fi
    echo "docker tag $key to ${REPO}:latest"
    docker tag "$key" "$REPO":latest
  done
}

function imagePush() {
  docker login -u "$1" -p "$2" docker.io
  if [[ "aarch64" == "${ARCHITECTURE}" ]]; then
    cd /tmp/autoBuildContext
    for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter reference="${HUB_DOCKER_USERNAME}/*:*" | grep -v latest); do
      local TAG=`echo $key | awk -F ":" '{print $2}'`
      local REPOSITORY=`echo $key | awk -F ":" '{print $1}'`
      local CMANGOS_CORE=`echo $key | awk -F "-" '{print $2}'`
      local TYPE=`echo $REPOSITORY | awk -F "-" '{print $3}'`
      echo "-----------"$TYPE
      local TARGET=""
      if [[ "$TYPE" == "server" ]]; then
        TARGET="--target mangosd"
      elif [[ "$TYPE" == "realmd" ]]; then
        TARGET="--target realmd"
      fi

      local DOCKER_FILE_NAME=""
      if [[ "$key" == *db* ]]; then
        DOCKER_FILE_NAME="Dockerfile-db"
      else
        DOCKER_FILE_NAME="Dockerfile-server"
      fi
      #https://medium.com/@hassanahmad61931/docker-buildx-building-multi-platform-container-images-made-easy-304e1c3f00f1
      echo " docker buildx build --platform linux/amd64,linux/arm64 --build-arg CMANGOS_CORE=${CMANGOS_CORE} --build-arg REVISION_NUM=$TAG -t ${key} ${TARGET} -f ${DOCKER_FILE_NAME} . --push"
      docker buildx build --platform linux/amd64,linux/arm64 --build-arg CMANGOS_CORE=${CMANGOS_CORE} --build-arg REVISION_NUM=$TAG -t ${key} ${TARGET} -f ${DOCKER_FILE_NAME} . --push
      echo " docker buildx build --platform linux/amd64,linux/arm64 --build-arg CMANGOS_CORE=${CMANGOS_CORE} --build-arg REVISION_NUM=$TAG -t ${REPOSITORY}:latest ${TARGET} -f ${DOCKER_FILE_NAME} . --push"
      docker buildx build --platform linux/amd64,linux/arm64 --build-arg CMANGOS_CORE=${CMANGOS_CORE} --build-arg REVISION_NUM=$TAG -t ${REPOSITORY}:latest ${TARGET} -f ${DOCKER_FILE_NAME} . --push
    done
  else
      for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter=reference="${HUB_DOCKER_USERNAME}/*"); do
        echo "docker push $key to hub"
        docker push "$key"
      done
  fi


  #manifest method
  #https://medium.com/@life-is-short-so-enjoy-it/docker-how-to-build-and-push-multi-arch-docker-images-to-docker-hub-64dea4931df9
  #https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
  #https://github.com/docker/buildx?tab=readme-ov-file
  #https://docs.docker.com/reference/cli/docker/manifest/
#  for key in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep  "^$HUB_DOCKER_USERNAME" | grep "$ARCHITECTURE"); do
#    repository=$(echo "${key}" | sed "s/-${ARCHITECTURE}//g")
#    echo "docker manifest create --amend $repository $key $repository"
#    docker manifest create --amend $repository $key $repository && docker manifest push $repository
#  done
}

function imageDelete() {
#  for i in $(docker images --filter "dangling=true" --format "{{.ID}}" && docker images --filter=reference="${HUB_DOCKER_USERNAME}/*${ARCHITECTURE}:latest" --format "{{.ID}}"); do
#    docker rmi -f $i
#  done
  for i in $(docker images --filter=reference="${HUB_DOCKER_USERNAME}/*:*" --format "{{.ID}}"); do
    docker rmi -f $i
  done
}

function initBuildContext() {
  if [ ! -d /tmp/autoBuildContext ]; then
    mkdir /tmp/autoBuildContext
  fi

  if [ ! -d /tmp/autoBuildContext ]; then
    mkdir /tmp/autoBuildContext
  fi
  cp -f ../Dockerfile-* /tmp/autoBuildContext
  cp -f ../*.sh /tmp/autoBuildContext/
}

function amd64() {
    if [ ! -z "$4" ]; then
      echo "docker run --privileged --rm tonistiigi/binfmt --uninstall "$4
    fi
    ARCHITECTURE=""
    autoBuildGitMaster
}

function aarch64() {
  if [[ $4 == "aarch64" ]]||[[ `uname -m` == "aarch64" ]]; then
      if [[ `uname -m` != "aarch64" ]]; then
        #https://blog.csdn.net/edcbc/article/details/139366049
        #https://github.com/multiarch/qemu-user-static?tab=readme-ov-file
        #https://hub.docker.com/r/tonistiigi/binfmt
        #https://bobcares.com/blog/mysql-5-7-arm64-docker/
        echo "docker run --privileged --rm tonistiigi/binfmt --install "$4
        docker run --privileged --rm tonistiigi/binfmt --install $4
      fi
      autoBuildGitMaster
  fi
}
ARCHITECTURE="$4"
start_time=$(date +%s)
#initBuildContext
#imageDelete
#aarch64 "$@"
#amd64 "$@"
#modifyImageTag
imagePush "$@"
cost_time=$(($(date +%s) - start_time))
echo "build time is $((cost_time / 3600))hours $((cost_time % 3600 / 60))min $((cost_time % 3600 % 60))s"