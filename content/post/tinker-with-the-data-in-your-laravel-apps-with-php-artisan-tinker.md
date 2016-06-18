+++
date = "2016-06-18T10:39:15+08:00"
draft = false
title = "使用 Php Artisan Tinker 来调试你的 Laravel"

+++

![0](http://ooo.0o0.ooo/2016/06/17/5764c10a130e3.png)

> 本文翻译自：[Tinker with the Data in Your Laravel Apps with Php Artisan Tinker
](https://scotch.io/tutorials/tinker-with-the-data-in-your-laravel-apps-with-php-artisan-tinker)


# 使用 Php Artisan Tinker 来调试你的 Laravel

今天，我们将通过介绍 Laravel 中一个不太为人所知的功能，来展示如何快捷的调试数据库中的数据。通过使用 Laravel artisan 内建的 `php artisan tinker`, 我们可以很方便的看到数据库中的数据并且执行各种想要的操作。

Laravel artisan 的 tinker 是一个 [REPL (read-eval-print-loop)](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop). REPL 是指 交互式命令行界面，它可以让你输入一段代码去执行，并把执行结果直接打印到命令行界面里。

### 如何简便快捷的查阅数据库数据？

我想最好的方式应该是输入下面这些熟悉的命令，然后立马能看到结果：

```php
// see the count of all users
App\User::count();

// find a specific user and see their attributes
App\User::where('username', 'samuel')->first();

// find the relationships of a user
$user = App\User::with('posts')->first();
$user->posts;
```

使用 `php artisan tinker`, 其实我们可以轻易的做到这点。 Tinker 是 Laravel 自带的 REPL，基于 [PsySH](http://psysh.org/) 构建而来。它帮助我们更轻松的和我们的应用交流，而无需再不停地使用 `dd()` 和 `die()` 。那种为了调试一段代码，通篇都是 `print_r()` 和 `dd()` 的痛苦，我想我们大部分人都能感同身受。

在我们使用 tinker 之前，我们先来创建一个测试项目，暂且就叫它 ScotchTest 吧。如果你的电脑上已经安装好 [laravel installer](https://laravel.com/docs/5.2#installation)，那么先执行：

```bash
laravel new ScotchTest
```

没有安装 Laravel installer 的电脑，可以通过 `composer` 来创建这个项目

```bash
composer create-project laravel/laravel ScotchTest --prefer-dist
```

* * *

## 初始化数据库: Running Migrations

创建完我们的测试项目（ScotchTest）后，我们还需要新建一个测试数据库并且执行数据库迁移（migrations）来初始化数据库。在本文的讲解中，我们直接使用 Laravel 默认的迁移就够了。首先在 `.env` 文件中配置好数据库连接信息，然后准备执行迁移，默认的迁移会帮我们生成一个 `users` 表和一个 `password_resets` 表。

```bash
php artisan migrate
```

当迁移完成的时候，我们应该可以看到类似这样的信息：

![1](http://ooo.0o0.ooo/2016/06/17/5764c060965c2.png)

* * *

## 填充我们的数据库

通常情况下，我们可以使用 Laravel 的模型工厂([model factory](https://scotch.io/tutorials/generate-dummy-laravel-data-with-model-factories))来快速填充我们的数据库，它可以帮我向数据库插入伪数据方便我们测试。现在让我们开始使用 tinker 吧。

```bash
php artisan tinker
```

这条命令会打开一个 REPL 窗口供我们使用。刚才我们已经执行过 migration, 现在我们可以直接在 REPL 中使用模型工厂来填充数据。

```php
factory(App\User::class, 10)->create();
```

这个时候，一个包含了 10 条新用户记录的集合将在你的终端上打印出来。现在我们可以检查一下这些记录是否真的已经被创建了。

```php
App\User::all();
```

使用 `count` 方法，还可以查看 `User` 模型在数据库中一共有多少个 user 。

```php
App\User::count();
```

在执行完 `App\User::all()` 和 `App\User::count()` 之后，我的输出是这个样子的，你们的输出应该和我差不多，仅仅是生成的内容不同。

![2](http://ooo.0o0.ooo/2016/06/17/5764c029829cf.png)

* * *

## 创建一个新用户

通过 REPL，我们还可以创建一个新用户。你应该已经注意到，我们在 REPL 使用的命令跟我们在 laravel 中所写的代码是一样的。所以创建一个新用户的代码：

```php
$user = new App\User;
$user->name = "Wruce Bayne";
$user->email = "iambatman@savegotham.com";
$user->save();
```

现在输入 `$user`，可以看到

![3](http://ooo.0o0.ooo/2016/06/17/5764c0297a57b.png)

* * *

## 删除一个用户

要删除 id 为 1 的用户：

```php
$user = App\User::find(1);
$user->delete();
```

* * *

## 查阅某个 类/方法 的注释文档

通过 tinker，你可以在 REPL 中查看某个 类/方法 的注释文档。但是文档内容取决于这个 类/方法 是否有一个文档注释块（`DocBlocks`）。

```bash
doc <functionName> # replace <functionName> with function name or class FQN
```

比如，查阅 `dd` 的注释文档

![4](http://ooo.0o0.ooo/2016/06/17/5764c02967b6f.png)

* * *

## 查看源码

我们还可以直接在 REPL 中打印出某个 类/方法 的源代码

```bash
show <functionName>
```

比如，查看 `dd` 的源码

![5](http://ooo.0o0.ooo/2016/06/17/5764c0296fa77.png)

* * *

## 总结

Laravel Tinker 是一款让我们可以更方便调试 laravel 的工具，有了它，没有必要再为了一个简单的调试而开启本地服务（server）。特别是当你想要测试一小段代码的时候，你无需再插入各种 `var_dump` 和 `die`，然后还要在调试完后删掉它们，你只需要 `php artisan tinker` 就够了。


