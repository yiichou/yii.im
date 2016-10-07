+++
comments = true
date = "2016-10-07T17:10:56+08:00"
title = "Wordpress 在 PHP7.1 下 wp_default_styles()报 Warning 的探究"

+++

## 遇到问题

如果你使用最新的发布的 PHP7.1 来跑 WordPress，会惊讶的发现页面上会报出几个 Warning 的错误

```
Warning: Parameter 1 to wp_default_styles() expected to be a reference, value given in /Users/Home/Sites/WordPress-4.6/wp-includes/plugin.php on line 600

Warning: Parameter 1 to wp_default_scripts() expected to be a reference, value given in /Users/Home/Sites/WordPress-4.6/wp-includes/plugin.php on line 600
```

也许你会觉得这可能是某个主题或者插件导致，或者是某个版本的 WordPress 有问题，然而不幸的是，这是一个 WordPress 与 PHP7.1 间的兼容问题，几乎所有版本的 WordPress 都会中招。

## 探查原因

在 WordPress 的官网 support 里面有人提过这个 BUG，但是并没有获得有效的回应，只是提醒大家 PHP7.1 目前还不是稳定版本 😂😂

最后，我倒是在 php 的官方组邮件中找到了相关信息：

邮件地址：http://php-news.ctrl-f5.net/message/php.internals/94856

主要解答：

> Thanks for pointing this out.
This is caused by the change to array_slice() as part of
https://github.com/php/php-src/commit/e730c8fc90299789a7f551cb7142e182952d92e0#diff-497f073aa1ab88afcb8b248fc25d2a12R3014
..
As a consequence of this change, an array_slice() on an array with rc=1
references will now not return these references in the result. (This is the
correct behavior -- previously it instead dropped the references in the
original array, which is not wrong either, but non-standard.)
It looks like Wordpress is passing these arrays to call_user_func_array()
with a function that expects a reference argument:

```php
call_user_func_array($the_['function'], array_slice($args, 0, (int)
$the_['accepted_args']));
```
> And this results in:

```bash
nikic@saturn:~/php-src-fast$ sapi/cgi/php-cgi -c php.ini -T1
.../wordpress-4.1/index.php | grep Warning
Warning:  Parameter 1 to wp_default_styles() expected to be a
reference, value given in
/home/nikic/wordpress-4.1/wp-includes/plugin.php on line
571
Warning:  Parameter 1 to wp_default_scripts() expected to be a
reference, value given in
/home/nikic/wordpress-4.1/wp-includes/plugin.php on line
571
```

> So essentially, we're winning 5% because these two calls do not occur...

这个 commit 是鸟哥(laruence) 提的，目的是优化 `array_merge()`, 顺便也就修复了 `array_slice()` 这个方法中**某些**不标准的行为。

## 尝试复现

调查到这里本来应该是『水落石出』了，但是，我 TM 英语差，理解不到 Nikita 说的改动到底是什么啊！！

> an array with rc=1 references

这里的 rc=1 到底是什么意思呢？

我试着在 php5.6 和 php7.1 里去复现 `array_slice()` 的这个变动导致的具体差异到底是什么，结果我崩溃了 —— 我完全没发现他们的返回有任何差异。

在两个 php 版本下调试 WordPress 也没发现 `array_slice()` 返回的内容有什么不同，然而 7.1 这个返回的 array 传入 `wp_default_styles()` 就是报错。

## 继续追查

自己不能验证，那就去看看 WordPress 官方会怎么修复这个 bug 吧，突然觉得自己机智了一把。屁颠屁颠的去找 WordPress 的官方开发组仓库，看看即将准备 release 的 4.7 版本会怎么解决这个问题：

https://core.trac.wordpress.org/changeset/38571

然后，我泪奔了😭。

整个 `do_action_ref_array()` 方法都被重写了，根本不再使用 `array_slice()`。

## 那么问题来了：

1. **这个修改，到底给 `array_slice()` 带来了什么变化？**

2. **WordPress 的这个问题真的是 `array_slice()` 引起的吗？**

求解答！

（不是我不去看鸟哥提的源码，真的是 C 基础不好，然后这个 array.c 的内容确实太多，吃不下来）


