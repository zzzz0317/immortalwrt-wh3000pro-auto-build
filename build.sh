#!/bin/bash
cd immortalwrt

cat ../wh3000pro.config > .config
echo "make defconfig"
make defconfig || { echo "defconfig failed"; exit 1; }
echo "diff initial config and new config:"
diff ../wh3000pro.config .config
echo "diff initial config and new config (from old config only):"
diff ../wh3000pro.config .config | grep -e "^<" | grep -v "^< #"
echo "diff initial config and new config (from new config only):"
diff ../wh3000pro.config .config | grep -e "^>" | grep -v "^> #"
echo "check device exist"
grep -Fxq "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y" .config || exit 1

year=$(date +%y)
month=$(date +%-m)
day=$(date +%-d)
hour=$(date +%-H)
zz_build_date=$(date "+%Y-%m-%d %H:%M:%S %z")
zz_build_uuid=$(uuidgen)

echo "zz_build_date=${zz_build_date}"
echo "zz_build_uuid=${zz_build_uuid}"
cat > files/etc/uci-defaults/zzzz-version << EOF
#!/bin/sh
sed -i "1i ZZ_DISTRIB_NAME='ImmortalWrt for Huasifei WH3000 Pro'" /etc/openwrt_release
sed -i "2i ZZ_DISTRIB_VERSION='R${year}.${month}.${day}.${hour}'" /etc/openwrt_release
/bin/sync
EOF
echo "ZZ_BUILD_ID='${zz_build_uuid}'" > files/etc/zz_build_id
echo "ZZ_BUILD_HOST='$(hostname)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_USER='$(whoami)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_DATE='${zz_build_date}'" >> files/etc/zz_build_id
echo "ZZ_BUILD_REPO_HASH='$(cd .. && git rev-parse HEAD)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_IMM_HASH='$(git rev-parse HEAD)'" >> files/etc/zz_build_id

MAKE_V=${1:-0}
echo "make immortalwrt"
make V=$MAKE_V -j$(nproc) || {
    echo "make failed";
    if [ "$MAKE_V" -eq 0 ]; then
        echo "Retrying with make V=s -j1";
        make V=s -j1 || { echo "Retry failed"; exit 1; }
    else
        exit 1;
    fi
}