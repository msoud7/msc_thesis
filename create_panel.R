library(tidyverse)
library(readr)
library(fixest)
library(ggplot2)
library(readxl)
library(lubridate)
library(stringr)

# ---------------------------------- get files from excel ---------------------------------- 
files <- list.files(
  path = "data/CSRD_thesis_data/data_lseg2",
  pattern = "_data.xlsx$",
  full.names = TRUE
) #get all the files with RegEx

print(files) #print file names to check

# ---------------------------------- clean column names function ---------------------------------- 

clean_colnames <- function(df) {
  
  cols <- colnames(df)
  new_cols <- cols 
  
  current_var <- NULL
  fy_counter <- 0
  in_panel <- FALSE
  
  for (i in seq_along(cols)) {
    
    next_is_dot <- if (i < length(cols)) {
      str_detect(cols[i + 1], "^\\.\\.\\.")
    } else {
      FALSE
    }
    
    if (!str_detect(cols[i], "^\\.\\.\\.") && next_is_dot) {
      
      current_var <- cols[i] %>%
        str_replace_all("\n.*", "") %>%
        str_replace_all("[^A-Za-z0-9]+", "_") %>%
        str_to_lower()
      
      fy_counter <- 0
      in_panel <- TRUE
      new_cols[i] <- paste0(current_var, "_FY", fy_counter)
      
    } else if (str_detect(cols[i], "^\\.\\.\\.") && in_panel) {
      
      fy_counter <- fy_counter + 1
      new_cols[i] <- paste0(current_var, "_FY", fy_counter)
      
    } else {
      in_panel <- FALSE
      current_var <- NULL
    }
  }
  
  colnames(df) <- new_cols
  df
}

# ---------------------------------- read and clean all the files ----------------------------------

#read all files and clean all colnames:
panel_raw <- lapply(files, function(f) {
  
  read_excel(f) %>%
    clean_colnames() %>%
    mutate(
      fiscal_date = ymd(`IV Latest Fiscal Year Period End Date`),
      fiscal_year = year(fiscal_date)
    )
  
}) %>%
  bind_rows(.id = "file_id") %>%
  
  # IMPORTANT: fix duplicate column names AFTER bind
  rename_with(~make.unique(.x, sep = "_dup"))

# ---------------------------------- basic filtering ----------------------------------

panel_raw <- panel_raw %>%
  filter(
    !is.na(fiscal_year)
  )

print("Raw panel loaded:")
glimpse(panel_raw)

# ---------------------------------- save the raw panel to csv  ----------------------------------
write.csv(panel_raw,
          file = "data/CSRD_thesis_data/panel_raw.csv",
          row.names = FALSE
          )

# ---------------------------------- convert fy-wide to long format  ----------------------------------

df_long <- panel_raw %>%
  pivot_longer(
    cols = matches("_FY\\d+"),
    names_to = c("variable", "fy"),
    names_pattern = "(.*)_FY(\\d+)"
  ) %>%
  mutate(
    fy = as.numeric(fy)
  )

# ---------------------------------- convert fy index to a real year ----------------------------------
df_long <- df_long %>%
  mutate(
    year = fiscal_year - fy
  )

# ---------------------------------- back to a panel format (year panel) ----------------------------------

df_panel <- df_long %>%
  pivot_wider(
    names_from = variable,
    values_from = value
  )

# ---------------------------------- save the final panel ----------------------------------
write.csv(df_panel,
          file = "data/CSRD_thesis_data/panel_final.csv",
          row.names = FALSE
          )