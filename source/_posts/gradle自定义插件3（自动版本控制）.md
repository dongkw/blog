---
title: gradle自定义插件3（自动版本控制）
date: 2020-04-09
categories:
- java
tags:
- java
- 运维
- gradle

---

gradle基础差不多看完了，给项目加个版本控制，其实springboot多模块项目直接引用其他模块并没有什么版本问题。
但是如果每个业务模块都是一个单体项目，版本依赖就会非常混乱，经常出现改了一个服务，其他服务引用旧版本的问题。

使用场景：
1. 改了代码加了功能 A服务发包
2. 需要让其他服务调用 B服务引用A的新包

<!--more--> 

## 发包

发到maven仓库的包都是最新的，会有新的版本号。所以第一个功能就是改版本号。

手动改版本号只是改了`gradle.properties`的某个属性

```
userApiVersion=20200403-99-SNAPSHOT
orderApiVersion=20200403-SNAPSHOT
utilVersion=20200326-SNAPSHOT
mybatisPlusVersion=3.3.0
mysqlVersion=8.0.18
velovityVersion=2.1
pluginsVersion=20200408-5-SNAPSHOT
```
### 第一步

因为gradle是支持groovy语言的，groovy又是java平台上的，所以约等于java。好! 那就用java写个直接改文件的程序吧。
读文件写文件谁不会，然后就出了这个东西。

```
public class LatestArtifactVersion extends DefaultTask {

  private final Property<String> serverUrl;

  public LatestArtifactVersion() {
    serverUrl = getProject().getObjects().property(String.class);
  }
  
  @Input
  public Property<String> getServerUrl() {
    return serverUrl;
  }
  
  @TaskAction
  public void resolveLatestVersion() {
    //改上面的配置文件 
    PropertiesUtil.handler(getServerUrl().get());

  }

}
```
除了改配置文件那行之外完全照抄[官方文档例子](https://guides.gradle.org/implementing-gradle-plugins/)，完美,
然后发现这个任务确实也能改掉配置文件。

### 第二步
 
和maven-publish插件绑定，让publish时候先掉一下我那个插件就好了

![](/images/100.png)

```
publish.dependsOn latestArtifactVersion

```

当我以为gradle不过如此的时候，却发现每次都是先打完包后才改配置文件，我理解的前后顺序完全不是那么回事。
并不是我说谁在谁前面就先执行的，publish竟然插队，gradle果然sb，并一点不智能。于是通过某些正当途径找到了下面这本书的高清扫描版。

![](/images/101.png)

于是我发现了gradle有三个阶段，初始化阶段、配置阶段、执行阶段。所有任务都是先执行了初始化阶段在同时执行配置阶段，等都完成了配置阶段后才会到执行阶段。
一直在执行阶段搞事情肯定是改不了已配置好的版本号的。
我对gradle的认知有误差，并不是人家不好，不了解别人却说别人sb，果然真相只有一个，所以说理论指导实践果然不假。

### 第三步

然后就是怎么在配置阶段把版本号改了，我发现了这么张图
![](/images/102.png)

所以在配置阶段之后，执行之前把配置好的文件给改了才应该是正解。于是我发现这个`gradle.properties`其实并没有什么卵用。
配置阶段本身是读取文件的值在配给某个new 出来的 project 对象。我先读文件，然后写文件，gradle在读我读过写完的文件在赋值，
这套起娃来也没什么意思，多麻烦，所以我为什么要改文件，直接给project对象赋值就好了啊。于是我觉得我思路通了。


```
public class BinaryRepositoryVersionPlugin implements Plugin<Project> {

  public void apply(Project project) {
    ...
    ReleaseVersionListener listener = new ReleaseVersionListener();
    project.getGradle().getTaskGraph().addTaskExecutionGraphListener(listener);
    ...
    }
  }

```

```
public class ReleaseVersionListener implements TaskExecutionGraphListener {

  private static final String PATH = ":latestArtifactVersion";

  @Override
  public void graphPopulated(TaskExecutionGraph graph) {

    List<Task> tasks = graph.getAllTasks();

    tasks.forEach(t -> {
      if (t.getPath().endsWith(PATH)) {
        LatestArtifactVersion l = (LatestArtifactVersion) t;
        String version = PropertiesUtil.getVersion(l.getServerUrl().get());
        t.getProject().setVersion(PropertiesUtil.nextVersion(version));
        
        //publishing的version赋值
        PublishingExtension extension = l.getProject().getExtensions()
            .getByType(PublishingExtension.class);
        MavenPublication mavenPublication = (MavenPublication) extension.getPublications()
            .findByName("maven");
        mavenPublication.setVersion(PropertiesUtil.nextVersion(version));
      }

    });
    
  }
}
```

然后问题又来了，我改了project的version属性，本地的build里的jar包是新的，但是发到远程仓库的包并不是我改完的，还是配置文件里写死的。
上面文件if里面的前三行。我就觉得publish有问题，为啥不会跟着project的version变呢，一点不智能，但是有了之前的上面真相只有一个的教训，我还是晚点下结论吧。

于是我就盯着下面的文件看，publish插件的基本写法，不知道从那里复制过来的，
但是这到底是啥意思，之前我也不知道，只是写了就能用。

后来我发现下面的version是userApiVersion的值，这个publishing就是传入publish插件的参数，就是一个bean，
创建时期是配置阶段，这个version我从来没有动过，所以发布到远程仓库的版本就是这个version指定的版本。
了解了这些以后就是去project对象中找到对应的值然后改掉。

```
publishing {
    publications {
        maven(MavenPublication) {
            groupId 'xyz.jecy.api'
            artifactId "user-api"
            version userApiVersion
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




### 第四步 

上一步改掉的事gradle的project的某些属性，比如说version、PublishingExtension,而且并没有改动物理的配置文件，发现gradle.properties并没什么用。
所以如果我把版本托管到第三方平台，或者某个数据库，每次发包时改掉。其他服务引用时就能拿到最新版本，就不需要改动文件，只要重新build就能引用最新的包。

就有了这么个插件，就是把包对应的版本号存到对应环境的redis里，这样同一环境所有的服务的版本都统一在一个数据库内。

```

public class DependenciesTask extends DefaultTask {

  private final Property<String> serverUrl;

  private final Property<String> env;

  public DependenciesTask() {
    serverUrl = getProject().getObjects().property(String.class);
    env = getProject().getObjects().property(String.class);
  }
  
  @Input
  public Property<String> getServerUrl() {
    return serverUrl;
  }

  @Input
  public Property<String> getEnv() {
    return env;
  }

  @TaskAction
  public void setDependencies() {

    PublishingExtension extension = getProject().getExtensions()
        .getByType(PublishingExtension.class);
    MavenPublication mavenPublication = (MavenPublication) extension.getPublications()
        .findByName("maven");

    RedisUtil redisUtil = new RedisUtil();
    Jedis jedis = redisUtil.getJedis();
    getLogger().quiet(env.get());
    jedis.hset(env.get(), mavenPublication.getArtifactId(),
        PropertiesUtil.getVersion(serverUrl.get()));
    jedis.close();
  }


```

### 第五步

到现在可以知道这么几件事

1. 能获取到project里的所有东西
2. 能修改project的所有东西

首先拿到依赖包，修改版本号。

```
  public static void setDependency(Project project) {

    RedisUtil redisUtil = new RedisUtil();
    Jedis jedis = redisUtil.getJedis();
    Map<String, String> map = jedis.hgetAll(PropertyUtil.getEnv(project));
    DependencyHandler dependencyHandler = project.getDependencies();
    ConfigurationContainer configurations = project.getConfigurations();

    try {
   
      // dependencies {
      //     api "xyz.jecy.api:user-api"    //找这种依赖
      //     api "xyz.jecy.api:order-api:${orderApiVersion}"
      //     implementation 'org.springframework.security:spring-security-jwt'
      //     implementation 'org.springframework.cloud:spring-cloud-starter-oauth2'
      //     implementation "com.baomidou:mybatis-plus-boot-starter:${mybatisPlusVersion}"
      //     implementation "mysql:mysql-connector-java:${mysqlVersion}"
      // }
      Configuration configuration = configurations.getByName("api");
      
      DependencySet dependencies = configuration.getAllDependencies();
      dependencies.forEach(r -> {
        String version = map.get(r.getName());
        if (Objects.nonNull(version)) {
          dependencyHandler.add("api", r.getGroup() + ":" + r.getName() + ":" + version);
        }
      });
    } catch (UnknownConfigurationException e) {
      System.out.println("wrapper no configuration");
    }
  }


```
然后放到hook里面只要执行task任务时候就找一遍版本号

```
public class QuoteListener implements TaskExecutionGraphListener {
  @Override
  public void graphPopulated(TaskExecutionGraph graph) {
    DependencyUtil.setDependency(graph.getAllTasks().get(0).getProject());
  }
}

```

在放到某个自定义的task里面，因为idea的`reimport all gradle projects`按钮除了wrapper外并不执行任何task，但是肯定把task new了，因为右边显示出来了。

```
public class DependenciesApplyTask extends DefaultTask {
  private final Property<String> env;
  public DependenciesApplyTask() {
    env = getProject().getObjects().property(String.class);
    DependencyUtil.setDependency(getProject());
  }
  
  @Input
  public Property<String> getEnv() {
    return env;
  }

  @TaskAction
  public void setDependencies() {

  }
```
到这以后就可以无限publish 在build, 看版本号增加了。

[项目地址](https://github.com/dongkw/spring-demo/tree/master/plugins)
### 最后


1. 版本号细节实现 时间+后缀 or 大版本+小版本+后缀
2. 不同环境区分  用-P 传环境参数 不传默认dev
3. 存起来的版本信息到底是什么 环境+当前项目+版本号 当前项目+引用依赖
4. 怎么改版本信息 改当前版本号+其他项目中依赖当前项目的版本 
5. 哪里简化了 简化了发包操作 不需要频繁改依赖包
6. 哪里复杂了  gradle.build文件多了几行，多了redis
7. gradle在干什么 gradle构建生命周期，project task property 三个基本构建块的使用 

