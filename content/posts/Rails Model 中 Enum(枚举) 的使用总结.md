+++
date = "2018-06-14T05:41:07+08:00"
title = "Rails Model 中 Enum(枚举) 的使用总结"
slug = "some-tips-about-activerecord-enum-in-rails"
+++

在 Rails 的 ActiveRecord 中，有一个 ActiveRecord::Enum 的 Module，即枚举对象。

官方说明：

> Declare an enum attribute where the values map to integers in the database, but can be queried by name.

给数据库中的整型字段声明一个一一对应的枚举属性值，这个值可以以字面量用于查询。

拿到具体的运用场景中去考虑，Enum 的主要用于数据库中类似于 状态(status) 的字段，这类字段用不同的 整数(Integer) 来表示不用的状态。如果不使用 Enum，那就意味着我们代码中会出现很多表示状态的数字，他们可能会出现在查询条件里，也可能会出现在判断条件里，除非你记得或者拿着数据字典去看，否则你很难理解这段代码的含义。

代码中，以数字方式去表示数据状态，导致代码可读性被破坏，这样的数字被称为『魔鬼数字』。

**Enum 就是 Rails 用来消灭魔鬼数字的工具。**

 * * *


### ActiveRecord::Enum 与 Mysql 的 Enum 有何不同

枚举的功能，是为了解决数据库相关的问题，那么当然的，数据库本身大多都含有枚举的功能。

以 Mysql 为例，mysql 的字段类型中有一个 ENUM 的类型：

```sql
CREATE TABLE person(
    name VARCHAR(255),
    gender ENUM('Male', 'Female')
);
```

这样就设置了一个叫 gender 的 ENUM 字段，其值为： `{NULL: NULL, 1: 'Male', 2: 'Female'}`, 在使用 SQL 的时候，数字键值(index of the value)和定义的字面量（actual constant literal）是通用的。

既然数据库的 ENUM 已是如此的方便，为什么我们不直接使用它呢？最大的问题在于 ENUM 的属性值在建表的时候就已经固定了下来，一旦到了后期需要加一个状态，那么就意味着需要改字段。而且目前各种数据库对于 ENUM 的处理方式也并非是完全一致的，给 ORM 的实现也带来的不少的问题。

ActiveRecord::Enum 在实现上，和对外键的处理方式一样，并不直接使用数据库自身的 ENUM，仅用普通的 Integer 来做存储，以此避免了 Enum 属性变动时需要修改数据库结构的问题。

### ActiveRecord::Enum 的使用

具体使用请参见[官方文档](http://api.rubyonrails.org/classes/ActiveRecord/Enum.html)

```ruby
# Migration
create_table :conversations do |t|
  t.integer :status, default: 0
end

# Model
class Conversation < ActiveRecord::Base
  enum status: { active: 0, waiting: 1, archived: 2 }
  # or, but not recommended
  enum status: [ :active, :waiting, :archived ]
end
```

声明之后，会多出以下一些辅助方法:

```ruby
conversation.active! # 改写状态为 active
conversation.active? # 检查状态是否为 active

conversation.status     # => "active" 输出为字面量
conversation[:status]   # => 0 输出为数字键值（仅 Rails 4.x的版本）


conversation.status = 2            # => "archived"
conversation.status = "archived"   # => "archived"
conversation.status = :archived    # => "archived" 赋值时，三者等价

# 自动添加 Scope
Conversation.active    # 等价于 Conversation.where(status: 0)

# 获得一个名为 statuses 的 HashWithIndifferentAccess
Conversation.statuses # => { "active" => 0, "waiting" => 1, "archived" => 2 }
Conversation.statuses[:active]    # => 0
Conversation.statuses["archived"] # => 2
```

### ActiveRecord::Enum 在 Rails 5.0+ 中的新特性 

首先需要提一下，ActiveRecord::Enum 是在 Rails 4.1 加入的功能，所以 4.1 以下的版本是没有原生 Enum 支持的，可以使用 [simple_enum](https://rubygems.org/gems/simple_enum) 这个 gem 来实现类似需求

然后在 Rails 5.0 中，又对 ActiveRecord::Enum 做了一些扩展，使得它现在用起来更为顺手

主要的改进有：

#### 1. where 查询支持直接使用字面量做查询条件

```ruby
# 在 Rails 4.1+ 中
Conversation.where(status: %i[active waiting]).to_sql
# => "SELECT `conversations`.* FROM `conversations` WHERE `conversations`.`status` IN (NULL, NULL)"

# 惊不惊喜，意不意外，这也是 4.x 版本 Enum 比较鸡肋的原因，正确的你应这样写
Conversation.where(status: %i[active waiting].map { |s| Conversation.statuses[s] }).to_sql
# => "SELECT `conversations`.* FROM `conversations` WHERE `conversations`.`status` IN (0, 1)"

# 好在，Rails 5.0 之后就可以这么用了
Conversation.where(status: %i[active waiting]).to_sql
# => "SELECT \"conversations\".* FROM \"conversations\" WHERE \"conversations\".\"status\" IN (0, 1)"

# BUT，当你选择手写 SQL 查询条件的时候，仍是需要自己转义的
Conversation.where("status <> ?", Conversation.statuses[:archived])
```

#### 2. conversation[:status] 与 conversation.status 返回值一致，都是字面量

```ruby
# Rails 4.1+
conversation.status # => "active"
conversation[:status] # => 0
Conversation.pluck(:status) # => [0, 1, 2, 1, ...]

# Rails 5.0+
conversation.status # => "active"
conversation[:status] # => "active"
Conversation.pluck(:status) # => ["active", "waiting", "archived", "waiting", ...]
```

#### 3. 增加了两个可选参数 `_prefix` 和 `_suffix`

在 Rails 4.1+ 的版本中，即使是不同的 enum 字段也不能有同名的值

```ruby
# user.rb
  enum status: [:temporary, :active, :deleted]
  enum admin_status: [:active, :super_admin]

# rails console
irb(main):001:0> u = User.new
ArgumentError: You tried to define an enum named "admin_status" on the model "User", but this will generate a instance method "active?", which is already defined by another enum.
...
```

于是在 Rails 5 中，引入了 `_prefix` 和 `_suffix` 两个选项来解决这个问题，它会给对应的 `!`、`?` 以及 scope 方法加上前/后缀以示区分

```ruby
# user.rb
  enum status: [:temporary, :active, :deleted], _suffix: true
  enum admin_status: [:active, :super_admin]
  
# rails console
  user = User.active_status.first
  user.active_status?
  user.deleted_status!
  
# user.rb
  enum status: [:temporary, :active, :deleted], _suffix: :stat
  enum admin_status: [:active, :super_admin]
  
# rails console
  user = User.active_stat.first
  user.active_stat?
  user.deleted_stat!
```


### 实际使用中的一些经验总结

#### 1. 不要使用数据库的 enum ！！！

除非你们的 DBA 同意你这么做，并且以后的迁移由他负责，否则真心不建议使用

#### 2. 尽量升级到 Rails 5 以上的版本

Rails 4.x 的 Enum 有点鸡肋的感觉，看上去感觉很爽，实际上用着蛋疼。

#### 3. 对 enum 字段赋值时，已经隐含了数据验证

在对一个 enum 字段赋值时，值必须是该字段字面量（symbol/string 皆可）或数字键值中的一个，否则会直接抛出一个 `ArgumentError`

以上文例子来说， 给 `conversation.status` 赋值时，必须是 `[:active, :waiting, :archived, "active", "waiting", "archived", 0, 1, 2]` 中的一个，否则就会报错

#### 4. 尽量不要使用数组来定义 enum

就是不要使用下面这种形式

```ruby
enum status: [ :active, :waiting, :archived ]
enum status: %i[active waiting archived]
```

相比起使用 Hash，数组相当于隐式指定了数字键值，字面量的顺序就很关键。你无法保证每个可能改这处代码的人都深知这一点，而一旦被插值或者打乱顺序，可能会导致几个通宵的加班。

#### 5. 手动设置了 table_name 时，需要警惕关联查询的陷阱

注：这条是 Rails 5.x 的专属烦恼

```ruby
# post.rb
class Post < ActiveRecord::Base
  self.table_name = :articles
  
  has_many :comments
  
  enum category: { it: 0, law: 1, medical: 2 }
end

# comment.rb
class Comment < ActiveRecord::Base
    belongs_to :post, foreign_key: :article_id
end

# 正常查询是 OK 的
Post.law.to_sql 
#=> "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"category\" = 1"

# 作为关联表的查询条件，enum 字段就无法转义了，查询会报错
Comment.joins(:post).where(articles: { category: :law }).to_sql
# => "SELECT \"comments\".* FROM \"comments\" INNER JOIN \"articles\" ON \"articles\".\"id\" = \"comments\".\"article_id\" WHERE \"articles\".\"category\" = 'law'"

# 故意写个错的查询，看看错出在哪儿
Comment.joins(:post).where(post: { category: :law }).to_sql
# => "SELECT \"comments\".* FROM \"comments\" INNER JOIN \"articles\" ON \"articles\".\"id\" = \"comments\".\"article_id\" WHERE \"post\".\"category\" = 1"
```

通过这个对比可以发现，因为手动设置了 table_name 时，关联表查询需要指定真实的表名，这会导致 enum 字段无法被正确转义

> **前方高能预警，神坑来了！！！**

猜猜这个查询会不会报错？能不能查出数据？

```ruby
Comment.joins(:post).where(articles: { category: [:law] })
```

答案是：不会报错，会查到数据，但绝不是你想要的

```ruby
Comment.joins(:post).where(articles: { category: [:law] }).to_sql
# => "SELECT \"comments\".* FROM \"comments\" INNER JOIN \"articles\" ON \"articles\".\"id\" = \"comments\".\"article_id\" WHERE \"articles\".\"category\" = 0"
```

`where` 条件里面变成了 `"articles"."category" = 0`, 也就是查出了条件为 `{ category: :it }` 的数据，够惊悚吧

所以，遇到这种情况，最好自己做转义！自己做转义！！自己做转义！！！

#### 6. 给 enum 字段添加默认值是一个好习惯

默认值最好还是定义的属性值里的第一个，通常来说是『0』

```ruby
create_table :conversations do |t|
  t.integer :status, limit: 2, default: 0, null: false
end
```

特别是对于 4.x 版本而言，如果字段允许为 NULL，当你按 5.x 的习惯写 where 查询的时候，可能会返回些让你一脸懵逼的结果。


#### 7. 添加新属性时，最好写一个迁移

加属性值的时候，并不涉及到数据库变动，为什么要写迁移呢？当然这不是必须的，建议写主要出于两项考虑

1. 检测当前数据库中新加的值是否已经被占用
2. 更新数据库字段的 comment

当多个系统使用同一张数据表的时候，可能会出现 A 系统加了一个新的状态 `{ deleted: 3 }`，B 系统不知道，也添加了一个 `{ reactive: 3 }` 的新状态，等到某天其中一方发现问题时，线上的数据早已经是一团浆糊了。

所以在这种情况下，应该写一个迁移

```ruby
class AddDeletedStatusToConversations < ActiveRecord::Migration[5.1]
  def up
    raise "The value of deleted status has already been taken." if Conversation.deleted.count.positive?
    change_column :conversations, :status, :integer, default: 0, null: false, comment: "0 - active, 1 - waiting, 2 - archived, 3 - deleted"
  end
end
```

虽然这并不能保证万无一失，但及时的修改 comment 至少还是一个好习惯，毕竟使用数据库的可能不止是写 Rails 的人，还有 DBA，还有数据分析师，好的 comment 给他们带来很多便利

#### 8. 数据库字段不一定非得是 Integer

可以是 boolean（个人觉得 boolean 字段已经没有必要使用 enum 了，毕竟语意已经很明确了）

还可以是 string，在对一些老代码做重构的时候，这个特性可能会很实用

#### 9. 结合 I18n 食用，风味更佳

针对 enum 的 i18n 方案有很多，比如 

[enum_i18n](https://rubygems.org/gems/enum_i18n) / [human_enum](https://rubygems.org/gems/human_enum) / [active_record-humanized_enum](https://github.com/dhyegofernando/active_record-humanized_enum) 

这三个很相似，都是把翻译放在 `zh-CN.activerecord.attributes.conversation.statuses` 下面，只是调用方式略微有点不同

另外还有 @zmbacker 写的 [enum_help](https://github.com/zmbacker/enum_help)

它的翻译放在 `zh-CN.enums.conversation.status` 下面，相比起来还更直观一点，而且它支持 simple_form，个人比较推荐

如果你不怕麻烦，也不想引入任何 gem，还可以利用 `human_attribute_name` 来实现：

```ruby
# zh-CN.yml
# zh-CN:
#   activerecord:
#     attributes:
#       conversation/status:
#         active: 当前激活
#         waiting: 等待中
#         archived: 已归档

conversation.status # => "active"
Conversation.human_attribute_name("status.#{conversation.status}") # => "当前激活"
```

#### 10. enum 的字面量要注意避开 model 已有的 method_names/attribute_names

这一点就不用啰嗦了，除非是表字段特别复杂，正常情况下，应该是不太会在这个问题上犯错的。

***


参考文章：[When you should and should NOT use ENUM data type](http://www.cubrid.org/blog/cubrid-life/when-you-should-and-should-not-use-enum-data-type/)


