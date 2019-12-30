FROM node
MAINTAINER dongkw xxx@qq.com

# 定义工作空间
WORKDIR /app

# install hexo
RUN npm install hexo-cli -g

# 初始化当前路径 (/app) 为 hexo 路径
RUN hexo init .

# 安装 npm 包管理工具
# RUN npm install

# install apollo theme 依赖包
# RUN npm install --save hexo-renderer-jade hexo-generator-feed hexo-generator-sitemap hexo-generator-archive
RUN npm install hexo-helper-live2d live2d-widget-model-z16  --save
# COPY 本地 Hexo 的 (注意不是 Theme 的 _config.yml) 到容器内
COPY _config.yml .

# COPY source 文件夹
COPY ./source ./source
#
# COPY themes
COPY ./themes/icarus ./themes/icarus

CMD ["hexo", "s", "-l"]