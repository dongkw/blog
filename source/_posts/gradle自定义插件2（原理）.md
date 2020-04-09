---
title: gradle自定义插件2（基础知识）
date: 2020-03-31
categories:
- java
tags:
- java
- 运维
- gradle

---

了解了自定义gradle插件的流程，就到了怎么实现一个完整的插件。然后就需要明白gradle究竟在干什么。

<!--more--> 

# 构建块

每个Gradle构建都包括三个基本构建块：project、task、property。每个构建至少包含一个project,每个project又包含一个或多个task,project和task通过暴露property来控制构建。

## 项目(project)

一个项目（project）代表一个正在构建的组件，当程序启动时，gradle基于build.gradle中的配置实例化prg.aradle.api.Project类，并且能通过project变量使其隐式使用。

## project中的重要方法

### 构建基本配置

1. apply(option: Map<String,?>)
2. buildscript(config: Closure)

### 依赖管理

1. dependencies(config: Closure)
2. configurations(config: Closure)
3. getDependencies()
4. getConfigurations()

### get/set属性

1. getAnt()
2. getName()
3. getDescription()
4. getGroup()
5. getVersion()
6. getLogger()
7. setDescription(description: String)
8. setVersion(version: Object)

### 创建文件

1. file(path: Object)
2. files(paths: Object...)
3. fileTree(baseDir: Object)

### 创建Task

1. task(args: Map<String,?> ,name: String)
2. task(args: Map<String,?> ,name: String, c: Closure)
3. task(name: String)
4. task(name: String, c:Closure)

# 任务（task）

任务分动作任务(task action)和依赖任务(task dependency)
 
## task中的主要方法

### task依赖

1. dependsOn(tasks: Object...)

### 动作定义

1. doFirst(action: Closure)
2. doLast(action)
3. getAction()

### 输入/输出数据说明

1. getAnt()
2. getDescription()
3. getEnable()
4. getGroup()
5. setDescription(description: String)
6. setEnable(enabled: boolean)
7. setGroup(group: String)

# 属性(property)

每个项目和任务多可以通过get/set方法访问属性值，gradle支持扩展属性。

## gradle属性

1. gradle属性可以通过在`gradle.properties`文件中直接声明来添加到项目中
2. 可以自定义

# task使用

每个新创建的task都是org.gradle.api.DefaultTask的子类

```
public class Task1 extends DefaultTask {

    @TaskAction
    public void task(){
       Object obj= getProject.getVersion();
        System.out.println(obj.toString());
    }

}
```
## gradle 构建的生命周期

1. 初始化阶段

gradle为项目创建一个project实例，找出依赖关系，但是在这个阶段所有脚本代码不执行。

2. 配置阶段

gradle构造了一个模型来表示任务，决定那些task需要运行，每次构建所有配置代码都会执行。

3. 执行阶段

顺序执行









