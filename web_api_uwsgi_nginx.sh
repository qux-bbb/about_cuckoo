#!/bin/bash
# 一条命令错误即退出
set -o errexit

# 相关日志文件
# /var/log/uwsgi/app/cuckoo-web.log
# /var/log/uwsgi/app/cuckoo-api.log

# ubuntu20没有这个包: uwsgi-plugin-python
# 通过该方法强行加上也会有其它包依赖错误: https://packages.ubuntu.com/xenial/amd64/uwsgi-plugin-python/download

# 通过uwsgi和nginx部署 https://cuckoo.sh/docs/usage/web.html#web-deployment
# 安装依赖
sudo apt-get install uwsgi uwsgi-plugin-python nginx
# 将www-data添加到hello组确保nginx能连接到uWSGI
sudo adduser www-data hello

# 进入python虚拟环境
source /home/hello/for_cuckoo/venv/bin/activate

# cuckoo-web uwsgi配置
cuckoo web --uwsgi > cuckoo-web.ini
sudo mv cuckoo-web.ini /etc/uwsgi/apps-available/cuckoo-web.ini
sudo ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/
sudo service uwsgi start cuckoo-web
# cuckoo-web nginx配置
cuckoo web --nginx > cuckoo-web
sudo mv cuckoo-web /etc/nginx/sites-available/cuckoo-web
sudo ln -s /etc/nginx/sites-available/cuckoo-web /etc/nginx/sites-enabled/
sudo service nginx start

# cuckoo-api uwsgi配置
cuckoo api --uwsgi > cuckoo-api.ini
sudo mv cuckoo-api.ini /etc/uwsgi/apps-available/cuckoo-api.ini
sudo ln -s /etc/uwsgi/apps-available/cuckoo-api.ini /etc/uwsgi/apps-enabled/
sudo service uwsgi start cuckoo-api
# cuckoo-api nginx配置
cuckoo api --nginx > cuckoo-api
sudo mv cuckoo-api /etc/nginx/sites-available/cuckoo-api
sudo ln -s /etc/nginx/sites-available/cuckoo-api /etc/nginx/sites-enabled/
sudo service nginx start

# 退出python虚拟环境
deactivate