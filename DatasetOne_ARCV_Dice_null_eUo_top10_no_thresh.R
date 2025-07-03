library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(patchwork)
library(ggpubr)
library(stringr)
setwd("U:/Documents-U/UDrive_RAnalysis/Tables_Dice_null_Tuckute")

# Load and clean full dataset
dice_rand_table <- read_csv("real_vs_null_dice_20thresh_results_eUo_top10_no_thresh.csv") %>%
  mutate(parcel = case_when(
    parcel == "LMFG_bin_-41_32_29" ~ "LMFG (MD)",
    parcel == "LMFG_bin_-43_-0_51" ~ "LMFG (Lang)",
    parcel == "wholebrain" ~ "Whole-brain",
    parcel == "LParInf_anterior_bin_-46_-38_46" ~ "LParInf ant",
    parcel == "LParInf_bin_-41_-54_49" ~ "LParInf",
    parcel == "RParInf_anterior_bin_46_38_46" ~ "RParInf ant",
    parcel == "RParInf_bin_41_54_49" ~ "RParInf",
    TRUE ~ parcel,  # Keeps original value if no condition matches
      ),
    parcel = str_remove(parcel, "_.*"))


# P-VALUES
# Create summarised means table
mean_null_parcel <- dice_rand_table %>%
  group_by(area, parcel) %>%
  summarise(
    mean_p = mean(p_value, na.rm = TRUE))





mean_null_parcel_subj <- dice_rand_table %>%
  group_by(area, parcel, subject) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "L_language_parcels")

mean_null_parcel_run <- dice_rand_table %>%
  group_by(area, parcel, run) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "L_language_parcels")

mean_null_parcel_subj_run <- dice_rand_table %>%
  group_by(area, parcel, subject, run) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "L_language_parcels")



dice_rand_signif_count <- dice_rand_table %>%
  group_by(parcel) %>%
  summarise(
    p_gt_.05_count = sum(p_value>0.05),
    p_gt_.1_count = sum(p_value>0.1),
    p_gt_.5_count = sum(p_value>0.5))



mean_null_parcel <- dice_rand_table %>%
  group_by(area,parcel) %>%
  summarise(
    mean_p = mean(p_value)) %>%
  filter(area == "LR_MD_parcels")

mean_null_parcel_subj <- dice_rand_table %>%
  group_by(area, parcel, subject) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "LR_MD_parcels")

mean_null_parcel_run <- dice_rand_table %>%
  group_by(area, parcel, run) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "LR_MD_parcels")

mean_null_parcel_subj_run <- dice_rand_table %>%
  group_by(area, parcel, subject, run) %>%
  summarise(
    mean_p = mean(p_value)
  )  %>%
  filter(area == "LR_MD_parcels")
