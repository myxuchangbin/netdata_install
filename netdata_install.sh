#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

#=================================================================#
#   Script Name: netdata.sh                                       #
#   System Required: Centos Ubuntu Debian                         #
#   Description:                                                  #
#   Version Number: Beta 1.0.1                                    #
#   Updated: 2019-04-17                                           #
#=================================================================#

# 判断用户是否为root
# Make sure only root can run our script
rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error: This script must be run as root!" 1>&2
       exit 1
    fi
}

##检测是否可以联网
checknetwork(){
    ping -c 3 114.114.114.114 &>/dev/null
    if [ ! $?  -eq 0 ];then
        echo -e "\033[31m error: Please check your network connection.  \033[0m"
        exit
    fi
}

# Check OS
checkos(){
    if [ -f /etc/redhat-release ];then
        OS='CentOS'
        if centosversion 5; then
            echo "Not support CentOS 5, please change OS to CentOS 6+ and retry."
            exit 1
        fi
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS='Debian'
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS='Ubuntu'
    else
        echo "Not support OS, Please reinstall OS to CentOS 6+/Debian 7+/Ubuntu 12+ and retry!"
        exit 1
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# firewall set
firewall_set(){
    if [ "$OS" == "CentOS" ];then
        echo "Firewall set start..."
        if centosversion 6; then
            /etc/init.d/iptables status > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                iptables -L -n | grep 19999 | grep 'ACCEPT' > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 19999 -j ACCEPT
                    /etc/init.d/iptables save
                    /etc/init.d/iptables restart
                else
                    echo "port 19999 has been set up."
                fi
            else
                echo "WARNING: iptables looks like shutdown or not installed, please manually set it if necessary."
            fi
        elif centosversion 7; then
            systemctl status firewalld > /dev/null 2>&1
            if [ $? -eq 0 ];then
                firewall-cmd --zone=public --list-all | grep 19999 > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                    firewall-cmd --permanent --zone=public --add-port=19999/tcp
                    firewall-cmd --reload
                fi
            else
                echo "Firewalld looks like not running !"
            fi
        fi
        echo "firewall set completed..."
    elif [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian" ];then
        echo "Warning: Please manually configure your firewall"
    fi
}

# Check selinux
disable_selinux(){
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" == "SELINUX=enforcing" ]; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
fi
        if [ "$CHECK" == "SELINUX=permissive" ]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
        fi
            if [ "$CHECK" == "SELINUX=disabled" ]; then
                echo "SELINUX is disable."
            fi
}

zip_check(){
if [ "$OS" == "CentOS" ];then
    yum install -y epel-release
    yum install -y wget bash-completion net-tools gcc-c++ autoconf automake curl gcc git libuv-devel libmnl-devel libuuid-devel lm_sensors make cmake MySQL-python nc pkgconfig python python-psycopg2 PyYAML zlib-devel python-yaml iproute python-pymongo libmnl
    if [ $? -ne 0 ]; then
        echo "netdata依赖软件安装出错，请联系作者。"
        exit 1
    fi
    # check_tar/unzip
    tar --version >/dev/null 2>&1
    [ ! $?  -eq 0 ]&&yum install -y tar &&echo "yum install tar"
    unzip -v >/dev/null 2>&1
    [ ! $?  -eq 0 ]&&yum install -y unzip &&echo "yum installing unzip"
elif [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian" ];then
    sudo apt-get install -y wget bash-completion sysv-rc-conf axel zlib1g-dev uuid-dev libmnl-dev libuv-dev gcc make cmake git autoconf autoconf-archive autogen automake pkg-config curl iproute  python python-yaml python-pymongo python-psycopg2
    if [ $? -ne 0]; then
        echo "netdata依赖软件安装出错，请联系作者。"
        exit 1
    fi
    tar --version >/dev/null 2>&1
    [ ! $?  -eq 0 ]&&apt-get install -y tar &&echo "install tar"
    unzip -v >/dev/null 2>&1
    [ ! $?  -eq 0 ]&&apt-get install -y unzip &&echo "installing unzip"
fi
}


# Install netdata
install_netdata(){
    if [ -e /etc/netdata/netdata.conf ]; then
        cd /opt/netdata
        if [ "$OS" == "CentOS" ]; then
            if centosversion 6; then
                cp -rf /opt/netdata/system/netdata-init-d /etc/init.d/netdata
                chmod +x /etc/init.d/netdata
                chkconfig netdata on
                service netdata start
            elif centosversion 7; then
                systemctl enable netdata
                systemctl start netdata
            fi
        elif [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian" ]; then
            cp -rf /opt/netdata/system/netdata-lsb /etc/init.d/netdata
            chmod +x /etc/init.d/netdata
            update-rc.d netdata defaults
            sysv-rc-conf netdata on
            systemctl start netdata
        fi
        echo netdata is installed!
        exit 0
    else
        cd /opt
        rm -rf /opt/netdata
        git clone https://github.com/firehol/netdata.git --depth=100
        cd /opt/netdata
        echo | bash netdata-installer.sh
        if [ -e /etc/netdata/netdata.conf ]; then
            cd /opt/netdata
            if [ "$OS" == "CentOS" ]; then
                if centosversion 6; then
                    cp -rf /opt/netdata/system/netdata-init-d /etc/init.d/netdata
                    chmod +x /etc/init.d/netdata
                    chkconfig netdata on
                    service netdata start 
                elif centosversion 7; then
                    systemctl enable netdata
                    systemctl start netdata
                fi
            elif [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian" ]; then
                cp -rf /opt/netdata/system/netdata-lsb /etc/init.d/netdata
                chmod +x /etc/init.d/netdata
                update-rc.d netdata defaults
                sysv-rc-conf netdata on
                systemctl start netdata
            fi
        fi
        if [ $? -eq 0 ];then
            echo netdata Installation success!
        else
            echo "netdata安装失败，请联系作者"
            exit 1
        fi
    fi
}

# Set netdata
set_netdata(){
 # 配置自动更新netdata
 cat /etc/crontab | grep '/opt/netdata/netdata-updater.sh' > /dev/null 2>&1
 if [ $? -ne 0 ]; then
    echo "0 2 * * * root /opt/netdata/netdata-updater.sh >/dev/null 2>&1" >> /etc/crontab
 fi
 # 内存去重，可以节省 40%-60% 的内存开销
 echo 1 >/sys/kernel/mm/ksm/run; echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs 
 cat /etc/rc.local | grep sleep_millisecs > /dev/null 2>&1
 if [ $? -ne 0 ]; then
    echo "echo 1 >/sys/kernel/mm/ksm/run" >> /etc/rc.local
    echo "echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs" >> /etc/rc.local
 fi
 if [ "$OS" == "CentOS" ]; then
    ipurl=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`:19999
 elif [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian" ]; then
    ipurl=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|awk -F: '{print $2}'`:19999
 fi
 
 echo "--------------------"
 echo "请在浏览器打开{$ipurl} 打开实时性能和健康监测界面！"
 echo "更多详情请查看官网文档：https://github.com/firehol/netdata"
 echo "--------------------"
}

# START #
    
checknetwork            #判断网络
rootness                #判断用户是否为root
checkos                 #判断操作系统
firewall_set            #防火墙开放19999端口
disable_selinux         #禁用selinux
zip_check               #安装解压工具及依赖软件
install_netdata         #安装netdata
set_netdata             #配置netdata

# END #
