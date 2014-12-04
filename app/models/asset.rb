class Asset
  include Mongoid::Document
  include Mongoid::Timestamps

  field :file, type: String
  field :content_type, type: String
  field :file_name, type: String
  field :file_size, type: Integer, default: 0

  mount_uploader :file, FileUploader

  belongs_to :user, index: true
  belongs_to :attachable, polymorphic: true, index: true
  index(created_at: 1)

  scope :orphan, ->{ where(attachable_id: nil) }

  before_save do |a|
    if file.present? && file_changed?
      a.content_type = file.file.content_type
      a.file_size = file.file.size
      a.file_name = file.file.filename
    end
  end
end
