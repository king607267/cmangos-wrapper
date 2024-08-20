部署说明
========================================
classic、tbc、wotlk文件夹中分别包含4个文件

db.yaml用做部署mysql数据库

server.yaml用做部署realmd，和server

pv_pvc.yaml用于存放数据库文件，地图文件，配置文件（可选）

secret.yaml用于存放帐号密码等信息。

先部署pv_pvc和secret再db.yaml和server.ymal完毕后可以开放nodePort访问服务，不过建议使用[metallb][1]。
```shell
kubectl create sc classic
kubectl apply -f classic/pv_pvc.yaml,classic/secret.yaml -n classic
kubectl apply -f classic/db.yaml -n classic
kubectl apply -f classic/server.yaml -n classic
```

[1]: https://metallb.universe.tf/ "metallb"