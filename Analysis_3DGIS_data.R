library(tidyverse)
source("Connect_db.R") # also loads library(RPostgres)

time_volume <- dbGetQuery(con, "SELECT *, ST_NPoints(geom) as nodes FROM public.gb_wegvak_3d")
ggplot(time_volume, aes(x=volume_m3, y=time_vol_calc)) + geom_point() + 
  xlab("Volume (m3)") + ylab("Seconds to calculate volume")
ggsave("export/scatter_time_volume_creation.png", dpi = 600)
ggplot(time_volume, aes(x=nodes, y=time_vol_calc)) + geom_point() + geom_smooth() +
  xlab("Vertices") + ylab("Seconds to calculate volume")
ggsave("export/scatter_time_vertices_creation.png", dpi = 600)
