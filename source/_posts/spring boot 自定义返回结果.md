---
title: spring boot 自定义返回结果
date: 2019-12-31
categories:
- java
tags:
- spring boot
- response

---

[项目地址](https://github.com/dongkw/spring-demo/tree/master/util)

### 1.统一返回值

>java序列化 和json序列化

<!--more-->

```
package xyz.jecy.util.response;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import java.io.Serializable;
import java.util.Objects;
import lombok.Data;
import xyz.jecy.util.bean.Code;
import xyz.jecy.util.bean.ErrorCode;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2019/12/10 6:24 下午
 */
@Data
@JsonSerialize
public class Response<T> implements Serializable {

  public static final int SUCCESS_CODE = 200;

  public static final String SUCCESS_MESSAGE = "操作成功";

  private int code;
  private String message;
  private T result;


  private Response(int code, String message, T result) {
    setCode(code);
    setMessage(message);
    setResult(result);
  }


  public static <T> Response<T> initSuccess() {
    return initSuccess(null);
  }

  public static <T> Response<T> initSuccess(T data) {
    return new Response<T>(SUCCESS_CODE, SUCCESS_MESSAGE, data);
  }

  public static <T> Response<T> initError() {
    return initError(ErrorCode.INVALID_PARAMS);
  }

  public static <T> Response<T> initError(Code code) {
    return new Response<T>(code.getCode(), code.getDescription(), null);
  }

  public static <T> Response<T> initError(Code code, String message) {
    return new Response<T>(code.getCode(), message, null);
  }

  public boolean success() {
    return Objects.equals(SUCCESS_CODE, code);
  }

  public boolean error() {
    return !success();
  }

  public boolean error(Code errorCode) {
    return Objects.equals(errorCode.getCode(), code);
  }


}


```

### 统一错误码

#### 业务中有自定义错误码可以继承Code接口

```
package xyz.jecy.util.bean;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2019/12/11 10:14 上午
 */
public interface Code {

  int getCode();

  String getDescription();
}
```

#### 例子
```
package xyz.jecy.util.bean;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2019/12/11 10:27 上午
 */
@Getter
@AllArgsConstructor
public enum ErrorCode implements Code {
  INVALID_PARAMS(400, "请求参数错误"),

  /**
   * 业务处理失败，通常不是由代码异常引起的，通常是业务原因，如规则不允许等
   */
  REQUEST_FAILED(450, "业务处理失败"),

  /**
   * 服务器异常，通常是由于代码逻辑错误导或外部服务不可用造成的致的非预期错误
   */
  SERVER_ERROR(500, "服务异常");

  private int code;
  private String description;
  
}

```

### 统一异常处理

#### 自定义异常

```
package xyz.jecy.util.exception;

import lombok.Data;
import lombok.EqualsAndHashCode;
import xyz.jecy.util.bean.Code;
import xyz.jecy.util.bean.ErrorCode;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2019/12/24 11:47 上午
 */
@Data
@EqualsAndHashCode(callSuper=false)
public class FailureException extends RuntimeException {

  private Code errorCode;

  public FailureException() {
    this(ErrorCode.REQUEST_FAILED);
  }

  public FailureException(Code code) {
    super(code.getDescription());
    this.errorCode = code;
  }

  public FailureException(Code code,String desc) {
    super(desc);
    this.errorCode = code;
  }

}

```
#### 自定义异常处理

```
package xyz.jecy.util.exception;

import javax.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.AutoConfigureBefore;
import org.springframework.boot.autoconfigure.web.servlet.error.ErrorMvcAutoConfiguration;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import xyz.jecy.util.response.Response;

/**
 * @Author dkw[dongkewei@xinzhili.cn]
 * @data 2019/12/24 11:40 上午
 */
@ControllerAdvice
@Slf4j
@Component
public class GlobalExceptionResolver {

  @ResponseBody
  @ExceptionHandler(FailureException.class)
  public Response failException(FailureException e, HttpServletRequest req) {
    log.error("failure exception -> {} : {}", e.getClass(), e.getMessage());
    return Response.initError(e.getErrorCode());
  }
}

```
#### 让自定义的异常处理自动加载

```
在resources/META-INF目录下建spring.factories 文件 内容

org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  xyz.jecy.util.exception.GlobalExceptionResolver
```