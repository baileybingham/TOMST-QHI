#########################################################
######  Monthly Averages of TOMST for Phenocam Paper ####
#########################################################

library(tidyverse)
library(data.table)
library(lubridate)
        

df <- read_csv("export_data/2026_TOMSTdata_preprocessed_monthly.csv")

#filter to just the T3 trimmed mean and May-Sept
df_t3 <- df %>%
  filter(locality_id %in% sprintf("TOMST_%02d", 1:40),
         sensor_name == "TMS_T3_mean_trimmed_mean",
         month %in% 5:9) %>%
  mutate(sensor_name = "T3_mean_t")
        
df_wide <- df_t3 %>%
  select(locality_id, month, year, value) %>%
  pivot_wider(
    names_from  = year,
    values_from = value,
    names_sort  = TRUE          
  ) %>%
  arrange(locality_id, month)

df_long <- df_wide %>%
  pivot_longer(cols = `2022`:`2026`,
               names_to = "year",
               values_to = "temp") %>%
  mutate(year = factor(year, levels = 2022:2026))

ggplot(df_long, aes(x = month, y = temp, colour = year, group = year)) +
  geom_line(na.rm = TRUE) +
  geom_point(size = 1, na.rm = TRUE) +
  facet_wrap(~ locality_id, ncol = 5) +
  scale_x_continuous(breaks = 5:9, labels = month.abb[5:9]) +
  scale_colour_viridis_d(name = "Year") +
  labs(x = "Month", y = "Monthly Avg T3 Temp (°C)") +
  theme_bw() +
  theme(legend.position = "bottom")

df_jul <- df_long %>%
  filter(month ==7)%>%
  group_by(locality_id, year) %>%
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") %>%
  mutate(temp = ifelse(is.nan(temp), NA, temp))   # all-NA years become NA, not NaN

ggplot(df_jul, aes(x = year, y = locality_id, fill = temp)) +
  geom_tile() +
  scale_fill_gradient2(low = "white", mid = "orange", high = "firebrick",
                       midpoint = median(df_long$temp, na.rm = TRUE),
                       name = "°C", na.value = "grey85") +
  labs(title = "July TMS-3 Temp (°C)", x = "Year", y = NULL) +
  theme_minimal()

df_aug <- df_long %>%
  filter(month ==8)%>%
  group_by(locality_id, year) %>%
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") %>%
  mutate(temp = ifelse(is.nan(temp), NA, temp))   # all-NA years become NA, not NaN

ggplot(df_aug, aes(x = year, y = locality_id, fill = temp)) +
  geom_tile() +
  scale_fill_gradient2(low = "white", mid = "orange", high = "firebrick",
                       midpoint = median(df_long$temp, na.rm = TRUE),
                       name = "°C", na.value = "grey85") +
  labs(title = "August TMS-3 Temp (°C)", x = "Year", y = NULL) +
  theme_minimal()

df_jun <- df_long %>%
  filter(month ==6)%>%
  group_by(locality_id, year) %>%
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") %>%
  mutate(temp = ifelse(is.nan(temp), NA, temp))   # all-NA years become NA, not NaN

ggplot(df_jun, aes(x = year, y = locality_id, fill = temp)) +
  geom_tile() +
  scale_fill_gradient2(low = "white", mid = "orange", high = "firebrick",
                       midpoint = median(df_long$temp, na.rm = TRUE),
                       name = "°C", na.value = "grey85") +
  labs(title = "June TMS-3 Temp (°C)", x = "Year", y = NULL) +
  theme_minimal()

df_may <- df_long %>%
  filter(month ==5)%>%
  group_by(locality_id, year) %>%
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") %>%
  mutate(temp = ifelse(is.nan(temp), NA, temp))   # all-NA years become NA, not NaN

ggplot(df_may, aes(x = year, y = locality_id, fill = temp)) +
  geom_tile() +
  scale_fill_gradient2(low = "white", mid = "orange", high = "firebrick",
                       midpoint = median(df_long$temp, na.rm = TRUE),
                       name = "°C", na.value = "grey85") +
  labs(title = "May TMS-3 Temp (°C)", x = "Year", y = NULL) +
  theme_minimal()
