---
title: Let's Encrypt 签名服务器
date: 2019-11-25 
categories:
- 服务配置
tags:
- nginx
- certbot
- https
---

## nginx配置

### nginx 命令
```
yum install nginx
nginx
vim /etc/nginx/nginx.conf
nginx -s reload
nginx -s stop

```
<!--more-->

## 用certbot签名证书

```

yum install epel-release
yum install certbot


certbot certonly --email xxx@qq.com --standalone -d jecy.xyz


```

>会将证书生成到这个目录下  /etc/letsencrypt
```
ls /etc/letsencrypt/

accounts  archive  csr  keys  live  renewal  renewal-hooks

```

## 修改nginx.conf

```
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  jecy.xyz;
        root         /usr/share/nginx/html;

        rewrite ^/(.*)$ https://jecy.xyz/$1 permanent;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

  server {
        listen       443 ssl http2 default_server;
        listen       [::]:443 ssl http2 default_server;
        server_name  jecy.xyz;
        root         /usr/share/nginx/html;

        ssl_certificate /etc/letsencrypt/live/jecy.xyz/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/jecy.xyz/privkey.pem;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

#        # Load configuration files for the default server block.
#        include /etc/nginx/default.d/*.conf;
#
        location / {
        }
#
#        error_page 404 /404.html;
#            location = /40x.html {
#        }
#
#        error_page 500 502 503 504 /50x.html;
#            location = /50x.html {
#        }
    }

```
>Let's Encrypt 90天过期 续期命令

`certbot renew`

