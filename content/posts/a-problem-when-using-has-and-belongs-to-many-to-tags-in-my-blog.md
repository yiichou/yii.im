+++
date = "2015-01-30T23:22:07+08:00"
title = "Rails 博客使用 has_and_belongs_to_many 处理 Tag 时遇到的一个问题"
toc = true

+++

这个 blog 本是基于 [vec.io](https://github.com/vecio/vec.io) 改写的，偷了很多懒，导致写成后博客一直存在一丢丢 BUG. Tag 关联丢失这个问题其实很久以前就发现了，也尝试解决过一次，但是检查了代码没有发现问题，然后又试了一下好像又没什么问题，就当成偶发故障忽略了。然而不久前又遇到了，还表现出时好时坏的「特性」，让人颇为烦躁啊~

Blog 数据库使用的是 MongoDB，rails 用 mongoid 来驱动。在处理 Tag 时没有使用多态，而是简单的用了 has_and_belongs_to_many 来处理，按理说是应该没有任何问题的。关键的声明代码如下：

    class Post
      include Mongoid::Document
      has_and_belongs_to_many :tags, autosave: true
      ...
    end

    class Tag
      include Mongoid::Document
      has_and_belongs_to_many :posts
    end

#### 问题描述

bug 表现出来的症状时，第一次添加一个 Tag 时，没有任何问题，双向索引都正常；当我更新这篇文章时，由于这个已经添加的 Tag 没有变动，本应是没有操作的，但是实际情况是 post 索引 tags 是正确的，但是从 tag 的索引中却找不到这篇 post 了；如果再一次更新文章，这个 tag 又正常了，如此往复循环。

经过调试，从控制台对比两次的 query 发现，每次更新的时候都会先清除双方的所有关联信息，然后再根据『新』的 tags，重新构建关联。而问题就出现在这里，若是某个 tag 之前就与此 post 是关联的，虽然在上一步中已经清楚了关联，但是 AR 似乎还是会判断它是没有变更的项，于是不会在此 tag 下重新添加此 post 的外键，于是前面描述的 Bug 就产生了。

#### 解决方式

对比看两段代码

    def tags_str=(str)
      self.tags = str.split(',').uniq.inject([]) { |ts, t|
        tag = Tag.find_or_create_by(title: t)
        ts << tag
      }
    end

对比

    def tags_str=(str)
      self.tags = []  # todo： Why it can fix the bug?
      self.tags = str.split(',').uniq.inject([]) { |ts, t|
        tag = Tag.find_or_create_by(title: t)
        ts << tag
      }
    end

添加一行代码，提前将 tags 手动赋空值便可以解决这个问题，在跟踪控制台输出后发现这添加的一句并没有增加新的 query。

对于问题实际的原因和机理我还没有找到明确的资料，下面仅附上我查到的相关知识点以及猜想：

#### mongoid 相关资料

详细的参考文档： [http://mongoid.org/en/mongoid/docs/relations.html#has_and_belongs_to_many](http://mongoid.org/en/mongoid/docs/relations.html#has_and_belongs_to_many)

> Many to many relationships where the inverse documents are stored in a separate collection from the base document are defined using Mongoid’s has_and_belongs_to_many macro. This exhibits similar behavior to Active Record with the exception that no join collection is needed, the foreign key ids are stored as arrays on either side of the relation.

mongoid 在处理 has_and_belongs_to_many 时，没有像 AR 那样生成一个中间链表来保证两个数据表的操作各自独立而自使用链表来管理二者的映射关系。它是直接在两个表中添加一个字段，用于存放对方的外键。这样一来，在做相同动作的时候，Mongoid 的实际操作应该比 AR 更多，但是相比起关系型数据库，这正是 MongoDB 的长处，数据直观简洁，便利维护之类云云~（真的有么？）

> One core difference between Mongoid and Active Record from a behavior standpoint is that Mongoid does not automatically save child relations for relational associations. This is for performance reasons.

> To enable an autosave on a relational association (embedded associations do not need this since they are actually part of the parent in the database) add the autosave option to the relation.

在我 debug 到一片混乱的时候，我尝试请教大牛已寻求帮助。他提醒我，修改 post 时理应没有对 tag 表的动作（AR 中确实是这样的），所以我所遇到的问题可能是 `autosave: true` 造成的。好吧，我试了一下这果然不是问题所在，而且即使不设置为自动，似乎对 Blog 的 tag 增存也没有什么影响。（没仔细验证，请以文档为准）

#### 不负责任猜想

原来对 tags 的处理中，没有显式的清空 tags, 而是将处理好的『新』 tags 赋给 post.tags, 于是在数据驱动层会自行去比对那些数据发生了改动，然后本应该只对改动过的 tag 作更新。但是，不知是为了简化操作，还是出于效率亦或是其他的考虑，在数据驱动隐式的执行清除时并没有做判断，而是无差别的清空。清除

