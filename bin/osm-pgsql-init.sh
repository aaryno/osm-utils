#!/bin/bash

OSMOSIS_DB_NAME=osm_snapshot
TABLESPACE_DIR=/data/tablespace_1
TABLESPACE_NAME=tablespace_1
OSMOSIS_DIR=/usr/local/osmosis

cd /usr/local
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
mkdir -p $OSMOSIS_DIR
mv osmosis-latest.tgz $(dirname $OSMOSIS_DIR)
cd $(dirname $OSMOSIS_DIR)
tar xvfz osmosis-latest.tgz
rm osmosis-latest.tgz


echo “Downloading some data“
PBF_DIR=/root/osm/downloads
mkdir -p $PBF_DIR
cd $PBF_DIR

wget http://download.geofabrik.de/north-america-latest.osm.pbf

echo "Creating tablespace directory $TABLESPACE_DIR"
mkdir -p $TABLESPACE2_DIR
chown -R postgres $TABLESPACE2_DIR
echo "Creating user $DATABASE_USER"
sudo -u postgres bash -c "createuser $DATABASE_USER"
echo "Creating tablespace $TABLESPACE_NAME"
sudo -u postgres bash -c "psql -p 5432 -c \"CREATE TABLESPACE $TABLESPACE_NAME location '$TABLESPACE_DIR'\""
sudo -u postgres bash -c "psql -p 5432 -c \"CREATE DATABASE $OSMOSIS_DB_NAME WITH OWNER $DATABASE_USER tablespace $TABLESPACE_NAME\""
echo "Creating extensions"

sudo -u postgres bash -c "psql -p 5432 -d $OSMOSIS_DB_NAME -c \"CREATE EXTENSION postgis\""
sudo -u postgres bash -c "psql -p 5432 -d $OSMOSIS_DB_NAME -c \"CREATE EXTENSION hstore\""
sudo -u postgres bash -c "psql -p 5432 -d $OSMOSIS_DB_NAME -c \"SELECT postgis_full_version()\""

sudo -u postgres bash -c "psql -p 5432 -U $DATABASE_USER -d $OSMOSIS_DB_NAME -f $OSMOSIS_DIR/script/pgsnapshot_schema_0.6.sql"
sudo -u postgres bash -c "psql -p 5432 -U $DATABASE_USER -d $OSMOSIS_DB_NAME -f $OSMOSIS_DIR/script/pgsnapshot_schema_0.6_linestring.sql"

# Now that the database is created, populate it with something. 
wget  http://download.geofabrik.de/north-america/us/arizona-latest.osm.pbf
# or go into the past a little bit
wget http://download.geofabrik.de/north-america/us/arizona-151022.osm.pbf

osm2pgsql -c -d $DATABASE_NAME -U $DATABASE_USER --cache 800 --number-processes 4 --slim --flat-nodes central-america_nodes.bin central-america-latest.osm.pbf

wget -O tucson.osm "http://api.openstreetmap.org/api/0.6/map?bbox=-110.6,32.3,-110.5,32.4"

osm2pgsql -c -C 4000 --slim -S /root/osm-utils/styles/mapzen_osm2pgsql.style -k -d osm -U osm -H localhost -P 5432 --flat-nodes central-america_nodes.bin central-america-latest.osm.pbf
osm2pgsql -c -C 4000 --slim -S /root/osm-utils/styles/mapzen_osm2pgsql.style -k -d osm -U osm -H localhost -P 5432 central-america-latest.osm.pbf


osmosis --read-xml tucson.osm --log-progress --write-pgsql database="$OSMOSIS_DB_NAME" host="localhost" user="$DATABASE_USER"

