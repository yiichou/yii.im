#!/usr/bin/env puma

environment "production"

daemonize true

wd          = File.expand_path('../../', __FILE__)
tmp_path    = File.join(wd, 'log')
Dir.mkdir(tmp_path) unless File.exist?(tmp_path)

pidfile          File.join(tmp_path, 'puma.pid')
state_path       File.join(tmp_path, 'puma.state')
stdout_redirect  File.join(tmp_path, 'puma.out.log'), File.join(tmp_path, 'puma.err.log'), true

threads 0,16
workers 0

bind  "unix:///var/run/yii.im.socket"
