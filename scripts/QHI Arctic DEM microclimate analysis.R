#### Packages ####
library(myClim)
library(data.table)
library(sf)
library(terra)
library(brms)
library(mapview)
library(lubridate)
#### data ####

export_dt_daily <- fread("export_data/2025_TOMSTdata_preprocessed_daily.csv")

meta_data_tomst <- fread("data/TOMST_metadata.csv")
meta_data_tomst[,Field_ID := paste0(Field_ID,"_QHI")]

export_dt_daily <- export_dt_daily[grepl("TMS_T",sensor_name) | sensor_name %in% c("GDD5_mean","FDD0_mean"),]
unique(export_dt_daily$sensor_name)


export_dt_daily[,datetime := ymd(datetime)]
export_dt_daily[,time_to := ymd(time_to)]

export_dt_daily <- export_dt_daily[datetime %between% c(ymd("2023-06-15"),ymd("2023-08-15")),]

meta_data_tomst <- meta_data_tomst[Field_ID %in% unique(export_dt_daily$locality_id) ,]
meta_data_tomst_sf <- st_as_sf(meta_data_tomst[complete.cases(meta_data_tomst[,c("Lon","Lat")]),],
                               coords = c("Lon","Lat"),crs = st_crs(4326))


DEM <- rast("spatial_data/arctic_dem_10m.tif")
names(DEM) <- "elevation"
DEM_terrain <- terrain(DEM,c("slope","TPI","TRI"))
DEM_aspect <- terrain(DEM,c("aspect"),unit  = "radians")

DEM_aspect$aspect_NS <- cos(DEM_aspect$aspect)
DEM_aspect$aspect_EW <- sin(DEM_aspect$aspect)

DEM_aspect_360 <-  terrain(DEM,c("aspect"),unit  = "degrees")

DEM <- c(DEM,DEM_terrain,DEM_aspect,DEM_aspect_360)

TOMST_terrain <- extract(DEM,vect(meta_data_tomst_sf))
TOMST_terrain$locality_id <- meta_data_tomst_sf$Field_ID

write.csv(TOMST_terrain,"data/TOMST_terrain.csv",row.names = F)

#### end of extraction ####


plot(DEM$elevation)

yday(ymd("2026-07-25"))
ymd("2026-07-25") - ymd("2025-10-20")
export_dt_daily_terrain <- merge(export_dt_daily,TOMST_terrain)
unique(export_dt_daily_terrain$sensor_name)

ggplot(export_dt_daily_terrain[sensor_name == "TMS_T3_mean",],aes(x = aspect_NS, y= value))+
  geom_point()+
  geom_smooth(method = 'lm')+
  theme_bw()


ggplot(export_dt_daily_terrain[sensor_name == "TMS_T3_max",],aes(x = datetime, y= value, color = cut_number(TRI,4)))+
  geom_point()+
  geom_smooth(method = 'gam')+
  theme_bw()

pairs(export_dt_daily_terrain[sensor_name == "TMS_T3_mean",c("elevation","TRI","aspect_NS")])
cor(export_dt_daily_terrain[sensor_name == "TMS_T3_mean",c("elevation","TRI","aspect_NS")])

model_topo <- brm(value ~ elevation + TRI + aspect_NS + (1|locality_id) + (1|datetime),
                  data =export_dt_daily_terrain[sensor_name == "TMS_T3_max",],
                  iter = 2000,
                  warmup = 500,
                  chains = 3,
                  cores = 3,
                  backend = "cmdstanr",
                  init = 0)

model_topo <- brm(value ~  TRI + aspect_NS + aspect_EW + (1|locality_id) + ( TRI + aspect_NS + aspect_EW |datetime),
                  data =export_dt_daily_terrain[sensor_name == "TMS_T3_max",],
                  iter = 2000,
                  warmup = 500,
                  chains = 3,
                  cores = 3,
                  backend = "cmdstanr",
                  init = 0)
pp_check(model_topo)
plot(model_topo)
bayes_R2(model_topo)
bayes_R2(model_topo,re_formula = NA)

conditional_effects(model_topo,effects = "TRI:aspect_NS",re_formula = NA)
conditional_effects(model_topo,effects = "datetime:TRI",re_formula = ~ (TRI|datetime))
conditional_effects(model_topo,effects = "datetime:elevation",re_formula = ~ (elevation|datetime))
conditional_effects(model_topo,effects = "datetime:aspect_NS",re_formula = ~ (aspect_NS|datetime))
conditional_effects(model_topo,effects = "datetime:aspect_EW",re_formula = ~ (aspect_EW|datetime))

plot( (17 + 4.9 *1.5) + (0.75 + 0.42*1.5) * scales::squish(DEM_cropped$TRI,c(0,2)))


new_rast <- predict(model_topo,DEM_cropped,re_formula = NA,summary = T)

DEM_prediction <- DEM_cropped$elevation
values(DEM_prediction)[values(!is.na(DEM_prediction))] <- new_rast[,1]
plot(DEM_prediction)

1+1

mapview(DEM_cropped$TRI)
