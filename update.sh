#!/bin/sh

#get latest rules
cd koolproxy/koolproxy/data/rules
rm -rf *
wget --no-check-certificate https://kprule.com/koolproxy.txt
wget --no-check-certificate https://kprule.com/daily.txt
wget --no-check-certificate https://kprule.com/kp.dat
wget --no-check-certificate https://kprule.com/user.txt