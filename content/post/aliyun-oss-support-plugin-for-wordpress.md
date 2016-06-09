+++
date = "2014-09-03T22:42:49+08:00"
title = "Aliyun OSS support plugin for wordpress (ver: 2.4.0)"

+++

某一天我打算把放在 ACE 上的老博客图片换到 Aliyun OSS 上去时，发现没有那个插架是可用的。一开始打算拿 马建文 同学的 [阿里云附件(Aliyun Support)](http://mawenjian.net/p/977.html) 来改改，发现这也是一个年久失修的作品了。迫不得已，自己动手造了个轮子。原本只是自己用，看到 ACE 论坛里面有人有同样的需求，于是就放到了论坛中去。意外的是除了 ACE，还引来了不少非 ACE 的用户（由于是阿里的社区，估计大部分是用 ECS 放 WP 的壕，哈哈~）。从用户的反馈邮件和 issue 来看，估摸着虽然不多，但是这个插件还是有不少用户了。有空时候，我也就稍微维护一下。

补一个刀：马建文 童鞋的插件后来也更新了，源码还放到了 Github.
当前的版本好像已经到 V2.1 beta版(2016年4月6日)，这个插件挺用心的，建议优先尝试一下
https://github.com/mawenjian/aliyun-oss-support


> **再补一个刀：AliyunOSS 推出了回源服务，也许你已经不再需要这个插件了**

* * *

## 基于阿里云OSS的WordPress远程附件支持插件 (Aliyun-OSS-Support)

### 插件简介

本插件主要为 Wordpress 提供基于阿里云 OSS 的远程附件存储功能，并且最大限度的依赖 wordpress 本身功能扩展来实现，以保证插件停用或博客搬迁时可以快速切换会原来的方式。插件采用静默工作方式，设置启用后会直接替换原生存储，无需增加任何额外操作。当然，缺点就是无法同时使用 本地 和 OSS 两边的资源，<del>或许稍微改下可以实现</del>（想想都好麻烦 ╮(╯▽╰)╭）

### 插件特色

1.  支持阿里云 OSS 的图片服务（—>这个图片服务是个神器啊）  

2.  支持设定文件在 OSS 上的存储路径  

3.  全格式附件支持，不仅仅是图片  

4.  可以设定本地文件是否保留  

5.  不使用图片服务时，会连缩略图一起上传  

6.  可以自定义域名（已绑定bucket的）（—> 这也算特色？） 

7.  支持 wordpress 4.4+ 新功能 srcset，在不同分辨率设备上加载不同大小图片

8.  最后，也是最重要的特色，它的代码看上去很优雅，很干净

### 插件使用

1.  下载  
    [Aliyun-OSS-Support](https://github.com/IvanChou/aliyun-oss-support/archive/master.zip)  

2.  安装并启用  
3.  按提示设置  
![](http://chou.oss-cn-hangzhou.aliyuncs.com/yii.im%2Fasset%2F549b11107969690548090000%2FFid_220-220_1900406608627700_2e0d2a0ca198570.png)

4.  试一下能不能用(=<sup>‥</sup>=)

### 关于设置的一些说明

1.  `img_server_url` 有值时，即代表开启了 OSS 的图片服务支持，关于图片服务请看 [图片服务使用手册](http://help.aliyun.com/view/11108271_13510461.html?spm=5176.383663.9.11.ax1FI3)  
    你需要设置 `{'thumbnail','post-thumbnail','large','medium'}`四种样式 
    
    ![](http://chou.oss-cn-hangzhou.aliyuncs.com/yii.im%2Fasset%2F549b111079696905480a0000%2FFid_220-220_1900406608627700_3cf7a9082ce9838.png) 

    这是我的设置，建议这里的设置和 WordPress 后台的多媒体设置同步  

2.  图片服务开启时，只会上传原图到 OSS 上  

3.  OSS-Http-Url 留空的话，WordPress 会切换回使用本地资源的状态，但是 OSS 上传依旧会进行  

4.  Save path on OSS 不会影响本地存储路径，可是放心设置  

* * *

### Github

[https://github.com/IvanChou/aliyun-oss-support](https://github.com/IvanChou/aliyun-oss-support)

### 问题反馈

[https://github.com/IvanChou/aliyun-oss-support/issues](https://github.com/IvanChou/aliyun-oss-support/issues)  
左下角的邮箱也可以

* * *

### 更新日志

#### 版本号: 1.0 

  Plugin URI: “[http://mawenjian.net/p/977.html](http://mawenjian.net/p/977.html)”  
  Author: 马文建(Wenjian Ma)  
  Author URI: [http://mawenjian.net/](http://mawenjian.net/)

#### 版本号：1.1

修正日期：2014-8-27

##### 修订项目：
1. 插件年久失修，其内部调用的 Aliyun OSS php SDK 已升级
2. WordPress 3.5以后 设置->多媒体 中没有路径配置，导致配置不便
3. Aliyun OSS 可以绑定自己的域名，插件中不能简单的设置

##### 修订内容：
1. 升级 Aliyun-OSS-SDK 到 1.1.6 版本 (2014-06-25更新)
2. 设置中可直接配置访问路径 Url，支持已绑定到 OSS 的独立域名
3. 支持自定义 OSS 上文件的存放目录 （不影响本地存储，中途若修改请手动移动 OSS 上文件，否则可能链接不到之前的资源）
4. 修正原插件 bug 若干
5. 优化代码 ~~（移除所有 Notice 级报错）~~

#### 版本号：2.0

修正日期：2014-9-1

##### 修订内容：
1. 完全重构，优化代码
2. 支持 Aliyun OSS 的图片服务
3. 改变钩子嵌入机制，支持所有附件（以前的版本只上传图片，而且启用时其他附件完全不可用了，坑！！）
4. 添加卸载、不残留
5. 支持 Aliyun ACE （ 切换到 ACE 分支 ）

#### 版本号：2.1

修正日期：2014-11-7

##### 修订内容：

在某些环境中，启用插件时提示

```
这个插件启用过程中产生了3个字符的**异常输出**。如果您遇到了……
```

原因为 sdk.class.php 这个文件编码问题，已修复

若仍有这个报错，请尝试转换文件编码与您的网站环境编码一致。

感谢：网友 tang6818(at)foxmail.com 反馈

#### 版本号：2.1.1

修正日期：2014-12-25

##### 修订内容：

处理 OSS 自定义存储 path 为空时出现的多斜线 Bug

感谢：网友 sjw(at)cnsjw.cn 反馈

#### 版本号：2.1.2

修正日期：2014-12-26

##### 修订内容：

修正在非当前月份文章中上传图片时，由于缩略图无法上传导致错误的 bug.

感谢：网友 sjw(at)cnsjw.cn 协助修订


#### 版本号：2.1.3

修正日期：2015-01-19

##### 修订内容：

1. 将设置界面的 Secret Key 隐藏，Secret Key 不再会被读取到客户端

2. 处理中文乱码问题

特别注意：处理中文问题的时候，我发现好像是 Aliyun SDK 的问题，细看了下源码，这个 SDK 写得有点怨念，对 Ali 的好感一下子掉了好多

具体修改了 sdk.class.php line 1290 ~ 1291

准备反馈给官方~

感谢：网友 sjw(at)cnsjw.cn 的建议 和 风的涟漪协助测试


#### 版本号：2.3.2

修正日期：2015-11-14

##### 修订内容：

1. 更新 SDK (2015-08-19 版)

2. 添加对数据节点设置的选项，考虑到以后可能还有各种节点，干脆留了个框自己填

3. 重新封装原来的 Aliyun_oss 对象，使其在使用上和 ACE 引擎内置的 Alibaba::Storge 类保持一致，现在 ACE 和其他环境通用一个版本 

4. 使用单例，之前脑子进屎了，没上传一个对象就要 new 一个对象，简直是浪费（可能是因为自己不需要上传缩略图，所以当时没 care，建议大家也使用 OSS 的图片服务，很 nice 的其实）

5. 解决设置本地不保存文件时，安装主题、插件失败，并被上传到 OSS 的 BUG

感谢各位的提的 Issue，~~由于已经转到 ruby 开发了，php 很少接触了，不能保持维护，实在对不住~~

#### 版本号：2.4.0

修正日期：2016-04-30

##### 修订内容：

1. 增加启用图片服务时，对 srcset 的支持（ 支持 wordpress 4.4+ ）

2. 修改数据节点的链接，原链接失效了

感谢 https://github.com/IvanChou/aliyun-oss-support/issues/9 （感谢 @hairui219 提供）
