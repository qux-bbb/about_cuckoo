#!/bin/bash
# 一条命令错误即退出
set -o errexit

# 参考: https://cuckoo.sh/docs/installation/host/index.html

# 供保存下载文件和部分组件使用
cuckoo_dir=~/for_cuckoo
if [ ! -d "${cuckoo_dir}" ]
then
    mkdir ${cuckoo_dir}
fi

sudo apt update

# 安装python2和依赖库
sudo apt install python python-dev libffi-dev libssl-dev -y
sudo apt install python-setuptools python-pip -y
sudo apt install libjpeg-dev zlib1g-dev swig -y
pip install virtualenv


# 创建虚拟环境并启用
cd  ${cuckoo_dir}
python -m virtualenv venv
. venv/bin/activate


# 安装mongoDB以使用网页接口
sudo apt install mongodb -y


# 安装PostgreSQL以使用该数据库
sudo apt install postgresql libpq-dev -y


# 安装yara
# 安装依赖
cd ${cuckoo_dir}
sudo apt install automake libtool make gcc pkg-config -y
sudo apt install flex bison -y
sudo apt install libjansson-dev -y
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


# 安装pydeep
# 安装依赖
cd ${cuckoo_dir}
sudo apt install libfuzzy-dev g++ -y
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
python setup.py install


# 安装mitmproxy
cd ${cuckoo_dir}
wget https://snapshots.mitmproxy.org/6.0.2/mitmproxy-6.0.2-linux.tar.gz
tar -zxvf mitmproxy-6.0.2-linux.tar.gz
sudo ln -s ${cuckoo_dir}/mitmdump /usr/local/bin/mitmdump
sudo ln -s ${cuckoo_dir}/mitmproxy /usr/local/bin/mitmproxy
sudo ln -s ${cuckoo_dir}/mitmweb /usr/local/bin/mitmweb
# &&&&&&& 暂时没找到不进入交互模式就生成证书的方法，待改进
# 可以简单运行一下mitmproxy（直接执行命令：mitmproxy），使其生成证书（~/.mitmproxy文件夹下），然后Ctrl+C退出
echo "will run mitmproxy to generate cert, you can press 'Ctrl+C' to quit the process"
echo "please press 'Enter' to continue"
read enter_key
mitmproxy


# 安装tcpdump
sudo apt install tcpdump apparmor-utils -y
sudo aa-disable /usr/sbin/tcpdump
# 设置不需要管理员权限启动tcpdump
sudo groupadd pcap
sudo usermod -a -G pcap `whoami`
sudo chgrp pcap /usr/sbin/tcpdump
# 安装setcap
sudo apt install libcap2-bin -y
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
# 确认结果
getcap /usr/sbin/tcpdump


# 安装volatility
cd ${cuckoo_dir}
sudo apt install unzip -y
wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip
unzip volatility_2.6_lin64_standalone.zip 
cd volatility_2.6_lin64_standalone/
sudo ln -s ${cuckoo_dir}/volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone /usr/local/bin/volatility


# 安装M2Crypto(这里装的是0.37.1版本)
cd ${cuckoo_dir}
. venv/bin/activate
pip install m2crypto


# # 安装guacd(缺少包) // &&&&&&& 待解决
# sudo apt install libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd -y

# 手动安装（configure出错，提示缺少libpng） // &&&&&&&
# sudo apt install libcairo2-dev 	libjpeg62-turbo-dev libpng-dev libtool-bin libossp-uuid-dev freerdp2-dev -y
# mkdir /tmp/guac-build && cd /tmp/guac-build
# wget https://downloads.apache.org/guacamole/1.2.0/source/guacamole-server-1.2.0.tar.gz
# tar -zxvf guacamole-server-1.2.0.tar.gz && cd guacamole-server-1.2.0
# ./configure --with-init-dir=/etc/init.d
# make && sudo make install && cd ..
# sudo ldconfig
# sudo /etc/init.d/guacd start


# 安装cuckoo
cd ${cuckoo_dir}
. venv/bin/activate
pip install -U pip setuptools
pip install -U cuckoo
# 执行一下cuckoo，生成初始的cwd：cuckoo
cuckoo
# 复制mitmproxy证书到对应路径下：
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 ~/.cuckoo/analyzer/windows/bin/cert.p12


# 设置mysql
# 安装mysql
sudo apt install mysql-server mysql-client libmysqlclient-dev -y
cd ${cuckoo_dir}
. venv/bin/activate
pip install mysql-python

the_name='mysql_cuckoo'
the_pass=`echo $RANDOM+$RANDOM+$RANDOM | md5sum | base64`

# 执行SQL语句：
# mysql默认用户root密码为空
sudo mysql -uroot -e "
CREATE DATABASE IF NOT EXISTS cuckoo default charset utf8 COLLATE utf8_general_ci;
create user '${the_name}'@'localhost' identified by '${the_pass}';
grant all privileges on cuckoo.* to '${the_name}'@'localhost';
"
# 更新配置文件 有问题，暂时到最后输出，先注释
mysql_connection="connection = mysql://${the_name}:${the_pass}@localhost/cuckoo?charset=utf8"
# sed -i "s/connection = /${mysql_connection}/g" ~/.cuckoo/conf/cuckoo.conf


# 安装virtualbox
sudo apt install virtualbox -y
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
# 把用户加到vboxusers组
sudo usermod -a -G vboxusers `whoami`

# 系统重启后，virtualbox无法自动启动相应虚拟网卡，使用如下命令配置：
# # If the hostonly interface vboxnet0 does not exist already.
# VBoxManage hostonlyif create
# # Configure vboxnet0.
# VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

# 通过iptables简单设置一下网络，运行iptables_set.sh即可
# 注意 -o 指定的网卡是上网网卡
# 在示例基础上调整了一下：限制对内网的访问，去掉同网段间可访问的规则

# 安装使用inetsim
# # 建一个ubuntu虚机，做如下操作
# su
# echo "deb http://www.inetsim.org/debian/ binary/" > /etc/apt/sources.list.d/inetsim.list
# wget -O - http://www.inetsim.org/inetsim-archive-signing-key.asc | apt-key add -
# apt update
# apt install inetsim

# ## nfqueue-bindings 没安装成功，遇到问题再说（&&&&&&&）
# # sudo apt install cmake -y
# # sudo apt install libnetfilter-queue-dev -y
# # sudo apt install swig -y
# # wget https://github.com/chifflier/nfqueue-bindings/archive/v0.6.tar.gz

# # 设置网络：192.168.56.103/255.255.255 网关：192.168.56.1
# # 将/etc/inetsim/inetsim.conf备份，并对原文件做修改，启动inetsim
# inetsim --conf /etc/inetsim/inetsim.conf
# # 我做的改动：将service_bind_address和dns_default_ip取消注释，值改成本机ip

# 启动rooter的命令
# cuckoo rooter -g `whoami` --sudo


# 退出python虚拟环境
deactivate

# 输出mysql信息供配置修改
echo "Please update cuckoo.conf, mysql info:"
echo ${mysql_connection}