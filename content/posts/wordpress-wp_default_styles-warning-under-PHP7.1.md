+++
comments = true
date = "2016-10-07T17:10:56+08:00"
title = "Wordpress 在 PHP7.1 下 wp_default_styles()报 Warning 的探究"

+++

## 遇到问题

如果你使用最新的发布的 PHP7.1 来跑 WordPress，会惊讶的发现页面上会报出几个 Warning 的错误

```plain
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
> 
> This is caused by the change to array_slice() as part of
> https://github.com/php/php-src/commit/e730c8fc90299789a7f551cb7142e182952d92e0#diff-497f073aa1ab88afcb8b248fc25d2a12R3014
> ..
> As a consequence of this change, an array_slice() on an array with rc=1 references will now not return these references in the result. (This is the correct behavior -- previously it instead dropped the references in the original array, which is not wrong either, but non-standard.)
> It looks like Wordpress is passing these arrays to call_user_func_array()
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

这个 commit 是鸟哥(laruence) 提的，目的是优化 `array_merge()`, 顺便也就修复了 `array_slice()` 这个方法中一个**不符合标准**的行为。

**当我们用 `array_slice()` 处理一个包含引用次数为 1 的引用元素的数组时，该元素在返回的结果中会以值(value)的形式存在，而不是引用(references)。**

## 复现与证实

调查到这里本来应该是『水落石出』了，但是，我 TM 英语差，一开始完全理解不到 Nikita 说的改动到底是什么，为了弄清楚这里面的详细，真是花去了我不少时间。

### 从哪儿报的错

先看测试代码：

```php
function test(&$t) {
    $t = $t + 1;
    return $t;
}

$a = 1;

test($a); 
// => 2

test(&$a);
// PHP Fatal error:  Call-time pass-by-reference has been removed in eval()'d

call_user_func('test', $a);
// PHP warning:  Parameter 1 to test() expected to be a reference, value given

call_user_func('test', &$a);
// PHP Fatal error:  Call-time pass-by-reference has been removed in eval()'d

call_user_func_array('test', [$a]);
// PHP warning:  Parameter 1 to test() expected to be a reference, value given

call_user_func_array('test', [&$a]);
// => 3

```

首先我们定义了一个 `test()` 方法，它将以引用的方式操作传入的参数。

1. 正常调用，因为是引用，执行完后，`$a` 的值变成 2.

2. 报错了，PHP 手册中[引用传递](http://php.net/manual/zh/language.references.pass.php#language.references.pass)一节解释了这个报错的原因。英文版手册中更是有明确提到这项改进是 5.3 加入的，5.4 开始会抛出一个 Fatal 错误。

3. 获得了一个目标报错，说明使用回调函数调用时，会检测参数是否为引用。

4. 同第2项报错，结合起来也说明了 `call_user_func()` 是无法使用引用元素作为回调参数的。

5. 同第3项，因为 WordPress 也是用的 `call_user_func_array()` 因此这组还原了报错来源。

6. 成功的调用，`$a` 的值被改写为 3.

这就证明了，WordPress 的这个报错确实是因为 `array_slice($args, 0, (int)
$the_['accepted_args']))` 所返回数组中的元素，不是引用，而是值。

更多关于回调函数与引用做参数的讨论：[Why does the error “expected to be a reference, value given” appear?](http://stackoverflow.com/questions/3637164/why-does-the-error-expected-to-be-a-reference-value-given-appear) 


### 验证 array_slice() 时遇到的坑

完成上面的验证之后，我打算进一步还原 WordPress 中的场景，向测试代码中加入了 `array_slice()`：

```php
function test(&$t) {
    $t = $t + 1;
    return $t;
}

$a = 1;
call_user_func_array('test', array_slice([&$a], 0, 1));
```

讲道理的话，这个会报错么？会？ NO！ 😰， `$a` 的值被成功改为 2，没有报错。

但是为什么呢？

### 查看引用计数 xdebug_debug_zval()

继续翻手册，在[引用计数基本知识](http://php.net/manual/zh/features.gc.refcounting-basics.php)中发现了可以查看变量引用计数的方法，Xdebug 的 `xdebug_debug_zval()` 方法。

顺便也看了 php 的 GC 机制，从描述看就是典型的 引用计数 方式，似乎还没有引入分代回收机制。

继续测试：

```php
$a = 1;
$b = [&$a];
xdebug_debug_zval('b');
//b:
//(refcount=1, is_ref=0)
//array (size=1)
//  0 => (refcount=2, is_ref=1)int 1

$_b = array_slice($b, 0, 1);
xdebug_debug_zval('_b');
//_b:
//(refcount=1, is_ref=0)
//array (size=1)
//  0 => (refcount=3, is_ref=1)int 1

class Test
{
	public function __construct() {
        $t = array(&$this);
        xdebug_debug_zval('t');
        
        $_t = array_slice($t, 0, 1);
        xdebug_debug_zval('_t');
	}
}
new Test()
//t:
//(refcount=1, is_ref=0)
//array (size=1)
//  0 => (refcount=1, is_ref=1)
//   object(Test)[1]
//_t:
//(refcount=1, is_ref=0)
//array (size=1)
//  0 => (refcount=4, is_ref=0)
//    object(Test)[1]

// refcount 指引用次数，is_ref 指是否是引用
```

通过常规赋值的方式，`$a`,`$b[0]` 会指向同一个内容对象，也就是说在我们完成这个赋值的时候，`$a` 所指向的内存对象已经被引用了两次，所以 refcount=2。这样也就不满足 Nikita 所说的 rc=1 的条件了，于是 `array_slice()` 返回的数组 `$_b` 中依旧是引用。

想要构造 refcount=1，is_ref=1 这个『苛刻』的条件，我目前知道也就在 class 的方法中用 `$this` 引用自身的时候会出现。当满足这个条件的 `$t` 经 `array_slice()` 处理后，返回的 `$_t` 中元素的引用次数虽然增加了，但是不在是引用了，is_ref=0。

后者的这个情况，也正是 WordPress 中所遇到的情况，可以说是在如此多低概率的巧合之下，才『终于』有了 WordPress 的这个报错。 😂

## 修复措施

知道原因之后，如果要修复这个问题就变得有点过于简单了。既然触发的条件是 rc=1, 那只需要在 `array_slice()` 之前随意用个变量把 `$args` 的元素多引用一次就可以解决了。当然也可以把`array_slice()` 处理之后的数组强行变回引用的方式。

最好的方法，还是在业务逻辑上就避免这种情况的发生。如果不是被逼不得已，否则千万不要让你的代码中出现太怪异的写法。

到 WordPress 核心维护小组的仓库中看了下下个版，也就是即将准备发布的 4.7，发现整个 `do_action_ref_array()` 方法都被重写了，根本不再使用 `array_slice()`，也就不会受这个问题的困扰了。

https://core.trac.wordpress.org/changeset/38571

## 总结和感悟

1. 有时候，找到一个合理的解释很容易，但是要真正的理解、复现并消化一个问题时，遇到的问题很可能会比你一开始想要解决的问题复杂得多。而且它们看上去并不是那么迫切的需要，追寻的过程中很容易放弃。
2. 能写代码证明的，不要靠猜
3. PHP 官方手册的中文版和英文版不是完全同步的，比如[引用做什么](http://php.net/manual/zh/language.references.whatdo.php)中的第二个 Note，英文版已经移除。还有一些具体的细节处，英文版都有明确指出改动的版本，中文版很多没有。
4. 鸟哥（Laruence）很强大
5. PHP 是世界上最好的语言

