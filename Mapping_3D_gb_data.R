# input vector layer should be polygon (not multipolygon!)

source("Connect_db.R") # also loads library(RPostgres)
source("ColumnExists.R") # load function to check if column exists

SQL_3D_view <- "create or replace view \"griffiersveld_3d\" as 
select * from \"3dbag_v210908_lod22_3d\" 
where ST_Within(\"3dbag_v210908_lod22_3d\".geom, (select geom from onderzoeksgebied));"
dbExecute(con,SQL_3D_view)

SQL_minimal_z <- "Select ST_ZMin(geom) from \"griffiersveld_3d\" "
z_values <- dbGetQuery(con, SQL_minimal_z)
mean_z <- round(mean(z_values$st_zmin),2)

#wegvlak <- dbGetQuery(con, "select * from gb_wegvakonderdeel")
# simplify road-layer to prevent errors in 3D geometry and speed up processes, 0.005 m resolution
dbExecute(con, "Update gb_wegvakonderdeel set geom = ST_SimplifyPreserveTopology(geom,0.005)")

# aanpassen tabel: diktes verharding: Sier/BSS = 8.8, betontegels = 7.3 cm
# add column for dikte_verharding
if (ColumnExists(con, "gb_wegvakonderdeel", "dikte_verharding") == FALSE) {
  dbExecute(con, "Alter table gb_wegvakonderdeel add column dikte_verharding numeric")
}
# update verharding
dbExecute(con, "UPDATE gb_wegvakonderdeel set dikte_verharding = 0.073 where verhardi00 like 'Tegels%';")
dbExecute(con, "UPDATE gb_wegvakonderdeel set dikte_verharding = 0.088 where verhardi00 like 'BSS%';")
dbExecute(con, "UPDATE gb_wegvakonderdeel set dikte_verharding = 0.088 where verhardi00 like 'Sier%';")

# dikte straatlaag op basis punten binnen polygoon, gemiddelde dikte


if (ColumnExists(con, "gb_wegvakonderdeel", "dikte_straatlaag") == FALSE) {
  dbExecute(con, "Alter table gb_wegvakonderdeel add column dikte_straatlaag numeric")
}
dbExecute(con, "UPDATE gb_wegvakonderdeel set dikte_straatlaag = avg_dikte FROM
	(select gb_wegvakonderdeel.gid, round(avg(straatlaag.dikte::numeric)/100,3) as avg_dikte
	 from straatlaag,gb_wegvakonderdeel
	 where st_within(straatlaag.geom, gb_wegvakonderdeel.geom)
	 group by gb_wegvakonderdeel.gid) as straatlaagdikte
WHERE straatlaagdikte.gid = gb_wegvakonderdeel.gid")


# create layer (first delete if exists)
if (dbExistsTable(con,"gb_wegvak_3d" )) {
  dbExecute(con, "drop table \"gb_wegvak_3d\"")  
}
# dikte bestrating
SQL_bestrating <- paste0("create table gb_wegvak_3d as select gid, verharding, verhardi00, std_verhar, 'bestrating' as laag3D, ",
                         "st_translate(ST_Extrude(geom,0,0,dikte_verharding),0,0,", mean_z,
                         "-dikte_verharding) as geom from gb_wegvakonderdeel where dikte_verharding is not null;")
# Code for multipolygon input
#SQL_bestrating <- paste0("create table gb_wegvak_3d as select gid, verharding, verhardi00, std_verhar, 'bestrating' as laag3D,
#ST_CollectionExtract(st_translate(ST_Extrude(geom,0,0,dikte_verharding),0,0,", mean_z,
#                         "-dikte_verharding)) as geom from gb_wegvakonderdeel where dikte_verharding is not null;")
dbExecute(con,SQL_bestrating)

dbExecute(con, "ALTER TABLE gb_wegvak_3d RENAME COLUMN gid TO gid_2d")
dbExecute(con, "ALTER TABLE gb_wegvak_3d add column gid bigserial")
# dbExecute(con, "UPDATE gb_wegvak_3d set gid = row_number()")


# st_volume is slow, store volumes in table:
if (ColumnExists(con, "gb_wegvak_3d", "volume_m3") == FALSE) {
  dbExecute(con, "Alter table gb_wegvak_3d add column volume_m3 numeric")
}
if (ColumnExists(con, "gb_wegvak_3d", "time_vol_calc") == FALSE) {
  dbExecute(con, "Alter table gb_wegvak_3d add column time_vol_calc numeric")
}
# loop to store volumes in DB, because slow process and can be stopped per iteration (record/volume) now
gid_n <- dbGetQuery(con, "select max(gid) from gb_wegvak_3D")
for (i in 0:as.integer(gid_n$max)){
  start_time <- Sys.time()
  dbExecute(con, paste0("UPDATE gb_wegvak_3d set volume_m3 = st_volume(geom) where gid = ", i, " and volume_m3 is null;"))
  dbExecute(con, paste0("UPDATE gb_wegvak_3d set time_vol_calc = ", as.numeric(difftime(Sys.time(), start_time, units="secs")), "where gid = ", i, "and time_vol_calc is null;"))
  cat('Processing record', i+1, 'of', as.integer(gid_n$max)+1,'\n')
}

#dbExecute(con, "UPDATE gb_wegvak_3d set volume_m3 = st_volume(geom)")

# dikte straatlaag invoegen
SQL_straatlaag <- paste0("INSERT INTO gb_wegvak_3d select gid, verharding, verhardi00, std_verhar, 'straatlaag' as laag3D,
ST_CollectionExtract(st_translate(ST_Extrude(geom,0,0,dikte_straatlaag),0,0,", mean_z,
                         "-dikte_verharding-dikte_straatlaag)) as geom from gb_wegvakonderdeel where dikte_straatlaag is not null;")
dbExecute(con,SQL_straatlaag)

dbDisconnect(con)