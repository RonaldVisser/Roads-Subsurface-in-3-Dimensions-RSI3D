select 
gb_wegvakonderdeel.gid,
gb_wegvakonderdeel.dikte_straatlaag,
gb_wegvakonderdeel2.dikte_straatlaag as dikte_straatlaag2
from gb_wegvakonderdeel,
(select * from gb_wegvakonderdeel) as gb_wegvakonderdeel2
where 
gb_wegvakonderdeel.gid <> gb_wegvakonderdeel2.gid
and gb_wegvakonderdeel.dikte_straatlaag  is null
and gb_wegvakonderdeel2.dikte_straatlaag  is not null
and ST_Intersects(gb_wegvakonderdeel.geom, gb_wegvakonderdeel2.geom) = TRUE
order by gb_wegvakonderdeel.gid