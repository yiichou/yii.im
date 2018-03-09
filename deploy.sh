#!/usr/bin/env bash

echo "========================"
echo "git push origin hugo"
git push origin hugo
echo "========================"
echo "Deploy to yii"
shell='cd /home/live/yii.im && git pull origin hugo && echo "========================" && hugo -t vec'
ssh yii ${shell}
echo "Status: Finished"
echo "========================"