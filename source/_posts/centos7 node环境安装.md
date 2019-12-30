---
title: centos7 node环境安装
date: 2109-12-30
categories:
- 服务配置
tags:
- hexo

---

## NVM安装

> 之前用docker装node环境也是脑子有问题 

<!--more-->

> NVM（Node version manager）顾名思义，就是Node.js的版本管理软件，可以轻松的在Node.js各个版本间切换，项目源码GitHub


## 1.下载并安装NVM脚本

```
curl https://raw.githubusercontent.com/creationix/nvm/v0.13.1/install.sh | bash

source ~/.bash_profile
```

## 2. 列出所需要的版本

```
nvm list-remote
[dkw776003@tw2 ~]$ nvm list-remote
     v0.1.14
     v0.1.15
     v0.1.16
     v0.1.17
     v0.1.18
     v0.1.19
     v0.1.20
     v0.1.21
     v0.1.22
     v0.1.23
     v0.1.24
     v0.1.25
     v0.1.26
     v0.1.27
     v0.1.28
     v0.1.29
     v0.1.30
     ...
```

## 3. 安装相应的版本

```
nvm install v11.0.0

```
## 4. 查看已安装的版本

```
$ nvm list
->   v11.0.0
      system
```

## 5.切换版本

nvm use v11.0.0



asdfas 
