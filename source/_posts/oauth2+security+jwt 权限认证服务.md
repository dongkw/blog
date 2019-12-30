---
title: oauth2+security+jwt 权限认证服务
thumbnail: https://jecy.xyz/web/images/auth.jpeg
date: 2109-12-25
categories:
- java后端
tags:
- java
- spring boot
- spring cloud
---
## 前言

> 原理什么的并不了解(真)，代码先撸出来再说。 [github.com/dongkw/spring-demo](https://github.com/dongkw/spring-demo)

<!--more-->


## 思路
> oauth2的流程  用graphviz生成的

![](https://jecy.xyz/web/images/test1.png)

 

### AuthorizationServer 授权服务器 贴一堆代码没什么意思 都写到注释里了

#### build.gradle引一堆包

```
version = '0.0.1-SNAPSHOT'


dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.cloud:spring-cloud-starter-oauth2'
    implementation 'org.springframework.security:spring-security-jwt'
    api "xyz.jecy.api:user-api:${userApiVersion}"

}

```
### EnableResourceServer 资源服务器

> yaml 可以写多行文本 用`|-`符号

```
public:
  key: |-
    -----BEGIN PUBLIC KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDf9wQAKPUI7bC68PKQ6BKUuOc
    LXLq7QEdT526+gxTO6CzZIcvdI1AtQ3aXFM105p9P9xZAme+v68xdRiVcn2y/1mS
    Y2KkzU9nT+GQa+sV/7i7GIoGdP+CQnoY3gySWx1U4wHXH57r/AujTT8JDSnolU2e
    Pxz18CwTpOgrYnPUMQIDAQAB
    -----END PUBLIC KEY-----

```

> 这里面只需要把token设置为jwt类型的 在放上对应的jwt公钥

```
@Configuration
@EnableResourceServer
public class AuthConfig extends ResourceServerConfigurerAdapter {

  @Value("${public.key}")
  private String publicKey;

  @Override
  public void configure(HttpSecurity http) throws Exception {
    http
        .authorizeRequests()
        .antMatchers("/user/auth").permitAll()
        .antMatchers("/user/load").permitAll()
        .anyRequest().authenticated();

  }

  @Override
  public void configure(ResourceServerSecurityConfigurer resources)
      throws Exception {
    resources.tokenServices(tokenServices());
  }


  @Bean
  @Primary
  public DefaultTokenServices tokenServices() {
    DefaultTokenServices defaultTokenServices = new DefaultTokenServices();
    defaultTokenServices.setTokenStore(tokenStore());
    return defaultTokenServices;
  }

  @Bean
  public TokenStore tokenStore() {
    return new JwtTokenStore(accessTokenConverter());
  }

  @Bean
  public JwtAccessTokenConverter accessTokenConverter() {
    JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
    converter.setAccessTokenConverter(new JwtAccessTokenConverter());
    converter.setVerifierKey(publicKey);
    return converter;
  }
}

```

加了点东西自动更新//////