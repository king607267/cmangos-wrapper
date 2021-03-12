自动构建说明
========================================
脚本会自动构建最新的[classic][1]，[tbc][2]，[wotlk][3]三个服务端一共9个镜像各自包含server，realmd和db。

[1]: https://github.com/cmangos/mangos-classic "classic"
[2]: https://github.com/cmangos/mangos-tbc "tbc"
[3]: https://github.com/cmangos/mangos-wotlk "wotlk"

请先确认是否已安装[docker][4]，确认安装后执行：

[4]: https://docs.docker.com/get-docker "docker"

```shell
git pull && sudo ./auto-build.sh [Docker ID] [password]
```
需要指定两个参数，Docker hub ID和password执行后会自动构建镜像，构建完成会推送镜像到你的仓库。