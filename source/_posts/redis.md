---
title: redis
date: 2020-03-20
categories:
- redis
tags:
- java
- redis

---

# Redis 基础数据结构

Redis 所有数据结构都是以唯一的key字符串作为名称，通过key获取value数据，不同类型的区别是value结构不一样。
<!--more--> 

Redis有5种基础数据结构

## string（字符串）

Redis 字符串是动态字符串，内部实现类似于Java的ArrayList，采用预分配冗余空间来减少内存频繁分配

分配方式 当字符串小于1M 每次加倍，大于1M 每次加1M 最大512M


## list （列表）

Redis 的列表相当于java的LinkedList, 插入 删除时间复杂度O(1),查找时间复杂度O(n);

当弹出最后一个元素后 数据结构自动删除，内存回收。

通常作为异步队列使用，一个线程往里列表放值 另一个线程轮询消费。

```
lpush lpop  左进右出 队列
rpush rpop 右进右出 栈
```

### 慢操作

取列表中的某个特定值

```
lindex 相当于get(int index)
ltrim 保留某个区间内的值 可以实现某个定长链表 
    index 可以为负数 倒叙
```

### 快速列表

Redis列表不是简单的LinkedList 是quicklist 未解决链表指针附加空间太多 用了ziplist结构 用连续内存代替链表指针，多个ziplist用双向指针串联。

## hash （哈希）

Redis的字典相当于Java中的HashMap。是无序字典。

是由数组加链表组成的二维结构。第一维数组碰撞时就把碰撞元素用链表串联起来。

redis字典在扩容时使用的事渐进式rehash。 

1. 某个时间点ht0需要rehash 分配空间 ht1
2. 在h0上维持索引计数器rehashidx 设置为0
3. 操作数据时 新增在ht1上操作,修改 查找 删除先在ht0上查找 然后同步操作记录到ht1上，h0上的索引计数器+1。
4. 某个时间 h1上所有数据同步完成，索引计数器设置为-1，等待回收，rehash结束。

Hash 结构可以单独获取某个属性，字符串会把所有结构一并返回。hash结构存储消耗高于字符串。


## set （集合）

Redis 的集合相当于java中的HashSet,内部键值对是无序唯一的。内部实现相当于特殊的字典，字典所有value为null。

set可以用来存储中奖活动用户id，保证不会重复获取用户。


## zset （有序列表）

zset 类似java 的sorted 和hashMap的结合体，是一个set 保证value唯一，可以给每个value赋一个score，代表value的排序权重

zset可以存学生id 后面是考试分数，可以根据分数进行排序。

zset用一种叫跳跃列表的数据结构实现。

### 跳跃列表

多层级的链表结构，最底层包含所有数据，每往上加一层数据减半，添加查询数据类似树 用的事二分查找定位元素。


## 容器型数据结构

1. 如果容器不存在就创建一个
2. 如果容器内元素没有了就删除容器

# redis 可以用来解决什么问题

## redis 分布式锁

1. setnx 与expire 组合的原子指令
2. 不能解决超时问题

## redis 队列

 适用于只有一组消费者，简单有效。

### 异步消息队列

利用redis的list 的rpush/lpush lpop/rpop操作队列。

1. 接受端增加延迟，使用blpop、brpop阻塞运行。
2. 空闲断开连接时异常处理
3. redis分布式锁冲突后处理。直接抛出异常，一会重试 加入延迟队列一会重试。

### 延时队列

利用Redis的zset实现，消息字符串作为zset的value 消息到期处理时间作为score。 多线程轮询找需要处理的任务。zrem保证数据只被一个线程处理。


```
import java.lang.reflect.Type;
import java.util.Set;
import java.util.UUID;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.TypeReference;
import redis.clients.jedis.Jedis;

public class RedisDelayingQueue<T> {

  static class TaskItem<T> {

    public String id;
    public T msg;
  }

  // fastjson 序列化对象中存在 generic 类型时，需要使用 TypeReference
  private Type TaskType = new TypeReference<TaskItem<T>>() {
  }.getType();
  private Jedis jedis;
  private String queueKey;

  public RedisDelayingQueue(Jedis jedis, String queueKey) {
    this.jedis = jedis;
    this.queueKey = queueKey;
  }

  public void delay(T msg) {
    TaskItem task = new TaskItem();
    task.id = UUID.randomUUID().toString();
    task.msg = msg;
    String s = JSON.toJSONString(task);
    jedis.zadd(queueKey, System.currentTimeMillis() + 5000, s); // 塞入延时队列 ,5s 后再试
  }
// 分配唯一的 uuid // fastjson 序列化

  public void loop() {
    while (!Thread.interrupted()) {
// 只取一条
      Set values = jedis.zrangeByScore(queueKey, 0, System.currentTimeMillis(), 0, 1);
      if (values.isEmpty()) {
        try {
          Thread.sleep(500); // 歇会继续
        } catch (InterruptedException e) {
          break;
        }
        continue;
      }
      String s = values.iterator().next();
      if (jedis.zrem(queueKey, s) > 0) {
// 抢到了
        TaskItem task = JSON.parseObject(s, TaskType);
        this.handleMsg(task.msg);
      }
    }
  }

  public void handleMsg(T msg) {
    System.out.println(msg);
  }

  public static void main(String[] args) {
// fastjson 反序列化
    Jedis jedis = new Jedis();
    RedisDelayingQueue queue = new RedisDelayingQueue<>(jedis, "q-demo");
    Thread producer = new Thread() {
      public void run() {
        for (int i = 0; i < 10; i++) {
          queue.delay("codehole" + i);
        }
      }
    };
    Thread consumer = new Thread() {
      public void run() {
        queue.loop();
      }
    };
    producer.start();
    consumer.start();
    try {
      producer.join();
      Thread.sleep(6000);
      consumer.interrupt();

      consumer.join();
    } catch (InterruptedException e) {
    }
  }
}

```

## 位图

位图就是普通的字符串，bool类型的数据 可以每个占一位。

可以用get/set操作整个位图的内容，也可以用getbit/setbit操作某一位的内容。

Redis 提供位图统计指令bitcount 统一1的个数 和bitpos统计范围内出现第一个0或1。 但是传的参数范围是字节索引，只能是8的倍数。

bitfeld 命令对多个位操作 流处理。最多64位，支持多个子命令。


## HyperLogLog 

适用范围 不精确去重统计UV访客数之类的 

指令 pfadd pfcount, 找个变量直接用pfadd扔用户id, 然后pfcount取结果就行。 pfmerge可以合并结果。

HyperLogLog占用12k的存储空间 不适合统计单个用户相关的数据，适合大数据量。

Redis 对HyperLogLog的存储进行了优化，采用系数矩阵存储，占用空间很小，数据量变大时才会占用12k的空间。

### HyperLogLog实现原理

基数统计算法 

依据 N个随机数与低连续零位K之间的大致关系为N=2^K

1. 找一个BitKeeper变量存K,每次新添加数据更新K值，不存原始数据。
2. 设计一个BitKeeper数组,进行加权评估。多个样本比较准确。
3. 计算倒数平均数（个别异常值对整体影响较小），算出平均K值。
4. 根据之前N=2^K公式算出N的大概值。

```
import java.util.concurrent.ThreadLocalRandom;

public class HyperLogLog {

  static class BitKeeper {

    private int maxbits;

    public void random(long value) {
      int bits = lowZeros(value);
      if (bits > this.maxbits) {
        this.maxbits = bits;
      }
    }

    private int lowZeros(long value) {
      int i = 1;
      for (; i < 32; i++) {
        if (value >> i << i != value) {
          break;
        }
      }
      return i - 1;
    }
  }

  static class Experiment {

    private int n;
    private int k;
    private BitKeeper[] keepers;

    public Experiment(int n) {
      this(n, 1024);
    }

    public Experiment(int n, int k) {
      this.n = n;
      this.k = k;
      this.keepers = new BitKeeper[k];
      for (int i = 0; i < k; i++) {

        this.keepers[i] = new BitKeeper();
      }
    }

    public void work() {
      for (int i = 0; i < this.n; i++) {
        long m = ThreadLocalRandom.current().nextLong(1L << 32);
        BitKeeper keeper = keepers[(int) (((m & 0xfff0000) >> 16) % keepers.length)];
        keeper.random(m);
      }
    }

    public double estimate() {
      double sumbitsInverse = 0.0;
      for (BitKeeper keeper : keepers) {
        sumbitsInverse += 1.0 / (float) keeper.maxbits;
      }
      double avgBits = (float) keepers.length / sumbitsInverse;
      return Math.pow(2, avgBits) * this.k;
    }
  }

  public static void main(String[] args) {
    for (int i = 100000; i < 1000000; i += 100000) {
      Experiment exp = new Experiment(i);
      exp.work();
      double est = exp.estimate();
      System.out.printf("%d %.2f %.2f\n", i, est, Math.abs(est - i) / i);
    }
  }
}

```

## 布隆过滤器Bloom Filter

解决问题，头条推送消息，去掉用户已经看过的。

判断某个值一定不存在，或可能存在。

1. 存储结构本质是一个长数组，里面存0或1两位数。
2. 通过两种hash算法将某个值映射到数组的两个不同的点钟 标记为1。
3. 判断传入值的hash映射的两个点是否为都为1 如果都为1则可能存在，有一个不为1则不存在。

![](/images/bloom.svg)










