---
title: springboot实战学习笔记（1）-基础
date: 2020-05-19
categories:
- spring
- spring boot
- java
- 框架
tags:
- spring

---

## spring boot核心

### 自动配置

spring boot 的条件化配置



spring-boot-autoconfigure jar包，包含许多配置类，每个配置类都在应用程序的classpath里，类似于springMVC的配置、thymeleaf配置、 jap配置等配置。

<!-- more-->

条件化配置存在系统中，当某些条件成立时才启用配置，在条件不足时忽略配置。

### 自定义条件 继承condition接口

```
package readinglist;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext; import org.springframework.core.type.AnnotatedTypeMetadata;
    public class JdbcTemplateCondition implements Condition {
      @Override
      public boolean matches(ConditionContext context,
                             AnnotatedTypeMetadata metadata) {
        try {
            //当jdbc创建时
          context.getClassLoader().loadClass(
                 "org.springframework.jdbc.core.JdbcTemplate");
          return true;
        } catch (Exception e) {
          return false;
} }
}
当你用Java来声明Bean的时候，可以使用这个自定义条件类:
    @Conditional(JdbcTemplateCondition.class)
    public MyService myService() {
... }

```

### spring boot定义了好多条件

|  条件化注解   | 配置生效条件  |
|  ----  | ----  |
| @ConditionalOnBean  | 配置了某个特定Bean |
| @ConditionalOnMissingBean  | 没有配置特定的Bean |
| @@ConditionalOnClass  | Classpath里有指定的类 |
| @ConditionalOnMissingClass  | Classpath里缺少指定的类 |
| @ConditionalOnExpression | 给定的Spring Expression Language(SpEL)表达式计算结果为true |
| @ConditionalOnJava  | ava的版本匹配特定值或者一个范围值 |
| @ConditionalOnJndi  | 参数中给定的JNDI位置必须存在一个，如果没有给参数，则要有JNDI InitialContext |
| @ConditionalOnProperty  | 指定的配置属性要有一个明确的值 |
| @ConditionalOnResource  | Classpath里有指定的资源 |
| @ConditionalOnWebApplication  | 这是一个Web应用程序 |
| @ConditionalOnNotWebApplication  | 这不是一个Web应用程序 |

### 例子
```
@Configuration
@ConditionalOnClass({ DataSource.class, EmbeddedDatabaseType.class }) @EnableConfigurationProperties(DataSourceProperties.class)
@Import({ Registrar.class, DataSourcePoolMetadataProvidersConfiguration.class }) public class DataSourceAutoConfiguration {
 ... 
 }

```
1.添加configuration注解
2.必须有DataSource.class, EmbeddedDatabaseType.class 两个bean存在。 如果不存在，datasoure所有配置都被忽略掉。

### spring boot 自动配置会做出以下决策

1. 因为Classpath里有H2，所以会创建一个嵌入式的H2数据库Bean，它的类型是
javax.sql.DataSource，JPA实现(Hibernate)需要它来访问数据库。
2. 因为Classpath里有Hibernate(Spring Data JPA传递引入的)的实体管理器，所以自动配置 会 配 置 与 Hibernate 相 关 的 Bean ， 包 括 Spring 的 LocalContainerEntityManager-
FactoryBean和JpaVendorAdapter。
3. 因为Classpath里有Spring Data JPA，所以它会自动配置为根据仓库的接口创建仓库实现。
4. 因为Classpath里有Thymeleaf，所以Thymeleaf会配置为Spring MVC的视图，包括一个Thymeleaf的模板解析器、模板引擎及视图解析器。视图解析器会解析相对于Classpath根目录的/templates目录里的模板。
5. 因为Classpath里有Spring MVC(归功于Web起步依赖)，所以会配置Spring的DispatcherServlet并启用Spring MVC。
6. 因为这是一个Spring MVC Web应用程序，所以会注册一个资源处理器，把相对于Classpath根目录的/static目录里的静态内容提供出来。(这个资源处理器还能处理/public、/resources和/META-INF/resources的静态内容。)
7. 因为Classpath里有Tomca(t 通过Web起步依赖传递引用)，所以会启动一个嵌入式的Tomcat容器，监听8080端口。

magic world


### 起步依赖 


1. 起步依赖是特殊的`maven依赖`和`gradle依赖`利用依赖的传递性，把几个常用的库聚合到一起组成为特定功能定制的依赖。

2. 起步依赖不需要关心jar包版本问题，引入的是功能，不是jar包
    gradle dependencies 任务会显示依赖树

spring boot 通过提供众多起步依赖来降低依赖的复杂度，`起步依赖本质上是一个maven项目对象模型（project object model, POM）`,定义了对其他库的传递依赖，这些东西加起来即支持某项功能。 

#### 起步依赖覆盖

可以通过构建工具中的功能，选择性覆盖传递依赖版本号，还可以指定起步依赖没覆盖的版本依赖

gradle 排除传递依赖 

```
compile("org.springframework.boot:spring-boot-starter-web"){ exclude group: 'com.fasterxml.jackson.core'
 }
```

### 小结

起步依赖帮你转正应用程序需要的功能类型，而非功能的具体库和版本。
自动配置把你从样板代码中解放出来。

实现最基础的功能，然后spring boot还提供定制化功能。


## 自定义配置

大部分情况不需要配置，自动配置不能满足特殊需要时需要手动配置

### 覆盖自动配置的bean

添加security起步依赖

```
compile("org.springframework.boot:spring-boot-starter-security")

```



### 用外置属性进行配置
### 自定义错误页




### 命令行界面

spring boot CLI能检测你使用了那些类，知道向classpath中添加哪些起步依赖才能让它运转起来，然后自动配置DispatcherServlet和spring mvc

5章
## Actuator

提供运行时检视应用程序内部情况的能力。
1. spring应用程序上下文里配置的bean
2. spring boot的自动配置做的决策
3. 应用程序取到的环境变量、系统属性、配置属性和命令参数
4. 应用程序里线程的当前状态
5. 应用程序最近处理过的http请求追踪情况
6. 各种和内存用量垃圾回收web请求一级数据源相关指标

7章

## 

