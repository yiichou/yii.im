+++
title = "在 ruby 中简单实现链式调用的方法"
comments = false
date = "2017-05-07T16:44:25+08:00"
toc = false
+++

最近项目组有一个关于人脸识别相关的需求，需要用到 FacePP 的服务，而官方提供的 Ruby SDK 自 2013 年提交以来，从未更新过，Issue 和 PR 也无人处理。So, 我被安排去『重新』实现 FacePP 的 SDK。

官方 SDK 地址: https://github.com/FacePlusPlus/facepp-ruby-sdk

本以为这是个苦差事，难鹅，当我拉下官方的 SDK 源码时，却被华丽丽的惊艳到了 w(°ｏ°)w

通常来说我们写 SDK 的常规思路：

1. 实现一个通用的请求处理，包括 url 拼装，参数处理，签名等
2. 根据各个接口去实现一个方法（method）

而这个 SDK 的实现，直接使用了 Ruby 里的大杀器 —— **元编程**， 进而毫不费力的实现了链式调用

## 链式调用

关于链式调用相信大家都不陌生，最常见的就是 ActiveRecord 的查询方法

```ruby
Article.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

个人认为，链式调用最大的优点就是优雅，相比起把所有参数放在一个 options(hash) 里喂给一个方法的调用方式，链式调用的可读性明显更好，参数组合也更自由。

FacePP 的 SDK 里面实现的链式调用

```ruby
api = FacePP.new 'YOUR_API_KEY', 'YOUR_API_SECRET'
puts api.detection.detect url: '/tmp/0.jpg'
```

## 实现原理

链式调用的实现原理其实很好理解，每当你调用一个链式对象的某个方法时，返回一个该对象所属类的新实例即可

比如在 ActiveRecord 中，当你调用 Model `Article` 的 `where` 方法时，它返回了一个 `ActiveRecord::Relation` 实例，假定它叫 `relation_1`。`.limit(20)` 其实调用的是`relation_1` 的 `limit` 方法，然后返回一个新的 `ActiveRecord::Relation` 实例 `relation_2`，以此类推。

所以当你只是调用 `ActiveRecord::Relation` 的各种查询方法时，并没有真的触发查询，而是不停的返回新的 `ActiveRecord::Relation` 实例，直到遇到第一个需要取值的调用，才会触发查询，并返回数据。

以上只是简单的描述，实际上 `ActiveRecord::Relation` 的实现还挺复杂的，有兴趣可以去看看源码：

https://github.com/rails/rails/blob/5-1-stable/activerecord/lib/active_record/relation.rb

相比起数据库查询的复杂性，http api 的复杂度就算很低了，因此在http 接口上实现链式调用，其实可以很容易。

## 简单实现

这个部分我就直接贴 FacePP SDK 的源码了：

```ruby
# https://github.com/FacePlusPlus/facepp-ruby-sdk/blob/master/lib/facepp/client.rb
# 代码略有删减

class FacePP
  APIS = [
      '/detection/detect',
      '/info/get_image',
      # ...
    ]

  def initialize(key, secret, options={})
    APIS.each do |api|
      m = self
      breadcrumbs = api.split('/')[1..-1]
      breadcrumbs[0..-2].each do |breadcrumb|
        unless m.instance_variable_defined? "@#{breadcrumb}"
          m.instance_variable_set "@#{breadcrumb}", Object.new
          m.singleton_class.class_eval do
            attr_reader breadcrumb
          end
        end
        m = m.instance_variable_get "@#{breadcrumb}"
      end

      m.define_singleton_method breadcrumbs[-1] do |*args|
        # send a request to #{api} with #{args}
      end
    end
  end
end
```

1. 先预置了一个 api path 的列表，相当于一个路由表。
2. 当 FacePP 被 new 的时候，会逐条解析这个路由表，把每条路由以 `/` 作分割符解析为数组。
3. 遍历数组至倒数第二个元素，把每个元素变成上层对象的一个同名实例变量，其值是一个新的 `Object` 实例，并通过 `attr_reader` 为该实例变量添加访问方法
4. 将数组的最后一个元素变成上层对象的一个 `singleton_method`, 里面包含了真正的请求代码。

其成果就是，我们可以以

```ruby
api.detection.detect url: '/tmp/0.jpg'
```

这样的方式，『形象的』调用 FacePP 的各个接口。当有新增接口的时候，也只需要添加一条路由即可。

作者 [@MaskRay](https://github.com/MaskRay) 用一个普通的 `Object` 替代了 `ActiveRecord::Relation` 的功能，我觉得是一种灰常 geek 的方式。因为这个东西足够简单，我们并没有必要去造一个自己的 `Relation`

## 改进空间

假定我们的需求场景再复杂一点

1. 包含的项目多，接口数量庞大，接口变动相对频繁
2. 常用的 4 种 http 请求方式都需要被支持（FacePP 所有接口都是 POST）
3. 被调用的路由很长，但前面有一大段是几乎不会变的前缀
4. 各个接口的的请求实现方式可能不完全一样

由此，我想到了一些改进思路

1. 抛弃预置路由表，通过覆写 method_missing 方法，在被调用的时候才去生成链式对象
2. 以 `get|post|put|delete` 或 `index|show|create|update|destroy|save` 作为最后一层发起请求的方法来结束一串调用
3. 为链式对象 `Object.new` 增加一些实例变量，比如 `@host`， `@path` 等，初始化时可以通过附加参数指定前缀等参数
4. 允许传入一个 block

## 总结

在我所在的公司，有一个内部 gem 叫 `services_support`, 专门用来处理系统间的 api 调用。这个 gem 实现了两种接口调用方式：

- 一种是诸如 `ServicesSupport::BMS.post 'api/orders', args` 这样将 path 作为参数传入
- 一种是预定义一个 `ServicesSupport::BMS.create_order(args)` 方法来调用

实际使用中，几乎所有同事都倾向于使用后面这种方式来书写代码，有定义好的要用，没有定义好的自己去加上也要用。不知道这是不是 Rubyist 们追求代码优雅的一个常态。

Anyway，等我用链式调用重写了这个 gem 后，他们就再也不用纠结怎么调了，也不用在新增接口时一个个的去新增调用方法了。想一想那酸爽，鸡肉味，嘎嘣脆~~~

