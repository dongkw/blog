---
title: gateway 服务网关配置
thumbnail: https://jecy.xyz/web/images/gateway.png
date: 2019-12-18
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---
## gateway简介
> Spring Cloud Gateway是spring团队基于netty重写的API Gateway组件，相对于Zuul性能较好，其不仅提供统一的路由方式，并且基于Filter链的方式提供了网关基本的功能，例如：安全，监控/埋点，和限流等。
<!--more-->

## gateway工作原理

![](https://jecy.xyz/web/images/17.png)

## gateway功能

1. 协议转换，路由转发
2. 流量聚合，对流量进行监控，日志输出
3. 作为整个系统的前端工程，对流量进行控制，有限流的作用
4. 作为系统的前端边界，外部流量只能通过网关才能访问系统
5. 可以在网关层做权限的判断
6. 可以在网关层做缓存

## gateway用法

> 就现在的项目来说用到的只有路由功能。

### 配置文件

> 需要注意的只有三个地方

1. build.gradle文件

``` 
version = '0.0.1-SNAPSHOT'
configurations {
    compile.exclude module: 'spring-boot-starter-web'
    all*.exclude group: 'org.springframework.boot', module: 'spring-boot-starter-web'
}
dependencies {
    implementation 'org.springframework.cloud:spring-cloud-starter-gateway'

}
bootJar {
    mainClassName = 'xyz.jecy.gateway.GatewayApplication'

}

```
2. bootstrap.yml

```
server:
  port: 9999
//这里面可以写路由规则 下面去掉注释和3里面意思一样
#spring:
#  cloud:
#    gateway:
#      routes:
#        - id: user_route
#          uri: http://localhost:8000
#          predicates:
#            - Path=/user/**
#          filters:
#            - StripPrefix=1

```


3. GatewayApplication

```
package xyz.jecy.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class GatewayApplication {

  public static void main(String[] args) {
    SpringApplication.run(GatewayApplication.class, args);
  }

  //自定义路由规则，意思是把 http://localhost:9999/user/aaa转到 http://localhost:8000/aaa
  @Bean
  public RouteLocator myRoutes(RouteLocatorBuilder builder) {
    return builder.routes()
        .route(p -> p
            .path("/user/**")
            .filters(f -> f.stripPrefix(1))
            .uri("http://127.0.0.1:8000"))
        .route(p -> p
            .path("/order/**")
            .filters(f -> f.stripPrefix(1))
            .uri("http://127.0.0.1:8001")
        )
        .build();

  }
}
```


> 项目地址: [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)



