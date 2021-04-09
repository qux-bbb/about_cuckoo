PWD=/home/hello/.cuckoo

source /home/hello/for_cuckoo/venv/bin/activate

supervisorctl -c ${PWD}/supervisord.conf stop all
supervisorctl -c ${PWD}/supervisord.conf shutdown

deactivate