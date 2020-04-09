---
title: 微信小程序上传图片到阿里oss
date: 2020-03-37
categories:
- 第三方
tags:
- java
- oss

---


1. wx.uploadFile 只支持post方法。
2. 一般的签名url用的是put方法。

<!--more--> 

## 阿里云

需要配置桶里支持post方法。

## 小程序

policy signature 由于要用到 `appSecret` 所有需要在后端服务器生成

```
  wx.uploadFile({
      url: server,
      filePath: filePath,
      name: 'file',
      formData: {
         'key': key,
         'policy': policy,
         'OSSAccessKeyId': accessid,
         'signature': sign,
         'success_action_status': '200',
      },
      success: function (res) {
         },
      fail: function (err) {
         
      },
   })
   
```

## java后端

和web生成签名url的方式不一样，调用OSSClient的方法 然后new个bean返回给前端

```
public static OssPostResponse generatePresignedUrl(String bucketName, String url,
      Long expireTime) {
    ClientConfiguration configuration = new ClientConfiguration();
    configuration.setProtocol(Protocol.HTTPS);
    OSSClient ossClient = new OSSClient(ENDPOINT, new SystemPropertiesCredentialsProvider(),
        configuration);

    long expireEndTime = System.currentTimeMillis() + expireTime * 1000;
    Date expiration = new Date(expireEndTime);
    PolicyConditions policyConds = new PolicyConditions();
    policyConds.addConditionItem(PolicyConditions.COND_CONTENT_LENGTH_RANGE, 0, 1048576000);

    String postPolicy = ossClient.generatePostPolicy(expiration, policyConds);
    byte[] binaryData = new byte[0];
    try {
      binaryData = postPolicy.getBytes("utf-8");
    } catch (UnsupportedEncodingException e) {
      e.printStackTrace();
    }
    String encodedPolicy = BinaryUtil.toBase64String(binaryData);
    String postSignature = ossClient.calculatePostSignature(postPolicy);

    OssPostResponse response = new OssPostResponse();
    response.setUrl(url);
    response.setPolicy(encodedPolicy);
    response.setSignature(postSignature);
    response.setOssAccessKeyId(
        StringUtils.trim(System.getProperty(AuthUtils.ACCESS_KEY_SYSTEM_PROPERTY)));
    response.setKey(UUID.randomUUID().toString());
    return response;
  }

```

