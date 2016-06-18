#!/usr/bin/env bash

echo "========================"
echo "git push origin hugo"
git push origin hugo
echo "========================"
echo "Deploy to yii"
shell='cd /var/www/yii.im.hugo && git pull origin hugo && echo "========================" && hugo -t slim'
ssh yii ${shell}
echo "Status: Finished"
echo "========================"