自动构建说明
========================================
脚本会自动构建最新的[classic][1]，[tbc][2]，[wotlk][3]三个服务端一共9个镜像各自包含server，realmd和db。

[1]: https://github.com/cmangos/mangos-classic "classic"
[2]: https://github.com/cmangos/mangos-tbc "tbc"
[3]: https://github.com/cmangos/mangos-wotlk "wotlk"

请先确认是否已安装[docker][4]，确认安装后执行：

[4]: https://docs.docker.com/get-docker "docker"

```shell
sudo ./auto-build.sh
```
执行后会自动生成一个配置文件记录本次构建的版本，下次构建时会对比版本如果没有变化则不会再次构建。