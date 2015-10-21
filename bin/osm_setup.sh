#!/bin/bash

# Configurable settings

TABLESPACE_DIR=/home/postgres/tablespace_1
TABLESPACE_NAME=tablespace_1
DATABASE_USER=osm
DATABASE_NAME=osm

INSTALL_DIR=/root

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
export PATH=$PATH:/usr/pgsql-9.3/bin
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

# GEOS Install GEOS
echo "Installing GEOS"
cd $INSTALL_DIR
wget http://download.osgeo.org/geos/geos-3.5.0.tar.bz2
bunzip2 geos-3.5.0.tar.bz2 
tar xvf geos-3.5.0.tar
cd geos-3.5.0
./configure --libdir=/usr/lib64
make
make install

# Install PROJ.4
echo "Installing Proj.4"
cd $INSTALL_DIR
git clone https://github.com/OSGeo/proj.4.git
cd proj.4
./autogen.sh
./configure -libdir=/usr/lib64
make
make install

# Install gdal
echo "Installing GDAL"
cd $INSTALL_DIR
wget http://download.osgeo.org/gdal/1.11.3/gdal-1.11.3.tar.gz
tar xvzf gdal-1.11.3.tar.gz
cd gdal-1.11.3
./autogen.sh
./configure --libdir=/usr/lib64
make
make install

echo "Updating path for gdal"
# Update paths for gdal
echo 'export GDAL_HOME=/usr/local/gdal' >> /etc/profile
echo 'export PATH=$PATH:$GDAL_HOME/bin' >> /etc/profile
. /etc/profile

# Install postgis
echo "Installing PostGIS"
cd $INSTALL_DIR
wget http://download.osgeo.org/postgis/source/postgis-2.2.0.tar.gz
tar zvxf postgis-2.2.0.tar.gz
cd postgis-2.2.0
./configure --libdir=/usr/lib64 
make
make install

## End Make stuff

#PG_DATADIR=/etc/postgresql/9.3/main # Ubuntu
PG_DATADIR=/var/lib/pgsql/9.3/data # CentOS

PG_CONF=$PG_DATADIR/postgresql.conf
HBA_CONF=$PG_DATADIR/pg_hba.conf

## Create database

echo "Creating tablespace directory $TABLESPACE_DIR"
mkdir -p $TABLESPACE_DIR
chown -R postgres $TABLESPACE_DIR
echo "Creating user $DATABASE_USER"
sudo -u postgres bash -c "createuser $DATABASE_USER"
echo "Creating tablespace $TABLESPACE_NAME"
sudo -u postgres bash -c "psql -p 5432 -c \"CREATE TABLESPACE $TABLESPACE_NAME location '$TABLESPACE_DIR'\""
sudo -u postgres bash -c "psql -p 5432 -c \"CREATE DATABASE $DATABASE_NAME WITH OWNER $DATABASE_USER tablespace $TABLESPACE_NAME\""
echo "Creating extensions"
sudo -u postgres bash -c "psql -p 5432 -d $DATABASE_NAME -c \"CREATE EXTENSION postgis\""
sudo -u postgres bash -c "psql -p 5432 -d $DATABASE_NAME -c \"CREATE EXTENSION postgis_topology\""
sudo -u postgres bash -c "psql -p 5432 -d $DATABASE_NAME -c \"CREATE EXTENSION hstore\""
sudo -u postgres bash -c "psql -p 5432 -d $DATABASE_NAME -c \"SELECT postgis_full_version()\""

### Database tuning
echo "Tuning PostgreSQL database settings"
echo "Backing up $PG_CONF to $PG_CONF.org"
cp -i $PG_CONF $PG_CONF.orig
echo "Backing up $HBA_CONF to $HBA_CONF.org"
cp -i $HBA_CONF $HBA_CONF.orig

tmpfile1=/tmp/postgresql.conf.$$.1
tmpfile2=/tmp/postgresql.conf.$$.2

cp $PG_CONF $tmpfile1

# Declare associative array to keep track of settings we want to change
# Change these as necessary as research and experience gives you the confidence
# and/or need to do so.

declare -A pgconf
pgconf=(["shared_buffers"]="4GB"
["work_mem"]="100MB"
["maintenance_work_mem"]="4096MB"
["fsync"]="off"
["autovacuum"]="off"
["checkpoint_segments"]="60"
["random_page_cost"]="1.1"
["effective_io_concurrency"]="2"
["temp_tablespaces"]="$TABLESPACE_NAME"
["listen_addresses"]="'*'")

echo "Updating settings in $PG_CONF"
# Update each of the settings in the associative array 'pgconf'
for key in ${!pgconf[@]}
do
  sed  "s/^[# ]*$key[ =].*/$key = ${pgconf["$key"]}/" $tmpfile1 >$tmpfile2
  mv -f $tmpfile2 $tmpfile1
done
mv $tmpfile1 $PG_CONF

echo "Updating PostgreSQL connection settings in $HBA_CONF"
# Alter pg_hba.conf so we can connect to postgresql.conf
sudo -u postgres bash -c "sed 's/\(^local.* \)[A-Za-z]*/\1trust/' $HBA_CONF | sed 's/\(^host.* \)[A-Za-z]*/\1trust/' > $tmpfile2"
sudo -u postgres bash -c "mv -f $tmpfile2 $HBA_CONF"

echo "Restarting PostgreSQL"
service postgresql restart

#Install osm2pgsql
echo “Installing osm2pgsql”
cd $INSTALL_DIR
git clone https://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql
./autogen.sh
./configure
make
make install

mkdir -p $INSTALL_DIR/osm/downloads
cd $INSTALL_DIR/osm/downloads
wget -O tucson.osm "http://api.openstreetmap.org/api/0.6/map?bbox=-110.6,32.3,-110.5,32.4"
osm2pgsql -c -C 4000 --slim -S $INSTALL_DIR/osm-utils/styles/mapzen_osm2pgsql.style -k -d $DATABASE_NAME -U $DATABASE_USER -H localhost -P 5432 tucson.osm

