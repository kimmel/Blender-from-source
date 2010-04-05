#!/bin/bash

#ubuntu_10.04_blender_install.sh Install x264, ffmpeg, blender from source code with dependencies
# Copyright (C) 2010 Kirk Kimmel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

#install path
INSTALL="/usr/local/src"

#Remove the stuff that will break the build process
apt-get -y remove ffmpeg x264 libx264-dev

##############################
# add repo for 'mediainfo'
# add repo for 'libvpx'
##############################
apt-add-repository ppa:shiki/mediainfo
apt-add-repository ppa:chromium-daily/ppa

#Refresh database
apt-get -y update

#install mediainfo and libvpx
apt-get -y install mediainfo-gui mediainfo libvpx-dev libvpx0

##############################
#install this for x264, and ffmpeg
##############################
apt-get -y install build-essential subversion git-core checkinstall yasm texi2html \
libfaac-dev libfaad-dev libmp3lame-dev libopencore-amrnb-dev \
libopencore-amrwb-dev libsdl1.2-dev libtheora-dev libx11-dev libxfixes-dev \
libxvidcore-dev zlib1g-dev \
libvorbis-dev libdirac-dev libschroedinger-dev libopenjpeg-dev libgsm1-dev libspeex-dev

##############################
#From the blender page: http://wiki.blender.org/index.php/Dev:2.4/Doc/Building_Blender/Linux
#apt-get -y install subversion openexr libopenexr-dev build-essential libjpeg-dev \
#libpng12-dev libopenal-dev libalut-dev libglu1-mesa-dev libsdl-dev libfreetype6-dev \
#libtiff-dev python-dev gettext libxi-dev yasm
##############################
apt-get -y install openexr libopenexr-dev libjpeg-dev \
libpng12-dev libopenal-dev libalut-dev libglu1-mesa-dev libsdl-dev libfreetype6-dev \
libtiff-dev python-dev gettext libxi-dev

##############################
# build x264
##############################
cd $INSTALL
git clone git://git.videolan.org/x264.git
cd x264
./configure
make
checkinstall --pkgname=x264 --pkgversion "2:0.`grep X264_BUILD x264.h -m1 | cut -d' ' -f3`.`git rev-list HEAD | wc -l`+git`git rev-list HEAD -n 1 | head -c 7`" --backup=no --default

##############################
# build ffmpeg
# --enable-shared - this builds the shared development libraries needed by other applications.
# --enable-libvpx - WebM Project ( http://www.webmproject.org/ ) video support
##############################
cd $INSTALL
svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-version3 --enable-nonfree --enable-postproc --enable-pthreads --enable-libfaac --enable-libfaad --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libxvid --enable-x11grab \
--enable-shared --enable-libvpx --enable-libvorbis \
--enable-libschroedinger --enable-libdirac --enable-libopenjpeg --enable-libgsm --enable-libspeex

make
checkinstall --pkgname=ffmpeg --pkgversion "4:SVN-r`svn info | grep Revision | awk '{ print $NF }'`" --backup=no --default

#build blender
cd $INSTALL
mkdir blender
cd blender/
#get the blender code
svn checkout https://svn.blender.org/svnroot/bf-blender/branches/blender2.4 blender;
cd blender/
cp config/linux2-config.py ./user-config.py

#edit user-config.py
#comment out
sed -i 's|^BF_FFMPEG\ =|#BF_FFMPEG =|' user-config.py
sed -i 's|^BF_FFMPEG_LIB\ =\ |#BF_FFMPEG_LIB = |' user-config.py
#uncomment these lines
perl -i -pe "s|^#\ BF_FFMPEG\ =\ \'/usr\'|BF_FFMPEG = '/usr/local'|" user-config.py
sed -i 's|^# BF_FFMPEG_LIB|BF_FFMPEG_LIB|' user-config.py

#compile blender
python scons/scons.py

echo '#!/bin/bash
export LD_LIBRARY_PATH="/usr/local/lib/"
/usr/local/src/blender/install/linux2/blender
' > /usr/local/bin/blender
chmod +x /usr/local/bin/blender
