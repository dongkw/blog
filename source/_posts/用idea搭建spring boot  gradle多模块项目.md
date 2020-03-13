---
title: idea搭建spring boot gradle多模块项目
thumbnail: /images/idea.jpg
date: 2019-11-29
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---

# 创建项目

> 项目地址: [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)

1. 创建一个gradle项目

<!--more-->

![](/images/new/1.png)

![](/images/new/3.png)

![](/images/new/4.png)

2. 删掉多余的src目录

![](/images/new/5.png)

3. 创建子模块

![](/images/new/6.png)

![](/images/new/7.png)

![](/images/new/8.png)

![](/images/new/9.png)

4. 删掉子模块里多余内容
![](/images/new/11.png)

5. 修改子模块里build.gradle文件
``` 
version = '0.0.1-SNAPSHOT'

dependencies {
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-server'
}

bootJar {
    mainClassName = 'xyz.jecy.eureka.EurekaApplication'
}

```

6. 修改父级项目build.gradle文件


> 没有什么多余的引用，几乎都是必须的

```

buildscript {
    repositories {
        maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
        maven { url "https://plugins.gradle.org/m2/" }
    }

}
plugins {
    id "base"
    id "io.spring.dependency-management" version "1.0.8.RELEASE"
    id "org.springframework.boot" version "2.1.9.RELEASE"

}

group = 'xyz.jecy'
version = '0.0.1-SNAPSHOT'
allprojects {

    apply plugin: 'java'
    apply plugin: 'idea'
    apply plugin: "org.springframework.boot"
    apply plugin: 'io.spring.dependency-management'
    bootJar { enabled = false }

    jar {
        enabled = true
    }
    dependencyManagement {
        imports {
            mavenBom "org.springframework.cloud:spring-cloud-dependencies:Greenwich.SR3"
        }
    }

    repositories {
        maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
        maven { url "https://plugins.gradle.org/m2/" }
    }


}

subprojects {

    sourceCompatibility = 9
    targetCompatibility = 9
    tasks.withType(JavaCompile) {
        options.encoding = 'UTF-8'
        options.compilerArgs << "-Xlint:unchecked" << "-Xlint:deprecation" << "-Werror"
    }
    configurations {
        providedRuntime

    }
    dependencies {
        implementation 'org.springframework.boot:spring-boot-starter-web'
        implementation 'org.springframework.cloud:spring-cloud-starter-config'
        implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
        implementation 'org.springframework.cloud:spring-cloud-starter-netflix-hystrix'
        implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'
        testImplementation 'org.springframework.boot:spring-boot-starter-test'
    }

}
```

7. 执行 `gradle clean build` 命令

```
> Task :eureka:compileTestJava FAILED
/Users/xinzhilimacpro/mytestwork/spring-demo/eureka/src/test/java/xyz/jecy/eureka/EurekaApplicationTests.java:3: 错误: 程序包org.junit.jupiter.api不存在

```
> 失败了 但是因为eureka 不需要test，而且也没有引对应test的包 删掉

![](/images/new/13.png)


8. 继续 `gradle clean build`

```
BUILD SUCCESSFUL in 2s
6 actionable tasks: 6 executed
```