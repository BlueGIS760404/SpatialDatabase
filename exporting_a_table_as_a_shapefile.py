import geopandas as gpd
from sqlalchemy import create_engine

# Create connection
engine = create_engine('postgresql://postgres:1368@localhost:5432/P_05_6.18.2025')

# Read data
gdf = gpd.read_postgis("SELECT * FROM public.roads", engine, geom_col='geom')

# Export to Shapefile
gdf.to_file("roads_export.shp")
