#!/bin/bash
set -eo pipefail

HUB_DOCKER_USERNAME="king607267"
EXTRACTORS_FLAG=$3
ARCHITECTURE=""
BASE_IMAGE="ubuntu:22.04"
MYSQL_BASE_IMAGE="mysql:5.7.37"

function initGitRepo() {
  #1 判断是否有对应的文件夹
  if [ ! -d "$1" ]; then
    git clone https://github.com/cmangos/"$1".git --recursive --depth=1 && cd "$1"
  else
    cd "$1" && git pull
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
  echo " docker build --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 --build-arg MYSQL_BASE_IMAGE=${MYSQL_BASE_IMAGE} --build-arg BASE_IMAGE=${BASE_IMAGE} --add-host raw.githubusercontent.com:199.232.68.133 -t ${HUB_DOCKER_USERNAME}/cmangos-$1${ARCHITECTURE}:$2 ${TARGET} -f ${DOCKER_FILE_NAME} ."
  docker build --build-arg CMANGOS_CORE=${1%-*} --build-arg REVISION_NUM=$2 --build-arg MYSQL_BASE_IMAGE=${MYSQL_BASE_IMAGE} --build-arg BASE_IMAGE=${BASE_IMAGE} --add-host raw.githubusercontent.com:199.232.68.133 -t ${HUB_DOCKER_USERNAME}/cmangos-$1${ARCHITECTURE}:$2 ${TARGET} -f ${DOCKER_FILE_NAME} .
}

declare -A DOCKER_REPO_NAMES
#DOCKER_REPO_NAMES["mangos-classic"]="classic-server,classic-realmd,classic-extractors"
#DOCKER_REPO_NAMES["mangos-tbc"]="tbc-server,tbc-realmd,tbc-extractors"
#DOCKER_REPO_NAMES["mangos-wotlk"]="wotlk-server,wotlk-realmd,wotlk-extractors"
DOCKER_REPO_NAMES["classic-db"]="classic-db"
#DOCKER_REPO_NAMES["tbc-db"]="tbc-db"
#DOCKER_REPO_NAMES["wotlk-db"]="wotlk-db"

function autoBuildGitMaster() {
  for key in ${!DOCKER_REPO_NAMES[*]}; do
    cd ~/autoBuildContext
    initGitRepo ${key}
    CURRENT_MASTER_COMMIT=$(getRepoCurrentMasterCommit)
    #获取server和realmd的docker repo
    NAMES=($(echo ${DOCKER_REPO_NAMES[$key]} | sed "s/,/\n/g"))
    for NAME in ${NAMES[*]}; do
      if [[ "${NAME}" =~ "-extractors" ]] && [ "${EXTRACTORS_FLAG}" != "true" ]; then
        echo "skip build extractors"
        continue
      fi
      cd ../file
      buildImage "${NAME}" "${CURRENT_MASTER_COMMIT}"
    done
  done
}

function modifyImageTag() {
  for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter=reference="${HUB_DOCKER_USERNAME}/*${ARCHITECTURE}"); do
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
  for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter=reference="${HUB_DOCKER_USERNAME}/*${ARCHITECTURE}"); do
    echo "docker push $key to hub"
    docker push "$key"
  done
}

function imageDelete() {
  for i in $(docker images --filter "dangling=true" --format "{{.ID}}" && docker images --filter=reference="${HUB_DOCKER_USERNAME}/*${ARCHITECTURE}:latest" --format "{{.ID}}"); do
    docker rmi -f $i
  done
  for i in $(docker images --filter=reference="${HUB_DOCKER_USERNAME}/*${ARCHITECTURE}:*" --format "{{.ID}}"); do
    docker rmi -f $i
  done
}

function initBuildContext() {
  if [ ! -d ~/autoBuildContext ]; then
    mkdir ~/autoBuildContext
  fi

  if [ ! -d ~/autoBuildContext/file ]; then
    mkdir ~/autoBuildContext/file
  fi
  cp -f ../Dockerfile-* ~/autoBuildContext/file
}

start_time=$(date +%s)
  if [[ $4 == "aarch64" ]]||[[ `uname -m` == "aarch64" ]]; then
    ARCHITECTURE="-aarch64"
    BASE_IMAGE="arm64v8/ubuntu"
    MYSQL_BASE_IMAGE="biarms/mysql:5.7.30-linux-arm64v8"
    if [[ `uname -m` != "aarch64" ]]; then
      #https://blog.csdn.net/edcbc/article/details/139366049
      #https://github.com/multiarch/qemu-user-static?tab=readme-ov-file
      echo "docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
      docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    fi
  fi
initBuildContext
#imageDelete
autoBuildGitMaster
modifyImageTag
#imagePush "$@"
cost_time=$(($(date +%s) - start_time))
echo "build time is $((cost_time / 3600))hours $((cost_time % 3600 / 60))min $((cost_time % 3600 % 60))s"
