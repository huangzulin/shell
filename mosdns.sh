#!/bin/bash

mkdir -p /root/mosdns

arch=""
case $(uname -m) in
    x86_64) arch="amd64" ;;
    aarch64)    arch="arm64" ;;
esac

mosdns_download_url=https://fastgit.org/IrineSistiana/mosdns-cn/releases/latest/download/mosdns-cn-linux-$arch.zip

wget -N --no-check-certificate $mosdns_download_url -O mosdns-cn.zip && unzip -p mosdns-cn.zip mosdns-cn >/root/mosdns/mosdns-cn && rm mosdns-cn.zip

chmod +x /root/mosdns/mosdns-cn

cat >/root/mosdns/config.yaml << EOL
server_addr: ":5353"
cache_size: 20000
lazy_cache_ttl: 86400
lazy_cache_reply_ttl: 0
redis_cache: ""
min_ttl: 0
max_ttl: 0
hosts: []
blacklist_domain: []
insecure: false
ca: []
debug: false
log_file: ""
upstream: []
local_upstream:
  - 119.29.29.29
  - 223.5.5.5
local_ip:
  - "geoip.dat:cn"
local_domain:
  - "geosite.dat:cn"
local_latency: 50
remote_upstream:
  - udpme://8.8.8.8
  - udpme://1.1.1.1
  - tls://1.1.1.1:853
  - https://dns.cloudflare.com/dns-query
  - tls://dot-jp.blahdns.com:443
  - https://doh-jp.blahdns.com/dns-query
remote_domain:
  - "geosite.dat:geolocation-!cn"
working_dir: ""
cd2exe: false

EOL
cd /root/mosdns && ./mosdns-cn --service install --config config.yaml

cat >/root/mosdns/update-geo.sh << EOL
#!/bin/bash

wget -O /root/mosdns/geoip.dat https://fastgit.org/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -O /root/mosdns/geosite.dat https://fastgit.org/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
/root/mosdns/mosdns-cn --service restart
EOL

chmod +x /root/mosdns/update-geo.sh

bash /root/mosdns/update-geo.sh

/root/mosdns/mosdns-cn --service start

crontab -l | { cat; echo "30 30 6 * * /root/mosdns/update-geo.sh 2>&1 >> null"; } | crontab -
