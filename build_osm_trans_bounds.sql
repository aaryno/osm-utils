
CREATE TABLE osm_border (id serial primary key, name varchar(128), boundary varchar(64), category varchar(32),osm_id bigint, modified timestamp);

SELECT AddGeometryColumn('osm_border','geom',900913,'LINESTRING',2);

INSERT INTO osm_border (name,boundary,category,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(boundary AS VARCHAR(64)) AS boundary,tags->'admin_level', CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE tags->'admin_level' in ('2','4','6') and osm_id not in (select osm_id from osm_border);

CREATE INDEX osm_border_geom_idx on osm_border using gist (geom);

DELETE FROM osm_border where not ST_IsValid(geom);

CREATE INDEX osm_border_idx on osm_border (boundary,category);

VACUUM ANALYZE osm_border;

CREATE TABLE osm_transportation (id serial primary key, name varchar(128), osm_tag varchar(32), category varchar(32), ref varchar(8), oneway int, osm_id bigint, modified timestamp);

SELECT AddGeometryColumn('osm_transportation','geom',900913,'LINESTRING',2);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, cast(aeroway as varchar(32)) as osm_tag,'aeroway',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref,CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway,CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::timestamp as modified, way from planet_osm_line where aeroway in ('runway','taxiway') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name,CAST(railway AS VARCHAR(32)) AS rail_type,'railway',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref,CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway,CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id,osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE railway IN ('rail','tram','light_rail','narrow_gauge','funicular','disused','subway') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'alley',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('service') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'interchange',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('motorway_link') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'motorway',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('motorway') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'primary',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('primary','primary_link') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'secondary',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('secondary','secondary_link') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'tertiary',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('tertiary','residential','living_street','unclassified','tertiary_link','residential_link','unclassified_link') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'trunk',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('trunk','trunk_link') and osm_id not in (select osm_id from osm_transportation);

INSERT INTO osm_transportation (name,osm_tag,category,ref,oneway,osm_id,modified,geom) SELECT CAST(name AS VARCHAR(128)) AS name, CAST(highway AS VARCHAR(32)) AS road_type,'walkway',CAST(CASE WHEN length(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) > 8 THEN null ELSE UPPER(regexp_replace(replace(regexp_replace(ref,'\;(.*)|\,(.*)',''),' ',''),'^(?!.*[0-9])','')) END AS VARCHAR(8)) AS ref, CAST(CASE WHEN oneway = 'yes' THEN 1 ELSE 0 END AS INT) AS oneway, CAST(FLOOR(CAST(osm_id AS NUMERIC))AS BIGINT) AS osm_id, osm_timestamp::TIMESTAMP AS modified, way FROM planet_osm_line WHERE highway IN ('pedestrian','footway','path','track') and osm_id not in (select osm_id from osm_transportation);

CREATE INDEX osm_tran_geom_idx on osm_transportation using gist (geom);

delete from osm_transportation where not ST_IsValid(geom);

CREATE INDEX osm_tran_idx on osm_transportation (osm_tag,category,oneway);

VACUUM ANALYZE osm_transportation;
