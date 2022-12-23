select
ST_MakeSolid(geom),
ST_IsValid(geom),
verhardi00
from 
gb_wegvak_3d
--where laag3D = 'bestrating'