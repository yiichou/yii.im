+++
date = "2016-07-30T19:33:03+08:00"
title = "造了一个快速切换系统代理的 Alfred workflow -- Trace ON!"

+++

在 Mac 上切换代理是一件挺麻烦的事情，然而不幸的是一旦你有了这个需求往往也意味着你需要频繁进行这个操作 

比如我， 
公司公用的扶墙是 Shadowsocks + PAC 
离开公司，就要自己开个 SS 了 
公司用的是香港 CN2 线路的服务器，自己的是个 Do 的小水管，所以虽然麻烦还是要来回切换 
另外，抓包用的 Cellist 设置代理的时候也有点问题，基本都需要手动去设置 

在网上找了一下 Alfred 的插件，发现一个 Pac-helper。用倒是可以用，不过略微有点简陋，于是就自己抽时间造了一个，效率提升杠杠的 

项目地址： 
https://github.com/yiichou/Trace.alfredworkflow 

### Quickly start

1. Download
    
    https://github.com/yiichou/Trace.alfredworkflow/raw/master/Trace%20(Proxy-helper).alfredworkflow
    
2. Setting
    
    - Doubule click `trace` in Alfred Workflows Preferences
    - Click `Open workflow folder` to open Finder
    - Open `proxy.conf` and modify it like sample

3. Use
    
    Call out your alfred, and type `trace`
    
    ![](http://ww4.sinaimg.cn/mw690/006pIUL1gw1f69r4xsjf0j30g10790tq.jpg)
    
4. Enjoy it!

### More feature

When you change your proxy setting via Trace, OSX may ask your password to allow this operation everytime. 

To slove this question, you can do something more:

1. add the following line to `/etc/sudoers/`
    
    ```
    yourusername ALL=NOPASSWD: /usr/sbin/networksetup 
    # e.g.
    IChou ALL=NOPASSWD: /usr/sbin/networksetup
    ```
    > Remeber the file `/etc/sudoers/` must be end with a empty line!!
    
2. re-link the scripts of trace
    
    ![](http://ww4.sinaimg.cn/large/006pIUL1gw1f6c4lm9l0qj30kh07o75b.jpg)

### About Trace

It's inspired by Fate.  "Trace on!"

