select
road_material,
sum(geom_volume) as volume_m3
from
(select id,roadlayer,road_material, st_volume(geom) as geom_volume
from griffiersveld_wegdeel_3d) as tbl_volume
group by road_material