class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Mongoid::History::Trackable

  field :published, type: Boolean
  field :title, type: String
  field :content, type: String

  index(created_at: 1)
  index({ title: 1 }, { unique: true })

  slug :title, permanent: true, history: true

  validates_presence_of :title, :content, allow_blank: false
  validates_uniqueness_of :title, case_sensitive: false, allow_blank: true

  belongs_to :user, index: true
  has_many :assets, as: :attachable, autosave: true, dependent: :destroy
  has_and_belongs_to_many :tags, autosave: true

  paginates_per 16

  track_history :on => [:published, :title, :content, :updated_at]

  scope :published, ->{ where(published: true) }

  def tags_str
    self.tags.map(&:title).join(',')
  end

  def tags_str=(str)
    self.tags = []  # todo: 没有这一句，保存文章是会把没变动的 tag 关联删除，很奇怪啊~ 
    self.tags = str.split(',').uniq.inject([]) { |ts, t|
      tag = Tag.find_or_create_by(title: t)
      ts << tag
    }
  end

  after_save do |p|
    p.tags.each { |t| t.set(:count => t.posts.published.count) }
  end

  after_update do |p|
    p.set(:created_at => p.updated_at) if p.changes['published'] && p.changes['published'][1]
  end

  after_destroy do |p|
    p.tags.each { |t| t.set(:count => t.posts.published.count) }
    p.history_tracks.destroy_all
  end
end
