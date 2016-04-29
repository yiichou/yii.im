root = File.expand_path('../../', __FILE__)
log_dir = File.join(root, 'log')
tmp_dir = File.join(root, 'tmp')
puma_env = "production"


directory root
rackup File.join(root, 'config.ru')
environment puma_env
ENV['SECRET_KEY_BASE'] = 'VBmrotiIYLCvAs0Dca9jh1Nw5H3OX78nQRUgGdMJP62fTkpq4KEWZSFbzuyxel'

tag "yii.im"

pidfile File.join(tmp_dir, 'pids', 'puma.pid')
state_path File.join(tmp_dir, 'pids', 'puma.state')
stdout_redirect "#{log_dir}/puma.log", "#{log_dir}/#{puma_env}_error.log", true

bind  "unix:///var/run/yii.im.socket"

worker_timeout 5
threads 4,8
workers 4

daemonize true
preload_app!