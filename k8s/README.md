部署说明
========================================
classic、tbc、wotlk文件夹中分别包含3个文件

db.yaml用做部署mysql数据库。

server.yaml用做部署realmd，和server。

secret.yaml用于存放帐号密码等信息。

pv_pvc.yaml用于存放数据库文件(可选)，地图文件（必须），配置文件（可选）。

先部署pv_pvc和secret再db.yaml和server.ymal完毕后可以开放nodePort访问服务，不过建议使用[metallb][1]。
```shell
kubectl create sc wow
kubectl apply -f classic/pv_pvc.yaml,classic/secret.yaml -n wow
kubectl apply -f classic/db.yaml -n wow
kubectl apply -f classic/server.yaml -n wow
```

[1]: https://metallb.universe.tf/ "metallb"