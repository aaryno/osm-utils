# osm-utils
Install git. E.g., for CentOS:

    yum -y install git
    
Then:

    git clone https://github.com/aaryno/osm-utils.git

Edit directories, usernames, workspace names, etc. in the following files, then run them as follows:

    ./osm-utils/bin/osm_setup_centos.sh
    
Edit osm-utils/bin/osm_setup.sh to your particular taste, specifically updating these 7 lines at the top of the file:

    TABLESPACE_DIR=/home/postgres/tablespace_1
    TABLESPACE_NAME=tablespace_1
    DATABASE_USER=osm
    DATABASE_NAME=osm
    PBF_DIR=/home/pbf/incoming
    PBF_URL=http://download.geofabrik.de/north-america/us/arizona-latest.osm.pbf
    PBF_NAME=arizona-latest.osm.pbf

Then

    ./osm-utils/bin/osm_setup.sh
    
    
