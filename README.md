# global-over-greatfirewall
一个全局翻墙的组件，使用openvpn, chinaroute, chinadns, dhcp等组合完成实现**全局的 国内外访问流量的 智能分流**

# 安装步骤
1. 首先需要一台不在墙内的服务器，比如香港或是一个vpn专线服务器。在该服务器配置openvpn server, 在你的网关服务器配置openvpn client，在server端开启全局代理  
配置文件参考  
  openvpn-server.conf  
  openvpn-client.conf  
  ccd/

2. 获取国内的IP列表http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest, 推列表中的IP段到本地国内网关，让流量从国内出去。github有项目可以提取国内的列表，或者自己写脚本筛  
配置文件参考  
  ip-pre-up   #这是我筛完的
  
3. 获取正确的DNS，由于国内的DNS被**荼毒污染**的，解析的地址**不正确**，所以使用ChinaDNS获取到正确的IP。在本地网关上搭建ChinaDNS，项目地址  https://github.com/shadowsocks/ChinaDNS    
    运行ChinaDNS  
    cd ChinaDNS-1.x.x  
    ./configure && make  
    src/chinadns -m -c chnroute.txt

4. 配置DHCP服务器，分发所有客户端的DNS为路由网关的IP

5. 配置nat  
-A POSTROUTING -s 192.168.x.0/24 ! -d 10.1.100.0/24 -j SNAT --to-source x.x.x.x        #192.168.x.0/24为你的本地网络内网网段，掩码什么的自行匹配。x.x.x.x为你的额公网IP地址  
-A POSTROUTING -s 192.168.x.0/24 -o tun0 -j MASQUERADE    #配置你的流量经过openvpn client 网络接口tun0（一般默认）出去

6. plugin目录里包含网络限速功能及openvpn自动恢复功能，后者需要添加到crond

7. 启动方式可以参考rc.local, 或者可以放在openvpn-client.conf里启动，不过后者更慢
