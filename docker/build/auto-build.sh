#!/bin/bash
set -eo pipefail

HUB_DOCKER_USERNAME="king607267"
BUILD_THREAD_COUNT="${BUILD_THREAD_COUNT:--j6}"
function localsFile(){
if [[ "$1" != *-db ]]; then
  return
fi
local LOCALS_FILE_PATH="/tmp/autoBuildContext/translations"
local BROADCAST_PATH
mkdir -p ${LOCALS_FILE_PATH}
if [[ "$1" == *classic* ]]; then
    # "classic use tbc BroadcastTextLocales."
    CMANGOS_CORE="zero"
    CMANGOS_CORE2="classic"
    BROADCAST_PATH="https://raw.githubusercontent.com/cmangos/tbc-db/master/locales/BroadcastTextLocales.sql"
  elif [[ "$1" = *tbc* ]]; then
    CMANGOS_CORE="one"
    CMANGOS_CORE2="tbc"
    BROADCAST_PATH="https://raw.githubusercontent.com/cmangos/tbc-db/master/locales/BroadcastTextLocales.sql"
  else
    CMANGOS_CORE="two"
    CMANGOS_CORE2="wotlk"
    BROADCAST_PATH="https://raw.githubusercontent.com/cmangos/wotlk-db/master/locales/BroadcastTextLocales.sql"
fi
local DB_FILES="translations-db-${CMANGOS_CORE2}"
if [ ! -f "${LOCALS_FILE_PATH}/${DB_FILES}.tar.gz" ]; then
  cd ${LOCALS_FILE_PATH}
  if [ ! -d "translations_${CMANGOS_CORE}" ]; then
    git clone https://github.com/mangos${CMANGOS_CORE}/database.git translations_${CMANGOS_CORE} -b master --recursive --depth=1
  fi

  local BTL_PREFIX="BroadcastTextLocales_${CMANGOS_CORE2}"
  if [ ! -f "${BTL_PREFIX}.sql" ]; then
    wget --no-check-certificate -O "${BTL_PREFIX}".sql ${BROADCAST_PATH}
  fi

  local LOACL_PATH=`ls /tmp/autoBuildContext/translations/translations_${CMANGOS_CORE}/Translations/Translations`
  mkdir -p ${DB_FILES}
  cp -f "${BTL_PREFIX}.sql" "${BTL_PREFIX}_bak.sql"
  for TRANS in ${LOACL_PATH}; do
      if [ "${TRANS}" = "German" ]; then
        LOCALE="deDE"
      elif [ "${TRANS}" = "Spanish" ]; then
        LOCALE="esES"
      elif [ "${TRANS}" = "Spanish_South_American" ]; then
        LOCALE="esMX"
      elif [ "${TRANS}" = "French" ]; then
        LOCALE="frFR"
      elif [ "${TRANS}" = "Korean" ]; then
        LOCALE="koKR"
      elif [ "${TRANS}" = "Russian" ]; then
        LOCALE="ruRU"
      elif [ "${TRANS}" = "Taiwanese" ]; then
        LOCALE="zhTW"
      elif [ "${TRANS}" = "Italian" ]; then
        LOCALE="itIT"
      else
        LOCALE="zhCN"
      fi
    echo "Processing ${BTL_PREFIX}_${LOCALE}.sql."
    sed -i "s/),(/);\nINSERT INTO \`broadcast_text_locale\` VALUES (/g" "${BTL_PREFIX}_bak.sql"
    cat "${BTL_PREFIX}_bak.sql" | grep -E "${LOCALE}|/\*|SET CHARACTER|SET NAMES|RUNCATE TABLE|LOCK TABLES|UNLOCK TABLES" >>"${BTL_PREFIX}_${LOCALE}.sql"
    mkdir -p "${DB_FILES}/${TRANS}" && mv -f "${BTL_PREFIX}_${LOCALE}.sql" "${DB_FILES}/${TRANS}"

    local SQL_123="1+2+3_${LOCALE}.sql"
    echo "Processing ${SQL_123}."
    local SQL_PATH="/tmp/autoBuildContext/translations/translations_${CMANGOS_CORE}/Translations"
    if [ ! -f "${SQL_123}" ]; then
      cat "${SQL_PATH}/1_LocaleTablePrepare.sql" >>${SQL_123}
      echo -e >>${SQL_123}
      cat "${SQL_PATH}/2_Add_NewLocalisationFields.sql" >>${SQL_123}
      echo -e >>${SQL_123}
      cat "${SQL_PATH}/3_InitialSaveEnglish.sql" >>${SQL_123}
      # 注释并替换相关SQL（合并为单次 sed 操作）
      sed -i \
        -e 's/^INSERT.*\(command\).*$/-- &/' \
        -e '/^        ALTER.*\(command\).*/,/;$/s/^/-- &/' \
        -e '/^UPDATE.*\(command\).*/,/;$/s/^/-- &/' \
        -e 's/db_script/dbscript/' \
        -e 's/^INSERT.*\(creature_ai_texts\).*$/-- &/' \
        -e '/^        ALTER.*\(creature_ai_texts\).*/,/;$/s/^/-- &/' \
        -e '/^UPDATE.*\(creature_ai_texts\).*/,/;$/s/^/-- &/' \
        -e 's/^INSERT.*\(dbscript_string\).*$/-- &/' \
        -e '/^        ALTER.*\(dbscript_string\).*/,/;$/s/^/-- &/' \
        -e '/^UPDATE.*\(dbscript_string\).*/,/;$/s/^/-- &/' \
        ${SQL_123}
      mv -f ${SQL_123} "${DB_FILES}/${TRANS}"

      local FULL_SQL="full_${LOCALE}.sql"
      echo "Processing ${FULL_SQL}."
      if [ ! -f "${FULL_SQL}" ]; then
        cd "${LOCALS_FILE_PATH}/translations_${CMANGOS_CORE}/Translations/Translations/${TRANS}"
        #https://github.com/cmangos/issues/issues/2331
        cat $(ls -I "${TRANS}_CommandHelp.sql" -I "*db_script_string.sql" -I "*Creature_AI_Texts.sql" -I "*creature_ai_texts.sql" | grep ".*\.sql") >${FULL_SQL}
        sed -i 's/db_script/dbscript/' ${FULL_SQL}
        mv -f ${FULL_SQL} "${LOCALS_FILE_PATH}/${DB_FILES}/${TRANS}"
        cd "${LOCALS_FILE_PATH}"
      fi
    fi
  done
  tar -czf "${DB_FILES}.tar.gz" ${DB_FILES} && chmod o+w "${DB_FILES}.tar.gz"
  cd /tmp/autoBuildContext
else
  echo "skip Translations Processed."
fi
}

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

function createBuildx() {
      PLATFORM="--platform linux/amd64"
      local BUILDX_VAR=`docker buildx ls --format "{{.Name}} {{.DriverEndpoint}}" | grep cmangos_buildx`
      if [ -z "$BUILDX_VAR" ]; then
        #if use proxy https://stackoverflow.com/questions/73210141/running-buildkit-using-docker-buildx-behind-a-proxy
        #buildx set proxy https://github.com/docker/buildx/pull/170
        #https://dev.to/aboozar/build-docker-multi-platform-image-using-buildx-remote-builder-node-5631
        #https://medium.com/@spurin/using-docker-and-multiple-buildx-nodes-for-simultaneous-cross-platform-builds-cee0f797d939
        #https://www.docker.com/blog/multi-platform-docker-builds/
        #https://medium.com/@hassanahmad61931/docker-buildx-building-multi-platform-container-images-made-easy-304e1c3f00f1
        #https://codeberg.org/woodpecker-plugins/docker-buildx/issues/82
        echo "docker buildx create --use --name cmangos_buildx \
              --platform linux/amd64 \
              --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 \
              --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000 \
              --driver-opt 'env.no_proxy='${NO_PROXY}' \
              --driver-opt env.http_proxy=${HTTP_PROXY} \
              --driver-opt env.https_proxy=${HTTPS_PROXY}"

         docker buildx create --use --name cmangos_buildx \
          --platform linux/amd64 \
          --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 \
          --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000 \
          --driver-opt '"env.no_proxy='${NO_PROXY}'"' \
          --driver-opt env.http_proxy=${HTTP_PROXY} \
          --driver-opt env.https_proxy=${HTTPS_PROXY}
        else
          echo "cmangos_buildx already exists."
        fi


        if [ -n "$AARCH64_NODE_IP" ]; then
        local AARCH64_NODE=`echo ${BUILDX_VAR} | grep ${AARCH64_NODE_IP}`;
          if [ -z "$AARCH64_NODE" ]; then
            echo "docker buildx create --name cmangos_buildx \
                          --append \
                          --node cmangos_buildx_aarch64 \
                          --platform linux/arm64 \
                          ssh://${AARCH64_NODE_IP} \
                          --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 \
                          --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000 \
                          --driver-opt 'env.no_proxy='${NO_PROXY}' \
                          --driver-opt env.http_proxy=${HTTP_PROXY} \
                          --driver-opt env.https_proxy=${HTTPS_PROXY}"

            docker buildx create --name cmangos_buildx \
            --append \
            --node cmangos_buildx_aarch64 \
            --platform linux/arm64 \
            ssh://${AARCH64_NODE_IP} \
            --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 \
            --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000 \
            --driver-opt '"env.no_proxy='${NO_PROXY}'"' \
            --driver-opt env.http_proxy=${HTTP_PROXY} \
            --driver-opt env.https_proxy=${HTTPS_PROXY}
          fi
          PLATFORM=${PLATFORM}",linux/arm64"
      else
        PLATFORM="--load "${PLATFORM}
      fi
}

function buildImage() {
  #构建
  DOCKER_FILE_NAME=""
  TARGET=""
  if [[ $1 =~ "3in1-db" ]]; then
    DOCKER_FILE_NAME="Dockerfile-3in1-db"
  elif [[ $1 =~ "-db" ]]; then
    DOCKER_FILE_NAME="Dockerfile-db"
  elif [[ $1 =~ "-server" ]]; then
    TARGET="--target mangosd"
    DOCKER_FILE_NAME="Dockerfile-server"
  elif [[ $1 =~ "-extractors" ]]; then
    TARGET="--target extractors"
    DOCKER_FILE_NAME="Dockerfile-server"
  elif [[ $1 == "registration" ]]; then
    DOCKER_FILE_NAME="Dockerfile-registration"
  else
    TARGET="--target realmd"
    DOCKER_FILE_NAME="Dockerfile-server"
  fi
  #https://stackoverflow.com/questions/22179301/how-do-you-run-apt-get-in-a-dockerfile-behind-a-proxy
  #export DOCKER_CONFIG=~/.docker
  # 自动判断是否需要多平台构建
  if [ -n "$AARCH64_NODE_IP" ] || [ "$3" == "--push" ]; then
    # 多平台模式：检测到远程 arm64 节点或明确要求 push
    PLATFORM="--platform linux/amd64,linux/arm64"
  else
    # 单平台模式：本地构建
    PLATFORM="--platform linux/amd64"
  fi
  # buildx 已在脚本启动时设置，无需重复 use
  local THREAD_ARG=""
  if [[ "${DOCKER_FILE_NAME}" == "Dockerfile-server" ]] && [ -n "${BUILD_THREAD_COUNT}" ]; then
    THREAD_ARG="--build-arg THREAD_COUNT=${BUILD_THREAD_COUNT}"
  fi
  echo " docker buildx build ${PLATFORM} --build-arg CMANGOS_CORE=${1%-*} ${THREAD_ARG} -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:latest ${TARGET} -f ${DOCKER_FILE_NAME} . $3"
  docker buildx build ${PLATFORM}  --build-arg CMANGOS_CORE=${1%-*} ${THREAD_ARG} -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 -t ${HUB_DOCKER_USERNAME}/cmangos-$1:latest ${TARGET} -f ${DOCKER_FILE_NAME} . $3


#    echo " docker build --build-arg CMANGOS_CORE=${1%-*} -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} ."
#    docker build --build-arg CMANGOS_CORE=${1%-*} -t ${HUB_DOCKER_USERNAME}/cmangos-$1:$2 ${TARGET} -f ${DOCKER_FILE_NAME} .
}

declare -A DOCKER_REPO_NAMES_SERVER
DOCKER_REPO_NAMES_SERVER["registration"]="registration"
DOCKER_REPO_NAMES_SERVER["mangos-classic"]="classic-server,classic-realmd,classic-extractors"
DOCKER_REPO_NAMES_SERVER["mangos-tbc"]="tbc-server,tbc-realmd,tbc-extractors"
DOCKER_REPO_NAMES_SERVER["mangos-wotlk"]="wotlk-server,wotlk-realmd,wotlk-extractors"

declare -A DOCKER_REPO_NAMES_DB
DOCKER_REPO_NAMES_DB["classic-db"]="classic-db"
DOCKER_REPO_NAMES_DB["tbc-db"]="tbc-db"
DOCKER_REPO_NAMES_DB["wotlk-db"]="wotlk-db"

declare -A DOCKER_REPO_NAMES_3IN1_DB
DOCKER_REPO_NAMES_3IN1_DB["3in1-db"]="3in1-db"

declare -A GLOBAL_MASTER_COMMIT
GLOBAL_MASTER_COMMIT["mangos-classic"]=""
GLOBAL_MASTER_COMMIT["mangos-tbc"]=""
GLOBAL_MASTER_COMMIT["mangos-wotlk"]=""
GLOBAL_MASTER_COMMIT["classic-db"]=""
GLOBAL_MASTER_COMMIT["tbc-db"]=""
GLOBAL_MASTER_COMMIT["wotlk-db"]=""
GLOBAL_MASTER_COMMIT["3in1-db"]="$(date +"%Y%m%d%H")"
GLOBAL_MASTER_COMMIT["registration"]="$(getRepoCurrentMasterCommit)"

function autoBuildGitMaster() {
  local -n repos=$1
  for key in ${!repos[*]}; do
    cd /tmp/autoBuildContext
    initGitRepo ${key}
    local CURRENT_MASTER_COMMIT=""
    if [ "${GLOBAL_MASTER_COMMIT["${key}"]}" == "" ]; then
      cd ${key}
      CURRENT_MASTER_COMMIT=$(getRepoCurrentMasterCommit)
      cd ..
      GLOBAL_MASTER_COMMIT["${key}"]="${CURRENT_MASTER_COMMIT}"
    else
      CURRENT_MASTER_COMMIT="${GLOBAL_MASTER_COMMIT["${key}"]}"
    fi
    #获取SERVER和realmd的docker repo
    NAMES=($(echo ${repos[$key]} | sed "s/,/\n/g"))
    for NAME in ${NAMES[*]}; do
      localsFile "${NAME}"
      buildImage "${NAME}" "${CURRENT_MASTER_COMMIT}" "${2}"
      if [ "${2}" == "--push" ]; then
       echo "sleep 120s for Docker Hub propagation..."
       sleep 120s
      fi
    done
  done
}

function initBuildContext() {
  if [ ! -d /tmp/autoBuildContext ]; then
    mkdir /tmp/autoBuildContext
  fi
  cp -f ../Dockerfile-* /tmp/autoBuildContext
  cp -f ../*.sh /tmp/autoBuildContext
  if [ ! -d /tmp/autoBuildContext/registration ]; then
    cp -rf ../../registration /tmp/autoBuildContext
  fi
  #Copy maps .7z to build context
  cp -f ~/WoW/maps/classic_maps.7z ~/WoW/maps/tbc_maps.7z ~/WoW/maps/wotlk_maps.7z /tmp/autoBuildContext
}

function imageBuildServer() {
  autoBuildGitMaster DOCKER_REPO_NAMES_SERVER ${1:-""}
}

function imageBuildDB() {
  autoBuildGitMaster DOCKER_REPO_NAMES_DB ${1:-""}
}

function imageBuild3in1DB() {
  autoBuildGitMaster DOCKER_REPO_NAMES_3IN1_DB ${1:-""}
}

function imagePush() {
  autoBuildGitMaster DOCKER_REPO_NAMES_SERVER "--push"
  autoBuildGitMaster DOCKER_REPO_NAMES_DB "--push"
  autoBuildGitMaster DOCKER_REPO_NAMES_3IN1_DB "--push"
}

function imageLoad() {
  autoBuildGitMaster DOCKER_REPO_NAMES_SERVER "--load"
  autoBuildGitMaster DOCKER_REPO_NAMES_DB "--load"
  autoBuildGitMaster DOCKER_REPO_NAMES_3IN1_DB "--load"
}

start_time=$(date +%s)
initBuildContext
# 提前创建 buildx 实例，避免每次构建时检查
createBuildx
docker buildx use cmangos_buildx

# 提前确定构建模式
if [ -n "$AARCH64_NODE_IP" ]; then
  BUILD_MODE="--push"
  echo "检测到多平台构建配置（AARCH64_NODE_IP=$AARCH64_NODE_IP），使用 push 模式"
else
  BUILD_MODE="--load"
  echo "检测到单平台构建，使用 load 模式"
fi

# 传递参数到构建函数，一次性完成构建
imageBuildDB $BUILD_MODE
imageBuild3in1DB $BUILD_MODE
imageBuildServer $BUILD_MODE
cost_time=$(($(date +%s) - start_time))
echo `date +"%H:%M:%S"`' build time is '$((cost_time / 3600))'hours '$((cost_time % 3600 / 60))'min '$((cost_time % 3600 % 60))'s'