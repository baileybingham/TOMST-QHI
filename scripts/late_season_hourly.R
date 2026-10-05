
### run pre processing script until  ggetting tms.calc

################## Aggregate to HOURLY values  ################# 
hourly.tms <- mc_agg(tms.calc,
                     fun=list(TMS_T3 =c("mean","min","max")), ### to fasten the computation, only selection the sensor of interest
                     period = "hour",
                     min_coverage=1,use_utc = T) ##have to use UTC == T for hourly

# Export the object out of the myClim framework so you can view it.  
export_dt_hourly <- data.table(mc_reshape_long(hourly.tms), use_utc = F) %>%
  select(-serial_number, -use_utc) %>% # remove these columns
  mutate(datetime = as.POSIXct(datetime)) %>% # make the date read as a date in lubridate
  mutate(  # add year column and calculate day of year (doy)
    year  = year(datetime),
    month = month(datetime),
    week  = week(datetime),
    day   = day(datetime),
    doy   = yday(datetime),
    hour  = hour(datetime)) %>%
  mutate(sensor_name = case_when(
    str_detect(sensor_name, "percentile2.5") ~ str_replace(sensor_name, "percentile2.5", "min"), # shortens percentiles to just being called min or max
    str_detect(sensor_name, "percentile97.5") ~ str_replace(sensor_name, "percentile97.5", "max"),
    TRUE ~ sensor_name
  ))

period_bailey <- export_dt_hourly[sensor_name == "TMS_T3_mean" &  doy %between% c(213,288) & year %in%c(2022:2024) ]
period_bailey_agg <- period_bailey[ , .(mean_T3 = mean(value,na.rm = T)), by = .(year,doy)]


(the_plot <- ggplot(period_bailey_agg[,],aes(x = doy, y = mean_T3 ))+
  geom_line(lwd = 1)+
  facet_wrap( ~ year)+
  theme_bw()+
  geom_hline(yintercept = 0,lty = 2)+
  #geom_line(data = period_bailey,aes( y = value,group = locality_id),alpha = 0.05)+
  scale_x_continuous(breaks = seq(from = 210, to = 290, by = 10))+
  geom_smooth())

library(plotly)
### interactive plot
ggplotly(the_plot)

unique(export_dt_hourly$sensor_name) #checking that the sensor names were shortened correctly

view(export_dt_hourly)
