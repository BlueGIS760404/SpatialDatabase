-- Database and schema for PostGIS
CREATE DATABASE p1_shp;
CREATE SCHEMA postgis;
GRANT USAGE ON SCHEMA postgis TO public;
CREATE EXTENSION postgis SCHEMA postgis;
ALTER DATABASE p1_shp SET search_path=public,postgis,contrib;

-- Check PostGIS version
SELECT postgis_full_version();

-- Create lookup table for popular brand sellers
CREATE TABLE postgis.lu_brands (
    brand_id CHAR(3) PRIMARY KEY,
    brand_name VARCHAR(100)
);

-- Populate brand lookup table with popular US brands
INSERT INTO postgis.lu_brands (brand_id, brand_name)
VALUES
    ('WMT', 'Walmart'),
    ('TGT', 'Target'),
    ('KHL', 'Kohl''s'),
    ('HD', 'Home Depot'),
    ('LOW', 'Lowe''s'),
    ('BBY', 'Best Buy'),
    ('MCS', 'Macy''s'),
    ('NKE', 'Nike'),
    ('GPS', 'Gap'),
    ('JCP', 'JCPenney');

-- Verify brand data
SELECT * FROM postgis.lu_brands;

-- Main stores table with spatial data
CREATE TABLE postgis.stores (
    id SERIAL PRIMARY KEY,
    brand_id CHAR(3) NOT NULL,
    geom GEOMETRY(point, 2163)
);

-- Create spatial index for stores
CREATE INDEX sidx_stores_geom
    ON postgis.stores USING gist(geom);

-- Add foreign key constraint
ALTER TABLE postgis.stores
    ADD CONSTRAINT fk_stores_lu_brands
    FOREIGN KEY (brand_id)
    REFERENCES postgis.lu_brands (brand_id)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Create index on brand_id column
CREATE INDEX fi_stores_brands
    ON postgis.stores (brand_id);

-- Shopping centers table with multi-polygon geometries
CREATE TABLE postgis.shopping_centers (
    gid INTEGER NOT NULL,
    name CHARACTER VARYING(120),
    state CHARACTER VARYING(2),
    geom GEOMETRY(multipolygon, 2163),
    CONSTRAINT pk_shopping_centers PRIMARY KEY (gid)
);

-- Spatial index for shopping centers
CREATE INDEX sidx_shopping_centers_geom
    ON postgis.shopping_centers USING gist(geom);

-- Staging table for importing store data from CSV
CREATE TABLE postgis.stores_staging (
    brand_id TEXT,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION
);

-- Import data from CSV (example command, adjust path as needed)
-- \copy postgis.stores_staging FROM '/path/to/stores.csv' DELIMITER as ',';

-- Verify staging data
SELECT * FROM postgis.stores_staging;

-- Transform and load data from staging to stores table
INSERT INTO postgis.stores (brand_id, geom)
    SELECT brand_id,
           ST_Transform(ST_SetSRID(ST_Point(lon, lat), 4326), 2163) AS geom
    FROM postgis.stores_staging;

-- Verify loaded store data
SELECT * FROM postgis.stores;

-- Import shapefile for shopping centers (example command, adjust path as needed)
-- shp2pgsql -D -s 4269 -g geom -I /path/to/shopping_centers.shp postgis.shopping_centers_staging | psql -h localhost -U postgres -p 5432 -d p1_shp

-- Transform and load shopping center data
INSERT INTO postgis.shopping_centers (gid, name, state, geom)
    SELECT gid,
           name,
           state,
           ST_Transform(geom, 2163)
    FROM postgis.shopping_centers_staging;

-- Verify shopping center data
SELECT * FROM postgis.shopping_centers;

-- Optimize shopping centers table
VACUUM ANALYSE postgis.shopping_centers;

-- Query: Count of stores within one mile (1609 meters) of any shopping center
SELECT b.brand_name,
       COUNT(DISTINCT s.id) AS total
FROM postgis.stores AS s
INNER JOIN postgis.lu_brands AS b ON b.brand_id = s.brand_id
INNER JOIN postgis.shopping_centers AS sc ON ST_DWithin(sc.geom, s.geom, 1609)
GROUP BY b.brand_name
ORDER BY total DESC;

-- Database backup command (example, adjust path as needed)
-- pg_dump -U postgres -d p1_shp -f /path/to/backup/p1_shp_6.25.2025.backup

-- Database restoration commands (example)
-- cd "C:\Program Files\PostgreSQL\15\bin"
-- psql -U postgres -c "CREATE DATABASE p1_shp;"
-- pg_restore -U postgres -d p1_shp -Fc "/path/to/backup/p1_shp_6.25.2025.backup"
-- psql -U postgres -d p1_shp
-- \dt
