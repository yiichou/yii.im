+++
date = "2014-08-28T22:40:24+08:00"
draft = false
title = "基于阿里云OSS的WordPress远程附件支持插件——阿里云附件(Aliyun Support)(修订版)"

+++

原插件地址：[http://mawenjian.net/p/977.html](http://mawenjian.net/p/977.html)

由于原插件作者没有持续更新，已经无法使用（或无法兼容最新版本环境），故对此进行一些小修正  
修正日期：2014-8-27  
版本号：1.1

#### 修订项目：

1.  插件年久失修，其内部调用的 Aliyun OSS php SDK 已升级  

2.  WordPress 3.5以后 设置->多媒体 中没有路径配置，导致配置不便  

3.  Aliyun OSS 可以绑定自己的域名，插件中不能简单的设置

#### 修订内容：

1.  升级 Aliyun-OSS-SDK 到 1.1.6 版本 (2014-06-25更新)  

2.  设置中可直接配置访问路径 Url，支持已绑定到 OSS 的独立域名  

3.  支持自定义 OSS 上文件的存放目录 （不影响本地存储，中途若修改请手动移动 OSS 上文件，否则可能链接不到之前的资源）  

4.  修正原插件 bug 若干

#### TODO:

原作者的代码在 github 上托管了一份，是不是应该联系原作者进行更新

#### 插件下载：

[OSS-Support.zip](https://github.com/IvanChou/aliyun-oss-support/archive/master.zip)

#### 源码

[https://github.com/IvanChou/aliyun-oss-support](https://github.com/IvanChou/aliyun-oss-support)

* * *

### Issues

1.  无法支持 Aliyun ACE 平台  
    <del>原因分析：ACE 本身的静态文件存储就是使用的 OSS（自带），静态文件可以上传到服务器，但是在执行存操作时会被移动到 OSS（自带） 中。此插件实现原理是：各个尺寸图片在服务器上生成好后，触发上传到 OSS（用户） ，再根据设定来决定是否删除服务器上的图片。在 ACE 上，生成的图片实际并不在指定的位置，故不会有文件上传到 OSS（用户）。</del>  
    原因是 ACE 已经在 PHP 环境中加入了 OSS 的 SDK，要使用这个 SDK 才可以，外部的 SDK 无法运行