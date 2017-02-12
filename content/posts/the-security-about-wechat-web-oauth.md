+++
comments = false
date = "2016-11-28T21:38:46+08:00"
slug = ""
title = "从 40029 和 state 来说说微信网页授权的安全问题"
toc = false
+++

本文其实有一点标题党，因为微信网页授权本身并没有什么安全问题，有安全问题的是一些不恰当的打开姿势。主要围绕授权过程中 40029 报错和 state 参数的使用方式来展开讨论，如果你在开发中也遇到过这类似的问题，或许这篇文章可以帮到你。

## 认识微信网页授权

微信网页授权([官方文档](http://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421140842&token=&lang=zh_CN))是公众号开发者在微信内嵌浏览器中获取用户基本信息的唯一方式，其最关键的就是取得用户的 openid，进而才能实现支付一类的功能，因此微信这个 OAuth 的意义已经不仅仅在于授权登录了。

一个简单的微信授权的流程大致如下：

![屏幕快照 2016-11-28 下午10.22.09](https://img.ichou.cn/assets/b8dcbd163afe76b05846eac50aee9ad6.png)

当然，在实际使用中，我们不会让用户每次都去授权，授权之后我们会把信息写入 session/cookie 中，于是一个比较标准的流程应该是：

![屏幕快照 2016-11-28 下午10.34.17](https://img.ichou.cn/assets/a9ae91255bb76ba3a387722ae1a50e38.png)

## state 该如何用

在微信授权的参数里面，有一个不太起眼的非必须字段 state ，官方的说明是『重定向后会带上state参数，开发者可以填写a-zA-Z0-9的参数值，最多128字节』，咋看一下，似乎只是一个标识字段，用来传递用户授权前的状态。

但实际上，我们可以在回调地址 redirect_uri 里传递任何参数，同样可以用来保持用户的状态，实现和 state 一样的效果，为什么还要单独设立一个 state 参数呢？

在我刚接触微信授权的时候，应业务需求做了一个微信授权的中转服务，我将 state 用来标识用户在授权后应该去到哪一个应用，比如用户需要去我们的商城 mall，那么就传 `state=mall`。这个设计看似高效合理，但是不知不觉间就已经引入了一个潜在的安全问题了：

如果授权第二步中微信 301 重定向的 url 被其他人截取了，我没有办法验证这个 url 的请求者是不是我的真实用户，因为没有一个字段可以给我用来做验证。只要行动够快或够鸡贼，这个不怀好意的家伙拿着这个 url 便可以跳过微信的授权以用户的身份登录到我们的商城，而且由于 state 设计得过于简单，他甚至可以通过修改 state 去到任何一个接入过的系统。

如果你用过一些主流的微信支持组件，如 ruby 的 wechat gem 包、php 的 EasyWeChat，你会发现他们的授权方法里都不支持自定义 state，授权 callback 的时候会对 state 做比对检测。对此，ruby wechat 的维护者 Eric-Guo 给出的解释是：

> state的确可以这么用（自定义使用），但是设计目的实际上是为了安全性，也就是说这个state设计的目的是防止有人冒名顶替的登录。。

> 这也是wechat gem内置帮你填写的原因，而不是放出来让你自定义的原因。

综上，state 一种比较有效的用法是：

**在授权开始前生成并写入用户的 cookie（还需要加密），授权完成时，比对 url 与 cookie 中的 state，如果不一致便可判定为非法请求。**

![屏幕快照 2016-11-28 下午11.27.27](https://img.ichou.cn/assets/300a204f1dd9441ecfd6b825dc9089a3.png)


## 40029 报错如何处理

我相信大部分开发过微信授权的人，都遇到过 40029 这个报错。对于这个报错，官方说明是 『40029 不合法的 oauth_code』，排开真正 code 错误的情况（这种情况几乎可以忽略），通常会遇到这个报错的原因都是同一个 code 被使用了两次。

其实这是微信的一项安全策略，将用户授权的 code 设计为一次性的，从而极大程度的避免了不怀好意的人截取并记录回调 url，然后恶意访问，绕过微信授权实现欺骗登录。上一节中提到这同一个问题时，我用了『只要行动够快或够鸡贼』这个限定，因为只有他赶在用户跳转前请求才能成功的伪装成用户登录，除了快他也可以篡改返回数据包中的 redirect_url 让用户根本就取不到真正的 url，他便可以悠哉悠哉的去操作了。

曾经我为了解决这个 40029 报错的问题，花了不少时间去查看日志，发现大约有下面几种情况有可能会触发 40029：

1. 用户授权跳转后，点击返回触发二次请求。这种情况，要么是你没有记录用户的状态（openid），要么就是用户状态正好丢失了（session 丢失或 cookie 丢失，都是小概率事件）
2. 用户在授权时，网速略慢，等待的时间略微有点久了，于是正好在第一次请求返回前刷新了页面，触发了第二次请求
3. 几乎同时收到两个完全一样的授权回调请求，不排除是某些手机某些版本的微信内置浏览的某些行为导致的
4. 还有一种，用户授权完成，几秒钟后另一个 ip 又来请求了同一个 URL， 😂 这个原因我就不多猜了

**为了『处理』40029 报错，将 code 换 access_token + openid 的结果缓存在服务端（如 redis）的行为是不可取的，这样无异于开门进屋之后，把钥匙留在门上**，在 code 被缓存这段时间，脚本小子可以拿着这个 code 拼装回调 url，冒充这个用户登录你们的各种服务。

所以，个人建议不要去处理 40029 报错，一来它本身是一种安全机制，处理不当反倒不好；二来它出现的概率也不大，多表现为间歇性抽风。

如果你有强迫症，不能容忍任何报错，你可以捕获 40029 然后让请求者再走一次微信授权流程，如果是真实用户，并没有什么影响，如果是恶意请求，那它会被微信服务器拦截下来。

## 总结

从流程设计上来说，微信网页授权其实是很安全的，而且有静默授权这种方式，用户体验也不错。但是所有的安全都是相对的，别有用心的人总有别出心裁的办法来攻击，区别只是难度的大或小。作为开发者的我们，首先应该做到不去破坏这些安全手段，然后在自己的领域里进一步补强。也许本文中提到的安全入侵你永远都遇不到，但那确实是一种可能，也比较容易做到，**在安全上，我们应当怀着最大的恶意去揣度这个世界**。
