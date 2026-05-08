#!/bin/bash
id
df -h
free -h
cat /proc/cpuinfo

echo "update submodules"
# git submodule update --init --recursive --remote || { echo "submodule update failed"; exit 1; }
git submodule update --init --recursive || { echo "submodule init failed"; exit 1; }

if [ -d "immortalwrt" ]; then
    echo "repo dir exists"
    cd immortalwrt
    git pull || { echo "git pull failed"; exit 1; }
    git reset --hard HEAD
    git clean -fd
else
    echo "repo dir not exists"
    git clone -b openwrt-25.12 --single-branch --filter=blob:none "https://github.com/immortalwrt/immortalwrt" || { echo "git clone failed"; exit 1; }
    cd immortalwrt
fi

# reset rust package Makefile
if [ -f "feeds/packages/lang/rust/Makefile" ]; then
   bash -c "cd feeds/packages && git checkout -- \"lang/rust/Makefile\""
fi

echo "add feeds"
cat feeds.conf.default > feeds.conf
echo "" >> feeds.conf
# echo "src-git qmodem https://github.com/FUjr/QModem.git;main" >> feeds.conf
# echo "src-git qmodem https://github.com/zzzz0317/QModem.git;v2.8.11" >> feeds.conf
echo "src-git qmodem https://github.com/zzzz0317/QModem.git;v3.0.2" >> feeds.conf
echo "update files"
rm -rf files
cp -r ../files .

echo "update feeds"
./scripts/feeds update -a || { echo "update feeds failed"; exit 1; }
echo "install feeds"
./scripts/feeds install -a || { echo "install feeds failed"; exit 1; }
./scripts/feeds install -a -f -p qmodem || { echo "install qmodem feeds failed"; exit 1; }

if [ -L "package/zz-packages" ]; then
    echo "package/zz-packages is already a symlink"
else
    if [ -d "package/zz-packages" ]; then
        echo "package/zz-packages directory exists, removing it"
        rm -rf package/zz-packages
    fi
    ln -s ../../zz-packages package/zz-packages
    echo "Created symlink package/zz-packages -> ../../zz-packages"
fi

# echo "Fix Rust build remove CI LLVM download"
# if [ -f "feeds/packages/lang/rust/Makefile" ]; then
#     sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "feeds/packages/lang/rust/Makefile"
# fi
