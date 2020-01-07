---
title: spring注册中心eureka配置
thumbnail: https://jecy.xyz/web/images/eureka.jpeg
date: 2019-12-02
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---

# eureka

> 项目地址: [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)

1. 引用个依赖

<!--more-->

>就是子项目eureka的build.gradle

```
version = '0.0.1-SNAPSHOT'

dependencies {
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-server'
}

bootJar {
    mainClassName = 'xyz.jecy.eureka.EurekaApplication'
}
```

2. 加上个注解

```
package xyz.jecy.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class EurekaApplication {

  public static void main(String[] args) {
    SpringApplication.run(EurekaApplication.class, args);
  }

}
```

3. 改改配置文件

> 首先把`resources`文件夹下的`application.properties`干掉，然后加上`bootstrap.yml`文件。

```
spring:
  application:
    name: eureka
  cloud:
    config:
      uri: http://localhost:8888/config

server:
  port: 8761
eureka:
  instance:
    hostname: localhost
  client:
    register-with-eureka: false
    fetch-registry: false      
```

> 关于找config项目文件，这里有个执行顺序 `bootstrap.yml` > 默认啥都不填 > `application.yml`。

4. 点下启动按钮

![](https://jecy.xyz/web/images/14.png)

> `http://localhost:8761/` 应该启动完了