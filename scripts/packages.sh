#!/bin/bash
	
NEW_PKG_DIR="./new"

# REPLACE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
# 调用示例
# REPLACE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# REPLACE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。
REPLACE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" $NEW_PKG_DIR/$REPO_NAME

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find $NEW_PKG_DIR/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} $NEW_PKG_DIR/ \;
		rm -rf $NEW_PKG_DIR/$REPO_NAME
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $NEW_PKG_DIR/$REPO_NAME $NEW_PKG_DIR/$PKG_NAME
	fi
}

# UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

# 替换软件包
REPLACE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
REPLACE_PACKAGE "v2ray-geodata" "sbwml/v2ray-geodata" "master"

REPLACE_PACKAGE "luci-app-athena-led" "NONGFAH/luci-app-athena-led" "main"
chmod +x $NEW_PKG_DIR/luci-app-athena-led/root/etc/init.d/athena_led $NEW_PKG_DIR/luci-app-athena-led/root/usr/sbin/athena-led

GO_VERSION_MAJOR_MINOR=$(grep -Po "GO_VERSION_MAJOR_MINOR:=\K.*" ../feeds/packages/lang/golang/golang/Makefile)
if [[ -n $GO_VERSION_MAJOR_MINOR ]] && dpkg --compare-versions "$GO_VERSION_MAJOR_MINOR" lt 1.24; then
	echo "update golang version from $GO_VERSION_MAJOR_MINOR to 1.24"
	rm -rf ../feeds/packages/lang/golang
	git clone --depth=1 --single-branch --branch 24.x https://github.com/sbwml/packages_lang_golang ../feeds/packages/lang/golang
fi

# istore首页及网络向导
UPDATE_PACKAGE "quickstart" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-quickstart" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
#UPDATE_PACKAGE "quickstart" "master-yun-yun/package-istore" "Immortalwrt" "pkg"
#UPDATE_PACKAGE "luci-app-quickstart" "master-yun-yun/package-istore" "Immortalwrt" "pkg"

# istore商店
UPDATE_PACKAGE "luci-app-store" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"

# luci-app-athena-led-雅典娜led屏幕显示（第一个源显示效果不好）
#UPDATE_PACKAGE "luci-app-athena-led" "haipengno1/luci-app-athena-led" "main"
UPDATE_PACKAGE "luci-app-athena-led" "NONGFAH/luci-app-athena-led" "main"
#-------------------2025.04.12-测试-----------------#
# 添加雅典娜LED执行权限
if [ -d "luci-app-athena-led" ]; then
    chmod +x luci-app-athena-led/root/etc/init.d/athena_led
    chmod +x luci-app-athena-led/root/usr/sbin/athena-led
    echo "Added execute permissions for athena_led files."
fi

# 更新软件包版本
# UPDATE_VERSION "sing-box"
