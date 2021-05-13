CWD=/home/hello/.cuckoo

supervisorctl -c ${CWD}/supervisord.conf stop all
supervisorctl -c ${CWD}/supervisord.conf shutdown

sudo service nginx stop
sudo service uwsgi stop cuckoo-web
sudo service uwsgi stop cuckoo-api