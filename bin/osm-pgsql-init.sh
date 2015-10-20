#!/bin/bash

echo “Downloading some data“
PBF_DIR=/root/pbf
mkdir -p $PBF_DIR
cd $PBF_DIR

wget -O tucson.osm "http://api.openstreetmap.org/api/0.6/map?bbox=-110.6,32.3,-110.5,32.4"

osm2pgsql -c -C 4000 --slim -S /root/osm-utils/styles/mapzen_osm2pgsql.style -k -d osm -U osm -H localhost -P 5432 tucson.osm
