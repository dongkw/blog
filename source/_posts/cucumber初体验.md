---
title: cucumber
date: 2020-08-03
categories:
- test
- java
tags:

---

## cucumber自动化接口测试

官方文档[https://cucumber.io/docs/installation/java/](https://cucumber.io/docs/installation/java/)

cucumber是BDD(behavior-driver-development),使用自然语言描述测试用例

## Gherkin

Gherkin是自然语言测试的简单语法。正则表达式复用用例。
### 语法
 


## 例子

```
Feature: Is it Friday yet?
  Everybody wants to know when it's Friday

  Scenario Outline: Today is or isn't  Friday
    Given today is "<day>"
    When I ask whether it's Friday yet
    Then I should be told "<answer>"

    Examples:
      | day           | answer |
      | Friday        | TGIF   |
      | Sunday        | Nope   |
      | anything else | Nope   |
```

## 关键词

|关键词  |描述                                          |
|  ----    | ----  |
|Feature      |所有测试用例的开头，表明测试用例是干什么的|
|description    |   扩展性文字描述    |
|Example（or Scenario）|一个具体的测试case,包涵多少个step,一般由Given、When、Then组成|
|Given|系统初始状态|
|When|描述一个事情或动作，可以是与系统的交互，也可以是系统触发某些事件|
|Then|描述期望输出或结果|
|And|多个Given|
|But|多个结果|
|Background|当同一个Feature里多个Secnario有相同的Given时，可以用Background将Given抽到一起，先运行Background|
|Scenario Outline (or Scenario Template)|运行相同的Scenario多次|
|Examples (or Scenarios)|多个用例值|


## 项目结构
```
src------------------------------------
    test-------------------------------
        java---------------------------
            hellocucumber--------------
                RunCucumberTest.Java
                Stepdefs.java
        resources----------------------
            hellocucumber--------------
                test1.feature
```


入口类

```

@RunWith(Cucumber.class)
@CucumberOptions(plugin = {"pretty"})
public class RunCucumberTest {
}
```

执行命令 `mvn test`会打印出

```
You can implement missing steps with the snippets below:

@Given("^today is \"([^\"]*)\"$")
public void today_is(String arg1) throws Exception {
    // Write code here that turns the phrase above into concrete actions
    throw new PendingException();
}

@When("^I ask whether it's Friday yet$")
public void i_ask_whether_it_s_Friday_yet() throws Exception {
    // Write code here that turns the phrase above into concrete actions
    throw new PendingException();
}

@Then("^I should be told \"([^\"]*)\"$")
public void i_should_be_told(String arg1) throws Exception {
    // Write code here that turns the phrase above into concrete actions
    throw new PendingException();
}

```

复制方法到StepDefs.java 并改为

```
//业务代码
class IsItFriday {
    static String isItFriday(String today) {
        if (today.equals("Friday")) {
            return "TGIF";
        }
        return "Nope";
    }
}
public class Stepdefs {
    private String today;
    private String actualAnswer;
    //初始化
    @Given("^today is \"([^\"]*)\"$")
    public void today_is_Sunday(String day) throws Exception {
        today = day;
    }
    //执行测试程序
    @When("^I ask whether it's Friday yet$")
    public void i_ask_whether_it_s_Friday_yet() throws Exception {
        actualAnswer = IsItFriday.isItFriday(today);
    }
    //验证程序结果
    @Then("^I should be told \"([^\"]*)\"$")
    public void i_should_be_told(String arg1) throws Exception {
        assertEquals(arg1, actualAnswer);
    }
}

```

## `pom.xml`文件

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>hellocucumber</groupId>
    <artifactId>hellocucumber</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>io.cucumber</groupId>
            <artifactId>cucumber-java</artifactId>
            <version>2.3.1</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>io.cucumber</groupId>
            <artifactId>cucumber-junit</artifactId>
            <version>2.3.1</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.7.0</version>
                <configuration>
                    <encoding>UTF-8</encoding>
                    <source>1.8</source>
                    <target>1.8</target>
                    <compilerArgument>-Werror</compilerArgument>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
</project>



```

