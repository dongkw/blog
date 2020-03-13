---
title: spring注册中心config配置
thumbnail: /images/config.jpg
date: 2019-12-05
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---

# config

> 项目地址: [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)

## 父项目中新建一个模块
> 构建子模块步骤前面有不多说

<!--more-->
> eureka启动后有这个提示，要加个config项目
![](/images/15.png)


1. 引用个依赖

>`build.gradle`文件，和之前的很像，引的包不一样而已。 

```
version = '0.0.1-SNAPSHOT'

dependencies {
    implementation 'org.springframework.cloud:spring-cloud-config-server'
}

bootJar {
    mainClassName = 'xyz.jecy.config.ConfigApplication'
}
```


2. 加上个注解

> 和之前的还是一样,只是注解不同...

```

package xyz.jecy.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

@SpringBootApplication
@EnableConfigServer
public class ConfigApplication {

  public static void main(String[] args) {
    SpringApplication.run(ConfigApplication.class, args);
  }

}
```

3. 改改配置文件

> 首先把`resources`文件夹下的`application.properties`干掉，然后加上`bootstrap.yml`文件。

    1. 配置文件 

> 还是用git配置方便，毕竟项目也是要版本控制的。

```
spring:
  application:
    name: config
  cloud:
    config:
      server:
        git:
          uri: https://github.com/dongkw/spring-demo.git
          search-paths: config-repo
          username: dongkw
server:
  port: 8888
eureka:
  instance:
    hostname: localhost
  client:
    register-with-eureka: false
    fetch-registry: false 
```

> 说明 Spring Cloud Config也提供本地存储配置的方式。需要设置属性spring.profiles.active=native，Config Server会默认从应用的src/main/resource目录下检索配置文件。
    
    2. 把项目提交到git仓库中去
    
    3. 再建一个`config-repo`子模块存放配置文件




