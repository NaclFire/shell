#ss-panel-v3-mod_UIChanges
#Author: 十一
#Blog: blog.67cc.cn
#Time：2018-8-25 11:05:33
#!/bin/bash

#check root
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
function check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "你的系统为[${release} ${bit}],检测${Green} 可以 ${Font}搭建。"
	else 
	echo -e "你的系统为[${release} ${bit}],检测${Red} 不可以 ${Font}搭建。"
	echo -e "${Yellow} 正在退出脚本... ${Font}"
	exit 0;
	fi
}
function install_ss_panel_mod_UIm(){
    yum remove httpd -y
	yum install unzip zip git -y
	wget -c --no-check-certificate https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/lnmp1.6.zip && unzip lnmp1.6.zip && rm -rf lnmp1.6.zip && cd lnmp1.6 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/
	cp -r default/phpmyadmin/ .  #复制数据库
	cd default
	rm -rf index.html
	yum update nss curl iptables -y
	#克隆项目
	git clone -b master https://github.com/NaclFire/SSPanel-Uim.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	#复制配置文件
	cp config/.config.example.php config/.config.php
	#移除防跨站攻击(open_basedir)
	cd /home/wwwroot/default
	chattr -i .user.ini
	rm -rf .user.ini
	sed -i 's/^fastcgi_param PHP_ADMIN_VALUE/#fastcgi_param PHP_ADMIN_VALUE/g' /usr/local/nginx/conf/fastcgi.conf
    /etc/init.d/php-fpm restart
    /etc/init.d/nginx reload
	#设置文件权限
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	#下载配置文件
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate "https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/nginx.conf"
	wget -N -P /usr/local/php/etc/ --no-check-certificate "https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/php.ini"
	#开启scandir()函数
	sed -i 's/,scandir//g' /usr/local/php/etc/php.ini
	service nginx restart #重启Nginx
	mysql -hlocalhost -uroot -proot <<EOF
create database sspanel;
use sspanel;
source /home/wwwroot/default/sql/glzjin_all.sql;
EOF
	cd /home/wwwroot/default
	#安装composer
	wget https://getcomposer.org/installer -O composer.phar
	php composer.phar
	php composer.phar install
	php xcat syncusers            #同步用户
	php xcat initQQWry            #下载IP解析库
	php xcat resetTraffic         #重置流量
	php xcat initdownload         #下载ssr程式
	#创建监控
	echo '30 22 * * * php /www/wwwroot/default/xcat sendDiaryMail' >> /etc/crontab
	echo '0 0 * * * php -n /www/wwwroot/default/xcat dailyjob' >> /etc/crontab
	echo '*/1 * * * * php /www/wwwroot/default/xcat checkjob' >> /etc/crontab
	echo '*/1 * * * * php /www/wwwroot/default/xcat syncnode' >> /etc/crontab
	crontab /etc/crontab
}



#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"
Notification="${Yellow}[Notification]${Font}"

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
clear
check_system
sleep 2
install_ss_panel_mod_UIm