library(sf)
library(tidyverse)
library(multimode)

verhardingsdikte <- st_read("data/GIS/Verhardingsdikte.shp")

ggplot(verhardingsdikte, aes(x=depth)) + 
  geom_histogram(binwidth = 0.2) + 
  geom_density(aes(y=0.2 * ..count..)) +
  ylab("count")
ggsave("export/verharingsdikte_hist_dens.png")

# Bimodal data: test for modality
# modetest(verhardingsdikte$depth)
jpeg("export/verhardingsdikte_modality.jpeg", width = 600, height = 600)
locmodes(verhardingsdikte$depth,mod0=2,display=TRUE)
dev.off()


straatlaag <- st_read("data/GIS/Straatlaag.shp")
# betekenis lagen is waarschijnlijk: 
# depth = metingsdiepte, depth_v = verhardingslaag, dikte = dikte straatlaag
ggplot(straatlaag, aes(x=dikte)) + 
  geom_histogram(binwidth = 0.2) + 
  geom_density(aes(y=0.2 * ..count..)) +
  ylab("count")
ggsave("export/straatlaag_hist_dens.png")

ggplot(straatlaag, aes(x=dikte)) + geom_boxplot()
mean(straatlaag$dikte)


steenslagwaarde <- st_read("data/GIS/Steenslagwaarde.shp")
# betekenis lagen is waarschijnlijk: 
# X40_K = kalium, X238_U = uranium, X232_Th = thorium, SSW = steenslagwaarde
ggplot(steenslagwaarde, aes(x=SSW_versch)) + 
  geom_histogram(binwidth = 0.2) + 
  geom_density(aes(y=0.2 * ..count..)) +
  ylab("count")
ggsave("export/steenslagwaarde_hist_dens.png")


klinkers <- st_read("data/GIS/Klinkers.shp")
ggplot(klinkers, aes(x=depth)) + 
  geom_histogram(binwidth = 0.2) + 
  geom_density(aes(y=0.2 * ..count..), bw = 0.15) +
  ylab("count")
ggsave("export/klinkers_hist_dens.png")
mean(klinkers$depth)
sd(klinkers$depth)

betontegels <- st_read("data/GIS/Betontegels.shp")
ggplot(betontegels, aes(x=depth)) + 
  geom_histogram(binwidth = 0.2) + 
  geom_density(aes(y=0.2 * ..count..), bw = 0.15) +
  ylab("count")
ggsave("export/betontegels_hist_dens.png")
mean(betontegels$depth)
sd(betontegels$depth)
