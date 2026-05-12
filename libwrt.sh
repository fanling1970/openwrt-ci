#!/bin/bash
./scripts/feeds update -a

# 修改默认IP
sed -i 's/192.168.1.1/192.168.192.1/g' package/base-files/files/bin/config_generate

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 雅典娜LED屏幕控制
# rm -rf feeds/luci/applications/luci-app-athena-led
rm -rf package/emortal/luci-app-athena-led
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led

# 网络速度诊断测试
rm -rf feeds/packages/net/speedtest-cli
git clone --depth=1 https://github.com/sirpdboy/luci-app-netspeedtest package/luci-app-netspeedtest

# openwrt常用软件包
rm -rf feeds/luci/applications/{*passwall,*homeproxy,*mosdns,*smartdns}
rm -rf feeds/packages/net/{adguardhome,mosdns,smartdns}
git clone --depth=1 https://github.com/kenzok8/openwrt-packages package/custom1
mkdir -p package/kenzo
mv package/custom1/{*adguardhome,*ddnsto,*argon-*,*-argon,*lucky,*smartdns}  package/kenzo/
rm -rf package/custom1

# 科学上网插件
git clone --depth=1 https://github.com/kenzok8/small package/custom2
mkdir -p package/small
mv package/custom2/{*fchomo,*homeproxy,*mosdns,*nikki,*passwall,trojan,trojan-go,mihomo,ssocks,shadow-tls,shadowsocksr-libev,v2dat,v2ray-geoview}  package/small/
rm -rf package/custom2

./scripts/feeds update -a
./scripts/feeds install -a
