+++
comments = true
date = "2016-11-07T02:22:25+08:00"
title = "请给你的 Laravel 一份更好的 Nginx 配置"
toc = true
+++

Laravel 是当今最流行的 PHP 框架之一，如所有 PHP 项目一样，通常情况下它都需要运行在 LAMP 或 LNMP 的环境之下。如何配置 LNMP 使之为 Laravel 工作可以说是每一个 Laravist 的必修技能。

本文将就 LNMP 环境下适用于 Laravel 的 Nginx 配置进行一次比较详细的探究，通过本文你可以更清晰的认识这份你每天都在使用的配置，理解其中的原理，知晓某些配置的好与不好。在文章的后半段，还会为你推荐一种更为安全，更加适合 Laravel 的配置方案。

## 广为流传的配置

```
root  /path/to/your/laravel/public;
index  index.php index.html index.htm;

location / {
    try_files $uri $uri/ /index.php?$query_string;
}

location ~ \.php$ {
    try_files $uri /index.php =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass unix:/var/run/php7.0-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

>  这段代码引用自：[How to Install Laravel with an Nginx Web Server on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-install-laravel-with-an-nginx-web-server-on-ubuntu-14-04)

在大部分的中文教程里面，你都可以看到这份配置，国人对知识的『薪火相传』由此可见一斑。我们在此应先感谢社区前人的辛勤搬运，然后，让我们来详细解读这份配置吧。

## 配置解读

在上面贴出的链接原文中，作者比较详细的解释了这份配置是如何一步一步写出来的，顺着作者的思路很容易理解。但是呢，我并不打算顺着作者的思路来，我会一条一条的来解读这些配置，看看能不能读出一点不一样的东西。

### Step 1

```
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

通过 `try_files` 来判断是否请求的是静态资源，不是的话将请求转发到 `/index.php` 下，并带上 `query_string`

### Step 2

请求被转发到 `/index.php` 后，进入 `~ \.php$` 的配置

```
location ~ \.php$ { 
    ... 
}
``` 

#### Step 2.1

```
try_files $uri /index.php =404;
``` 

再一次 `try_files`, 当被请求的 php 文件不存在时，将请求转发到 `/index.php`
    
Laravel 是一个单入口框架，标准的实现中，我们不会允许用户直接访问其他的 php 文件，所以我们不需要也没有理由对不存在的 php 文件访问做兼容处理，因此这句配置是不应该有的。

#### Step 2.2
    
```
fastcgi_split_path_info ^(.+\.php)(/.+)$;
```
    
> fastcgi_split_path_info 

> Defines a regular expression that captures a value for the `$fastcgi_path_info` variable. The regular expression should have two captures: the first becomes a value of the `$fastcgi_script_name` variable, the second becomes a value of the `$fastcgi_path_info` variable.
    
详细参阅：[官网文档](http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info)
    
它的作用是把形如 `/index.php/arg1/arg2` 这样的 `$fastcgi_script_name` 拆成两个参数

- $fastcgi_script_name : /index.php
- $fastcgi_path_info : /arg1/arg2
    
由于在 Step 1 中，我们直接转到了没有 path_info 的 `/index.php`，所以这条配置并没有意义。
   
#### Step 2.3
 
```
fastcgi_pass unix:/var/run/php7.0-fpm.sock;
```

没什么需要说的
 
#### Step 2.4
   
```
fastcgi_index index.php;
```

当 URI 以 `/` 结束的时候，使用 `index.php` 作为默认执行脚本。
    
然而以 `/` 结束的请求根本就不会进入这个 location 里，所以这句也是废话。
    
#### Step 2.5

```
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
```

这两句等同于

```
include  fastcgi.conf;
```

所以使用下面这句就好了
    
### Step 3

请求被转发到 php-fpm 上，php-fpm 根据传入的参数处理请求。

### 小结 

其实这一份配置应该是一份较通用的 LNMP 配置，不只是 Laravel，它同样可以应对大部分的 PHP 框架和系统，堪称『以不变应万变』的典范。

当然，当我们只是针对 Laravel 来配置的时候，这份配置就显得有些臃肿了，并且过多的兼容处理也增加了潜在的不安全因素。比如在开启 `cgi.fix_pathinfo` 的情况下，你的服务就会被置于脚本小子的攻击范围之中。
    
## 配置简化

```
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php7.0-fpm.sock;
        include  fastcgi.conf;
    }
```

## 新问题：让人崩溃的 PHP-FPM 日志和 Ai 服务支持

简化之后的配置清爽了很多，各项功能正常，这样是否就完美了呢？

如果你不需要 PHP-FPM 日志，也没有使用 Ai （应用探针）服务，这样子应该就可以了。如果有，你应该就会遇到下面的问题：

```
127.0.0.1 -  10/Nov/2016:13:19:52 +0800 "GET /index.php" 304 /current/public/index.php 391.240 2048 2.56%
127.0.0.1 -  10/Nov/2016:13:22:15 +0800 "POST /index.php" 200 /current/public/index.php 333.085 2048 9.01%
127.0.0.1 -  10/Nov/2016:13:22:16 +0800 "POST /index.php" 200 /current/public/index.php 313.295 2048 3.19%
127.0.0.1 -  10/Nov/2016:14:01:48 +0800 "GET /index.php" 200 /current/public/index.php 9.712 2048 102.97%
```

所有的请求，无论请求的路由是什么，日志里面记录的都是 `/index.php`。

如果使用了类似 OneAPM 的插入到 php 环境中的 Ai 服务，侦听到的请求数据也会有同样的问题。当你去看 Ai 生成的数据报表或者错误信息时，根本没有办法区分路由，也不能快速的定位问题所在。

导致这个问题的原因是我们通过 `try_files` 把所有 Laravel 的请求转到了 `/index.php?$query_string` 上，后续的处理无法取得原始的路由信息。虽然 Laravel 本身可以通过正确传递的 `REQUEST_URI` 获取请求的真实路由，但是 php-fpm 并不使用这个参数，于是就出现了上述问题。

### SCRIPT_FILENAME 与 SCRIPT_NAME

通过各种尝试之后，我逐步将问题定位到 SCRIPT_FILENAME 与 SCRIPT_NAME 这两个参数上：

**SCRIPT_FILENAME**

> The absolute pathname of the currently executing script.


**SCRIPT_NAME**

> Contains the current script's path. This is useful for pages which need to point to themselves. The __FILE__ constant contains the full path and filename of the current (i.e. included) file.

PHP-FPM 通过 `SCRIPT_FILENAME` 来找到真正需要执行的文件，`SCRIPT_NAME` 只用来标记当前脚本的 path 信息， PHP-FPM （日志）中的 `%r: the request URI` 参数其实就是 `SCRIPT_NAME` 的值。

因此只要将 `SCRIPT_FILENAME` 指向 Laravel 的入口文件 '/index.php', 而 `SCRIPT_NAME` 保持请求原本的 URI path 便可以达到想要的结果。

想要详细了解 CGI 请参阅：[rfc3875](http://www.faqs.org/rfcs/rfc3875.html)

### 最终配置

```
root   /path/to/your/laravel/public;

location / {
    include  fastcgi_params;
    fastcgi_pass unix:/var/run/php7.0-fpm.sock;
    fastcgi_param  SCRIPT_FILENAME  $document_root/index.php;
}

location ~* \.(ico|css|js|gif|jpe?g|png)(\?.*)?$ {
    # something you want
}

```

这份配置的特点在于把 Laravel 当成一个独立的纯粹的单入口应用来处理，而不是考虑各种 php 环境的通性。它直接将所有非静态资源的请求直接转发到驱动 Laravel 的 PHP-FPM 中，而静态资源使用下面的一条规则，直接取得文件（具体原理见参考文章第一篇）。

### 继续优化的方向

到目前为止，本文的讨论的内容只涉及到了 Nginx 的配置，其实在这个环境体系中还有一个关键的环节 —— PHP-FPM。通常（至少我接触到的）来说，人们只会在一个环境上配置一个 PHP-FPM, 然后所有的项目都使用这个 fpm 提供的服务，PHP-FPM 本身也被设计成可以接受这样的方式。

但是这种把 fpm 当成黑盒的使用方式其实是并不可取的，关于这一点 [A better way to run PHP-FPM](https://ma.ttias.be/a-better-way-to-run-php-fpm/) 中有非常详细的说明。至少在生产环境中，对不同项目的做 fpm 隔离是十分必要的。

如果系统部署基于一个项目一个 fpm 服务的方式，那么还可以通过设置 fpm 的 chroot 获得更好的安全隔离效果。

## 总结

其实这份『最终配置』并不是我自己拍脑袋想出来的，在 Rails、Django 等其他语言框架中，Nginx 大都是这类似的配置方式。现如今无论是何种语言，其流行的框架几乎都已经采用了单一入口模式，这一模式在代码复用和项目可维护性上的优势，古老的多入口模式远不能望其项背。

一个真正的『独立的纯粹的单入口应用』，对于其前方的 Nginx 来说应该是一个黑盒子，他们之间只能通过唯一的入口通道来进行数据交换，而不是让 Nginx 来决定访问系统的哪一个部分。Laravel 就是这样的一匹单入口应用的骏马，你为什么不给它配一个好一点的鞍呢？

虽然现今的 php 框架早已经实现了单入口，但是在 php 环境搭建这个环节上，广为流传的还是各种通用的配置。将就用，俨然已是现今 phper 们的普遍追求，只是偶尔感慨起来，还是会觉得有些许无奈。

* * *

参考文章：

- http://homeway.me/2015/05/22/nginx-rewrite-conf/
- http://huoding.com/2013/10/23/290
- https://www.digitalocean.com/community/tutorials/how-to-install-laravel-with-an-nginx-web-server-on-ubuntu-14-04
- https://ma.ttias.be/a-better-way-to-run-php-fpm



