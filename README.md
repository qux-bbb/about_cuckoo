记一下搭建cuckoo涉及的东西  

因为cuckoo已经不维护了，这里有一个fork，效果更好：  
https://github.com/kevoreilly/CAPEv2  

本仓库不再更新  

---
使用cuckoo步骤：  
1. sudo执行 start_setting.sh, 设置虚拟网卡和iptables
2. 之后和cuckoo相关的命令，都要先进入虚拟环境，我这里是 `. ~/for_cuckoo/venv/bin/activate`
3. 启动rooter: `cuckoo rooter -g hello --sudo`
4. 启动cuckoo: `cuckoo`
5. 提交样本: `cuckoo submit the_sample_file --machine win7_x64`
6. 查看json报告: `view ~/.cuckoo/storage/analyses/8/reports/report.json`
7. 如果想web操作，可以这样: `cuckoo web`

[ ] windows怎么激活比较好  
[ ] inetsim要有一个合适的配置
