---
title: gradle自定义插件（java语言）
date: 2020-03-25
categories:
- java
tags:
- java
- 运维
- gradle

---

# 自定义一个gradle插件



## 随便新建一个普通java gradle项目

<!--more--> 

## 在`build.gradle`文件里引 `java-gradle-plugin` 插件

```
plugins {
    id 'java'
    id 'maven-publish'
    id 'java-gradle-plugin' 
}
```
## 写gradle插件入口类，类似于spring boot的main方法

```
package xyz.jecy.generator;

import org.gradle.api.Plugin;
import org.gradle.api.Project;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2020/3/24 2:40 下午
 */
public class MyFristPlugin implements Plugin<Project> {

  @Override
  public void apply(Project target) {
    target.getTasks().create("generator", MyTask.class);
  }
}

```

## 自定义task

```
package xyz.jecy.generator;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import xyz.jecy.generator.GeneratorService;
import xyz.jecy.util.exception.FailureException;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2020/3/24 3:53 下午
 */
public class MyTask extends DefaultTask {

  @TaskAction
  private void generator() throws FailureException {
    GeneratorService service = new GeneratorService();
    service.generateCode();

  }
}

```
## 给自定义的插件起个Id方便别人引用
 
在gradle.build中加入如下代码，可以在一个项目中定义多个插件。

```
gradlePlugin {
    plugins {
        generator {
            id = "xyz.jecy.util.generator"
            implementationClass = 'xyz.jecy.generator.MyFristPlugin'
        }
//         generator {
//            id = "xyz.jecy.util.generator"
//           implementationClass = 'xyz.jecy.generator.MyFristPlugin'
//        }
    }

}
```



# 发布插件

插件写好了就可以发布了，可以发到私有maven仓库里。

## 准备好一个自己的私有云仓库。

直接阿里的云效就能白嫖。

## 引用gradle的maven-publish插件。

```
    id 'maven-publish'
```

## gradle.build 发包的模板代码

```

version '1.0'

publishing {
    publications {
        maven(MavenPublication) {
            groupId 'xyz.jecy'
            artifactId "util"
            version version
            from components.java
        }
    }
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

## 项目目录下执行命令

```
gradle publish

```


# 引用自定义插件


## 第一种引用方法

在需要引用插件的项目的`build.gradle`中的buildscript中加入仓库地址 引用包等信息

repositories为仓库地址

dependencies的classpath引用为 gradle task需要的包。
    
apply plugin 引用插件

```
buildscript{
    repositories {

        maven {  url 'https://repo.rdc.aliyun.com/repository/113197-release-J0KMpi/' }
        maven { url 'https://repo.rdc.aliyun.com/repository/113197-snapshot-Kix4rb/'  }
        maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
        maven { url "https://plugins.gradle.org/m2/" }
        mavenCentral()
    }

    dependencies{
        classpath "xyz.jecy:util:${utilVersion}"
    }
}



apply plugin: 'xyz.jecy.util.generator'


```

## 第二种引用方法

1. 在`settings.gradle`加入pluginManagement 代表从下面的仓库找插件

```
pluginManagement {

    repositories {
        maven { url 'https://repo.rdc.aliyun.com/repository/113197-release-J0KMpi/' }
        maven { url 'https://repo.rdc.aliyun.com/repository/113197-snapshot-Kix4rb/' }
        maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
        maven { url "https://plugins.gradle.org/m2/" }
        mavenCentral()
    }
    
}

```

2. 在`build.gradle`中用DSL方式引入插件 需要版本号

```
plugins {
    id "xyz.jecy.util.generator" version "20200325-1-SNAPSHOT"
}
```



然后build成功就可以在idea里面看到自己定义的插件了

![](/images/ideagradle.png)

