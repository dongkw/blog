---
title: redis
date: 2020-03-20
categories:
- redis
tags:
- java
- redis

---

[redis知识点]https://www.processon.com/view/link/5ef981b9f346fb1ae5831bdc


# Redis 基础数据结构

Redis 所有数据结构都是以唯一的key字符串作为名称，通过key获取value数据，不同类型的区别是value结构不一样。


<!--more--> 


Redis有5种基础数据结构

## string（字符串）

![](/images/redisstring.svg)

header和 SDS组成

header对象
1. type 对象的类型 4byte
2. encoding 对象的编码格式 4byte
3. lru 记录当前项目的缓存淘汰算法 24byte
4. refcount 引用计数器 4byte
5. *ptr 指向内容 8byte

SDS对象
1. capacity 对象总空间 
2. len 对象已用空间 
3. flags 代表header对象类型 1byte
4. content 具体字符串信息 以"\0"结尾

embstr 开始分配内存时header与sds相连 
raw sds对象扩容 header通过#ptr指针指向扩容后的sds对象。

Redis 字符串是动态字符串，内部实现类似于Java的ArrayList，采用预分配冗余空间来减少内存频繁分配

分配方式 当字符串小于1M 每次加倍，大于1M 每次加1M 最大512M


## 字典dict

字典包括两个哈希表。


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
2. 通过两种hash算法将某个值映射到数组的两个不同的点 标记为1。
3. 判断传入值的hash映射的两个点是否为都为1 如果都为1则可能存在，有一个不为1则不存在。

![](/images/bloom.svg)

## 简单限流

应用场景，某段时间内的只处理几个请求其余的全部拒绝掉

```
public class SimpleRateLimiter {

  private Jedis jedis;

  public SimpleRateLimiter(Jedis jedis) {
    this.jedis = jedis;
  }

  public boolean isActionAllowed(String userId, String actionKey, int period, int maxCount) {
    String key = String.format("hist:%s:%s", userId, actionKey);
    long nowTs = System.currentTimeMillis();
    Pipeline pipe = jedis.pipelined();
    pipe.multi();
    pipe.zadd(key, nowTs, "" + nowTs);
    pipe.zremrangeByScore(key, 0, nowTs - period * 1000);
    Response<Long> count = pipe.zcard(key);
    pipe.expire(key, period + 1);
      pipe.exec();
    try {
      pipe.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
    return count.get() <= maxCount;
  }

  public static void main(String[] args) {
    Jedis jedis = new Jedis();
    SimpleRateLimiter limiter = new SimpleRateLimiter(jedis);
    for (int i = 0; i < 20; i++) {
      System.out.println(limiter.isActionAllowed("laoqian", "reply", 60, 5));
    }
  }
}

```

## 漏斗限流 redis-cell


```
cl.throttle laoqian:reply 15 30 60
```

## GeoHash 地理位置排序


地理位置排序，将二维经纬度映射到一维整数，将所有元素挂载到一条线上。

二刀法 一个正方形切成4个小正方形 可以标记为 00，01，10，11 
在切第一个小正方形 0000 0001 0010 0011 每个分成4个二进制整数。真实算法还会有其他刀法，最终编码出的整数也不一样。

单个key中的数据量不应超过1M

六个命令 geoadd geolist geopos geohash georadiusbymember georadius

```
127.0.0.1:6379> geoadd company 116.48105 39.996794 juejin (integer) 1
127.0.0.1:6379> geoadd company 116.514203 39.905409 ireader (integer) 1
127.0.0.1:6379> geoadd company 116.489033 40.007669 meituan
(integer) 1
127.0.0.1:6379> geoadd company 116.562108 39.787602 jd 116.334255 40.027400 xiaomi (integer) 2

127.0.0.1:6379> geodist company juejin ireader km "10.5501"
127.0.0.1:6379> geodist company juejin meituan km "1.3878"
127.0.0.1:6379> geodist company juejin jd km "24.2739"
127.0.0.1:6379> geodist company juejin xiaomi km "12.9606"
127.0.0.1:6379> geodist company juejin juejin km "0.0000"



127.0.0.1:6379> geopos company juejin 1) 1) "116.48104995489120483"
2) "39.99679348858259686"
127.0.0.1:6379> geopos company ireader 1) 1) "116.5142020583152771"
2) "39.90540918662494363" 
127.0.0.1:6379> geopos company juejin ireader 1) 1) "116.48104995489120483"
2) "39.99679348858259686" 2) 1) "116.5142020583152771"
2) "39.90540918662494363"

127.0.0.1:6379> geohash company ireader 1) "wx4g52e1ce0"
127.0.0.1:6379> geohash company juejin 1) "wx4gd94yjn0"

# 范围 20 公里以内最多 3 个元素按距离正排，它不会排除自身
127.0.0.1:6379> georadiusbymember company ireader 20 km count 3 asc 1) "ireader"
2) "juejin"
3) "meituan"
# 范围 20 公里以内最多 3 个元素按距离倒排
127.0.0.1:6379> georadiusbymember company ireader 20 km count 3 desc 1) "jd"
2) "meituan"
3) "juejin"
# 三个可选参数 withcoord withdist withhash 用来携带附加参数
# withdist 很有用，它可以用来显示距离
127.0.0.1:6379> georadiusbymember company ireader 20 km withcoord withdist withhash count 3 asc 1) 1) "ireader"
2) "0.0000"
3) (integer) 4069886008361398 4) 1) "116.5142020583152771"
2) "39.90540918662494363" 2) 1) "juejin"
2) "10.5501"
3) (integer) 4069887154388167 4) 1) "116.48104995489120483"
2) "39.99679348858259686" 3) 1) "meituan"
2) "11.5748"
3) (integer) 4069887179083478 4) 1) "116.48903220891952515"
2) "40.00766997707732031"


127.0.0.1:6379> georadius company 116.514202 39.905409 20 km withdist count 3 asc 1) 1) "ireader"
2) "0.0000" 2) 1) "juejin"
2) "10.5501" 3) 1) "meituan"
2) "11.5748"
```

## Scan 找出特定前缀的key列表

1. 指令 keys [regular] 

缺点:
1. 没有分页 
2. 遍历算法 时间复杂度O(n) redis单线程 其他指令会延后

```
127.0.0.1:6379> set codehole1 a OK
127.0.0.1:6379> set codehole2 b OK
127.0.0.1:6379> set codehole3 c OK
127.0.0.1:6379> set code1hole a OK
127.0.0.1:6379> set code2hole b OK
127.0.0.1:6379> set code3hole b OK
127.0.0.1:6379> keys * 
1) "codehole1"
2) "code3hole"
3) "codehole3"
4) "code2hole"
5) "codehole2"
6) "code1hole"
127.0.0.1:6379> keys codehole* 
1) "codehole1"
2) "codehole3"
3) "codehole2"
127.0.0.1:6379> keys code*hole 
1) "code3hole"
2) "code2hole"
3) "code1hole"
```

2. scan 

scan 参数提供了三个参数，第一个是 cursor 整数值，第二个是 key 的正则模式，第三
个是遍历的 limit hint。第一次遍历时，cursor 值为 0，然后将返回结果中第一个整数值作为
下一次遍历的 cursor。一直遍历到返回的 cursor 值为 0 时结束。

1、复杂度虽然也是 O(n)，但是它是通过游标分步进行的，不会阻塞线程;
2、提供 limit 参数，可以控制每次返回结果的最大条数，limit 只是一个 hint，返回的 结果可多可少;
3、同 keys 一样，它也提供模式匹配功能;
4、服务器不需要为游标保存状态，游标的唯一状态就是 scan 返回给客户端的游标整数; 
5、返回的结果可能会有重复，需要客户端去重复，这点非常重要; 
6、遍历的过程中如果有数据修改，改动后的数据能不能遍历到是不确定的; 
7、单次返回的结果是空的并不意味着遍历结束，而要看返回的游标值是否为零;


```
127.0.0.1:6379> scan 0 match key99* count 1000
1) "13976"
2)1) "key9911" 
2) "key9974" 
3) "key9994" 
4) "key9910" 
5) "key9907" 
6) "key9989" 
7) "key9971" 
8) "key99" 
9) "key9966"
10) "key992" 
11) "key9903" 
12) "key9905"
127.0.0.1:6379> scan 13976 match key99* count 1000 
1) "1996"
2)1) "key9982" 
2) "key9997" 
3) "key9963" 
4) "key996" 
5) "key9912" 
6) "key9999" 
7) "key9921" 
8) "key994" 
9) "key9956"10) 
"key9919"
127.0.0.1:6379> scan 1996 match key99* count 1000 
1) "12594"
2) 1) "key9939"
2) "key9941" 
3) "key9967" 
4) "key9938" 
5) "key9906" 
6) "key999" 
7) "key9909" 
8) "key9933"
 9) "key9992"
......
127.0.0.1:6379> scan 11687 match key99* count 1000 
1) "0"
2)1) "key9969" 
2) "key998" 
3) "key9986" 
4) "key9968"
 5) "key9965" 
 6) "key9990" 
 7) "key9915"
  8) "key9928" 
  9) "key9908"
  10) "key9929" 
  11) "key9944

```

### 原理
 
 ![](/images/103.png)
 
 redis所有key都存在一个很大的字典中，是数组加链表的结构。
 
 scan的游标是一维数组的索引。
 
 scan的遍历是高位进位加法。
 
 hash底层就是字典，set也是特殊的字典，都可以用scan遍历
 
 redis字典扩容 加一位高位 从一个槽变成两个。
 
  ![](/images/104.png)

 高位进位加法从左边加 进位往右边移动，与普通加法正好相反。
 
 扩容后的字典，用高位加法遍历是相邻的，可以避免重复遍历
  
 ![](/images/105.png)

### 避免使用大key

有时候会因为业务人员使用不当，在 Redis 实例中会形成很大的对象，
比如一个很大的 hash，一个很大的 zset 这都是经常出现的。这样的对象对 Redis 的集群数据迁移带来了很 大的问题，因为在集群环境下，
如果某个 key 太大，会数据导致迁移卡顿。另外在内存分配 上，如果一个 key 太大，那么当它需要扩容时，会一次性申请更大的一块内存，
这也会导致 卡顿。如果这个大 key 被删除，内存会一次性回收，卡顿现象会再一次产生。

#### 定位大key

```
redis-cli -h 127.0.0.1 -p 7001 –-bigkeys
redis-cli -h 127.0.0.1 -p 7001 –-bigkeys -i 0.1
```

# redis IO模型

redis是单线程

redis所有数据存在内存中所以很快

多路复用 select系列的事件轮询API 非阻塞IO


## 什么是IO

IO在计算机中指Input/Output，由于程序和运行时数据是在内存中驻留，由CPU这个超快的计算核心来执行，涉及到数据交换的地方，通常是磁盘、网络等，就需要IO接口。

## 非阻塞IO



类似于读书，一个人可以看多本书，但是每次只能看一本，而且也不可能一次看完一本书，至于每次到底看几页，那和看书的时间长度与人看书的效率有关。


## 事件轮询 (多路复用)

和看书一样，如果要求你写读后感，就是输出一个io操作的结果。肯定要等到这本书都看完才行。
而现在又需要你写好多本书的读后感的话，就会出现一个人在那里问 A书的读后感写了吗，B书的读后感写了吗... 一会一次的在那催。

## 指令队列

客户端的指令过来，单线程不能全部执行，肯定要放到队列里，先进先出

## 响应队列

处理完的结果不是直接返回而是放到队列里，供轮询时直接调用返回结果事件

## 定时任务


# Redis通信协议

Redis 的作者认为数据库系统的瓶颈一般不在于网络流量，而是数据库自身内部逻辑处理上。
所以即使 Redis 使用了浪费流量的文本协议，依然可以取得极高的访问性能。Redis 将所有数据都放在内存，
用一个单线程对外提供服务，单个节点在跑满一个 CPU 核心的情 况下可以达到了 10w/s 的超高 QPS。

## RESP(Redis Serialization Protocol)Redis序列化协议

文本协议

将传输的结构数据分成5种最小单元 单元结束事统一加回车换行符`/r/n`

1. 单行字符串 以`+`号开头  
2. 多行字符串 以`$`开头 后跟字符串长度
3. 整数字值 以`:`开头 后跟字符串形式
4. 错误消息 以`-`开头
5. 数组 以`*`号开头 后跟数组长度

```
1. hellow world

+hello world\r\n

2. hellow world

$11/r/nhello world/r/n

3. 1024

:1024/r/n

4. 参数类型错误

-WRONGTYPE Operation against a key holding the wrong kind of value

5. ["hello","world"]

*3/r/n+hello/r/n+world/r/n

6. NULL

$-1/r/n

7. ""

$0/r/n/r/n

```

## 客户端->服务器

客户端到服务器只有一种格式就是`多行字符串数组`

set name kwkw

序列化后 *3/r/n$3/r/nser/r/n$4/r/nname/r/n$4/r/nkwkw/r/n

## 服务器->客户端

上述5中基本数据结构的组合

# redis持久化

redis数据存在内存中，为保证数据不丢失需要引入redis持久化机制

## 快照 一次性全量备份

快照是内存数据的二进制序列化，在存储上非常紧凑。

### 原理

前提是redis是单线程的程序，这个线程负责多客户端的并发读写操作。在并发操作的同时还需要进行文件io操作备份快照。

要求是不能影响线上服务，必须进行本地快照，持久化的同时数据结构还会变。

redis使用操作系统的多进程COW（copy on write）来实现快照持久化。

redis在持久化时候回调用glibc的fork函数创建一个子进程。持久化操作完全交给子进程。
创建子进程之处，由于操作系统的优化，子进程和父进程共享内存中带代码段和数据段。内存几乎不变。
子进程负责持久化工作，父进程负责业务服务。
子进程负责写入内存里面的数据段不变。而父进程的业务数据会改内存的数据段。
而当改变的时候操作系统会首先看有没有别的进程在使用当前数据段，如果有那就复制一份改自己复制出的这份。这就是操作系统的COW机制。
随着父线程的修改，共享内存会越来越多，但是最多不会超过开启进程前的二倍。

## AOF重写 连续增量备份

AOF日志记录是内存数据修改的指令记录文本。

AOF日志存储是redis服务器的顺序指令序列，只记录对内存进行修改的指令记录。

Redis 提供了 bgrewriteaof 指令用于对 AOF 日志进行瘦身。
就是开辟一个子进程对内存进行遍历转换成redis指令序列化到另一个AOC文件，在将序列化这段时间内的指令追加到新的AOC文件上。

AOC是日志文件，指令是存在内存中，如果指令没有同步到文件之前就宕机了，就会发生日志文件不全，数据丢失。

Linux 的 glibc 提供了 fsync(int fd)函数能强制将缓存刷到磁盘。

redis提供了两种机制 

1. 实时同步每一条指令刷一次 缺点非常慢，数据一定完整。
2. 不同步 让操作系统决定什么时候同步。 缺点 数据不一定完整。

而使用redis为的就是追求高性能，在同时尽可能保证数据的准确性 所以线上设置1s一次fsync。

`redis不能保证数据完全不丢失`

## 运维

快照是通过开启子进程的方式进行的，是个比较耗时的操作。

1. 遍历所有内存大块写内存耗费系统资源。
2. AOC的fsync操作是耗时的io操作，会增加系统负担。

所以用到redis集群时为了追求性能主库不会持久化数据，要在从库上做持久化，从库需要考虑的问题就是与主库的数据同步，加一个从库保证系统数据不丢失。

## 混合持久化

把rdb与AOC日志文件放到一起，AOC日志文件只存储持久化过程中的数据。读数据时候先读rdb在从新放AOC增量。


# Redis管道

redis管道是由redis客户端提供了 和服务器没关系

封装了多次http请求的request和response，统一处理， 和服务器的指令队列和响应队列差不多。只是改到了客户端。

# redis事务

只支持隔离性 多条操作如果有一条失败其他会顺序执行
discard(丢弃)命令 在事务提交前 可以取消掉操作结果。
当执行redis事务时，用管道操作 pipeline

redis 不支持事务回滚，只能在事务提交前用discard命令取消掉当前提交，需要手动控制。



# redis 小对象压缩

## 小对象压缩存储 ziplist

如果redis内部管理的数据结构很小 就会使用紧凑存储结构压缩储存。

如果存储的数据少于某个临界点，那么就会存在一个叫ziplist的字节数组中。 大于某个临界点就会升级为标准结构

```
hash-max-zipmap-entries 512 # hash 的元素个数超过 512 就必须用标准结构存储 
hash-max-zipmap-value 64 # hash 的任意元素的 key/value 的长度超过 64 就必须用标准结构存储 
list-max-ziplist-entries 512 # list 的元素个数超过 512 就必须用标准结构存储
list-max-ziplist-value 64 # list 的任意元素的长度超过 64 就必须用标准结构存储
zset-max-ziplist-entries 128 # zset 的元素个数超过 128 就必须用标准结构存储
zset-max-ziplist-value 64 # zset 的任意元素的长度超过 64 就必须用标准结构存储
set-max-intset-entries 512 # set 的整数元素个数超过 512 就必须用标准结构存储

```

## redis的内存回收机制

删除key后，value分配的内存并没有直接回收，而是后来的数直接用，flushdb时才会回收内存。


redis内存分配直接用第三方分配库实现 jemalloc(facebook) tcmalloc(google),libc

# redis主从同步

## cap原则 

分布式系统设计理论

网络分区发生时 一致性和可用性不能两全。

## 最终一致性

redis主从系统数据异步同步，只满足最终一致性。

## 主从同步

redis支持主从同步

## 增量同步

redis同步的是指令流，主节点会将对自己状态产生修改行影响的指令记录在本地buffer中，然后异步将buffer同步到从节点。
由于内存中的buffer长度有限，redis内存中的buffer是一个定长的环形数组，如果buffer满了就会覆盖之前的数据，覆盖后的数据会丢失。


## 快照同步

首先主库进行一次bgsave将内存中的数据快照进磁盘文件中，磁盘文件同步到从库，从库直接load rdb文件，然后增量同步主库的buffer.
如果buffer内存不够，依然会丢失数据

在增加从节点时必须先进行一次快照同步之后才能进行增量同步。

## 无盘复制

快照时会发生很重的io操作，所以主库省略写文件过程，直接通过socket发给从库，从库直接写入。

## wait指令

使某个操作同步执行到从库，wait 1\[从库的数量\] 0\[最多等待时间，0表示无限\]。

```
> set key value 
OK
> wait 1 0 
(integer) 1

```

# redis 集群策略

## Redis Sentinel(哨兵)

1. 客户端先与sentinel节点通信获取master节点的地址。
2. 客户端访问master节点。
3. 如果master节点down掉sentinel选举出新的master。
4. 如果原来的master节点恢复会变成slave节点。

在master节点挂掉到选举出新的master节点之前会丢失一部分数据。

```
min-slaves-to-write 1 
min-slaves-max-lag 10
第一个参数表示主节点必须至少有一个从节点在进行正常复制，否则就停止对外写服务，丧失可用性。
第二个参数控制的，它的单位是秒，表示如 果 10s 没有收到从节点的反馈，就意味着从节点同步不正常，要么网络断开了，要么一直没有给反馈。

```








