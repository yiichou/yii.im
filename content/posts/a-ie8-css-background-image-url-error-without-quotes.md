+++
date = "2014-10-24T22:51:30+08:00"
title = "IE8 下 css background-image 图片路径不加引号导致的问题"

+++

今天在日志中看到一个很奇怪的报错，发现有一部分用户请求了一个错误的图片 url

    2014/10/24 13:23:35 [error] 29108#0: *38 open() "/var/www/xiaom_v2/public/assets/signup-bg.png),url("bgimg.png"" failed (2: No such file or directory), client: 118.119.93.192, server: www.ixiaomei.com, request: "GET /assets/signup-bg.png),url("bgimg.png" HTTP/1.1", host: "www.ixiaomei.com", referrer: "http://www.ixiaomei.com/about/"

    2014/10/24 13:26:03 [error] 29105#0: *67 open() "/var/www/xiaom_v2/public/assets/signup-bg.png),url("bgimg.png"" failed (2: No such file or directory), client: 182.141.26.27, server: www.ixiaomei.com, request: "GET /assets/signup-bg.png),url("bgimg.png" HTTP/1.1", host: "www.ixiaomei.com", referrer: "http://www.ixiaomei.com/"

居然请求了 `/assets/signup-bg.png),url("bgimg.png"` 这样的地址，看得我也是醉了。不过也是很明显的可以看出问题出在 css 的多背景图片引用上。

到访客统计里面一看，过不其然，这两个都是 IE6。再查看其他记录，发现 IE8 及 IE8 以下的浏览器（下文称 IE8-）都有这个问题。

因为网站上多处使用了多背景叠加，却只有这一处请求是错误的，我就意识到这又是一个 IE8- 支持上的坑，查看 css 看到这行是这样写的：

    background-image: url(signup-bg.png), url("bgimg.png");

居然前面一张图片没加引号，其他浏览器可以识别出来，但是 IE8- 直接把第一个括号和最后一个括号中间的所有内容识别成了图片的 URL。加上引号的，就没有出现这个错误。

    background-image: url("signup-bg.png"), url("bgimg.png");

在 css 的书写规范里，并没有强调被引用的 url 是否应该加上引号。包括官方文档中 background-image 的例子里也有不加引号的（总的来说大部分都加了引号）。这说明，在浏览器的规范中，这两种写法应该是等价的。

**IE8- 之所会有这个问题**，我猜测和 IE8- 原本就不支持多张背景图有关，在它的设计里面，background-image 本来就只应该有一个 url，所以如果没有引号来告诉它那一部分是 url 地址的话，它就只能依靠其他的标识来判断，比如 `(.*);` 这样的匹配。当然，这里只是举个例子，实际的处理有可能比这个更复杂，由于手边没有可用的 IE8 我也没有办法做详尽的测试。

说到底，其实有点矫情，因为使用多背竟图的时候已经就等于放弃了 IE8-,现在又来研究 IE8 的 css 特性，究其原因也不是为了兼容，只是不想在看到上面那个 魂淡 的报错而已。因此这问题的实际意义好像几乎没有，如果强行说有的话就是：在使用css多背竟图的时候，url 加引号可以确保在 IE8 下，你的第一张背景图可以显示出来。

<del>不过呢，反过来考虑，在高级浏览器里面，加引号与否是否会有性能的差异？</del>

