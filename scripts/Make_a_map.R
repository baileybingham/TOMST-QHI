library(data.table)
library(sf)
library(mapview)
library(ggspatial) ## backend for adding north arrow, scale, basemap
library(ggplot2)
## coordinates
meta_data <- fread(file.path("data","TOMST_metadata.csv"))
meta_data[, Field_ID := paste0(Field_ID,"_QHI")]
## Extracting a hot day
dailytms <- fread(file.path("export_data","2025_TOMSTdata_preprocessed_daily.csv"))
dailytms <- dailytms[datetime == "2023-07-26",]
dailytms <- dailytms[sensor_name == "TMS_T3_max",]
## merging meta data and temp
dailytms <- merge(dailytms,meta_data,by.x = "locality_id",by.y = "Field_ID")
dailytms[,`Maximum temperature`:= value ]
##converting to a spatial feature object
dailytms_sf <- st_as_sf(dailytms,coords = c("Lon","Lat"),crs = st_crs(4326))
## interactive fun map (IDK how to embed it in the README)
mapview(dailytms_sf,zcol = "Maximum temperature", label = "locality_id")
## Making a map using ggplot2 and ggspatial
(export_map <- ggplot(dailytms_sf)+
  annotation_map_tile(type = "osm",zoomin= 0)+ # open street map tile, zoom moderate
  geom_sf(pch = 21, size = 4,mapping = aes(fill = value))+
  scale_fill_viridis_c(limits = c(19,27),option = "plasma",oob = scales::squish)+
  coord_sf(ylim = range(dailytms$Lat)+ c(-0.01,0.01)*0.125 ,xlim = range(dailytms$Lon)+c(-0.025,0.025)*0.25)+
  annotation_north_arrow(location = 'tr')+ #nort arrow
  annotation_scale(location = "br")+# scale
  labs(fill = "Tmax",
       title = "Where are the TOMST temperature logger?",
       subtitle = "Maximum temperature of the 26th of July 2023")
)
## Exporting the pretty map
ggsave(file.path("figures","TOMST_QHI_map.jpg"),
       export_map,
       unit = "cm",width = 18,height = 12,scale = 1)

