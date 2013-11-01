#!/bin/sh

SWFTOOL_VERSION=0.9.2

DEVELOPER=$(xcode-select --print-path)
SDK_VERSION=$(xcrun -sdk iphoneos --show-sdk-version)
SDK_VERSION_MIN=4.3

DEVICE_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"
rm -rf include lib

rm -f /tmp/swftools-*.log

mkdir include
mkdir lib

# build

build()
{
	ARCH=$1
	PLATFORM=$2
	SDK=$3

	rm -rf swftools-${SWFTOOL_VERSION}
	tar xvzf swftools-${SWFTOOL_VERSION}.tar.gz

	pushd .
	cd swftools-${SWFTOOL_VERSION}

	perl -i -pe 's|\*-pc-\* \)|*-pc-* \| *arm* )|g' configure

	CC=$DEVELOPER/usr/bin/gcc \
	CXX=$DEVELOPER/usr/bin/g++ \
	AR=ar \
	CFLAGS="-isysroot $SDK -arch $ARCH -miphoneos-version-min=${SDK_VERSION_MIN}" \
	LDFLAGS="-dynamiclib -L $SDK/usr/lib -miphoneos-version-min=${SDK_VERSION_MIN}" \
	./configure --host=arm-apple-darwin &> "/tmp/swftools-$ARCH.log"

	perl -i -pe 's|#define HAVE_JPEGLIB_H 1||g' config.h
	cd lib
	patch -u jpeg.c < ../../jpeg.c.patch
	make libbase.a librfxswf.a >> "/tmp/swftools-$ARCH.log"

	popd

	cp swftools-${SWFTOOL_VERSION}/lib/libbase.a "lib/libbase-$ARCH.a"
	cp swftools-${SWFTOOL_VERSION}/lib/librfxswf.a "lib/librfxswf-$ARCH.a"
}

build "armv7" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "armv7s" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "i386" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"

#
cp swftools-${SWFTOOL_VERSION}/config.h include/
mkdir include/swftools
cp swftools-${SWFTOOL_VERSION}/lib/*.h include/swftools
mkdir include/swftools/as3
cp swftools-${SWFTOOL_VERSION}/lib/as3/*.h include/swftools/as3

xcrun lipo \
	lib/libbase-armv7.a \
	lib/libbase-armv7s.a \
	lib/libbase-i386.a \
	-create -output lib/libbase.a
	
xcrun lipo \
	lib/librfxswf-armv7.a \
	lib/librfxswf-armv7s.a \
	lib/librfxswf-i386.a \
	-create -output lib/librfxswf.a

rm -f lib/libbase-*.a
rm -f lib/librfxswf-*.a
