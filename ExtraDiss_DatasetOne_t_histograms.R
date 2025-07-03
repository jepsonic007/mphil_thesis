library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(patchwork)
library(ggpubr)
library(stringr)
setwd("U:/Documents-U/UDrive_RAnalysis/Graphing_t_histograms_Tuckute")

# Load and clean full dataset
unthresh_table <- read_csv("vox_hist_unthresh_masked.csv") %>%
  mutate(
    parcel = case_when(
      parcel == "LMFG_bin_-41_32_29" ~ "LMFG (MD)",
      parcel == "LMFG_bin_-43_-0_51" ~ "LMFG (Lang)",
      parcel == "wholebrain" ~ "Wholebrain",
      parcel == "LParInf_anterior_bin_-46_-38_46" ~ "LParInf ant",
      parcel == "LParInf_bin_-41_-54_49" ~ "LParInf",
      parcel == "RParInf_anterior_bin_46_38_46" ~ "RParInf ant",
      parcel == "RParInf_bin_41_54_49" ~ "RParInf",
      parcel == "wholebrain_minus_L_language_parcels_bin" ~ "WB minus Lang",
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula m LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) m LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup m LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG m [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA m LMFG (Lang)",
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula m LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) m LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup m LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG m [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA m LMFG (Lang)",
      TRUE ~ parcel  # Keeps original value if no condition matches
    ),
    parcel = str_remove(parcel, "_.*"),
    area = case_when(
      area == "LR_MD_parcels" ~ "LR MD parcels",
      area == "wholebrain" ~ "Wholebrain",
      area == "wholebrain_minus_L_language_parcels" ~ "WB minus Lang",
      area == "L_language_parcels" ~ "L Language parcels",
      area == "MD_not_language_parcels" ~ "MD minus Lang",
      area == "MD_parcels_top10_masked" ~ "MD parcels top 10 masked",
      TRUE ~ area
    ))

# Option 1
unthresh_table_criteria <- unthresh_table %>%
  group_by(subj, parcel) %>%
  mutate(
    top10_all = as.integer(t_values >= quantile(t_values, 0.9, na.rm = TRUE)),
    top10_pos = as.integer(t_values > 0 & t_values >= quantile(t_values[t_values > 0], 0.9, na.rm = TRUE)),
    top20_pos = as.integer(t_values > 0 & t_values >= quantile(t_values[t_values > 0], 0.8, na.rm = TRUE))
  ) %>%
  ungroup() %>%
  mutate(
    criteria_group = case_when(
      top10_all == 1 & top10_pos == 1 & top20_pos == 1 ~ "All Three",
      top10_pos == 1 & top20_pos == 1 ~ "Top10+Top20 Pos",
      top10_all == 1 ~ "Top10 All",
      top10_pos == 1 ~ "Top10 Pos",
      top20_pos == 1 ~ "Top20 Pos",
      TRUE ~ "None"
    )
  )

# Option 2
unthresh_table_criteria <- unthresh_table %>%
  group_by(subj, parcel) %>%
  mutate(
    top10_all = as.integer(t_values >= quantile(t_values, 0.9, na.rm = TRUE))) %>%
  ungroup() %>%
  mutate(
    definition = case_when(
      top10_all == 1 ~ "Top10 All",
      top10_all != 1 ~ "None"))

# GRAPH: TOP 10 THRESH ----------------------------------------------------
unthresh_table_criteria_filt <- unthresh_table_criteria %>%
  filter(area == "L Language parcels")

# OPTION 1
# Create column graph
p_histogram <- ggplot(unthresh_table_criteria_filt, aes(x = t_values, fill = most_active_definition)) +
  geom_histogram(binwidth = 0.05, alpha = 0.7, position = "stack") +
  xlab("T-value (bin width = 0.05)") +
  ylab("Frequency") +
  facet_grid(. ~ parcel) +
  scale_fill_manual(values = c(
    "Top10 All" = "blue",
    "Top10 All + Top20 Pos" = "green",
    "Top20 Pos" = "yellow",
    "None" = "grey70"
  )) +
  annotate("segment",
             x = 0, xend = 0,
             y = -5, yend = 5,  # adjust based on your y-scale
             color = "red", linewidth = 0.2) +
  # geom_vline(xintercept = 0, linetype = "solid", color = "red", linewidth = 0.2) +
  coord_cartesian(ylim = c(0, 150)) +
  scale_x_continuous(limits = c(-12, 12), breaks = c(0)) +
  theme()

p_histogram

ggsave("hist_top10all_top20_clipped.png",plot=p_histogram,
       width = 8,
       height =4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_t_histograms_Tuckute")

# theme_minimal() for exporting with no background

  
p_histogram_subj <- ggplot(unthresh_table_criteria_filt, aes(x = t_values, fill = most_active_definition)) +
  geom_histogram(binwidth = 0.1, alpha = 0.7, position = "stack") +
  xlab("T-value (binwidth = 0.1)") +
  ylab("Frequency (max = 50)") +
  facet_grid(subj ~ parcel) +
  scale_fill_manual(values = c(
    "Top10 All" = "blue",
    "Top10 All + Top20 Pos" = "green",
    "Top20 Pos" = "yellow",
    "None" = "grey70"
  )) +
  # annotate("segment",  x = 0, xend = 0, y = -100, yend = 100, color = "red", linewidth = 0.2) +
  geom_vline(xintercept = 0, linetype = "solid", color = "red", linewidth = 0.2) +
  coord_cartesian(ylim = c(0, 50)) +
  scale_x_continuous(limits = c(-5, 5),breaks = c(0)) +
  theme(axis.text.y = element_blank())

p_histogram_subj

ggsave("hist_top10all_top20_bysubj_clipped.png",plot=p_histogram_subj,
       width = 8,
       height = 17,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_t_histograms_Tuckute")




# OPTION 2
unthresh_table_criteria_filt$definition <- factor(unthresh_table_criteria_filt$definition, levels = c( "None","Top10 All"))

p_histogram <- ggplot(unthresh_table_criteria_filt, aes(x = t_values, fill = definition)) +
  geom_histogram(binwidth = 0.05, alpha = 0.7, position = "stack") +
  xlab("T-value (bin width = 0.05)") +
  ylab("Frequency") +
  facet_grid(. ~ parcel) +
  scale_fill_manual(values = c(
    "Top10 All" = "blue",
    "None" = "grey70"
  )) +
  annotate("segment",
           x = 0, xend = 0,
           y = -5, yend = 5,  # adjust based on your y-scale
           color = "red", linewidth = 0.2) +
  # geom_vline(xintercept = 0, linetype = "solid", color = "red", linewidth = 0.2) +
  coord_cartesian(ylim = c(0, 750)) +
  scale_x_continuous(limits = c(-12, 12), breaks = c(0)) +
  theme()

p_histogram

ggsave("report_hist_top10all.png",plot=p_histogram,
       width = 8,
       height =4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_t_histograms_Tuckute")


p_histogram_subj <- ggplot(unthresh_table_criteria_filt, aes(x = t_values, fill = definition)) +
  geom_histogram(binwidth = 0.1, alpha = 0.7, position = "stack") +
  xlab("T-value (binwidth = 0.1)") +
  ylab("Frequency (max = 50)") +
  facet_grid(subj ~ parcel) +
  scale_fill_manual(values = c(
    "Top10 All" = "blue",
    "None" = "grey70"
  )) +
  # annotate("segment",  x = 0, xend = 0, y = -100, yend = 100, color = "red", linewidth = 0.2) +
  geom_vline(xintercept = 0, linetype = "solid", color = "red", linewidth = 0.2) +
  coord_cartesian(ylim = c(0, 50)) +
  scale_x_continuous(limits = c(-5, 5),breaks = c(0)) +
  theme(axis.text.y = element_blank())

p_histogram_subj

ggsave("report_hist_top10all_bysubj.png",plot=p_histogram_subj,
       width = 10,
       height = 17,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_t_histograms_Tuckute")
