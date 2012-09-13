#!/bin/sh

DEVELOPER="/Applications/Xcode.app/Contents/Developer"
SDK_VERSION="6.0"

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

	rm -rf swftools-0.9.1
	tar xvzf swftools-0.9.1.tar.gz

	pushd .
	cd swftools-0.9.1

	perl -i -pe 's|\*-pc-\* \)|*-pc-* \| *arm* )|g' configure

	CC=$PLATFORM/Developer/usr/bin/gcc \
	CXX=$PLATFORM/Developer/usr/bin/g++ \
	AR=$PLATFORM/Developer/usr/bin/ar \
    CFLAGS="-isysroot $SDK -arch $ARCH" \
    LDFLAGS="-dynamiclib -L $SDK/usr/lib" \
    ./configure --host=arm-apple-darwin &> "/tmp/swftools-$ARCH.log"

	perl -i -pe 's|#define HAVE_JPEGLIB_H 1||g' config.h
	cd lib
	patch -u jpeg.c < ../../jpeg.c.patch
	make libbase.a librfxswf.a >> "/tmp/swftools-$ARCH.log"

	popd

	cp swftools-0.9.1/lib/libbase.a "lib/libbase-$ARCH.a"
	cp swftools-0.9.1/lib/librfxswf.a "lib/librfxswf-$ARCH.a"
}

build "armv7" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "armv7s" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "i386" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"

#
cp swftools-0.9.1/config.h include/
mkdir include/swftools
cp swftools-0.9.1/lib/*.h include/swftools
mkdir include/swftools/as3
cp swftools-0.9.1/lib/as3/*.h include/swftools/as3

lipo \
	lib/libbase-armv7.a \
	lib/libbase-armv7s.a \
	lib/libbase-i386.a \
	-create -output lib/libbase.a
	
lipo \
	lib/librfxswf-armv7.a \
	lib/librfxswf-armv7s.a \
	lib/librfxswf-i386.a \
	-create -output lib/librfxswf.a

rm -f lib/libbase-*.a
rm -f lib/librfxswf-*.a
