+++
date = "2014-08-30T22:43:03+08:00"
draft = false
title = "WordPress 邮件插件分析 与 简信（Jianxin for WordPress）"

+++

* * *

虽然 Wordpress 邮件插件已经有很多了，国外的 [Configure SMTP](http://wordpress.org/plugins/configure-smtp/) 和 [WP-Mail-SMTP](http://wordpress.org/plugins/wp-mail-smtp/)，国内的 [WP SMTP](http://wordpress.org/plugins/wp-smtp/)，甚至还有很多所谓的无插件添加 SMTP 邮件服务的教程，但是 **简信** 和上面这些的邮件发送方式并不一样，即所谓的编程式邮件，可以作为一种（伪）geek的选择。

### wordpress 默认邮件解决方案

wordpress 默认的邮件解决方案是使用 php 的 `mail()` 方法，调用的是 php 环境自身的邮件组件。想起来这的确是最简单、最干净的处理方式，就像图片处理用 gd，请求用 curl 一样，但是由于垃圾邮件这个问题的存在, `mail()` 就成了被遗弃的一部分了。大多数 php 环境里都没有开启对 `mail()` 的支持，即使发出去的，也通常会被 spam 拦截掉，这也是静默安装的 wordpress 无法发出邮件的原因。

### wordpress 内置其他解决方案

除了 `mail()` ，wordpress 内核中还内置了其他几种邮件解决方案：

- SMTP  
- POP3  
- Sendmail  
- Qmail

SMTP 是最常用的解决方案，上面列出的几个插件都是调用的这一功能，而这些插件本身其实就是实现了 SMTP 的快速配置接口。

POP3 和 SMTP 类似，但是现在用得已经相对较少了。

Sendmail 和 Qmail 是类似的，都是一种需要在服务器上安装的邮件发送组件，其具体实现方式没有研究过，因为需要服务器组件支持，感觉上一般用户很少有人使用。

### SMTP 插件和 SMTP 无插件教程

如上所说，SMTP 插件本身并没有带上 SMTP 邮件发送的核心方法，只是实现配置接口。而网上流传的 SMTP 无插件教程，就是把配置的核心部分提出来放在 WordPress 的源文件里。从原则上来讲两种方法是没有优劣之分的，但是从管理和 wordpress 本身的架构方式（钩子遍地式架构）来看，还是插件的方式更值得推荐。

### 简信

*   [简信官网](http://jianxin.io)  
    就如进入简信里所看到的一样，简信目前推行的是 http 接口方式来发送邮件，操作自由度以及对程序员的友好度是其他方式不能比拟的，如果说 SMTP 是解决了邮件发送问题，JianXin 则是在一种欢快的心情下解决邮件发送问题的方式。这就是简信的 **编程式邮件解决方案**

* * *

### 简信 for WordPress 插件（工程版）

**JianXin for WordPress plugin** 是我代为简信开发的第一个产品，目前暂以实现邮件发送功能为主，然后逐步拓展功能，为之后的正式版以及简信的 PHP-SDK 开发做铺垫

#### == Date-line ==

* start：2014-08-19  
* ver.0.0.1：2014-08-22  
* var.0.0.2: 2014-08-08

#### == 嵌入方式 ==

由于 WordPress 没有为邮件发送预留其他的方式（这种事儿也没法预留吧 ╮(╯_╰)╭）,所以要实现简信插件理论上来说是需要重写整个 `PHPMailer Class` 的。但是原生的 `PHPMailer Class` 很机智的留了一个回调函数，所以暂时的，我选择了用 `mail method` 的回调来接入 Jianxin Mail 的功能。**这样的方式是有前提的，就是当前 `mail method` 一定要是无效的，否则用户可能收到两封相同的邮件。**

#### == 其他说明 ==

后台设置的样式暂借鉴 WP-SMTP 的样式。  
（ PS: WP-SMTP真的是一款用心的插件 ）

#### == 下载 ==

[JianxinMail.zip](http://www.ichou.cn/files/5401bc72b1fc2dcb87000023)
