---
title: docker + hexo 配置
date: 2019-11-24
categories:
- 服务配置
tags:
- docker
- hexo

---

# docker hexo



## hexo下载


 ```

   npm install -g hexo-cli 
   npm i npm
   mkdir blog
   hexo init blog
   hexo s
   
 ```

## hexo主题

```
git clone https://github.com/theme-next/hexo-theme-next themes/next
git clone https://github.com/litten/hexo-theme-yilia.git themes/yilia
```
<!--more-->
## docker配置

### dockerfile文件

```
FROM node
MAINTAINER dongkw xxx@qq.com

# 定义工作空间
WORKDIR /app

# install hexo
RUN npm install hexo-cli -g

# 初始化当前路径 (/app) 为 hexo 路径
RUN hexo init .

# 安装 npm 包管理工具
RUN npm install

# install apollo theme 依赖包
RUN npm install --save hexo-renderer-jade hexo-generator-feed hexo-generator-sitemap hexo-generator-archive

# COPY 本地 Hexo 的 (注意不是 Theme 的 _config.yml) 到容器内
COPY _config.yml .

# COPY source 文件夹
COPY ./source ./source
#
# COPY themes
COPY ./themes/icarus ./themes/icarus

CMD ["hexo", "s", "-l"]


```

### docker 命令

```
# 构建镜像
docker build -t my_hexo_node .

# 改成对应dockerhub文件
docker tag my_hexo_node dongkw/hexo:latest

docker push dongkw/hexo

#启动命令 用自己建的文件夹替换镜像内文件
docker run -p4000:4000  -it -v /home/dkw776003/source:/app/source -d --rm --privileged --name hexo dongkw/hexo
 
  说明 --privileged 权限 自动更新用的
      -it -v /home/dkw776003/source:/app/source 替换目录
    
```

### 上传博客内容

`scp -i ~/.ssh/id_rsa_tw2  /Users/xinzhilimacpro/myworkspace/blog/source/_posts/*  dkw776003@34.80.218.241:~/source/_posts`