
### run pre processing script until  ggetting tms.calc

################## Aggregate to HOURLY values  ################# 
hourly.tms <- mc_agg(tms.calc,
                     fun=list(TMS_T3 =c("mean","min","max")), ### to fasten the computation, only selection the sensor of interest
                     period = "hour",
                     min_coverage=1,use_utc = T) ##have to use UTC == T for hourly

# Export the object out of the myClim framework so you can view it.  
export_dt_hourly <- data.table(mc_reshape_long(hourly.tms, use_utc = F)) %>%
  select(-serial_number) %>% # remove these columns
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

period_bailey <- export_dt_hourly[sensor_name == "TMS_T3_mean" &  doy %between% c(226,234) & year %in%c(2022:2024) ]
period_bailey_agg <- period_bailey[ , .(mean_T3 = mean(value,na.rm = T)), by = .(year,doy,hour,datetime)]


(the_plot <- ggplot(period_bailey_agg[,],aes(x = (hour+1)/24, y = mean_T3 , colour=year))+
  geom_point()+
 # geom_line(lwd = 0.5)+
  facet_wrap( ~ doy)+
  theme_bw()+
  geom_hline(yintercept = 0,lty = 2))
  #geom_line(data = period_bailey,aes( y = value,group = locality_id),alpha = 0.05)+
 # scale_x_continuous(breaks = seq(from = 226, to = 234, by = 1)))

library(plotly)
### interactive plot
ggplotly(the_plot)

unique(export_dt_hourly$sensor_name) #checking that the sensor names were shortened correctly

view(export_dt_hourly)

########################################################################################
the_plot<-ggplot(period_bailey_agg,aes(x = hour, y = mean_T3)) +
  geom_line(aes(group = interaction(year, doy), colour = factor(doy)), alpha = 0.1, linewidth = 0.5) +
  geom_point(aes(shape = factor(year), colour = factor(doy)), alpha = 0.1, size = 2) +
    # Smooth average line across all data combined
  geom_smooth(aes(group = 1), method = "gam", formula = y ~ s(x, bs = "cc"), colour = "black", linewidth = 1.3, se = FALSE) +
  scale_x_continuous(
    breaks = seq(0, 23, by = 4),
    labels = paste0(seq(0, 23, by = 4), ":00")
  ) +
  geom_hline(yintercept = 0, lty = 2, color = "gray50") +
  labs(
    title = "QHI hourly TOMST- Aug 14 - Aug 22",
    x = "Hour of Day",
    y = "Mean T3 Temperature (°C)",
    shape = "Year"
  ) +
  theme_bw() +
  # Hide the massive colour legend since dozens of unique days will clutter the plot
  guides(colour = "none") + 
  theme(panel.grid.minor = element_blank())
