#!/bin/bash
ODEV="eth1"   #外网网卡   
IDEV="eth0"    #内网网卡   
 
UP="2560kbps"    #上行总带宽：注意单位其实应该是KB/S，TC写法如此没办法，如下同单位。   
DOWN="2560kbps"   #下行总带宽   
 
UPLOADrate="128kbps"     #限速范围IP上行保证带宽   
UPLOADceil="384kbps"     #限速范围IP上行最大带宽   
DOWNLOADrate="128kbps"   #限速范围IP下行保证带宽   
DOWNLOADceil="200kbps"   #限速范围IP下行最大带宽   
 
INET="192.168.2."    #限速网段   
 
IPS="1"                 #限速范围起始IP   
IPE="240"                 #限速范围结束IP   
EXPEND="241"             #限速例外的范围
 
outdown="512kbps"      #不在限速范围IP共享（总）下行速度   
outup="512kbps"        #不在限速范围IP共享（总）上行速度    
 
tc qdisc del dev $ODEV root 2>/dev/null       #清除队列规则（初始化）   
tc qdisc del dev $IDEV root 2>/dev/null   
 
tc qdisc add dev $ODEV root handle 10: htb default 2254        #设置根队列   
tc qdisc add dev $IDEV root handle 10: htb default 2254  
 
tc class add dev $ODEV parent 10: classid 10:1 htb rate $UP ceil $UP             #设置总速度   
tc class add dev $IDEV parent 10: classid 10:1 htb rate $DOWN ceil $DOWN  

#block
i=$IPS;   
while [ $i -le $IPE ]   
do   
	tc class add dev $ODEV parent 10:1 classid 10:2$i htb rate $UPLOADrate ceil $UPLOADceil prio 1   
	tc qdisc add dev $ODEV parent 10:2$i handle 100$i: pfifo   
	tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i   
	tc class add dev $IDEV parent 10:1 classid 10:2$i htb rate $DOWNLOADrate ceil $DOWNLOADceil prio 1   
	tc qdisc add dev $IDEV parent 10:2$i handle 100$i: pfifo   
	tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i   
	iptables -t mangle -A PREROUTING -s $INET$i -j MARK --set-mark 2$i   
	iptables -t mangle -A POSTROUTING -d $INET$i -j MARK --set-mark 2$i   
	i=`expr $i + 1`   
done  
#expect

E="241";   
while [ $E -le $EXPEND ]   
do   
	tc class add dev $ODEV parent 10:1 classid 10:2$E htb rate $outup ceil $outup prio 1   
	tc qdisc add dev $ODEV parent 10:2$E handle 100$E: pfifo   
	tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2$E fw classid 10:2$E  
	tc class add dev $IDEV parent 10:1 classid 10:2$E htb rate $outdown ceil $outdown prio 1   
	tc qdisc add dev $IDEV parent 10:2$E handle 100$E: pfifo   
	tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2$E fw classid 10:2$E 
	iptables -t mangle -A PREROUTING -s $INET$E -j MARK --set-mark 2$E   
	iptables -t mangle -A POSTROUTING -d $INET$E -j MARK --set-mark 2$E  
	E=`expr $E + 1`   
done  



##accept
ALLUP="2500kbps"
ALLDOWN="2500kbps"
tc class add dev $ODEV parent 10:1 classid 10:2254 htb rate $ALLUP ceil $ALLUP prio 1   
tc qdisc add dev $ODEV parent 10:2254 handle 100254: pfifo   
tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254   
 
tc class add dev $IDEV parent 10:1 classid 10:2254 htb rate $ALLDOWN ceil $ALLDOWN prio 1   
tc qdisc add dev $IDEV parent 10:2254 handle 100254: pfifo   
tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2254 fw classid 10:2254   
 
