自动构建说明
========================================
脚本会自动构建最新的[classic][1]，[tbc][2]，[wotlk][3]，[extractors][4]，registration一共15个镜像。

[1]: https://github.com/cmangos/mangos-classic "classic"
[2]: https://github.com/cmangos/mangos-tbc "tbc"
[3]: https://github.com/cmangos/mangos-wotlk "wotlk"
[4]: https://github.com/cmangos/issues/wiki/Installation-Instructions#compiling-cmangos-nix--macos "extractors"
[5]: https://docs.docker.com/get-docker "docker"
[6]: https://github.com/direnv/direnv
请先确认是否已安装[docker][5]，确认安后执行：



```shell
git clone https://github.com/king607267/cmangos-wrapper.git && cd cmangos-wrapper/docker/build  && docker login && ./auto-build.sh
```
可以在环境变量中指定指定如下可选值:
```shell
export HTTP_PROXY=http://proxy:1111
export HTTPS_PROXY=http://proxy:1111
export NO_PROXY=localhost,127.0.0.1
export AARCH64_NODE_IP=192.168.1.1
```
修改变量值使其符合你的环境推荐使用[direnv][6],默认只构建amd64架构镜像。 如果你想构建aarch64镜像可以指定一台aarch64机器并安装docker,
然后指定AARCH64_NODE_IP会一起构建aarch64架构镜像。
