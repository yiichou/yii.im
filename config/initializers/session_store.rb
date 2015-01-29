# Be sure to restart your server when you modify this file.

# check if working om my mac ( under development).
Rails.application.config.session_store :redis_store, key: '_yii_im_session' unless FileTest::exist?("/Users/ichou")
