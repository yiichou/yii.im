RailsConfig.setup do |config|
  config.const_name = "Preference"
end

Rails::Timeago.locales = [:en, :de, "zh-CN", :sjn]
