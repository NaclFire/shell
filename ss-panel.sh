#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
install_ss_panel_mod_v3(){
	yum -y remove httpd
	yum install -y unzip zip git
	yum update -y nss curl libcurl 
	num=$1
	if [ "${num}" != "1" ]; then
  	  wget -c --no-check-certificate https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/lnmp1.6.zip && unzip lnmp1.6.zip && rm -rf lnmp1.6.zip && cd lnmp1.6 && chmod +x install.sh && ./install.sh lnmp
	fi
	cd /home/wwwroot/
	# 移动phpmyadmin
	mv default/phpmyadmin/ .
	cd default
	rm -rf index.html
	#克隆项目
	git clone -b master https://github.com/NaclFire/SSPanel-Uim.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	git config core.filemode false
	wget https://getcomposer.org/installer -O composer.phar
	#复制配置文件
	cp config/.config.example.php config/.config.php
	#移除防跨站攻击(open_basedir)
	cd /home/wwwroot/default
	chattr -i public/.user.ini
	chattr -i .user.ini
	rm -rf .user.ini
	#下载配置文件
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/nginx.conf
	wget -N -P /usr/local/php/etc/ --no-check-certificate https://raw.githubusercontent.com/NaclFire/ss-panel-v3-mod_Uim/master/php.ini
	service nginx restart
	/etc/init.d/php-fpm restart
	#导入数据库
	mysql -uroot -psspanel -e"create database sspanel;" 
	mysql -uroot -psspanel -e"use sspanel;" 
	mysql -uroot -psspanel sspanel < /home/wwwroot/default/sql/glzjin_all.sql
	cd /home/wwwroot/default
	#安装composer
	php composer.phar
	php composer.phar install
	#设置文件权限
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	php xcat syncusers
	php xcat initQQWry
	php xcat resetTraffic
	php xcat initdownload
	chattr +i public/.user.ini
	yum -y install vixie-cron crontabs
	echo '30 22 * * * php /www/wwwroot/default/xcat sendDiaryMail' >> /etc/crontab
	echo '0 0 * * * php -n /www/wwwroot/default/xcat dailyjob' >> /etc/crontab
	echo '*/1 * * * * php /www/wwwroot/default/xcat checkjob' >> /etc/crontab
	echo '*/1 * * * * php /www/wwwroot/default/xcat syncnode' >> /etc/crontab
	crontab /etc/crontab
}

install_node(){
	wget https://raw.githubusercontent.com/SuicidalCat/Airport-toolkit/master/ssr_node_c7.sh && chmod +x ssr_node_c7.sh && ./ssr_node_c7.sh
}

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo
echo "#############################################################"
echo "# One click Install SS-panel								  #"
echo "# 1  SS-V3_mod_panel One click Install                      #"
echo "# 2  SS-node modwebapi One click Install                    #"
echo "#############################################################"
echo
num=$1
if [ "${num}" == "1" ]; then
    install_ss_panel_mod_v3 1
else
    stty erase '^H' && read -p " Please enter number:" num
		case "$num" in
		1)
		install_ss_panel_mod_v3 $1
		;;
		2)
		install_node
		;;
		*)
		echo "Please enter the correct number"
		;;
	esac
fi

