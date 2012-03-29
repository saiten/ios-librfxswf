#!/bin/sh

IOS_VERSION=5.0
DEVICE_PLATFORM="/Developer/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="/Developer/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${IOS_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${IOS_VERSION}.sdk"

rm -rf include lib

rm -f /tmp/swftools-*.log

mkdir include
mkdir lib

#armv6
rm -rf swftools-0.9.1
tar xvzf swftools-0.9.1.tar.gz

pushd .
cd swftools-0.9.1

perl -i -pe 's|\*-pc-\* \)|*-pc-* \| *arm* )|g' configure

CC=$DEVICE_PLATFORM/Developer/usr/bin/gcc \
CXX=$DEVICE_PLATFORM/Developer/usr/bin/g++ \
AR=$DEVICE_PLATFORM/Developer/usr/bin/ar \
CFLAGS="-isysroot $DEVICE_SDK -arch armv6" \
LDFLAGS="-dynamiclib -L $DEVICE_SDK/usr/lib" \
./configure --host=arm-apple-darwin &> /tmp/swftools-armv6.log

perl -i -pe 's|#define HAVE_JPEGLIB_H 1||g' config.h
cd lib
patch -u jpeg.c < ../../jpeg.c.patch
make libbase.a librfxswf.a >> /tmp/swftools-armv6.log

popd
cp swftools-0.9.1/lib/libbase.a lib/libbase-armv6.a
cp swftools-0.9.1/lib/librfxswf.a lib/librfxswf-armv6.a

# armv7
rm -rf swftools-0.9.1
tar xvzf swftools-0.9.1.tar.gz

pushd .
cd swftools-0.9.1

perl -i -pe 's|\*-pc-\* \)|*-pc-* \| *arm* )|g' configure

CC=$DEVICE_PLATFORM/Developer/usr/bin/gcc \
CXX=$DEVICE_PLATFORM/Developer/usr/bin/g++ \
AR=$DEVICE_PLATFORM/Developer/usr/bin/ar \
CFLAGS="-isysroot $DEVICE_SDK -arch armv7" \
LDFLAGS="-dynamiclib -L $DEVICE_SDK/usr/lib" \
./configure --host=arm-apple-darwin &> /tmp/swftools-armv7.log

perl -i -pe 's|#define HAVE_JPEGLIB_H 1||g' config.h
cd lib
patch -u jpeg.c < ../../jpeg.c.patch
make libbase.a librfxswf.a >> /tmp/swftools-armv7.log

popd
cp swftools-0.9.1/lib/libbase.a lib/libbase-armv7.a
cp swftools-0.9.1/lib/librfxswf.a lib/librfxswf-armv7.a

# i386
rm -rf swftools-0.9.1
tar xvzf swftools-0.9.1.tar.gz

pushd .
cd swftools-0.9.1

CC=$SIMULATOR_PLATFORM/Developer/usr/bin/gcc \
CXX=$SIMULATOR_PLATFORM/Developer/usr/bin/g++ \
AR=$SIMULATOR_PLATFORM/Developer/usr/bin/ar \
CFLAGS="-isysroot $SIMULATOR_SDK -arch i386" \
LDFLAGS="-dynamiclib -L $SIMULATOR_SDK/usr/lib" \
./configure --host=i386-apple-darwin &> /tmp/swftools-i386.log

perl -i -pe 's|#define HAVE_JPEGLIB_H 1||g' config.h
perl -i -pe 's|#define USE_FREETYPE 1||g' config.h
perl -i -pe 's|#define HAVE_FREETYPE 1||g' config.h
perl -i -pe 's|#define HAVE_FREETYPE_FREETYPE_H 1||g' config.h
cd lib
patch -u jpeg.c < ../../jpeg.c.patch
make libbase.a librfxswf.a >> /tmp/swftools-i386.log

popd
cp swftools-0.9.1/lib/libbase.a lib/libbase-i386.a
cp swftools-0.9.1/lib/librfxswf.a lib/librfxswf-i386.a

#
cp swftools-0.9.1/config.h include/
mkdir include/swftools
cp swftools-0.9.1/lib/*.h include/swftools
mkdir include/swftools/as3
cp swftools-0.9.1/lib/as3/*.h include/swftools/as3

lipo \
	lib/libbase-armv6.a \
	lib/libbase-armv7.a \
	lib/libbase-i386.a \
	-create -output lib/libbase.a
	
lipo \
	lib/librfxswf-armv6.a \
	lib/librfxswf-armv7.a \
	lib/librfxswf-i386.a \
	-create -output lib/librfxswf.a

rm -f lib/libbase-*.a
rm -f lib/librfxswf-*.a
