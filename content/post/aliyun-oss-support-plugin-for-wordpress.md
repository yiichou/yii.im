+++
date = "2014-09-03T22:42:49+08:00"
title = "Aliyun OSS support plugin for wordpress (ver: 2.0)"

+++

前文接 [基于阿里云OSS的WordPress远程附件支持插件——阿里云附件(Aliyun Support)(修订版)](http://ichou.cn/posts/ji-yu-a-li-yun-ossde-wordpressyuan-cheng-fu-jian-zhi-chi-cha-jian-a-li-yun-fu-jian-aliyun-support-xiu-ding-ban)

随着使用，发现这个插件有几个比较严重的问题，改动中代码结构也稍显混乱，于是花了点时间完全重写了这个插件。

由于百分之绝大部分代码都是重写的，原来的插件几乎只剩下了参考作用，想了很久还是打算重新发布。（PS: 主要是我把更新过代码托管到 github 后，特意通知了原作者，缺遗憾的没有得到回复 :sad ）

* * *

## 基于阿里云OSS的WordPress远程附件支持插件 (Aliyun-OSS-Support)

#### 题外话：

[Aliyun](http://www.aliyun.com/) 作为国内认可度最高的云服务提供商，进来在产品的完善上也有长足进步，个人感觉已经直逼甚至将超越号称国内顶级实力的 [青云](https://www.qingcloud.com/) 了。无论是个人，还是露珠的公司，都将阿里云视为不二的选择。这次阿里云突出大尺度的优惠活动，自然也是不能错过的，作为一个全功能平台，多样的产品让我们构建产品时有了更多的选择，而不是单单的一台 VPS 来解决所有问题。借这次优惠活动，露珠将自己的博客搬进了阿里云的 ACE，配合分布式数据库、分布式存储来搭建，也当做是为以后使用练手。

### 插件简介

本插件主要为 Wordpress 提供基于阿里云 OSS 的远程附件存储功能，并且最大限度的依赖 wordpress 本身功能扩展来实现，以保证插件停用或博客搬迁时可以快速切换会原来的方式。插件采用静默工作方式，设置启用后会直接替换原生存储，无需增加任何额外操作。当然，缺点就是无法同时使用 本地 和 OSS 两边的资源，<del>或许稍微改下可以实现</del>（想想都好麻烦 ╮(╯▽╰)╭）

### 插件特色

1.  支持阿里云 OSS 的图片服务（—>这个图片服务是个神器啊）  

2.  支持设定文件在 OSS 上的存储路径  

3.  全格式附件支持，不仅仅是图片  

4.  可以设定本地文件是否保留  

5.  不使用图片服务时，会连缩略图一起上传  

6.  可以自定义域名（已绑定bucket的）（—> 这也算特色？）  

7.  最后，也是最重要的特色，它的代码看上去很优雅，很干净

### 插件使用

1.  下载  
    [Aliyun-OSS-Support](https://github.com/IvanChou/aliyun-oss-support/archive/master.zip)  
    [Aliyun-OSS-Support for ACE](https://github.com/IvanChou/aliyun-oss-support/archive/Aliyun-ACE.zip) ACE专用  

2.  安装并启用  

3.  按提示设置  

4.  试一下能不能用(=<sup>‥</sup>=)

### 关于设置的一些说明

1.  `img_server_url` 有值时，即代表开启了 OSS 的图片服务支持，关于图片服务请看 [图片服务使用手册](http://help.aliyun.com/view/11108271_13510461.html?spm=5176.383663.9.11.ax1FI3)  
    你需要设置 `{'thumbnail','post-thumbnail','large','medium'}`四种样式  

    这是我的设置，建议这里的设置和 WordPress 后台的多媒体设置同步  

2.  图片服务开启时，只会上传原图到 OSS 上  

3.  OSS-Http-Url 留空的话，WordPress 会切换回使用本地资源的状态，但是 OSS 上传依旧会进行  

4.  Save path on OSS 不会影响本地存储路径，可是放心设置  

5.  *** 特别注意啊！！ 插件没有彻底的判错机制，也没有全方位的测试，看源码前，请不要有什么奇怪的想法，为了你好，阿门 ***

* * *

### Github

[https://github.com/IvanChou/aliyun-oss-support](https://github.com/IvanChou/aliyun-oss-support)

### 问题反馈

[https://github.com/IvanChou/aliyun-oss-support/issues](https://github.com/IvanChou/aliyun-oss-support/issues)  
左下角的邮箱也可以

* * *

### 更新日志

    ==== ver: 1.0 ====

Plugin URI: “[http://mawenjian.net/p/977.html](http://mawenjian.net/p/977.html)”  
Author: 马文建(Wenjian Ma)  
Author URI: [http://mawenjian.net/](http://mawenjian.net/)

    ==== ver: 1.1 ====

Author: Ivan Chou (ichou.cn)  
date: 2014-08-27

1.  升级 ali-OSS-SDK 到 1.1.6 版本  

2.  支持给 OSS 绑定的独立域名  

3.  支持自定 OSS 上文件存放目录 （不影响本地存储，中途若修改请手动移动 OSS 上文件，否则可能链接不到之前的资源）  

4.  修正原插件 bug 若干  

5.  优化代码 （移除所有 Notice 级报错）

Update URI: [http://ichou.cn/posts/ji-yu-a-li-yun-ossde-wordpressyuan-cheng-fu-jian-zhi-chi-cha-jian-a-li-yun-fu-jian-aliyun-support-xiu-ding-ban](http://ichou.cn/posts/ji-yu-a-li-yun-ossde-wordpressyuan-cheng-fu-jian-zhi-chi-cha-jian-a-li-yun-fu-jian-aliyun-support-xiu-ding-ban)

    ==== ver: 2.0 ====

Author: Ivan Chou (ichou.cn)  
date: 2014-09-01

1.  完全重构  

2.  支持 Aliyun OSS 的图片服务  

3.  改变钩子嵌入机制，支持所有附件（以前的版本只有图片，而且启用时其他附件完全不可用了，坑！！）  

4.  添加卸载、不残留

Update URI: [http://www.ichou.cn/posts/aliyun-oss-support-plugin-for-wordpress](http://www.ichou.cn/posts/aliyun-oss-support-plugin-for-wordpress)

    ==== ver: 2.1 ====

Author: Ivan Chou (ichou.cn)  
date: 2014-11-7

修正文件编码，解决某些环境下启用插件的 异常输出 报错。

若仍遇此报错，请尝试转换文件编码与您的网站环境编码一致。

感谢：网友 tang6818(at)foxmail.com 反馈
