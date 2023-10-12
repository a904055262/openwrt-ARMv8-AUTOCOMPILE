#!/usr/bin/env bash

# 大佬打好补丁的包
# https://github.com/immortalwrt/immortalwrt/tree/openwrt-23.05/package/network/utils/fullconenat
# https://github.com/immortalwrt/luci/tree/openwrt-23.05/applications/luci-app-firewall
# https://github.com/immortalwrt/immortalwrt/tree/openwrt-23.05/package/network/config/firewall


#脚本所在路径
sdir=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)
cd "$sdir"


# base system > firwall
# network > firewall > iptables-mod-fullconenat
# luci > applications > luci-app-firewall

declare -A dlAddr
dlAddr=(
[firewall]=https://github.com/immortalwrt/immortalwrt/branches/openwrt-23.05/package/network/config/firewall
#[luci-app-firewall]=https://github.com/immortalwrt/luci/branches/openwrt-23.05/applications/luci-app-firewall
[fullcone]=https://github.com/immortalwrt/immortalwrt/branches/openwrt-23.05/package/network/utils/fullconenat
)

echo '开始下载其他补丁包'

mkdir -p fullcone3patch
cd fullcone3patch

for d in "${!dlAddr[@]}";do
	echo "-下载大佬打过补丁的: $d"
	rm -rf $d
	
	for i in {1..100};do
		echo $i
		
		if svn export "${dlAddr[$d]}" $d >/dev/null;then
			echo -成功
			break
		fi
		
		if (( i == 100));then 
			echo "下载$d失败，脚本退出，请重新运行脚本，尝试重新下载"
			exit 1
		fi
		
		sleep 1
		
		let i++ 
	done

done 

cd ..


patchlucifirewall(){
	# 给luci-app-firewall 打补丁
	echo 开始给 luci-app-firewall 打补丁

	local zonejs=feeds/luci/applications/luci-app-firewall/htdocs/luci-static/resources/view/firewall/zones.js
	if [ ! -f $zonejs ];then
		echo 找不到zonejs
		exit 1
	fi

	if grep -q 'Full-cone' $zonejs;then
		echo 已经打过了
		return 0
	fi

	cp $zonejs $zonejs.bak 

	local tmf=$(mktemp)
	cat <<-'EOF' > $tmf
		o = s.option(form.Flag, 'fullcone', _('Full-cone NAT'));
	EOF

	#cat $tmf

	local linenum=$(sed -n '/drop_invalid/{
			=;q
		}' $zonejs)
	if [ ! "$linenum" ];then
		echo 找不到修改点
		exit 1
	fi

	sed -i "$linenum r $tmf
		" $zonejs

	echo luci-app-firewall 打补丁-成功
	
}

patchlucifirewall


#exit

echo '开始替换源文件'
cd fullcone3patch

declare -A rPath
rPath=(
[firewall]='../package/network/config/'
[fullcone]='../package/'
#[luci-app-firewall]='../feeds/luci/applications/'
)

for d in $(ls);do
	echo "替换 $d"
	rm -rf "${rPath[$d]}$d"
	cp -rf $d "${rPath[$d]}"
done

rm -rf ../tmp
echo '替换完成'







