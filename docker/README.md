构建指南
========================================
数据库
------------
使用Dockerfile-db构建镜像使用如下命令:
```shell
sudo docker build --build-arg CMANGOS_CORE=classic -t cmangos-docker/cmangos-classic-db:1.0 -f Dockerfile-db .
```
认证登陆服务器
------------
使用Dockerfile-realmd构建镜像使用如下命令:
```shell
sudo docker build --build-arg CMANGOS_CORE=classic -t cmangos-docker/cmangos-classic-realmd:1.0 --target realmd -f Dockerfile-server .
```
游戏逻辑服务器
------------
使用Dockerfile-mangosd构建镜像使用如下命令:
```shell
sudo docker build --build-arg CMANGOS_CORE=classic -t cmangos-docker/cmangos-classic-server:1.0 --target mangosd -f Dockerfile-server .
```
提示
------------
参数CMANGOS_CORE支持三种：classic(经典旧世)、tbc(燃烧的远征)、wotlk(巫妖王之怒)、请在构建时指定其中一种，不指定默认为classic。