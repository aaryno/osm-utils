#!/bin/bash

# Install some deps
echo "Installing dependencies"
yum install -y gcc-c++ automake libtool pkgconfig boost-devel \
  expat-devel bzip2-devel bzip2 \
  lua-devel zlib-devel git wget libxml2-devel

echo "Updating repo servers"
# Install postgresql server repo for 9.3
yum install -y http://yum.postgresql.org/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-1.noarch.rpm

echo "Installing postgres dependencies"
yum install -y postgresql93-devel postgresql93-contrib postgresql93-server

echo "Updating path"
#Update path for pgsql-9.3/bin:
echo 'export PATH=$PATH:/usr/pgsql-9.3/bin' >> /etc/profile
. /etc/profile

echo "Linking pgsql libs"
# Link all libs (there is probably a better way using LD_LIBRARY_PATH or something)
ln -s /usr/pgsql-9.3/lib/*so* /usr/lib64/

echo "Initializing database"
/usr/pgsql-9.3/bin/postgresql93-setup initdb

echo "Starting database server"
systemctl start postgresql-9.3.service

echo "Adding port 5432 to firewall allow list"
# make it last after reboot
firewall-cmd --permanent --add-port=5432/tcp
# change runtime configuration
firewall-cmd --add-port=5432/tcp
install_dir=/root

# GEOS Install GEOS
echo "Installing GEOS"
cd $install_dir
wget http://download.osgeo.org/geos/geos-3.5.0.tar.bz2
bunzip2 geos-3.5.0.tar.bz2 
tar xvf geos-3.5.0.tar
cd geos-3.5.0
./configure --libdir=/usr/lib64 --prefix=/usr/local/geos
make
make install

# Install PROJ.4
echo "Installing Proj.4"
cd $install_dir
git clone https://github.com/OSGeo/proj.4.git
cd proj.4
./autogen.sh
./configure -libdir=/usr/lib64 --prefix=/usr/local/proj.4
make
make install

# Install gdal
echo "Installing GDAL"
cd $install_dir
wget http://download.osgeo.org/gdal/1.11.3/gdal-1.11.3.tar.gz
tar xvzf gdal-1.11.3.tar.gz
cd gdal-1.11.3
./autogen.sh
./configure --libdir=/usr/lib64 --prefix=/usr/local/gdal
make
make install

echo "Updating path for gdal"
# Update paths for gdal
echo 'export GDAL_HOME=/usr/local/gdal' >> /etc/profile
echo 'export PATH=$PATH:$GDAL_HOME/bin' >> /etc/profile
. /etc/profile

# Install postgis
echo "Installing PostGIS"
cd $install_dir
wget http://download.osgeo.org/postgis/source/postgis-2.2.0.tar.gz
tar zvxf postgis-2.2.0.tar.gz
cd postgis-2.2.0
./configure --libdir=/usr/lib64 
make
make install

