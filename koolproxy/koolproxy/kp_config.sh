#! /bin/sh

# shadowsocks script for arm router with kernel 2.6.36.4 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export koolproxy_`
SOFT_DIR=/koolshare
KP_DIR=$SOFT_DIR/koolproxy
lan_ipaddr=$(nvram get lan_ipaddr)
LOCK_FILE=/var/lock/koolproxy.lock
#=======================================

set_lock(){
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}

unset_lock(){
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

get_lan_cidr(){
	netmask=`nvram get lan_netmask`
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
	x=${1%%$3*}
	suffix=$(( $2 + (${#x}/4) ))
	#prefix=`nvram get lan_ipaddr | cut -d "." -f1,2,3`
	echo $lan_ipaddr/$suffix
}

write_sourcelist(){
	if [ -n "$koolproxy_sourcelist" ];then
		echo $koolproxy_sourcelist|sed 's/>/\n/g' > $KP_DIR/data/source.list
	else
		cat > $KP_DIR/data/source.list <<-EOF
			1|koolproxy.txt|https://kprule.com/koolproxy.txt|
			1|daily.txt|https://kprule.com/daily.txt|
			1|kp.dat|https://kprule.com/kp.dat|
			1|user.txt||
			
		EOF
	fi
	
	if [ -n "$koolproxy_custom_rule" ];then
		echo $koolproxy_custom_rule| base64_decode |sed 's/\\n/\n/g' > $KP_DIR/data/rules/user.txt
		dbus remove koolproxy_custom_rule
	fi
}

start_koolproxy(){
	write_sourcelist
	echo_date 开启koolproxy主进程！
	[ ! -L "$KSROOT/bin/koolproxy" ] && ln -sf $KSROOT/koolproxy/koolproxy $KSROOT/bin/koolproxy
	cd $KP_DIR && koolproxy --mark -d
	[ "$?" != "0" ] && dbus set koolproxy_enable=0 && exit 1
}

stop_koolproxy(){
	if [ -n "`pidof koolproxy`" ];then
		echo_date 关闭koolproxy主进程...
		kill -9 `pidof koolproxy` >/dev/null 2>&1
		killall koolproxy >/dev/null 2>&1
	fi
}

creat_start_up(){
	[ ! -L "/koolshare/init.d/S98koolproxy.sh" ] && {
		echo_date 加入开机自动启动...
		ln -sf /koolshare/koolproxy/kp_config.sh /koolshare/init.d/S98koolproxy.sh
	}
}

write_nat_start(){
	echo_date 添加nat-start触发事件...
	dbus set __event__onnatstart_koolproxy="/koolshare/koolproxy/kp_config.sh"
}

remove_nat_start(){
	[ -n "`dbus get __event__onnatstart_koolproxy`" ] && {
		echo_date 删除nat-start触发...
		dbus remove __event__onnatstart_koolproxy
	}
}

add_ipset_conf(){
	if [ "$koolproxy_mode" == "2" ];then
		echo_date 添加黑名单软连接...
		rm -rf /jffs/configs/dnsmasq.d/koolproxy_ipset.conf
		ln -sf /koolshare/koolproxy/data/koolproxy_ipset.conf /jffs/configs/dnsmasq.d/koolproxy_ipset.conf
		dnsmasq_restart=1
	fi
}

remove_ipset_conf(){
	if [ -L "/jffs/configs/dnsmasq.d/koolproxy_ipset.conf" ];then
		echo_date 移除黑名单软连接...
		rm -rf /jffs/configs/dnsmasq.d/koolproxy_ipset.conf
		dnsmasq_restart=1
	fi
}

restart_dnsmasq(){
	if [ "$dnsmasq_restart" == "1" ];then
		echo_date 重启dnsmasq进程...
		service restart_dnsmasq > /dev/null 2>&1
	fi
}

write_reboot_job(){
	# start setvice
	if [ "1" == "$koolproxy_reboot" ]; then
		echo_date 开启插件定时重启，每天"$koolproxy_reboot_hour"时"$koolproxy_reboot_min"分，自动重启插件...
		cru a koolproxy_reboot "$koolproxy_reboot_min $koolproxy_reboot_hour * * * /bin/sh $KP_DIR/kp_config.sh restart"
	elif [ "2" == "$koolproxy_reboot" ]; then
		echo_date 开启插件间隔重启，每隔"$koolproxy_reboot_inter_hour"时"$koolproxy_reboot_inter_min"分，自动重启插件...
		cru a koolproxy_reboot "*/$koolproxy_reboot_inter_min */$koolproxy_reboot_inter_hour * * * /bin/sh $KP_DIR/kp_config.sh restart"
	fi
}

remove_reboot_job(){
	jobexist=`cru l|grep koolproxy_reboot`
	# kill crontab job
	if [ -n "$jobexist" ];then
		echo_date 关闭插件定时重启...
		sed -i '/koolproxy_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

creat_ipset(){
	xt=`lsmod | grep xt_set`
	OS=$(uname -r)
	if [ -z "$xt" ] && [ -f "/lib/modules/${OS}/kernel/net/netfilter/xt_set.ko" ];then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
	echo_date 创建ipset名单
	ipset -N white_kp_list nethash
	ipset -N black_koolproxy iphash
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"
	for ip in $ip_lan
	do
		ipset -A white_kp_list $ip >/dev/null 2>&1

	done
	ipset -A black_koolproxy 110.110.110.110 >/dev/null 2>&1
}

get_mode_name() {
	case "$1" in
		0)
			echo "不过滤"
		;;
		1)
			echo "http模式"
		;;
		2)
			echo "http + https"
		;;
	esac
}

get_jump_mode(){
	case "$1" in
		0)
			echo "-j"
		;;
		*)
			echo "-g"
		;;
	esac
}

get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "KOOLPROXY_HTTP"
		;;
		2)
			echo "KOOLPROXY_HTTPS"
		;;
	esac
}

factor(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

flush_nat(){
	if [ -n "`iptables -t nat -S|grep KOOLPROXY`" ];then
		echo_date 移除nat规则...
		cd /tmp
		iptables -t nat -S | grep -E "KOOLPROXY|KOOLPROXY_HTTP|KOOLPROXY_HTTPS" | sed 's/-A/iptables -t nat -D/g'|sed 1,3d > clean.sh && chmod 777 clean.sh && ./clean.sh > /dev/null 2>&1 && rm clean.sh
		iptables -t nat -X KOOLPROXY > /dev/null 2>&1
		iptables -t nat -X KOOLPROXY_HTTP > /dev/null 2>&1
		iptables -t nat -X KOOLPROXY_HTTPS > /dev/null 2>&1
	fi
	[ -n "`ipset -L -n|grep black_koolproxy`" ] && ipset -F black_koolproxy > /dev/null 2>&1 && ipset -X black_koolproxy > /dev/null 2>&1
	[ -n "`ipset -L -n|grep white_kp_list`" ] && ipset -F white_kp_list > /dev/null 2>&1 && ipset -X white_kp_list > /dev/null 2>&1
}

lan_acess_control(){
	# lan access control
	[ -z "$koolproxy_acl_default_mode" ] && koolproxy_acl_default_mode=1
	acl_nu=`dbus list koolproxy_acl_mode_|sort -n -t "_" -k 4|cut -d "=" -f 1 | cut -d "_" -f 4`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get koolproxy_acl_ip_$acl`
			mac=`dbus get koolproxy_acl_mac_$acl`
			proxy_name=`dbus get koolproxy_acl_name_$acl`
			proxy_mode=`dbus get koolproxy_acl_mode_$acl`
			[ "$koolproxy_acl_method" == "1" ] && echo_date 加载ACL规则：【$ipaddr】【$mac】模式为：$(get_mode_name $proxy_mode)
			[ "$koolproxy_acl_method" == "2" ] && mac="" && echo_date 加载ACL规则：【$ipaddr】模式为：$(get_mode_name $proxy_mode)
			[ "$koolproxy_acl_method" == "3" ] && ipaddr="" && echo_date 加载ACL规则：【$mac】模式为：$(get_mode_name $proxy_mode)
			iptables -t nat -A KOOLPROXY $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -p tcp $(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
		done
		echo_date 加载ACL规则：其余主机模式为：$(get_mode_name $koolproxy_acl_default_mode)
	else
		echo_date 加载ACL规则：所有模式为：$(get_mode_name $koolproxy_acl_default_mode)
	fi
}

load_nat(){
	nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	i=120
	# laod nat rules
	until [ -n "$nat_ready" ]
	do
	    i=$(($i-1))
	    if [ "$i" -lt 1 ];then
	        echo_date "Could not load nat rules!"
	        sh /koolshare/koolproxy/kp_config.sh stop
	        exit
	    fi
	    sleep 1
		nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	done
	
	echo_date 加载nat规则！
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	# 创建KOOLPROXY nat rule
	iptables -t nat -N KOOLPROXY
	# 局域网地址不走KP
	iptables -t nat -A KOOLPROXY -m set --match-set white_kp_list dst -j RETURN
	#  生成对应CHAIN
	iptables -t nat -N KOOLPROXY_HTTP
	iptables -t nat -A KOOLPROXY_HTTP -p tcp -m multiport --dport 80 -j REDIRECT --to-ports 3000
	iptables -t nat -N KOOLPROXY_HTTPS
	iptables -t nat -A KOOLPROXY_HTTPS -p tcp -m multiport --dport 80,443 -j REDIRECT --to-ports 3000
	# 局域网控制
	lan_acess_control
	# 剩余流量转发到缺省规则定义的链中
	iptables -t nat -A KOOLPROXY -p tcp -j $(get_action_chain $koolproxy_acl_default_mode)
	# 重定所有流量到 KOOLPROXY
	# 全局模式和视频模式
	[ "$koolproxy_mode" == "1" ] || [ "$koolproxy_mode" == "3" ] && iptables -t nat -I PREROUTING 1 -p tcp -j KOOLPROXY
	# ipset 黑名单模式
	[ "$koolproxy_mode" == "2" ] && iptables -t nat -I PREROUTING 1 -p tcp -m set --match-set black_koolproxy dst -j KOOLPROXY
}

dns_takeover(){
	lan_ipaddr=`nvram get lan_ipaddr`
	#chromecast=`iptables -t nat -L PREROUTING -v -n|grep "dpt:53"`
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
	if [ "$koolproxy_mode" == "2" ]; then
		if [ -z "$chromecast_nu" ]; then
			echo_date 黑名单模式开启DNS劫持
			iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
		fi
	fi
}

detect_cert(){
	if [ ! -f $KP_DIR/data/private/ca.key.pem ]; then
		echo_date 检测到首次运行，开始生成koolproxy证书，用于https过滤！
		echo_date 生成证书需要较长时间，请一定耐心等待！！！
		cd $KP_DIR/data && sh gen_ca.sh
		echo_date 证书生成完毕！！！
	fi
}

case $ACTION in
start)
	#开机触发，wan重启触发，所以需要先关后开
	set_lock
	if [ "$koolproxy_enable" == "1" ];then
		logger "[软件中心]: 启动koolproxy插件！"
		rm -rf /tmp/user.txt && ln -sf /koolshare/koolproxy/data/rules/user.txt /tmp/user.txt
		remove_reboot_job
		flush_nat
		stop_koolproxy
		remove_ipset_conf && restart_dnsmasq
		detect_cert
		start_koolproxy
		add_ipset_conf && restart_dnsmasq
		creat_ipset
		load_nat
		dns_takeover
		write_nat_start
		write_reboot_job
		creat_start_up
	else
		logger "[软件中心]: koolproxy插件未开启，不启动！"
	fi
	unset_lock
	;;
restart)
	#web提交触发，需要先关后开
	# now stop
	set_lock
	echo_date ================================ 关闭 ===============================
	rm -rf /tmp/user.txt && ln -sf /koolshare/koolproxy/data/rules/user.txt /tmp/user.txt
	remove_reboot_job
	remove_ipset_conf && restart_dnsmasq
	remove_nat_start
	flush_nat
	stop_koolproxy
	# now start
	echo_date ============================ koolproxy启用 ===========================
	detect_cert
	start_koolproxy
	add_ipset_conf && restart_dnsmasq
	creat_ipset
	load_nat
	dns_takeover
	write_nat_start
	write_reboot_job
	creat_start_up
	echo_date koolproxy启用成功，请等待日志窗口自动关闭，页面会自动刷新...
	echo_date =====================================================================
	unset_lock
	;;
stop)
	#web提交触发，需要先关后开
	set_lock
	echo_date ================================ 关闭 ===============================
	rm -rf /tmp/user.txt
	remove_reboot_job
	remove_ipset_conf && restart_dnsmasq
	remove_nat_start
	flush_nat
	stop_koolproxy
	echo_date koolproxy插件已关闭
	echo_date =====================================================================
	unset_lock
	;;
stop_nat)
	set_lock
	flush_nat
	unset_lock
	;;
*)
	set_lock
	#WAN_ACTION=`ps|grep /jffs/scripts/wan-start|grep -v grep`
	if [ "$koolproxy_enable" == "1" ] ;then
		remove_reboot_job
		remove_ipset_conf && restart_dnsmasq
		remove_nat_start
		flush_nat
		stop_koolproxy
		detect_cert
		start_koolproxy
		add_ipset_conf && restart_dnsmasq
		creat_ipset
		load_nat
		dns_takeover
		write_nat_start
		write_reboot_job
		creat_start_up
	fi
	unset_lock
	;;
esac