#! /bin/sh

sh /koolshare/koolproxy/koolproxy.sh stop
rm -rf /koolshare/bin/koolproxy >/dev/null 2>&1
rm -rf /koolshare/koolproxy/koolproxy.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/nat_load.sh >/dev/null 2>&1
rm -rf /koolshare/koolproxy/data/1.dat
rm -rf /koolshare/koolproxy/data/koolproxy.txt
rm -rf /koolshare/koolproxy/data/koolproxy_ipset.conf
rm -rf /koolshare/koolproxy/data/gen_ca.sh
rm -rf /koolshare/koolproxy/data/openssl.cnf
rm -rf /koolshare/koolproxy/data/serial
rm -rf /koolshare/koolproxy/data/serial
rm -rf /koolshare/koolproxy/data/version


