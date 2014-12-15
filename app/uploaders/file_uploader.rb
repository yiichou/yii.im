# encoding: utf-8

class FileUploader < CarrierWave::Uploader::Base  
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick if Rails.env.development?
  
  include CarrierWave::MimeTypes

  process :set_content_type

  # Choose what kind of storage to use for this uploader:
  # storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "yii.im/#{model.class.to_s.underscore}/#{model.id}"
  end

  # Create different versions of your uploaded files:
  # version :large, :if => :image? do
  #   process :resize_to_limit => [1920, 1080]
  # end
  #
  # version :small, :if => :image? do
  #   process :resize_to_limit => [854, 480]
  # end

  if Rails.env.development?
    version :thumb do
      process :resize_to_fill => [80, 80]
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w[jpg jpeg gif png
       tar tar.bz2 tar.gz 7z zip rar
       apk pdf odt txt]
  end

  CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
