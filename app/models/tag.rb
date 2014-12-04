class Tag
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title, type: String
  field :count, type: Integer, default: 0

  index({ title: 1 }, { unique: true })
  index(count: 1)

  slug :title, permanent: true

  validates_presence_of :title, allow_blank: false
  validates_uniqueness_of :title, case_sensitive: false, allow_blank: true

  has_and_belongs_to_many :posts

  scope :used, ->{ where(:count.gt => 0) }
  
  def set_count
    self.set(:count => self.posts.published.count)
    self.destroy if self.count == 0
  end
end
