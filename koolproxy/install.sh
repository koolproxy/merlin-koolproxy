#! /bin/sh
eval `dbus export koolproxy`

# stop first
dbus set koolproxy_enable=0
[ -f /koolshare/koolproxy/koolproxy.sh ] && sh /koolshare/koolproxy/koolproxy.sh stop
[ -f /koolshare/koolproxy/kp_config.sh ] && sh /koolshare/koolproxy/kp_config.sh stop
# remove old files
rm -rf /koolshare/bin/koolproxy >/dev/null 2>&1
rm -rf /koolshare/koolproxy/koolproxy.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/nat_load.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/*.dat >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/*.txt >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/*.conf >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/gen_ca.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/openssl.cnf >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/version >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/serial >/dev/null 2>&1
rm -rf /koolshare/koolproxy/rule_store


# copy new files
cd /tmp
mkdir -p /koolshare/koolproxy
mkdir -p /koolshare/koolproxy/data
cp -rf /tmp/koolproxy/bin/* /koolshare/bin/
cp -rf /tmp/koolproxy/scripts/* /koolshare/scripts/
cp -rf /tmp/koolproxy/webs/* /koolshare/webs/
cp -rf /tmp/koolproxy/res/* /koolshare/res/
cp -rf /tmp/koolproxy/koolproxy/kp_config.sh /koolshare/koolproxy/
cp -rf /tmp/koolproxy/koolproxy/rule_store /koolshare/koolproxy/
cp -rf /tmp/koolproxy/koolproxy/data/koolproxy_ipset.conf /koolshare/koolproxy/data/
cp -rf /tmp/koolproxy/koolproxy/data/gen_ca.sh /koolshare/koolproxy/data/
cp -rf /tmp/koolproxy/koolproxy/data/openssl.cnf /koolshare/koolproxy/data/
cp -rf /tmp/koolproxy/koolproxy/data/version /koolshare/koolproxy/data/
if [ ! -f /koolshare/koolproxy/data/user.txt ];then
	cp -rf /tmp/koolproxy/koolproxy /koolshare/
else
	mv /koolshare/koolproxy/data/user.txt /tmp/user.txt.tmp
	cp -rf /tmp/koolproxy/koolproxy /koolshare/
	mv /tmp/user.txt.tmp /koolshare/koolproxy/data/user.txt
fi
if [ ! -d /koolshare/koolproxy/data/certs ];then
	cp -rf /tmp/koolproxy/koolproxy/data/certs /koolshare/koolproxy/data/
fi
if [ ! -d /koolshare/koolproxy/data/certs ];then
	cp -rf /tmp/koolproxy/koolproxy/data/private /koolshare/koolproxy/data/
fi

cp -f /tmp/koolproxy/uninstall.sh /koolshare/scripts/uninstall_koolproxy.sh


cd /

chmod 755 /koolshare/bin/koolproxy
chmod 755 /koolshare/koolproxy/*
chmod 755 /koolshare/koolproxy/data/*
chmod 755 /koolshare/scripts/*

rm -rf /tmp/koolproxy* >/dev/null 2>&1

[ -z "$koolproxy_policy" ] && dbus set koolproxy_policy=1
[ -z "$koolproxy_acl_default_mode" ] && dbus set koolproxy_acl_default_mode=1
[ -z `dbus list koolproxy_rule_name_` ] && dbus set koolproxy_rule_name_1="视频规则(new)" && dbus set koolproxy_rule_name_2="静态规则(new)"
[ -z `dbus list koolproxy_rule_address_` ] && dbus set koolproxy_rule_address_1="http://entware.mirrors.ligux.com/koolproxy/1.dat" && && dbus set koolproxy_rule_address_2="http://entware.mirrors.ligux.com/koolproxy/koolproxy.txt"
[ -z `dbus list koolproxy_rule_load_` ] && dbus set koolproxy_rule_load_1="1" && dbus set koolproxy_rule_load_2="1"
[ -z `dbus list koolproxy_rule_date_` ] && dbus set koolproxy_rule_date_1="Mar 27 10:02" && dbus set koolproxy_rule_date_2="Mar 27 10:02"

dbus set koolproxy_rule_info=`cat /koolshare/koolproxy/data/version | awk 'NR==2{print}'`
dbus set koolproxy_video_info=`cat /koolshare/koolproxy/data/version | awk 'NR==4{print}'`
dbus set softcenter_module_koolproxy_install=1
dbus set softcenter_module_koolproxy_version=3.3.5
dbus set koolproxy_version=3.3.5

