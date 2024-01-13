wget -qO- https://static.qchwnd.moe/shell-helpers/azure-cipv2-srv.sh | bash
跑完这个之后，去改 /etc/azure-cip 填写的具体东西都要放在单引号内。
这个文件中，前面的
tenant=''
app=''
pwd=''
subs=''
rg=''
vm=''
这些前三个是 API 的部分，后三个分别是账号的订阅名、资源组、机器名称。
中间的
auth_email=''
auth_key=''
auth_header='X-Auth-Key'
dns_ttl='300'
zone_name=''
record_name=''
这些是提供给 CF DDNS 用的。auth_key 是 Global Key，zone_name 是母域名（如 baidu.com），record_name 是子域名（如 pan.baidu.com）。如果自己有运行其它 DDNS 服务，可以不填这些。
最后的 port='' 填的是探测墙的具体端口，比如说节点服务端口为 1234 那就填 1234 即可。
全部填完之后运行 systemctl enable azure-cip
全部填完之后运行 systemctl restart azure-cip
