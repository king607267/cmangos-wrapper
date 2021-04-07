自动构建说明
========================================
脚本会自动构建最新的[classic][1]，[tbc][2]，[wotlk][3]，[extractors][4]（可选）每个版本的server，realmd，db和可选的extractors一共12个镜像。

[1]: https://github.com/cmangos/mangos-classic "classic"
[2]: https://github.com/cmangos/mangos-tbc "tbc"
[3]: https://github.com/cmangos/mangos-wotlk "wotlk"
[4]: https://github.com/cmangos/issues/wiki/Installation-Instructions#compiling-cmangos-nix--macos "extractors"

请先确认是否已安装[docker][4]，确认安装后执行：

[4]: https://docs.docker.com/get-docker "docker"

```shell
git pull && sudo ./auto-build.sh [Docker ID] [password] [extractors]
```
需要指定参数，Docker hub ID，password和可选的bool参数extractors指定是否构建地图提取器，执行构建完所有镜像后成会推送镜像到你的仓库。