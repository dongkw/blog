---
title: spring+gradle多模块项目配置
thumbnail: https://jecy.xyz/web/images/keng.png
date: 2019-12-11
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---

# 多模块项目配置

> 目的是搞明白原理。 

<!--more-->

> 最开始以为和单模块项目没啥区别，但是在建了一个项目后发现会出现好多莫名奇妙的问题。

> 具体表现就是配置文件不生效、找不到主类，各种build失败。

> 项目地址: [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)

## 项目结构

> 分三种子模块 

```
1. 什么都没有的空模块
2. jar包
3. 可执行java程序
```

![](https://jecy.xyz/web/images/16.png)

## build.gradle 文件

1. 空模块的build.gradle文件


``` 
  //不需要打jar包
jar {
  enabled = false
}
  //不需要可执行程序
bootJar {
    enabled = false
}
```

2. jar包的build.gradle 文件 order-api user-api util ...

```
 //引用gradle 插件
plugins {
    //引用java插件 可以打出jar包
    id 'java'
    
    // maven 发布插件
    id 'maven-publish'
}
// 执行gradle clean build时 jar包的版本号
version userApiVersion
 
 
bootJar {
    enabled = false
}

publishing {
    publications {
        maven(MavenPublication) {
            groupId 'xyz.jecy.api'
            artifactId "user-api"
            //发布包的版本号
            version version
            from components.java
        }
    }
    //发到哪个远程仓库
    repositories {
        maven {
            credentials {
                username 'g0uETP'
                password 'mTjlwdQ55W'
            }
            def releasesRepoUrl = "https://repo.rdc.aliyun.com/repository/113197-release-J0KMpi/"
            def snapshotsRepoUrl = "https://repo.rdc.aliyun.com/repository/113197-snapshot-Kix4rb/"
            url = version.endsWith('SNAPSHOT') ? snapshotsRepoUrl : releasesRepoUrl
        }

    }

}


```

3. 程序的gradle 文件 各种service、config、eureka等

```

version '0.0.1-SNAPSHOT'

//自己单独需要的依赖
dependencies {
    api "xyz.jecy.api:user-api:${userApiVersion}"
    api "xyz.jecy.api:order-api:${orderApiVersion}"
}

bootJar {
    //spring boot 的main方法
    mainClassName = 'xyz.jecy.user.UserApplication'
}

```

4. 父级项目的配置文件 

```

// 父项目的插件引用 和里面的子项目没有任何关系 仅仅是为了支撑下面的bootJar命令
plugins {
    id "java"
    id "org.springframework.boot" version "2.1.9.RELEASE"
}
//父项目不需要打包 只是一个文件夹
bootJar {
    enabled = false
}

group = 'xyz.jecy'
version = '0.0.1'
//到这为止都是父项目的东西 我理解成只有一个spring-boot文件夹

//所有项目的配置包括父项目 优先级最高 
// 例如 在 allprojects 里配置了 bootJar {enabled = false} 在父项目或子项目中配置bootJar {enabled = true} 的话 是前面的命令生效
allprojects {


    //引用了一堆插件 这里如果用 plugins { } 引用会报错 不理解为什么 没有查到
    apply plugin: 'java' 
    apply plugin: 'idea'
    apply plugin: "org.springframework.boot"
    apply plugin: 'io.spring.dependency-management'

    //导入现有的Maven Bom以利用其依赖性 对应spring cloud在下面有链接
    dependencyManagement {
        imports {
            mavenBom "org.springframework.cloud:spring-cloud-dependencies:Greenwich.SR3"
        }
    }

    //所有项目引用的仓库
    repositories {
        maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
        maven { url "https://plugins.gradle.org/m2/" }
        mavenCentral()
        //个人学习用 没有空闲机器 用的是阿里的云效
        maven {
            credentials {
                username 'g0uETP'
                password 'mTjlwdQ55W'
            }
            url 'https://repo.rdc.aliyun.com/repository/113197-release-J0KMpi/'
        }
        maven {
            credentials {
                username 'g0uETP'
                password 'mTjlwdQ55W'
            }
            url 'https://repo.rdc.aliyun.com/repository/113197-snapshot-Kix4rb/'
        }
    }


}

//子项目配置
subprojects {
    //实现api与implementation 分离 逐渐弃用compile
    apply plugin: 'java-library'

    sourceCompatibility = 9
    targetCompatibility = 9
    
    //java构建时候加一堆参数
    tasks.withType(JavaCompile) {
        options.encoding = 'UTF-8'
        options.compilerArgs << "-Xlint:unchecked" << "-Xlint:deprecation" << "-Werror"
    }
    //下面这个一定不要写  本来就是默认配置打包 但是写了就是按着下面的配置打包 会找不到主类
   // jar {
   //     enabled = true
   // }
    
    //To build a jar file that is both executable and deployable into an external container, you need to mark the embedded container dependencies as belonging to a configuration named "providedRuntime"
    configurations {
        providedRuntime

    }
    //各种项目公用的依赖
    dependencies {
        compileOnly 'org.projectlombok:lombok:1.18.10'
        annotationProcessor 'org.projectlombok:lombok:1.18.10'
        implementation 'org.springframework.boot:spring-boot-starter-web'
        implementation 'org.springframework.cloud:spring-cloud-config-client'
        implementation 'org.springframework.cloud:spring-cloud-starter-netflix-hystrix'
        implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'
        //patch接口用的
        implementation 'com.netflix.feign:feign-httpclient:8.18.0'
        implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
        testImplementation 'org.springframework.boot:spring-boot-starter-test'
        //在这统一依赖版本是个大坑 下面这种看似很好其实问题很多 个人感觉放在子项目里会好些
        if (it.name != "util") {
            dependencies {
                api "xyz.jecy:util:${utilVersion}"
            }
        }        
        

    }

}


```
> Maven Bom对应spring boot版本 [https://mvnrepository.com/artifact/org.springframework.cloud/spring-cloud-dependencies](https://mvnrepository.com/artifact/org.springframework.cloud/spring-cloud-dependencies)


5. 父项目 gradle.properties 文件

 ```
 //统一自己发的jar 版本
userApiVersion=20191211-SNAPSHOT
orderApiVersion=20191211-SNAPSHOT
utilVersion=20190911-1-SNAPSHOT

```



