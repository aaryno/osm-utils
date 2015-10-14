# osm-utils
Install git. E.g., for CentOS:

    yum -y install git wget

If you are going to be working with a very large OSM file, you might want to start downloading it before you compile and install all the postgis and osm dependencies, although in my example at the end of this document I show the proof of concept with a much smaller area (the state of Arizona). This is how to get the latest planet file:

    wget http://planet.osm.org/pbf/planet-latest.osm.pbf

Then:

    git clone https://github.com/aaryno/osm-utils.git

Edit directories, usernames, workspace names, etc. in the following files, then run them as follows.

    ./osm-utils/bin/osm_setup_centos.sh
    
Edit `./osm-utils/bin/osm_setup.sh` to your particular taste, specifically updating these 7 lines at the top of the file:

    TABLESPACE_DIR=/home/postgres/tablespace_1
    TABLESPACE_NAME=tablespace_1
    DATABASE_USER=osm
    DATABASE_NAME=osm

This installs a few things and updates the /etc/profile. Since it runs in a shell, ENV variables do not propagate back to your shell so:

    . /etc/profile
    ./osm-utils/bin/osm_setup.sh
    
When that's finished compiling and installing, you're ready to download data and import it. What follows below is a small file (just the state of Arizona). For larger files you may have thought to download this file earlier. Assuming you haven't, download it now:

    wget http://download.geofabrik.de/north-america/us/arizona-latest.osm.pbf
    
Then run `osm2pgsql` to import it into your PostgreSQL database:

    osm2pgsql -c -C 4000 --slim -S ./osm-utils/styles/mapzen_osm2pgsql.style -k -d osm -U osm -H localhost -P 5432 arizona-latest.osm.pbf 

