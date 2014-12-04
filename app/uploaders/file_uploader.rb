# encoding: utf-8

class FileUploader < CarrierWave::Uploader::Base
  
  after :remove, :remove_dir
  
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  
  include CarrierWave::MimeTypes

  process :set_content_type

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Create different versions of your uploaded files:
  # version :large, :if => :image? do
  #   process :resize_to_limit => [1920, 1080]
  # end
  #
  # version :small, :if => :image? do
  #   process :resize_to_limit => [854, 480]
  # end

  version :thumb, :if => :image? do
    process :resize_to_fill => [80, 80]
  end

  def image?(file)
    file.content_type.include? 'image'
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
  
  # Delete the auto-created directory when remove the files
  def remove_dir
    dir = 'public/' +  store_dir
    Dir.rmdir(dir) if Dir.exists?(dir)
  end

end
