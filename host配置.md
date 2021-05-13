# host配置

由于ubuntu20缺少依赖项: uwsgi-plugin-python, 所以使用ubuntu18  
https://mirrors.huaweicloud.com/repository/ubuntu-releases/18.04.5/ubuntu-18.04.5-live-server-amd64.iso  

我的系统信息  
```
$ cat /etc/issue
Ubuntu 18.04.5 LTS \n \l
$ uname -a
Linux hello_server 4.15.0-141-generic #145-Ubuntu SMP Wed Mar 24 18:08:07 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```

cuckoo 2.0.7 不支持python3，这里用了python2.7.18  
安装python和依赖库  
```bash
sudo apt-get install python python-dev libffi-dev libssl-dev
sudo apt-get install python-setuptools python-pip
sudo apt-get install libjpeg-dev zlib1g-dev swig
sudo pip install virtualenv
```
pip如果安装失败，可以这样安装: `wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && sudo python get-pip.py`  

创建虚拟环境，安装cuckoo  
```bash
virtualenv venv
. venv/bin/activate
pip install -U pip setuptools
pip install -U cuckoo  # 这里可能有一些包的新版本已经只支持python3所以会出错，可以手动安装符合条件的最小版本的包，如: pip install pyrsistent==0.14.0
# 执行一下cuckoo，生成初始的cwd：cuckoo
cuckoo
```

安装yara  
```bash
# 安装依赖
sudo apt-get install automake libtool make gcc
sudo apt-get install flex bison
sudo apt-get install libjansson-dev
# 下载解压，版本可能变化
wget https://github.com/VirusTotal/yara/archive/v4.0.5.tar.gz
tar -zxvf v4.0.5.tar.gz
# 编译安装
cd yara-4.0.5
./bootstrap.sh
./configure --enable-cuckoo
make
sudo make install
# 检查
make check
```

安装pydeep  
```bash
# 安装依赖
sudo apt install libfuzzy-dev g++
# ssdeep下载解压，版本可能变化
wget https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz
tar -zxvf ssdeep-2.14.1.tar.gz
# 编译安装
cd ssdeep-2.14.1
./configure
make
sudo make install
sudo ldconfig
cd ../
# pydeep下载解压
wget https://github.com/kbandla/pydeep/archive/0.2.tar.gz
tar -zxvf 0.2.tar.gz
# 编译安装
cd pydeep-0.2
python setup.py build
sudo python setup.py install
```

安装mitmproxy  
```bash
# 下载解压
wget https://snapshots.mitmproxy.org/6.0.2/mitmproxy-6.0.2-linux.tar.gz
tar -zxvf mitmproxy-6.0.2-linux.tar.gz
# 创建软链接
sudo ln -s /home/hello/for_cuckoo/mitmdump /usr/local/bin/mitmdump
sudo ln -s /home/hello/for_cuckoo/mitmproxy /usr/local/bin/mitmproxy
sudo ln -s /home/hello/for_cuckoo/mitmweb /usr/local/bin/mitmweb
```
可以简单运行一下mitmproxy（直接执行命令：mitmproxy），使其生成证书（~/.mitmproxy文件夹下），然后Ctrl+C退出  
复制mitmproxy证书到analyzer对应路径下：  
```bash
cp /home/hello/.mitmproxy/mitmproxy-ca-cert.p12 /home/hello/.cuckoo/analyzer/windows/bin/cert.p12
```

安装tcpdump  
```bash
sudo apt-get install tcpdump apparmor-utils
sudo aa-disable /usr/sbin/tcpdump
# 设置不需要管理员权限启动tcpdump
sudo groupadd pcap
sudo usermod -a -G pcap hello
sudo chgrp pcap /usr/sbin/tcpdump
# 安装setcap
sudo apt-get install libcap2-bin
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
# 确认结果
getcap /usr/sbin/tcpdump
```

安装volatility  
```bash
# 下载解压
sudo apt install unzip
wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip
unzip volatility_2.6_lin64_standalone.zip 
# 创建软链接
sudo ln -s /home/hello/for_cuckoo/volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone /usr/local/bin/volatility
```

安装M2Crypto(这里装的是0.37.1版本)  
```bash
sudo apt-get install swig
pip install m2crypto
```

安装guacd用于远程操作(ubuntu20会缺少包)  
```bash
sudo apt install libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd
```
如果想体验最新版，可以手动安装  
```bash
# 在这里找到最新的版本，替换下载链接: https://downloads.apache.org/guacamole
sudo apt install libcairo2-dev 	libjpeg62-turbo-dev libpng-dev libtool-bin libossp-uuid-dev freerdp2-dev
mkdir /tmp/guac-build && cd /tmp/guac-build
wget https://downloads.apache.org/guacamole/1.2.0/source/guacamole-server-1.2.0.tar.gz
tar -zxvf guacamole-server-1.2.0.tar.gz && cd guacamole-server-1.2.0
./configure --with-init-dir=/etc/init.d
make && sudo make install && cd ..
sudo ldconfig
sudo /etc/init.d/guacd start
```

安装配置mysql(cuckoo默认用sqlite数据库，所以如果只是测试，不装数据库也能用)  
```bash
# 安装mysql
sudo apt install mysql-server mysql-client libmysqlclient-dev
# mysql默认用户root密码为空
sudo mysql -uroot -p
```
执行SQL语句：  
```bash
# 这里版本信息是：mysql  Ver 8.0.22-0ubuntu0.20.04.3 for Linux on x86_64 ((Ubuntu))
# 因为mysql 版本更新，不能用这条命令了：GRANT all ON cuckoo.* TO 'your_name'@'localhost' identified by 'your_pass';
# 拆成2条命令代替
CREATE DATABASE IF NOT EXISTS cuckoo default charset utf8 COLLATE utf8_general_ci;
create user 'your_name'@'localhost' identified by 'your_pass';
grant all privileges on cuckoo.* to 'your_name'@'localhost';
```
在cuckoo.conf里需要设置：`connection = mysql://your_name:your_pass@localhost/cuckoo?charset=utf8`  
还需要pip安装一个包：`pip install mysql-python`，如果出现my_config.h不存在错误，执行以下命令后重新pip安装mysql-python:  
`sudo wget https://raw.githubusercontent.com/paulfitz/mysql-connector-c/master/include/my_config.h -P /usr/include/mysql/`  

为了使用基于Django的web界面，安装mongoDB  
```bash
sudo apt-get install mongodb
```
安装完成之后，在reporting.conf里将mongodb下的enable改为"yes"  

使用推荐的PostgreSQL，安装PostgreSQL(和mysql作用一样，所以如果安装mysql就不需要安装这个了)  
```bash
sudo apt-get install postgresql libpq-dev
```

安装virtualbox  
```bash
sudo apt-get install virtualbox
```
创建hostonly类型的网卡：  
```bash
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
VBoxManage dhcpserver remove --ifname vboxnet0
```
把用户加到vboxusers组：  
```bash
sudo usermod -a -G vboxusers hello
```
系统重启后，virtualbox无法自动启动相应虚拟网卡，使用如下命令配置：
```bash
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
```

通过iptables简单设置一下网络，运行iptables_set.sh即可  
注意 -o 指定的网卡是上网网卡  
在示例基础上调整了一下：限制对内网的访问，去掉错误的同网段间可访问的规则(因为位置靠后，根本不会触发)  

安装使用inetsim  
```bash
# 建一个ubuntu虚机，做如下操作
su
echo "deb http://www.inetsim.org/debian/ binary/" > /etc/apt/sources.list.d/inetsim.list
wget -O - http://www.inetsim.org/inetsim-archive-signing-key.asc | apt-key add -
apt update
apt install inetsim

## nfqueue-bindings 没安装成功，遇到问题再说（&&&&&&&）
# sudo apt install cmake
# sudo apt install libnetfilter-queue-dev
# sudo apt install swig
# wget https://github.com/chifflier/nfqueue-bindings/archive/v0.6.tar.gz

# 设置ipv4网络：192.168.56.103/255.255.255 网关：192.168.56.1
# 将/etc/inetsim/inetsim.conf备份，并对原文件做修改，启动inetsim
# 我做的改动：将service_bind_address和dns_default_ip取消注释，值改成本机ip
inetsim --conf /etc/inetsim/inetsim.conf
```
修改配置文件routing.conf，把inetsim下的enabled改为"yes"  

启动rooter的命令  
```bash
cuckoo rooter -g hello --sudo
```