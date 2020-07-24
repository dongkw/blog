---
title: docker+redis主从结构
date: 2020-04-20
categories:
- redis
tags:
- 数据库
- 运维
- redis
---

目标：一个master库两个slave库自动同步数据

<!--more--> 

## 下载最新版本镜像

```
docker pull redis

docker images

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
redis               latest              975fe4b9f798        3 days ago          98.3MB

```

## 下载redis.conf文件


```
wget http://download.redis.io/redis-stable/redis.conf

 5744  mkdir redis
 5745  mv redis.conf redis
 5747  cd redis
 5749  cp redis.conf redis-slave.conf
 5750  mv redis.conf redis-master.conf
➜  redis ls
redis-master.conf redis-slave.conf
 
```

## 修改配置文件

### 主库配置文件`redis-master`

把原来的 `bind 127.0.0.1` 注释掉

`bind 0.0.0.0`所有地址可以访问
`daemonize yes` 以守护进程启动
`requirepass master` 主库密码

```

bind 0.0.0.0    
daemonize yes
requirepass master

```

### 从库配置文件`redis-slave`

`replicaof redis-master 6379` 设置主库为 docker redis-master镜像的6379端口。 slaveof命令从5.0弃用但是兼容
`masterauth master` 主库密码

```
bind 0.0.0.0
daemonize yes
requirepass slave
replicaof redis-master 6379
masterauth master

```

## 启动redis 镜像 

```
 5796   docker run -itd --name redis-master \
        -v /Users/xinzhilimacpro/redis/redis-master.conf:/usr/local/etc/redis/redis.conf \
        -p 7000:6379  \
        --rm \
        redis \
        redis-server  /usr/local/etc/redis/redis.conf 

 5821   docker run -itd --name redis-slave1  \
        -v /Users/xinzhilimacpro/redis/redis-slave.conf:/usr/local/etc/redis/redis.conf \
        -p 7001:6379   \
        --link redis-master:master    \
        --rm \
        redis \
        redis-server  /usr/local/etc/redis/redis.conf
 
 5823   docker run -itd --name redis-slave2  \  
        -v /Users/xinzhilimacpro/redis/redis-slave.conf:/usr/local/etc/redis/redis.conf \
        -p 7002:6379 \
        --link redis-master:master  \
        --rm \
        redis \
        redis-server  /usr/local/etc/redis/redis.conf
 
```

然后主库插入数据 从库可以直接查询到。
因为纯属自己体验所用没有把redis的数据设置映射文件，而且基本是docker命令和redis本身无关。


# redis集群 

设置了主从数据库以后

## Sentinel(哨兵)

