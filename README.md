## netdata一键安装脚本
### netdata介绍
netdata 是一个分布式实时性能和健康监控系统。netdata 可以实时监控的操作系统和应用程序（如 Web服务器软件 和 数据库服务器软件），并通过现代化的 Web 界面表现出来。netdata 非常的快速和高效，其可以在 物理或虚拟服务器、容器、IoT设备上持续运行。

目前 netdata 可以运行在：Linux 发行版、FreeBSD 和 MacOS 上。

netdata源码：https://github.com/firehol/netdata

官方虽然提供了一键安装脚本（相信我，这跟那些坑爹的 lnmp 的一键安装脚本不一样，自从用过那些脚本后，我再也不相信“一键”了……）和一键依赖安装脚本（如果你懒到连 apt-get 或 yum 都不愿意用的话），你只需要使用 git clone 整个仓库然后运行安装脚本就好了。

为了以后经常安装使用，所以将git clone的安装方式步骤写成了脚本。


### 脚本介绍
netdata官方演示：https://my-netdata.io/

操作系统：支持CentOS6+、Ubuntu12+、Debian6+

脚本特性：
1. 自动优化netdata占用内存问题

### 安装方式

    wget https://raw.githubusercontent.com/myxuchangbin/netdata_install/master/netdata_install.sh && bash netdata_install.sh 

	
### 问题反馈
欢迎大家反馈问题
