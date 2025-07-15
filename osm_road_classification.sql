/*
Road Classification Symbology
Road Type	Color (Hex)	RGB Values	Line Width	Line Style	Draw Order
Major Roads	#E31A1C	227, 26, 28	2.0 pt	Solid	1 (Top)
Minor Roads	#FB9A99	251, 154, 153	1.5 pt	Solid	2
Local Roads	#6A3D9A	106, 61, 154	1.0 pt	Solid	3
Non-Motorized Paths	#33A02C	51, 160, 44	0.6 pt	Dashed (---)	4
Specialized Tracks	#B15928	177, 89, 40	0.6 pt	Dash-Dot (-.-.-)	5
Other	#B2DF8A	178, 223, 138	0.5 pt	Dotted (•••)	6 (Bottom)
*/

-- This statement adds a new column named 'road_class' to the 'roads' table in the 'public' schema
-- The column will store character strings up to 20 characters in length
ALTER TABLE public.roads ADD COLUMN road_class VARCHAR(20);

-- This commented-out query would list all column names in the 'roads' table 
-- within the 'public' schema. Useful for verifying the existence of columns.
-- (Note it's currently commented with -- so it won't execute)
-- SELECT column_name 
-- FROM information_schema.columns 
-- WHERE table_name = 'roads' AND table_schema = 'public';

-- This UPDATE statement populates the newly created 'road_class' column
-- based on values in the existing 'fclass' column
UPDATE roads SET road_class = CASE
    -- When fclass matches any of these highway types (major roads)
    WHEN fclass IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link') THEN 'major_roads'
    
    -- When fclass matches these medium-importance road types
    WHEN fclass IN ('secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'minor_roads'
    
    -- When fclass matches local street types
    WHEN fclass IN ('residential', 'living_street', 'service', 'unclassified') THEN 'local_roads'
    
    -- When fclass matches pedestrian/cycle paths (note hyphen removed from value)
    WHEN fclass IN ('footway', 'steps', 'pedestrian', 'cycleway', 'path', 'bridleway') THEN 'non-motorized_paths'
    
    -- When fclass matches various track types (including all grade levels)
    WHEN fclass IN ('track', 'track_grade1', 'track_grade2', 'track_grade3', 'track_grade4', 'track_grade5') THEN 'specialized_tracks'
    
    -- For any fclass values that didn't match above conditions
    ELSE 'other'
END;
