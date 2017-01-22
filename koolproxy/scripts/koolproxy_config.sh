#! /bin/sh
eval `dbus export koolproxy`


if [ "$koolproxy_enable" == "1" ];then
	sh /koolshare/koolproxy/koolproxy.sh restart  > /tmp/koolproxy_run.log
else
	sh /koolshare/koolproxy/koolproxy.sh stop  > /tmp/koolproxy_run.log
fi
echo XU6J03M6 >> /tmp/koolproxy_run.log
sleep 1
rm -rf /tmp/koolproxy_run.log