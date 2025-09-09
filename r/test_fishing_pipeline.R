#' Process Test Fishing and Sampling workbook
#'
#' Replaces dataflows:
#'   - df_qualark_testfishandsamples_to_silver
#'   - df_insert_drifts_silver_to_sql
#'   - df_insert_fish_samples
#'
#' Steps
#' 1. Read raw Excel data.
#' 2. Cast time fields and validate required columns.
#' 3. Write cleaned data to `data/silver/qualark_testfishing_and_sampling.csv`.
#' 4. Load drifts and fish sample records into SQL tables.

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(DBI)

run_id <- format(Sys.time(), "%Y%m%d-%H%M%S")

raw_file <- "prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx"
# Normalize column names from Excel (spaces and case) to snake_case expected by pipeline
raw <- read_excel(raw_file, col_types = "text") %>%
  rename_with(~ str_replace_all(str_to_lower(.x), "[^a-z0-9]+", "_"))

clean <- raw %>%
  mutate(
    drift_start_time = str_sub(drift_start_time, 12, 19),
    drift_end_time   = str_sub(drift_end_time, 12, 19),
    duration         = str_sub(duration, 12, 19),
    across(c(mesh_size, ends_with("_retained"), ends_with("_released"),
             total_adult_chinook_retained:total_coho_released), as.numeric),
    drift_number = as.integer(drift_number)
  )

validated <- clean %>%
  mutate(
    reason_code = case_when(
      is.na(drift_date) ~ "Missing drift_date",
      is.na(drift_number) | drift_number <= 0 ~ "Invalid drift_number",
      is.na(location) | location == "" ~ "Missing location",
      is.na(mesh_size) | mesh_size < 0 ~ "Invalid mesh_size",
      TRUE ~ "None"
    ),
    pipeline_run_id = run_id
  )

valid <- validated %>% filter(reason_code == "None")
invalid <- validated %>% filter(reason_code != "None") %>%
  mutate(error_timestamp = Sys.time())

dir.create("data/silver", recursive = TRUE, showWarnings = FALSE)
dir.create("data/error", recursive = TRUE, showWarnings = FALSE)

write.csv(valid %>% select(-reason_code, -pipeline_run_id),
          "data/silver/qualark_testfishing_and_sampling.csv", row.names = FALSE)

write.csv(invalid,
          sprintf("data/error/invalid_detailed_catch-%s.csv", run_id),
          row.names = FALSE)

# Lookup tables
locations <- read_excel("prototype_data/lookup/DriftLocation.xlsx")
mesh_sizes <- read_excel("prototype_data/lookup/MeshSizes.xlsx")
species_lookup <- read_excel("prototype_data/lookup/Species.xlsx")
life_history_lookup <- read_excel("prototype_data/lookup/LifeHistoryTypes.xlsx")
mark_lookup <- read_excel("prototype_data/lookup/MarkedFishType.xlsx")

# Prepare drifts
drifts <- valid %>%
  left_join(locations, by = c("location" = "LocationName")) %>%
  left_join(mesh_sizes, by = c("mesh_size" = "MeshSize")) %>%
  transmute(
    drift_date = as.Date(drift_date),
    drift_number,
    location_id = LocationID,
    start_time = drift_start_time,
    end_time   = drift_end_time,
    duration_minutes = duration,
    mesh_id   = MeshId,
    comments
  )

# Pivot fish counts
exclude_cols <- c("drift_date","drift_number","location","drift_start_time",
                  "drift_end_time","duration","mesh_size","comments",
                  "total_adult_chinook_retained","total_jack_chinook_retained",
                  "total_adult_chinook_released","total_jack_chinook_released",
                  "total_coho_retained","total_coho_released")

long_samples <- valid %>%
  pivot_longer(-all_of(exclude_cols), names_to = "metric", values_to = "catch_count") %>%
  filter(!is.na(catch_count) & catch_count > 0) %>%
  mutate(metric = str_to_lower(metric), parts = str_split(metric, "_"))

parse_samples <- long_samples %>%
  mutate(
    is_lh_first = map_lgl(parts, ~ .x[1] %in% c("adult", "jack")),
    life_history_key = if_else(is_lh_first, map_chr(parts, 1), "none"),
    species_key = if_else(is_lh_first, map_chr(parts, 2), map_chr(parts, 1)),
    retention_key = if_else(is_lh_first, map_chr(parts, 3), map_chr(parts, 2)),
    marking_token = if_else(
      is_lh_first,
      if_else(lengths(parts) == 5, paste(map_chr(parts,4), map_chr(parts,5), sep="_"), "none"),
      if_else(lengths(parts) == 4, paste(map_chr(parts,3), map_chr(parts,4), sep="_"), "none")
    ),
    retention_type = if_else(str_detect(retention_key, "released"), "Released", "Retained")
  ) %>%
  left_join(species_lookup, by = c("species_key" = "Species")) %>%
  left_join(life_history_lookup, by = c("life_history_key" = "LifeHistoryType")) %>%
  left_join(mark_lookup, by = c("marking_token" = "MarkedFishTypeCode")) %>%
  rename(
    species_id = SpeciesId,
    life_history_type_id = LifeHistoryTypeId,
    adipose_status = MarkedFishTypeId
  )

# Connect to DB
con <- dbConnect(
  RPostgres::Postgres(),
  host     = Sys.getenv("DB_HOST"),
  port     = Sys.getenv("DB_PORT", "5432"),
  dbname   = Sys.getenv("DB_NAME"),
  user     = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASS")
)

# Load drifts
if (nrow(drifts) > 0) {
  dbWriteTable(con, "drifts", drifts, append = TRUE, row.names = FALSE)
}

drift_lookup <- dbReadTable(con, "drifts") %>% select(drift_id, drift_date, drift_number)

samples_final <- parse_samples %>%
  left_join(drift_lookup, by = c("drift_date", "drift_number")) %>%
  transmute(
    drift_id,
    species_id,
    retention_type,
    life_history_type_id,
    catch_count,
    adipose_status
  )

if (nrow(samples_final) > 0) {
  dbWriteTable(con, "fish_samples", samples_final, append = TRUE, row.names = FALSE)
}

dbDisconnect(con)
