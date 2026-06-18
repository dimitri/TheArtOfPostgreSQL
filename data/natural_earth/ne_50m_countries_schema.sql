-- Natural Earth 50m countries schema
-- PostGIS must be installed in the postgres.Dockerfile for this to work.
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS natural_earth;

DROP TABLE IF EXISTS natural_earth.ne_countries CASCADE;

CREATE TABLE natural_earth.ne_countries (
    id         SERIAL PRIMARY KEY,
    name       TEXT   NOT NULL,
    iso_a2     VARCHAR(10),
    geom       GEOMETRY(MULTIPOLYGON, 4326)
);

CREATE INDEX ne_countries_geom_idx
    ON natural_earth.ne_countries USING GIST (geom);
