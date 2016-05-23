+++
date = "2015-10-11T23:47:39+08:00"
title = "Rubymine 全屏下切换 Tab 会闪烁一下的 BUG 及解决方案"

+++

### Rubymine 8 已经解决这个问题

* * *
 
#### 系统环境

> **Mac:** MacBook Air & MacBook Pro  
> **Mac OS X:** EI Capitan  
> **App:** Rubymine 7.1.4 & PhpStorm  
> **Java:** Java6 for OS X 2015-001 via Apple  
> **问题描述：** 在全屏模式下，切换 Tab 会出现竖条状闪烁，目前发现都是在界面的中部，闪烁很快，影响不大；切换窗口时，会出现全屏闪烁，界面反白，闪烁明显，偶尔甚至卡顿

其实这个问题并不只有 Rubymine 有，也并非 EI Capitan 才开始出现。根据社区的反应，Jetbrains 家的所有 IDE：Intellij, Rubymine, Pycharm, PhpStorm, WebStorm 几乎全部都已经出现过类似问题，而且最迟从 Yosemite 10.10 起，切换 Tab 的闪烁就已经存在了。

#### 解决方案

各种查询，能找出的解决方案仅有一枚：

**使用 Java7 以上的版本**

1.  安装 Oracle 的 JDK  
    下载地址 -> [http://www.oracle.com/technetwork/java/javase/downloads/index-jsp-138363.html#javasejdk](http://www.oracle.com/technetwork/java/javase/downloads/index-jsp-138363.html#javasejdk)

2.  安装好 JDK 后，可以在终端中查看目前默认的 java 版本是否是刚刚安装的版本

    java -version
    javac -version

1.  修改 Rubymine 的 Info.plist  
    Info.plist 位于 Rubymine.app/Contents/Info.plist

    vi /Applications/RubyMine.app/Contents/Info.plist 

将其中

    <key>JVMVersion</key>
    <string>1.6*,1.7+</string> # 优先使用1.6 的版本，其次选择1.7 以后的最高版本

改为

    <key>JVMVersion</key>
    <string>1.6+</string> # 使用1.6 以后的最高版本

1.  修改完成  
    重启 Rubymine, 已经不会再有闪烁的情况了，其他的几个 IDE 同理。

#### 新的问题

苹果维护的 JDK 6 支持 OS X 的字体渲染方式，字体看上去会更饱和，更友好

而 Oracle 家的，只有在 Retina 屏上才能实现近似的效果，而在 non-Retina displays 上字体偏细，也不够圆滑，有点惨不忍睹。

对于此，目前并没有什么解决方案，能搜出来的大多都是老外的吐槽

可以参考的资料：[https://bulenkov.com/2013/09/12/font-rendering-apple-jdk-6-vs-oracle-jdk-1-7-0_40/](https://bulenkov.com/2013/09/12/font-rendering-apple-jdk-6-vs-oracle-jdk-1-7-0_40/)

#### 另外几个不得不提的点

1.  在 Mac OS X 10.11 EI Capitan 中，默认没有安装 Java6 及以上的版本，Java6 会在首次使用时让用户根据提示安装。一定要注意的重点来了：  
    **默认的安装路径已经改变了，不再是之前的 `/System/Library/Java/JavaVirtualMachines/` 而是 `/Library/Java/JavaVirtualMachines/`, 也就是说现在 apple 的 jdk 和 oracle 的 jdk 是装在同一个目录下的。**

2.  Mac 上是可以多个 Java 版本并存的，系统中是通过 /usr/libexec/java_home 来实现的，可以执行

    /usr/libexec/java_home -V

来查看目前可用的版本的相关信息。

**要注意的是：** 如 Jetbrains 的相关产品以及很多依赖于系统 jdk 的 app，都是通过这个里面所包含的版本来寻找它们想要的 jdk 的。理论上来说，它们对 jdk 的选择只决定于 Info.plist 中的配置，和JAVA_HOME 指向哪一个 jdk 是无关的。

详细可以参考： [http://www.liudonghua.com/?p=62](http://www.liudonghua.com/?p=62)

这是一篇十分有意思的文章，全是干货，解读得也很清晰。文中特别提到一种将系统 jdk 设为 java6 的方法：

    sudo mv /usr/libexec/java_home /usr/libexec/java_home_bak
    sudo vi /usr/libexec/java_home
    echo `/usr/libexec/java_home_bak -v 1.6*`
    sudo chmod a+x /usr/libexec/java_home

其实这是一种 hack 式的设定修改，相当于将原来调用的 java_home 方法都加上了一个 `-v 1.6*` 参数，从而达到了让系统以为只有 Java6 的效果。但实际上通过配置 JAVA_HOME， 我们可以在终端环境中方便的切换和使用其它版本的 jdk。

