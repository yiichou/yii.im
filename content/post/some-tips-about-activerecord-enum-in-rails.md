+++
date = "2016-05-22T15:01:07+08:00"
title = "Rails Model 中 Enum(枚举) 的使用总结"

+++
在 Rails 的 ActiveRecord 中，有一个 ActiveRecord::Enum 的 Module，即枚举对象。

其官方说明：

> Declare an enum attribute where the values map to integers in the database, but can be queried by name.

给数据库中的整型字段声明一个一一对应的枚举属性值，这个值可以以字面量用于查询。

拿到具体的运用场景中去考虑，Enum 的主要用于数据库中类似于 状态(status) 的字段，这类字段用不同的 整数(Integer) 来表示不用的状态。如果不使用 Enum，那就意味着我们代码中会出现很多表示状态的数字，他们可能会出现在查询条件里，也可能会出现在判断条件里，除非你记得或者拿着数据字典去看，否则你很难理解这段代码的意义。

代码中，以数字方式去表述数据状态，导致代码可读性被破坏，这样的数字称为 ‘魔鬼数字’。

Enum 就是 rails 用来消灭魔鬼数字的工具。

 * * *

#### ActiveRecord::Enum 与 Mysql 的 Enum 有何不同

枚举的功能，是为了解决数据库相关的问题，那么当然的，数据库本身大多都含有枚举的功能。

以 Mysql 为例，mysql 的字段类型中有一个 ENUM 的类型：

```
CREATE TABLE person(
    name VARCHAR(255),
    gender ENUM('Male', 'Female')
);
```

这样就设置了一个叫 gender 的 ENUM 字段，其值为： `{NULL: NULL, 1: 'Male', 2: 'Female'}`, 在使用 SQL 的时候，数字键值(index of the value)和定义的字面量（actual constant literal）是通用的。

既然数据库的 ENUM 已是如此的方便，为什么很多时候我们还是不愿意使用它呢？最大的问题在于 ENUM 的属性值在建表的时候就已经固定了下来，一旦到了后期需要加一个状态，那么就意味着需要改字段。而且目前各种数据库对于 ENUM 的处理方式也并非是完全一致的，给 ORM 也带来的不小的问题。

参考文章：[When you should and should NOT use ENUM data type](http://www.cubrid.org/blog/cubrid-life/when-you-should-and-should-not-use-enum-data-type/)

ActiveRecord::Enum 在实现上，和对外键的处理方式是一样的，并不直接使用数据库自身的 Enum 和 外键，而是通过在 Model 中来维护这些关系。实际在数据库中存的只是单纯的 Integer，这样就避免了 Enum 属性变动需要修改数据库结构的问题。

* * *

#### ActiveRecord::Enum 的使用

具体使用请参见[官方文档](http://api.rubyonrails.org/classes/ActiveRecord/Enum.html#method-i-enum)

```
class Conversation < ActiveRecord::Base
  enum status: { active: 0, waiting: 1 ,archived: 2 }
  # or
  enum status: [ :active, :waiting, :archived ]
end
```

声明之后，会多出以下一些方法(methods):

```
conversation.active! # 改写状态为 active
conversation.active? # 检查状态是否为 active

conversation.status     # => "active" 输出为字面量
conversation[:status]   # => 0 输出仍为数据库真实值

conversation.status = 1            # => "archived"
conversation.status = 'archived'   # => "archived"
conversation.status = :archived    # => "archived" 赋值时，三者等价

# 自动添加 Scope
Conversation.active    # 等价于 Conversation.where status: 0

# 获得一个名为 statuses 的 Hash
Conversation.statuses # => { "active" => 0, "waiting" => 1, "archived" => 2 }
```

* * *

#### Rails 中使用 enum 的一些总结

1. 不要使用数据库的 enum，理由如上

2. enum 会自动添加 scope    

3. **作为查询条件时，不能使用字面量，需要转义成对应的 Integer** （目前的 rails 版本中是这样的，这也导致了 enum 有点鸡肋）

4. 取用时，method 和 [] 取得的值不同，一个是字面量(String)，一个是整数型 Integer

5. Model.new 时，enum 字段若非整数型,便必须为 enum attribute 中的一个，否则报错

6. 赋值时，字面量 和 整型 是等效的

7. 结合 local(本地化) 翻译一起使用，效果更好

8. 在 Rails 的 edge 版本中，字面量可以直接用于做查询条件
参考：[http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html](http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html)

9. 状态只有开和关的(1和0)，数字本身就已经能表达的语意，可以不用 enum

