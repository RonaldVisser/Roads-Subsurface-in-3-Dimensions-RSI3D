
source("Connect_db.R") # also loads library(RPostgres)

#set.seed(666)


SQL_3D_view <- "create or replace view \"griffiersveld_3d\" as 
select * from \"3dbag_v210908_lod22_3d\" 
where ST_Within(\"3dbag_v210908_lod22_3d\".geom, (select geom from onderzoeksgebied));"
dbExecute(con,SQL_3D_view)

if (dbExistsTable(con,"griffiersveld_wegdeel" )) {
  dbExecute(con, "drop table \"griffiersveld_wegdeel\"")  
}

SQl_road_layer <- "create table \"griffiersveld_wegdeel\" as
select * from \"top10nl_wegdeel\" where ST_Within(\"top10nl_wegdeel\".geom, (select geom from onderzoeksgebied));"
dbExecute(con, SQl_road_layer)

SQL_minimal_z <- "Select ST_ZMin(geom) from \"griffiersveld_3d\" "
z_values <- dbGetQuery(con, SQL_minimal_z)
mean_z <- round(mean(z_values$st_zmin),2)


# create layers
road_layers <- c("top layer", "layer below", "bottom layer")
road_layers_depth <- c(0.2,0.5,0.3)
road_layers_material <- c("brick", "clay", "compacted material")

if (dbExistsTable(con,"griffiersveld_wegdeel_3d" )) {
  dbExecute(con, "drop table \"griffiersveld_wegdeel_3d\"")  
}

for (i in 1:length(road_layers)){
  SQL_road_select <- paste0("select id,st_translate(ST_Extrude(geom,0,0,", 
                            road_layers_depth[i] ,"),0,0,", mean_z-sum(road_layers_depth[1:i]), ") as geom, '", 
                            road_layers[i], "' as roadlayer, ",
                            road_layers_depth[i]," as depth, '",
                            road_layers_material[i],"' as road_material ",
                            "from griffiersveld_wegdeel;")
  if (i == 1){
    SQL_road_create <- paste0("create table \"griffiersveld_wegdeel_3d\" as ",SQL_road_select)
    dbExecute(con, SQL_road_create)
  } else {
    SQL_road_append <- paste0("INSERT INTO \"griffiersveld_wegdeel_3d\" ",SQL_road_select)
    dbExecute(con, SQL_road_append)
  }
}


if (dbExistsTable(con,"griffiersveld_leiding_segment" )) {
  dbExecute(con, "drop table \"griffiersveld_leiding_segment\"")  
}
SQL_leiding_segment <- paste0("create table griffiersveld_leiding_segment as
  WITH segments AS (SELECT  
  id,
  ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY id ORDER BY id, (pt).path), (pt).geom)::geometry(LineString, 7415) AS geom
  FROM (
	SELECT 
		id
		, ST_DumpPoints(geom) AS pt 
	FROM 
	    griffiersveld_leiding	
	) as dumps
)
SELECT 
	row_number() over () as uid
	, * 
FROM 
	segments 
WHERE 
	geom IS NOT NULL;")
dbExecute(con, SQL_leiding_segment)

if (dbExistsTable(con,"griffiersveld_leiding_3d" )) {
  dbExecute(con, "drop table \"griffiersveld_leiding_3d\"")  
}
SQL_leiding_3D <- paste0("create table griffiersveld_leiding_3d as
select 
    id
	, st_translate(
	    st_rotatez(
		    st_rotatex(
			    st_extrude(
                    st_buffer(
                        st_setsrid(st_makepoint(0, 0, 0), 7415)
                        , 0.2)
                    , 0, 0, st_length(geom) )
                , pi() / 2 )
		    , - st_azimuth(st_endpoint(geom), st_startpoint(geom)) )
        , st_x(st_startpoint(geom))
		, st_y(st_startpoint(geom))
        , ", mean_z - 0.5, ") as tube
from griffiersveld_leiding_segment;")
dbExecute(con, SQL_leiding_3D)

