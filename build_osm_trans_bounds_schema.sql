
CREATE TABLE osm_border (id serial primary key, name varchar(128), boundary varchar(64), category varchar(32),osm_id bigint, modified timestamp);

SELECT AddGeometryColumn('osm_border','geom',900913,'LINESTRING',2);

CREATE INDEX osm_border_geom_idx on osm_border using gist (geom);

CREATE INDEX osm_border_idx on osm_border (boundary,category);

CREATE TABLE osm_transportation (id serial primary key, name varchar(128), osm_tag varchar(32), category varchar(32), ref varchar(8), oneway int, osm_id bigint, modified timestamp);

SELECT AddGeometryColumn('osm_transportation','geom',900913,'LINESTRING',2);

CREATE INDEX osm_tran_geom_idx on osm_transportation using gist (geom);

CREATE INDEX osm_tran_idx on osm_transportation (osm_tag,category,oneway);


