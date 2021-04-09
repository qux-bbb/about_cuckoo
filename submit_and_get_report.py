# coding:utf8
# python3

import os
import sys
import re
import json
import requests
from time import sleep


ip_port = 'localhost:8090'
HEADERS = {'Authorization': 'Bearer S4MPL3'}


def submit(file_path):
    url = 'http://{}/tasks/create/file'.format(ip_port)

    file_name = re.split(r'[/\\]', file_path)[-1]

    with open(file_path, 'rb') as sample:
        files = {'file': (file_name, sample)}
        r = requests.post(url, headers=HEADERS, files=files)
    
    print(r.json())

    # Add your code to error checking for r.status_code.

    task_id = r.json()['task_id']

    # Add your code for error checking if task_id is None.

    return task_id


def tasks_view(task_id):
    url = 'http://{}/tasks/view/{}'.format(ip_port, task_id)

    max_time = 300
    cur_time = 0
    while cur_time < max_time:
        res = requests.get(url, headers=HEADERS)
        res_json = res.json()
        status = res_json.get('task', {}).get('status', '')
        if status == 'reported':
            return True
        else:
            if status == 'completed':
                print('time: {}, completed but not reported...'.format(cur_time))
            else:
                print('time: {}, {}...'.format(cur_time, status))
            cur_time += 5
            sleep(5)
    return False


def get_report(task_id, file_path):
    url = 'http://{}/tasks/report/{}'.format(ip_port, task_id)

    report_path = file_path + '.json'

    res = requests.get(url, headers=HEADERS)
    res_json = res.json()
    with open(report_path, 'w') as f:
        json.dump(res_json, f, indent=4)
    print('{} saved'.format(report_path))



def print_usage():
    print('usage: py -3 {} <file_path>'.format(sys.argv[0]))


def main():
    if len(sys.argv) != 2:
        print_usage()
        exit(0)

    file_path = sys.argv[1]
    if not os.path.isfile(file_path):
        print_usage()
        exit(0)

    task_id = submit(file_path)
    if tasks_view(task_id):
        get_report(task_id, file_path)
    else:
        print('[!] timeout, no report!')


if __name__ == '__main__':
    main()
