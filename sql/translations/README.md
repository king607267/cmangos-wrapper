国际化说明
========================================
数据库国际化支持语言如下：

Chinese，French，German，Italian，Korean，Russian，Spanish，Spanish_South_American，Taiwanese

首先通过文件translations.config配置你的数据库相关信息、需要国际化的服务端以及对应的语言然后执行：

```shell
./translations.sh
```
注意:该脚本已经集成到[launch_mysql.sh](..%2F..%2Fdocker%2Flaunch_mysql.sh)通常情况下无需单独执行.