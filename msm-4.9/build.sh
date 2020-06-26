#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
DTBIMAGE="dtb"
DEFCONFIG=c330ae-perf_defconfig
TC_DIR=~/bin/aarch64-linux-android-4.9/bin
# https://github.com/1582130940/android_prebuilts_clang_host_linux-x86_llvm-Snapdragon-6.0.9
CC_DIR=~/bin/llvm-Snapdragon-6.0.9/bin
export DTC_EXT=dtc
export CROSS_COMPILE=${TC_DIR}/aarch64-linux-android-

# Kernel Details
VER=".v01"

# Paths
KERNEL_DIR=`pwd`
TOOLS_DIR=/mnt/android/kernel/bin
REPACK_DIR=/mnt/android/kernel/bin/AnyKernel3
PATCH_DIR=/mnt/android/kernel/bin/AnyKernel3/patch
MODULES_DIR=/mnt/android/kernel/bin/AnyKernel3/modules/system/lib/modules
ZIP_MOVE=/mnt/android/kernel/bin/out/
ZIMAGE_DIR=${KERNEL_DIR}/out/arch/arm64/boot

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		cd $KERNEL_DIR/out/kernel
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make O=out clean && make O=out mrproper
}

function make_kernel {
		echo
		make O=out $DEFCONFIG $THREAD
		make O=out $THREAD

}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		#$TOOLS_DIR/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/
		mkdtimg create $REPACK_DIR/dtbo.img --page_size=4096 `find out/arch/arm64/boot/dts -name "*.dtbo"`
}

function make_boot {
		cp -vr $ZIMAGE_DIR/Image.gz ${REPACK_DIR}/zImage
}


function make_zip {
		cd ${REPACK_DIR}
		zip -r9 `echo $AK_VER`.zip *
		mv `echo $AK_VER`.zip ${ZIP_MOVE}
		
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making AndroPlus Kernel:"
echo "-----------------"
echo -e "${restore}"


# Vars
BASE_AK_VER="AndroPlus-C330"
AK_VER="$BASE_AK_VER$VER"
export LOCALVERSION=~`echo $AK_VER`
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=AndroPlus
export KBUILD_BUILD_HOST=andro.plus

echo

while read -p "Do you want to clean stuffs (y/N)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		break
		;;
esac
done

make_kernel
#make_dtb
make_modules
make_boot
make_zip

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
