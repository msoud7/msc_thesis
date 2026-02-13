library(dplyr)
library(tidyverse)
library(haven)

WoON_dir <- "data/WoON data"

time_periods <- c("2012", "2015", "2018", "2021", "2024")

directories <- c("/WoON 2012/WoON2012_e_1.1.sav",
                 "/WoON 2015/WoON2015_e_1.0.sav",
                 "/WoON 2018/WoON2018_e_1.0.sav",
                 "/WoON 2021/WoON2021_e_1.0.sav",
                 "/WoON 2024/WoON2024_e_1.1.sav")

woon_data <- list()

#load all the individual datasets
for (i in seq_along(directories)) {
  path <- file.path(WoON_dir, directories[i])
  name <- paste0("df_WoON_", time_periods[i])
  
  woon_data[[name]] <- read_sav(path)
}


