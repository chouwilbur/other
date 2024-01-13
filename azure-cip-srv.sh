#!/bin/bash
apt update
apt install -y jq
rm -f /etc/azure-cip
cat >> /etc/azure-cip << EOF
tenant=''
appid=''
passwd=''
subs=''
group=''
vm=''

auth_email=''
auth_key=''
auth_header='X-Auth-Key'
dns_ttl='300'
zone_name=''
record_name=''

port=''
EOF
rm -f /opt/azure-cip.sh
cat >> /opt/azure-cip.sh << EOF
#!/bin/bash

source /etc/azure-cip

zone_id=\$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=\$zone_name" \\
	-H "X-Auth-Email: \$auth_email" \\
	-H "\$auth_header: \$auth_key" \\
	-H "Content-Type: application/json" \\
	| grep -Po '(?<="id":")[^"]*' \\
	| head -1)
record_id=\$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records?name=\$record_name" \\
	-H "X-Auth-Email: \$auth_email" \\
	-H "\$auth_header: \$auth_key" \\
	-H "Content-Type: application/json" \\
	| grep -Po '(?<="id":")[^"]*' \\
	| head -1)
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records/\$record_id" \\
	-H "X-Auth-Email: \$auth_email" \\
	-H "\$auth_header: \$auth_key" \\
	-H "Content-Type: application/json" \\
	--data "{\"id\":\"\$zone_id\",\"type\":\"A\",\"name\":\"\$record_name\",\"content\":\"\$(curl -s -4 https://api.optage.moe/ip.php)\",\"ttl\":\"\$dns_ttl\"}"

while true
do

	i=1
	while [ \$i -le 5 ]
	do
		ip=\$(curl -s -4 https://api.optage.moe/ip.php)
		gfw=\$(curl -4 -fsL --write-out %{http_code} --output /dev/null --max-time 5 "https://1314756652-ent9iaxw7r-gz.scf.tencentcs.com/?host=\$ip&port=\$port" 2>&1)
		if [ \$gfw -eq "200" ]
		then
			break
		fi
		sleep 2
		let i++
	done

	if [ \$i -eq 6 ]
	then
		token=\$(curl -X POST -d "grant_type=client_credentials&client_id=\$appid&client_secret=\$passwd&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/\$tenant/oauth2/token" | jq -r .access_token)
		curl -X GET "https://api.optage.moe/azure/cip.php?token=\$token&subs=\$subs&group=\$group&vm=\$vm" &
		curl -X POST -d "" -H "Authorization: Bearer \$token" "https://management.azure.com/subscriptions/\$subs/resourceGroups/\$group/providers/Microsoft.Compute/virtualMachines/\$vm/deallocate?api-version=2022-08-01"
	fi

	sleep 90
done
EOF
chmod +x /opt/azure-cip.sh
rm -f /etc/systemd/system/azure-cip.service
cat >> /etc/systemd/system/azure-cip.service << EOF
[Unit]
Description=azure-cip
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
Type=simple
User=root
Restart=always
RestartSec=10
WorkingDirectory=/opt
ExecStart=/opt/azure-cip.sh
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable azure-cip
