CarrierWave.configure do |config|
  config.storage = :aliyun
  config.aliyun_access_id = Preference.aliyun_oss.access_id
  config.aliyun_access_key = Preference.aliyun_oss.access_key
  
  # 你需要在 Aliyum OSS 上面提前创建一个 Bucket
  config.aliyun_bucket = Preference.aliyun_oss.bucket
  
  # 是否使用内部连接，true - 使用 Aliyun 局域网的方式访问  false - 外部网络访问
  config.aliyun_internal = false
  
  # 配置存储的地区数据中心，默认: cn-hangzhou
  config.aliyun_area = "cn-hangzhou" 
  
  # 使用自定义域名，设定此项，carrierwave 返回的 URL 将会用自定义域名
  # 自定于域名请 CNAME 到 you_bucket_name.oss.aliyuncs.com (you_bucket_name 是你的 bucket 的名称)
  config.aliyun_host = Preference.aliyun_oss.stc
end if Rails.env.production?