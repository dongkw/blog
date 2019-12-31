---
title: graphviz画图工具
date: 2109-12-31
categories:
- 工具asdaf
tags:
- 流程图

---

## 简介

> 简单来说就是两步
 1. 写代码
 2. 转成图片
 
<!--more-->

graphviz是贝尔实验室开发的一个开源的工具包，它使用一个特定的DSL(领域特定语言):dot作为脚本语言，然后使用布局引擎来解析此脚本，并完成自动布局。graphviz提供丰富的导出格式，如常用的图片格式，SVG，PDF格式等。

```
dot 默认布局方式，主要用于有向图
neato 基于spring-model(又称force-based)算法
twopi 径向布局
circo 圆环布局
fdp 用于无向图
```





## 安装

[下载地址](http://www.graphviz.org/download/)

```
brew install graphviz

```

## 例子

### demo1
```
digraph image{

A[label="A项目"]

A->B->C

C->A

}

```
执行命令
```
dot demo1.dot -o demo1.png -Tpng
```
![demo1.png](https://jecy.xyz/web/images/demo1.png)

### demo2

1. subgraph定义子图，但是名字必须以cluster开头，否则不识别
2. node[]设置当前大括号下节点属性
3. edge[]设置当前大括号下线段属性
4. 每个节点可以单独设置属性   B[label="B项目",color="green",style="filled",shape="diamond"]
5. 每条联系也可以单独设置属性E->A[label="失败",style="dashed"]
6. E->F[更多语法](https://graphviz.gitlab.io/_pages/doc/info/lang.html)
7. shape="diamond"[更多形状](https://graphviz.gitlab.io/_pages/doc/info/shapes.html)
8. color="green"[更多颜色](https://graphviz.gitlab.io/_pages/doc/info/colors.html)
9. 到这我认为流程图就没问题了，更多请看[官方文档](http://www.graphviz.org/documentation/)
```
digraph image{
  subgraph cluster_cd{
      node[shape="box"]
      edge [style="dashed"];
      label="子图";
      bgcolor="mintcream"
      E->F->G;
    }
  B[label="B项目",color="green",style="filled",shape="diamond"]
  A->B
  B->C[label="成功",style="dashed"]
  C->E
  G->END
  C->END
  E->A[label="失败",style="dashed"]
}

```
执行命令
```
dot demo2.dot -o demo2.png -Tpng
```
![demo2.png](https://jecy.xyz/web/images/demo2.png)


## 个人体会

graphviz对我的最大意义就是理清逻辑,比如我知道A与B有关，B与C有关,就会自动生成A与C的关系。如果逻辑复杂只需要抽象出一个个的对象，然后分别想清楚某几个对象间的关系，就会自动生成全部的逻辑流程。