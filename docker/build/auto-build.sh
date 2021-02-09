#!/bin/bash
set -eo pipefail

CONFIG_FILE="auto-builder.config"
HUB_DOCKER_USERNAME="king607267"

function initConfFile() {
  if [ ! -f ~/${CONFIG_FILE} ]; then
    cat >~/${CONFIG_FILE} <<EOF
#记录最后一次构建的版本号
mangos-classic=00
classic-db=00

mangos-wotlk=00
wotlk-db=00

mangos-tbc=00
tbc-db=00
EOF
  fi
}

function updateConfFiles() {
  echo "updating... config file:"$1=$2
  sed -i "s/^$1=.*$/$1=$2/" ~/${CONFIG_FILE}
}

function initGitRepo() {
  #1 判断是否有对应的文件夹
  if [ ! -d "$1" ]; then
    git clone https://github.com/cmangos/$1.git && cd $1
  else
    cd $1 && git pull --tags
  fi
}

function getRepoCurrentTag() {
  echo $(git tag --sort=-creatordate | awk '{if(NR==1) print}')
}

function getLastedCommit() {
  line=$(grep -r "^$1=" ~/${CONFIG_FILE})
  echo ${line#*=}
}

function getBuildType() {
  line=$(grep -r "^build-type=" ~/${CONFIG_FILE})
  echo ${line#*=}
}

function getRepoCurrentTagCommit() {
  echo $(git log $(getRepoCurrentTag) -1 --pretty=format:'%h')
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
  else
    TARGET="--target realmd"
    DOCKER_FILE_NAME="Dockerfile-server"
  fi
  echo " docker build --build-arg CMANGOS_CORE=${1%-*} --add-host raw.githubusercontent.com:199.232.68.133 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ../${DOCKER_FILE_NAME} ."
  docker build --build-arg CMANGOS_CORE=${1%-*} --add-host raw.githubusercontent.com:199.232.68.133 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ../${DOCKER_FILE_NAME} .
}

declare -A DOCKER_REPO_NAMES
DOCKER_REPO_NAMES["mangos-classic"]="classic-server,classic-realmd"
DOCKER_REPO_NAMES["mangos-tbc"]="tbc-server,tbc-realmd"
DOCKER_REPO_NAMES["wotlk-db"]="wotlk-db"
DOCKER_REPO_NAMES["classic-db"]="classic-db"
DOCKER_REPO_NAMES["tbc-db"]="tbc-db"
DOCKER_REPO_NAMES["mangos-wotlk"]="wotlk-server,wotlk-realmd"

function autoBuildGitMaster() {
  for key in ${!DOCKER_REPO_NAMES[*]}; do
    initGitRepo ${key}
    #前当前版本和前一次不同需要构建
    CURRENT_MASTER_COMMIT=$(getRepoCurrentMasterCommit)
    if [ $(getLastedCommit ${key}) != ${CURRENT_MASTER_COMMIT} ]; then
      #获取server和realmd的docker repo
      NAMES=($(echo ${DOCKER_REPO_NAMES[$key]} | sed "s/,/\n/g"))
      for NAME in ${NAMES[*]}; do
        buildImage ${NAME} ${CURRENT_MASTER_COMMIT}
        checkImage ${NAME} ${CURRENT_MASTER_COMMIT}
        updateConfFiles ${key} ${CURRENT_MASTER_COMMIT}
      done
    else
      echo "${key} no build"
    fi
    cd ..
  done
}

declare -A DOCKER_IMAGES

function checkImage() {
  DOCKER_IMAGE_NAME="${HUB_DOCKER_USERNAME}/cmangos-$1"
  DOCKER_IMAGE_IS_MATCH_TAR_FILE="false"
  # 判断是否有镜像,存在时创建相应的容器实例
  for i in [ $(docker images) ]; do
    if [[ "$i" == "$2" ]]; then
      DOCKER_IMAGE_IS_MATCH_TAR_FILE="true"
      echo "${DOCKER_IMAGE_NAME} build success!"
      DOCKER_IMAGES[${DOCKER_IMAGE_NAME}]=$2
      break
    fi
  done
  if [[ $DOCKER_IMAGE_IS_MATCH_TAR_FILE == "false" ]]; then
    echo "${DOCKER_IMAGE_NAME} build fail exit!"
    exit 1
  fi
}

function modifyImageTag() {
  for key in ${!DOCKER_IMAGES[*]}; do
    echo "docker tag $key:${DOCKER_IMAGES[$key]} to  $key:latest"
    docker tag $key:${DOCKER_IMAGES[$key]} $key:latest
  done
}

function imagePush() {
  for key in ${!DOCKER_IMAGES[*]}; do
    if [ "$1" == "latest" ]; then
      echo "docker push $key:latest to hub"
      docker push $key:latest
    else
      echo "docker push $key:${DOCKER_IMAGES[$key]} to hub"
      docker push $key:${DOCKER_IMAGES[$key]}
    fi
  done
}

function imageDelete() {
  for i in $(docker images --filter "dangling=true" --format "{{.ID}}" && sudo docker images --filter=reference="${HUB_DOCKER_USERNAME}/*:latest" --format "{{.ID}}") ; do
      docker rmi -f $i
  done
}

start_time=$(date +%s)
initConfFile
cp -f ../Dockerfile-* /tmp
cd /tmp
imageDelete
autoBuildGitMaster
#imagePush ""
modifyImageTag
#imagePush "latest"
end_time=$(date +%s)
cost_time=$(($end_time - $start_time))
echo "build time is $(($cost_time / 60))min $(($cost_time % 60))s"