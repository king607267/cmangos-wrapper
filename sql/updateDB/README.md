数据库更新说明
========================================
#### db_version更新
当你的服务端运行一段时间后你可能会想把server和realmd升级到最新，但是最新版本可能和你现有的数据库版本不一致不用担心。
首先修改一下update-db-ver.sh中的数据库相关信息、要更新的服务端然后执行：

```shell
./update-db-ver.sh
```
数据库将会更新到最新版本。

#### realmlist更新
修改update_realmd.sql中的name,address,port使之符合你的要求后去数据库中执行。 或许有天你想和你的小伙伴一起冒险这将
很有趣，那么你可以把你的服务端ip修改为你的域名并做好端口映射，最后别忘了修改客户端realmlist.wtf文件其中的地址需要和
数据库保持一致。

你也可以在容 器启动时时指定REALM_NAME，REALM_IP和REALM_PORT三个ENV效果相同，不再需要执行update_realmd.sql。