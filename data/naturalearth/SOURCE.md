# Natural Earth — 1:50m Admin-0 Countries

`ne_50m_admin_0_countries.zip` is the unmodified Natural Earth vector shapefile,
committed as-is so its provenance is obvious and the build is reproducible.

- **Source:** <https://www.naturalearthdata.com/downloads/50m-cultural-vectors/>
- **Direct URL:** <https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip>
- **Theme:** Admin 0 – Countries
- **Scale:** 1:50,000,000 (medium scale — the sweet spot for world / continental
  figures rendered to TikZ; 1:110m is too coarse, 1:10m is ~23 MB and would have
  to be simplified back down anyway)
- **Version:** 5.1.1
- **Size:** ≈800 KB (zip)
- **CRS:** WGS 84 / EPSG:4326 (longitude, latitude)
- **Licence:** Public domain — no restrictions, freely redistributable. See
  <https://www.naturalearthdata.com/about/terms-of-use/>.

## How it is processed

The zip is **not** loaded directly. At image build time the `naturalearth-build`
stage in `docker/taop.Dockerfile` runs GDAL `ogr2ogr -f PGDUMP` to convert the
shapefile into `ne_50m_admin_0_countries.sql`, keeping only a curated subset of
the ~170 attribute columns:

    NAME, NAME_LONG, ISO_A2, ISO_A3, CONTINENT, REGION_UN, SUBREGION, POP_EST, GDP_MD

That dump (≈3.3 MB, never committed) creates `naturalearth.countries`
(MULTIPOLYGON, SRID 4326) with a GiST index. The `taop naturalearth` loader then
creates the PostGIS extension if needed and runs the dump with psql.

To regenerate the SQL by hand (for inspection), with GDAL installed:

    unzip ne_50m_admin_0_countries.zip
    ogr2ogr -f PGDUMP ne_50m_admin_0_countries.sql ne_50m_admin_0_countries.shp \
      -nln naturalearth.countries -lco SCHEMA=naturalearth \
      -lco GEOMETRY_NAME=geom -lco SRID=4326 -lco CREATE_SCHEMA=ON \
      -nlt PROMOTE_TO_MULTI \
      -select NAME,NAME_LONG,ISO_A2,ISO_A3,CONTINENT,REGION_UN,SUBREGION,POP_EST,GDP_MD
