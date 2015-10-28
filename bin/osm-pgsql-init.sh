#!/bin/bash

DATA_DIR=/data
TABLESPACE_DIR=$DATA_DIR/tablespace_1
DOWNLOAD_DIR=$DATA_DIR/download
OSMOSIS_DB_NAME=osmosis
TABLESPACE_NAME=tablespace_1
OSMOSIS_DIR=/usr/local/osmosis
DATABASE_USER=osm
REPLICATION_WORKSPACE_DIR=$DATA_DIR/replication_workspace

cd /tmp
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
mkdir -p $OSMOSIS_DIR
mv osmosis-latest.tgz $(dirname $OSMOSIS_DIR)
cd $(dirname $OSMOSIS_DIR)
tar xvfz osmosis-latest.tgz
rm osmosis-latest.tgz

echo "Creating tablespace directory $TABLESPACE_DIR"
mkdir -p $TABLESPACE_DIR
chown -R postgres $TABLESPACE_DIR
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

mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR
# Now that the database is created, populate it with something. 
#wget  http://download.geofabrik.de/north-america/us/arizona-latest.osm.pbf
# or go into the past a little bit
wget http://download.geofabrik.de/north-america/us/arizona-151022.osm.pbf

# This is from http://gis.stackexchange.com/questions/94352/update-database-via-osmosis-and-osm2pgsql-too-slow
# which suggests:
# osm2pgsql -c -d gps -U gps --cache 8000 --number-processes 4 --slim \
#  --flat-nodes europe_nodes.bin europe-latest.osm.pbf
#
# Your update command would be something like
#
# osmosis --read-replication-interval workingDirectory=/osmosisworkingdir/ \
#  --simplify-change --write-xml-change - | \

# You need to initialize the replication workspace first:
mkdir -p $REPLICATION_WORKSPACE_DIR
osmosis --rrii workingDirectory=$REPLICATION_WORKSPACE_DIR

# This creates a config file in $REPLICATION_WORKSPACE_DIR containing the following:
    # The URL of the directory containing change files.
    baseUrl=http://planet.openstreetmap.org/replication/minute
    
    # Defines the maximum time interval in seconds to download in a single invocation.
    # Setting to 0 disables this feature.
    maxInterval = 3600
                  
osmosis --rri workingDirectory==$REPLICATION_WORKSPACE_DIR --wxc foo.osc.gz

osmosis --read-xml tucson.osm --log-progress --write-pgsql database="$OSMOSIS_DB_NAME" host="localhost" user="$DATABASE_USER"


