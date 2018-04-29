#! /bin/sh
eval `dbus export koolproxy`

# stop first
[ "$koolproxy_enable" == "1" ] && sh /koolshare/koolproxy/kp_config.sh stop

# remove old files
rm -rf /koolshare/bin/koolproxy >/dev/null 2>&1
rm -rf /koolshare/init.d/*koolproxy.sh
rm -rf /koolshare/scripts/koolproxy*
rm -rf /koolshare/webs/Module_koolproxy.asp
rm -rf /koolshare/koolproxy/*.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/koolproxy >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/*.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/koolproxy_ipset.conf >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/openssl.cnf >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/rules/*.dat >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/rules/daily.txt >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/rules/koolproxy.txt >/dev/null 2>&1

# remove old ss event
cd /tmp
dbus list __|grep koolproxy |cut -d "=" -f1 | sed 's/-A/iptables -t nat -D/g'|sed 's/^/dbus remove /g' > remove.sh && chmod 777 remove.sh && ./remove.sh


# copy new files
cd /tmp
mkdir -p /koolshare/koolproxy
mkdir -p /koolshare/koolproxy/data
cp -rf /tmp/koolproxy/scripts/* /koolshare/scripts/
cp -rf /tmp/koolproxy/webs/* /koolshare/webs/
cp -rf /tmp/koolproxy/res/* /koolshare/res/
if [ ! -f /koolshare/koolproxy/data/rules/user.txt ];then
	cp -rf /tmp/koolproxy/koolproxy /koolshare/
else
	mv /koolshare/koolproxy/data/rules/user.txt /tmp/user.txt.tmp
	cp -rf /tmp/koolproxy/koolproxy /koolshare/
	mv /tmp/user.txt.tmp /koolshare/koolproxy/data/rules/user.txt
fi
cp -f /tmp/koolproxy/uninstall.sh /koolshare/scripts/uninstall_koolproxy.sh

chmod 755 /koolshare/koolproxy/*
chmod 755 /koolshare/koolproxy/data/*
chmod 755 /koolshare/scripts/*
[ ! -L "/koolshare/bin/koolproxy" ] && ln -sf /koolshare/koolproxy/koolproxy /koolshare/bin/koolproxy
[ ! -L "/koolshare/init.d/S98koolproxy.sh" ] && ln -sf /koolshare/koolproxy/kp_config.sh /koolshare/init.d/S98koolproxy.sh
rm -rf /tmp/koolproxy* >/dev/null 2>&1

[ -z "$koolproxy_policy" ] && dbus set koolproxy_policy=1
[ -z "$koolproxy_acl_default_mode" ] && dbus set koolproxy_acl_default_mode=1
dbus set softcenter_module_koolproxy_install=1
dbus set softcenter_module_koolproxy_version=3.7.2
dbus set koolproxy_version=3.7.2


[ "$koolproxy_enable" == "1" ] && sh /koolshare/koolproxy/kp_config.sh restart


