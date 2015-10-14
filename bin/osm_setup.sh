#!/bin/bash

# Configurable settings

TABLESPACE_DIR=/home/postgres/tablespace_1
TABLESPACE_NAME=tablespace_1
DATABASE_USER=osm
DATABASE_NAME=osm

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
cd $install_dir
git clone https://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql
./autogen.sh
./configure
make
make install



