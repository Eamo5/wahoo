#!/bin/bash
## Wahoo Kernel Build Script by @Eamo5
# Syntax - ./makewahoo.sh (branch) (gcc-version) (clean) (date)
# eg. ./makewahoo.sh sultan-q gcc-9.1 clean dd-mm-yy
# If no parameters are passed, the script defaults to the current branch with GCC 8. LOWERCASE ONLY!

## To add:
# * Variable increment when using release parameter
# * Detect uncommited work and present confirmation prompt

## Directories

KERNEL_DIR=${HOME}/kernels/builds/wahoo/
TOOLCHAIN_DIR=${HOME}/kernels/toolchains/
SULTAN_ZIP=${HOME}/kernels/zip-wahoo-sultan/
SULTAN_Q_ZIP=${HOME}/kernels/zip-wahoo-sultan-q/
SULTAN_UNIFIED_ZIP=${HOME}/kernels/zip-wahoo-sultan-unified/
ALT_ZIP=${HOME}/kernels/zip-wahoo/
ZIP_OUTPUT_DIR=${HOME}/kernels/zips/
if  [ "$3" == "clean" ]; then
	VERSION_DATE=$4
else
	VERSION_DATE=$3
fi

## Kernel Directory

cd $KERNEL_DIR

## Build environment

export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=Eamo5
export KBUILD_BUILD_HOST=HotBox

# Check for specified GCC parameters. If no valid argument passed, use GCC 8 by default.
case $2 in
	gcc-9.1)
		# Arch Linux Packages (aarch64-linux-gnu-gcc & arm-none-eabi-gcc)
		export CROSS_COMPILE="ccache aarch64-linux-gnu-"
		export CROSS_COMPILE_ARM32="ccache arm-none-eabi-" ;;
	bare-metal-gcc-9.1)
		# https://github.com/kdrag0n/aarch64-elf-gcc
		export CROSS_COMPILE="ccache ${TOOLCHAIN_DIR}aarch64-elf-gcc/bin/aarch64-elf-"
		# https://github.com/kdrag0n/arm-eabi-gcc
		export CROSS_COMPILE_ARM32="ccache ${TOOLCHAIN_DIR}arm-eabi-gcc/bin/arm-eabi-" ;;
	linaro)
		# https://github.com/arter97/linaro-64
		export CROSS_COMPILE="ccache ${TOOLCHAIN_DIR}linaro-64/bin/aarch64-linux-gnu-"
		export CROSS_COMPILE_ARM32="ccache ${TOOLCHAIN_DIR}arm-eabi-gcc/bin/arm-eabi-" ;;
	gcc-8)
		# https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/8.1.0/x86_64-gcc-8.1.0-nolibc-aarch64-linux.tar.xz
		export CROSS_COMPILE="ccache ${TOOLCHAIN_DIR}aarch64-linux-8.1.0/bin/aarch64-linux-"
		# https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/8.1.0/x86_64-gcc-8.1.0-nolibc-arm-linux-gnueabi.tar.xz
		export CROSS_COMPILE_ARM32="ccache ${TOOLCHAIN_DIR}arm-linux-gnueabi-8.1.0/bin/arm-linux-gnueabi-" ;;
	*)
		echo "No valid toolchain selected... using GCC 8 by default."
		export CROSS_COMPILE="ccache ${TOOLCHAIN_DIR}aarch64-linux-8.1.0/bin/aarch64-linux-"
		export CROSS_COMPILE_ARM32="ccache ${TOOLCHAIN_DIR}arm-linux-gnueabi-8.1.0/bin/arm-linux-gnueabi-" ;;
esac

## Checkout

case $1 in
	sultan)
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi
		git checkout sultan
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi ;;
	sultan-q)
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi
		git checkout sultan-q
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi ;;
	sultan-unified)
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi
		git checkout sultan-qp-unified
		if  [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
			git reset --hard
		fi ;;
	*)
		echo "No valid branch provided. Not switching branches..."
		:
esac

## Prebuild Summary

echo ""
echo "Summary:"
echo ""
echo "Building = "$1""
echo "Date / Version = "$VERSION_DATE""
echo "Toolchain = "$2""
if [ "$3" == "clean" ] || [ "$4" == "clean" ]; then
	echo "Source = clean"
else
	echo "Source = dirty"
fi
echo ""

## Make

make -j$(nproc) clean
make -j$(nproc) mrproper
make -j$(nproc) O=out clean
make -j$(nproc) O=out mrproper
if [ "$1" == "sultan" ] || [ "$1" == "sultan-q" ] || [ "$1" == "sultan-unified" ]; then
	make -j$(nproc) O=out wahoo_defconfig
else
	echo "Please run make -j$(nproc) <defconfig> first!"
	echo "Trying to build anyway..."
fi
	make -j$(nproc) O=out || exit


## AnyKernel2

case $1 in
	sultan)
		cp ${KERNEL_DIR}out/arch/arm64/boot/Image.lz4-dtb ${SULTAN_ZIP}Image.lz4-dtb
		cp ${KERNEL_DIR}out/arch/arm64/boot/dtbo.img ${SULTAN_ZIP}dtbo.img ;;
	sultan-q)
		cp ${KERNEL_DIR}out/arch/arm64/boot/Image.lz4-dtb ${SULTAN_Q_ZIP}Image.lz4-dtb
		cp ${KERNEL_DIR}out/arch/arm64/boot/dtbo.img ${SULTAN_Q_ZIP}dtbo.img ;;
	sultan-unified)
		cp ${KERNEL_DIR}out/arch/arm64/boot/Image.lz4-dtb ${SULTAN_UNIFIED_ZIP}Image.lz4-dtb
		cp ${KERNEL_DIR}out/arch/arm64/boot/dtbo.img ${SULTAN_UNIFIED_ZIP}dtbo.img ;;
	other)
		cp ${KERNEL_DIR}out/arch/arm64/boot/Image.lz4-dtb ${ALT_ZIP}kernel/Image.lz4
		cp ${KERNEL_DIR}out/arch/arm64/boot/dtbo.img ${ALT_ZIP}dtbo.img
		cp ${KERNEL_DIR}out/arch/arm64/boot/dts/qcom/msm8998-v2.1-soc.dtb ${ALT_ZIP}dtbs/msm8998-v2.1-soc.dtb ;;
	*)
		echo "You're on your own for zipping.."
		exit ;;
esac

## Zip

case $1 in
	sultan)
		cd ${SULTAN_ZIP}
		rm *.zip
		if [ "$2" == "gcc-9.1" ]; then
			zip -r Sultan-Kernel-"$VERSION_DATE"-GCC-9.zip *
		else
			zip -r Sultan-Kernel-"$VERSION_DATE".zip *
		fi ;;
	sultan-q)
		cd ${SULTAN_Q_ZIP}
		rm *.zip
		if [ "$2" == "gcc-9.1" ]; then
			zip -r Sultan-Kernel-Q-"$VERSION_DATE"-GCC-9.zip *
		else
			zip -r Sultan-Kernel-Q-"$VERSION_DATE".zip *
		fi ;;
	sultan-unified)
		cd ${SULTAN_UNIFIED_ZIP}
		rm *.zip
		if [ "$2" == "gcc-9.1" ]; then
			zip -r Sultan-Kernel-+-"$VERSION_DATE"-GCC-9.zip *
		else
			zip -r Sultan-Kernel-+-"$VERSION_DATE".zip *
		fi ;;
	other)
		cd ${ALT_ZIP}
		rm *.zip
		zip -r Custom-Wahoo.zip * 
		echo "Using Caesium installer...";;
	*)
		echo "No defined zip directory. Not zipping..." ;;
esac 

## Output

case $1 in
	sultan)
		if [ "$2" == "gcc-9.1" ]; then
			cp ${SULTAN_ZIP}Sultan-Kernel-"$VERSION_DATE"-GCC-9.zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-"$VERSION_DATE"-GCC-9.zip
		else
			cp ${SULTAN_ZIP}Sultan-Kernel-"$VERSION_DATE".zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-"$VERSION_DATE".zip
		fi
		echo "Done" ;;
	sultan-q)
		if [ "$2" == "gcc-9.1" ]; then
			cp ${SULTAN_Q_ZIP}Sultan-Kernel-Q-"$VERSION_DATE"-GCC-9.zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-Q-"$VERSION_DATE"-GCC-9.zip
		else
			cp ${SULTAN_Q_ZIP}Sultan-Kernel-Q-"$VERSION_DATE".zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-Q-"$VERSION_DATE".zip
		fi
		echo "Done" ;;
	sultan-unified)
		if [ "$2" == "gcc-9.1" ]; then
			cp ${SULTAN_UNIFIED_ZIP}Sultan-Kernel-+-"$VERSION_DATE"-GCC-9.zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-+-"$VERSION_DATE"-GCC-9.zip
		else
			cp ${SULTAN_UNIFIED_ZIP}Sultan-Kernel-+-"$VERSION_DATE".zip ${ZIP_OUTPUT_DIR}Sultan-Kernel-+-"$VERSION_DATE".zip
		fi
		echo "Done" ;;
	other)
		cp ${ALT_ZIP}Custom-Wahoo.zip ${ZIP_OUTPUT_DIR}Custom-Wahoo.zip
		echo "Done" ;;
	*)
		echo "Done" ;;
esac