+++
comments = true
date = "2016-11-07T02:22:25+08:00"
title = "如何正确的为 Laravel 配置 Nginx 和 php-fpm"
toc = true
+++

如何配置 nginx + php-fpm 使 Laravel 工作应该是每一个 Laravel 使用者的必备技能，其实也就几行配置。

```
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

如果只是让 Laravel 工作起来，上面的方式已经足够了。

如果你并不满足于仅仅能用这种层面，那你应该会问：它是怎么运作的？会不会有问题？有没有更好的方式？

## 工作原理

在上面链接的原文中，有详细介绍这个配置的编写过程，在此我从另一个角度再梳理一下这个配置：

### Step 1

通过 `try_files` 来判断是否请求的是静态资源，不是的话将请求转发到 `/index.php` 下，并带上 `query_string`

### Step 2

请求被转发到 `/index.php` 后，就满足了 `location ~ \.php$` 的条件，开始执行这下面的配置

1. `try_files $uri /index.php =404;` 

    再一次 `try_files`, 其意义在于被请求的 php 文件不存在时，将请求转发到 `/index.php`

    由于 Laravel 只有 `index.php`，所以这句其实没有意义的。
    
2. `fastcgi_split_path_info ^(.+\.php)(/.+)$;`
    
    > fastcgi_split_path_info 
    > Defines a regular expression that captures a value for the `$fastcgi_path_info` variable. The regular expression should have two captures: the first becomes a value of the `$fastcgi_script_name` variable, the second becomes a value of the `$fastcgi_path_info` variable.
    
    详细参阅：[官网文档](http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info)
    
    它的作用是把形如 `/index.php/arg1/arg2` 这样的 path 拆成两个参数 `$fastcgi_script_name` : `/index.php` 和 `$fastcgi_path_info` : `/arg1/arg2`。
    
    由于在 Step 1 中，我们直接转到了没有 path 部分的 `/index.php`，所以这一条配置也是没有意义的。
    
3. `fastcgi_pass unix:/var/run/php7.0-fpm.sock;`

    没什么需要说的
    
4. `fastcgi_index index.php;`

    当 URI 以 `/` 结束的时候，使用 `index.php` 作为默认执行脚本。
    
    然而以 `/` 结束的请求根本就不会进入这个 location 里，所以这句也是废话。
    
5. `fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;`

    这个需要和最后一句 `include fastcgi_params;` 连在一起说，因为 `fastcgi_params` 中缺了 `SCRIPT_FILENAME` 这项配置，所以需要补充这句。事实上，在 nginx 自带的 `fastcgi.conf` 已经包含了这一项，所以可以直接使用 `include  fastcgi.conf;` 来替代这两句。
    
    如果在 `include  fastcgi.conf;` 的时候还用了这一句，虽然完全不会影响程序工作，但是也暴露了你对你每天都在使用的工具还不够了解。
    
### Step 3

请求被转发到 php-fpm 上，php-fpm 根据传入的参数找到 Laravel 的 `index.php`, 执行`index.php` 并将收到的参数传递过去。

### 小结 
    
综上所述，你会发现这短短几行配置竟有一半都是无意义的。 第 1 条其实是给多入口文件的 php 项目使用的；第 2 条是很多其他框架都会用到的一种路由规则；第 4 条则是因为用错了地方所以永远不会执行。

这份 nginx 转发 fpm 的规则更像是 php 框架的通用方案，它可以为 Laravel 工作，但还不够优雅。
    
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

### 不足之处

简化之后的配置清爽了很多，但是这份配置依旧存在不足：

经过这样的转发，所有到达 php-fpm 的请求，`request URI` 全都是 `/index.php`，当你需要去追踪 fpm 日志时，整个人都是崩溃的。

当然还有更惨的，这个问题同样还严重影响 oneapm 一类的 AI 服务的使用效果，你会发现所有的请求都打到了 `/index.php` 下面，原本直观的错误信息定位、慢事务分析，如今都要靠自己一点一点的去看才能找到有问题的到底是哪一个路由。

导致这个问题的关键是我们通过 `try_files` 把所有 Laravel 的请求转到了 `/index.php?$query_string` 上，后续的处理无法取得原始的路由信息。虽然 Laravel 本身可以通过正确传递的 `REQUEST_URI` 获取请求的真实路由，但是 php-fpm 并不使用这个参数，于是就出现了上述问题。

### SCRIPT_FILENAME 与 SCRIPT_NAME

本文不讨论 CGI、FastCGi、php-fpm 之间的关联与区别，想要详细了解 CGI 请参阅：[rfc3875](http://www.faqs.org/rfcs/rfc3875.html)

通过各种尝试之后，我逐步将问题定位到 SCRIPT_FILENAME 与 SCRIPT_NAME 这两个参数上：

**SCRIPT_FILENAME**

> The absolute pathname of the currently executing script.


**SCRIPT_NAME**

> Contains the current script's path. This is useful for pages which need to point to themselves. The __FILE__ constant contains the full path and filename of the current (i.e. included) file.

`SCRIPT_FILENAME` 为当前执行脚本的绝对路径，`SCRIPT_NAME` 用于存储当前脚本的 path，用于脚本获取自己的位置。

php-fpm 通过 `SCRIPT_FILENAME` 来找到真真需要执行的文件，通过 `SCRIPT_NAME` 来标记当前的 path 信息，包括写日志用的 `%r: the request URI` 参数。因此只要将 `SCRIPT_FILENAME` 指向 Laravel 的入口文件 '/index.php', 而 `SCRIPT_NAME` 依旧传入之前的 URL path 便可以达到想要的结果。

## 最终配置

```
    location / {
        try_files $uri $uri/ @laravel;
    }

    location @laravel {
      include  fastcgi_params;
      fastcgi_pass unix:/var/run/php7.0-fpm.sock;
      fastcgi_param  SCRIPT_FILENAME  $document_root/index.php;
    }
```

这份配置是以我目前的能力能写出的最适合 Laravel 的 nginx 配置，不过它绝非最好的配置。

首先，它不支持访问 `index.php` 以为的 php 文件。既然使用了 laravel，遵循习惯优于配置的思想，这个应用中就不应该再出现其他可直接访问的 php 文件，于是去掉了对 php 的广泛支持。

其次，保持 `SCRIPT_NAME` 为原始状态，而不是真正被执行的 `index.php`， 从规范上讲是有一点违背设计思想的，如果有人用 `$_SERVER['SCRIPT_NAME']` 来当前执行文件就会取到一个错误的值。好在在 Laravel 中，并不会有人这么干，对于所有单入口应用而言，这样的取值都不会符合预期。


## 小感

我经常会觉得，拿来主义是多年前的伸手党风气的延续。终有一天，拿来主义会被证明和伸手党一样是不可取的，一味的拿来主义背离了学习的初衷，看似了解的背后是与知识的真相越走越远。有时候，还是动下脑子比较好。

* * *

参考文章：

- http://homeway.me/2015/05/22/nginx-rewrite-conf/
- http://huoding.com/2013/10/23/290
- https://www.digitalocean.com/community/tutorials/how-to-install-laravel-with-an-nginx-web-server-on-ubuntu-14-04



