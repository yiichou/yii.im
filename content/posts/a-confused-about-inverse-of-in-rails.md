+++
date = "2015-04-04T23:25:23+08:00"
title = "关于 inverse_of 的困惑"
comments = true

+++

接上一篇博文，最近花了比较多的时间来折腾 rails 的 Active Record Associations, 一些以前没注意过的问题这次纠集成一大波僵尸直奔我可怜的脑子来了喂。

进入正题，昨天基本明确了 关联 的是使用规则，今天开始在项目里尝试用一些附属功能去提升效率（其实就是瞎折腾），以求写出更简洁漂亮的业务逻辑。果不其然，刚想用 inverse_of 就被难住了。

### 问题缘由

我对 `inverse_of` 的困惑并不是在实际使用中产生的，即使不了解它也能在项目中愉快的玩耍，这似乎又旁证了 Rails 是一个很智能的框架。

不过它的 Guide 文档里这一部分就有些描述不清了（或说自相矛盾？）。关于 `inverse_of ` 的功用倒是没有什么疑惑，只是被这混乱的文档弄得不知道哪些情况下需要去显示的声明 `inverse_of ` , 哪些情况下 `inverse_of ` 又是无效果的。


### 问题描述

Guide 中关于 `inverse_of` 的解释：http://guides.rubyonrails.org/association_basics.html#bi-directional-associations

其中有两处说明让我很费解：

**其一：**

>There are a few limitations to inverse_of support:
1. They do not work with :through associations.
2. They do not work with :polymorphic associations.
3. They do not work with :as associations.
**4. For belongs_to associations, has_many inverse associations are ignored.**
  
按第四条所说的，has_many 的关联是无效的，但是 Guide 中的栗子便是使用的 has_many, 而且很好的证明了 inverse_of 的效果。

**其二：**

> **Every association will attempt to automatically find the inverse association and set the :inverse_of option heuristically (based on the association name).** Most associations with standard names will be supported. However, associations that contain the following options will not have their inverses set automatically:
1. :conditions 
2. :through
3. :polymorphic 
4. :foreign_key 

按这个说法，只要是按约定命名的 关联 会自动加上 inverse_of, 那么，演示用例是按约定命名的吧，也不属于下面声明的四种情况，为什么加与不加是有差别的？


### 相关主题查询结果

1. https://ruby-china.org/topics/8560
2. https://ruby-china.org/topics/6426
3. http://stackoverflow.com/questions/9296694/what-does-inverse-of-do-what-sql-does-it-generate
4. http://stackoverflow.com/questions/14927952/why-would-i-not-want-to-use-inverse-of-everywhere
5. http://stackoverflow.com/questions/7654184/does-inverse-of-works-with-has-many
6. http://stackoverflow.com/questions/7436173/activerecord-inverse-of-does-not-work-on-has-many-through-on-the-join-model-on

ruby-china 的两条，偏向于解读 inverse_of 的作用，对理解 inverse_of 有帮助
stackoverflow 的四条涵盖的信息较多，基本弄清了我的疑问

从这些信息中，总结出以下要点：

①  `inverse_of` 的作用在于关联模型间共用实例，而不是让不同的查询在内存中存在多份 Copies. 
实际运用中可以带来两个好处，一是减少数据库查询；二是在对 关联对象 修改数据后写入数据前，保证从任何一方取得的值都是最新的。
 

② Guide 的相关用例是有问题的，或者说是适用于老版本的 Rails，而不是当前版本。
**因为给 `basic associations\*` 自动添加 `inverse_of` 是在 Rails 4.1 加入的特性。**
事实上，关于 has_many 的那个例子，在 4.1 及以后的版本中已经不能复现了。 

> http://edgeguides.rubyonrails.org/4_1_release_notes.html 
http://wangjohn.github.io/activerecord/rails/associations/2013/08/14/automatic-inverse-of.html
 

③ Guide 的内容中出现了新旧说明混在一起的情况。有些是新版本的特性，有些却是过时的。
比如：从 3.2.1 开始，`inverse_of ` 已经支持 has_many 了，只是没有支持 :through
原文如下：

> As per the active record api 3.2.1: "Currently :inverse_of supports has_one and has_many (but not the :through variants) associations. It also supplies inverse support for belongs_to associations where the inverse is a has_one and it’s not a polymorphic."

但是，如上文所说的，文档中仍有说不支持的话。



### 动手验证

*验证环境 Rails 版本：4.2.1*

定义模型：

```
# a.rb
class A < ActiveRecord::Base
	has_many :b
end

# b.rb
class B < ActiveRecord::Base
	belongs_to :a
end
```

测试结果：

```
2.2.1 :001 > a = A.create :name => 'ichou'
   (0.1ms)  begin transaction
  SQL (0.4ms)  INSERT INTO "as" ("name", "created_at", "updated_at") VALUES (?, ?, ?)  [["name", "ichou"], ["created_at", "2015-04-04 06:41:41.187074"], ["updated_at", "2015-04-04 06:41:41.187074"]]
   (9.1ms)  commit transaction
 => #<A id: 2, name: "ichou", created_at: "2015-04-04 06:41:41", updated_at: "2015-04-04 06:41:41">

2.2.1 :002 > b1 = B.create :name => 'kindle', :a => a
   (0.1ms)  begin transaction
  SQL (0.4ms)  INSERT INTO "bs" ("name", "a_id", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["name", "kindle"], ["a_id", 2], ["created_at", "2015-04-04 06:42:45.165370"], ["updated_at", "2015-04-04 06:42:45.165370"]]
   (9.0ms)  commit transaction
 => #<B id: 3, name: "kindle", a_id: 2, created_at: "2015-04-04 06:42:45", updated_at: "2015-04-04 06:42:45">

2.2.1 :003 > b2 = B.create :name => 'Air', :a => a
   (0.1ms)  begin transaction
  SQL (0.4ms)  INSERT INTO "bs" ("name", "a_id", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["name", "Air"], ["a_id", 2], ["created_at", "2015-04-04 06:43:10.143507"], ["updated_at", "2015-04-04 06:43:10.143507"]]
   (9.3ms)  commit transaction
 => #<B id: 4, name: "Air", a_id: 2, created_at: "2015-04-04 06:43:10", updated_at: "2015-04-04 06:43:10">

2.2.1 :004 > a.name.object_id
 => 70264637654120

2.2.1 :005 > b1.a.name.object_id
 => 70264637654120

2.2.1 :006 > b2.a.name.object_id
 => 70264637654120
```

object_id 全都一样，说明 `inverse_of ` 已经被启用了。事实上，即使严格按照 Guide 的案例来做，你也会发现结果全是 True，而不是 Guide 所说的结果。

**结论：在 4.1+ 的 Rails 中，即使不手动声明 `inverse_of ` ，has_many 关联也会自动创建，而且是有效的！**


### 总结与使用

1. 基本的关联类型（has_many, has_one, belongs_to），若按约定命名，不需要再手动设定 `inverse_of`

2. has_many :through 型的关联，若不设置 inverse_of ，through 表（the through record ）
不会被记录
 PS: 这一条是看 API 得出来的，我还没有去验证。
 
3. 使用没有持久化的关联对象时，根据需要使用 inverse_of，否则反向调用会得到 nil 或者还未更新的 对象。详见上文的 [topics/6426](https://ruby-china.org/topics/6426)
