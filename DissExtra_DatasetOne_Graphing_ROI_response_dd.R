library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(patchwork)
library(ggpubr)
setwd("U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# Loading full dataset (all four locations, all 3 ROI methods), from U-Drive version
response_estimation_table <- read_csv("dd_combined_no_thresh_response.csv") %>%
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
      # DD
      parcel == "wholebrain_minus_L_language_parcels_bin_top677_voxels" ~ "WB minus Lang (677)",
      parcel == "wholebrain_top677_voxels" ~ "Wholebrain (677)",
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
      # DD
      area == "LR_MD_parcels_no_thresh" ~ "LR MD parcels",
      area == "wholebrain_no_thresh" ~ "Wholebrain",
      area == "wholebrain_minus_L_language_parcels_no_thresh" ~ "WB minus Lang",
      area == "L_language_parcels_no_thresh" ~ "L Language parcels",
      area == "MD_not_language_parcels_no_thresh" ~ "MD minus Lang",
      area == "MD_parcels_top10_masked_no_thresh" ~ "MD parcels top 10 masked",
      TRUE ~ area
    ),
    SvR_mean = ifelse(ROI_method == "ARCV", (mean_signal_So + mean_signal_Se)/2, SvR_mean),
    NvR_mean = ifelse(ROI_method == "ARCV", (mean_signal_No + mean_signal_Ne)/2, NvR_mean),
    SvR_minus_NvR = SvR_mean - NvR_mean) %>%
  select(-c(mean_signal_So, mean_signal_Se, mean_signal_No, mean_signal_Ne))

# Creating long format (preserving raw datapoints for jitter)
response_estimation_long <- response_estimation_table %>%
  pivot_longer(cols = c(SvR_mean,NvR_mean,SvR_minus_NvR), names_to = "Condition", values_to = "BOLD_response")








# All ROI methods, Language area ------------------------------------------------

# Creating long format (preserving raw datapoints for jitter)
response_language_area_long <- response_estimation_long %>%
  filter(area == "L Language parcels") %>%
  filter(ROI_method == "ARCV" | ROI_method == "DD")

response_language_parcels_mean <- response_language_area_long %>%
  group_by(ROI_method, area, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_language_parcels_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()

response_language_parcels_paired_t <- response_language_area_long %>%
  filter(Condition != "SvR_minus_NvR") %>%
  group_by(ROI_method) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .3)

# Creating column graph with SEM bars (SvR, NvR)
p_language_parcels_all_methods <- ggplot(response_language_parcels_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             size = 1.5, shape = 21, alpha = 0.15, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "SvR_minus_NvR"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj,parcel)),
            color = "gray60", alpha = 0.15) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("SvR_mean" = "red", "NvR_mean" = "blue", "SvR_minus_NvR" = "green")) +
  xlab("N>R (B), S>R (R), S>R - N>R (G) across language parcels, ARCV v. double-dipping") +
  ylab("Mean t-value response in ROI masks") +
  scale_y_continuous(limits = c(-5, 16)) +
  guides(fill = "none") +
  facet_grid(area ~ ROI_method) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_language_parcels_paired_t) +
  stat_pvalue_manual(response_language_parcels_one_sample,
                     x = "Condition",
                     y.position=response_language_parcels_mean$Mean + response_language_parcels_mean$SEM + 0.7,)

p_language_parcels_all_methods

ggsave("Tuckute_response_DD_langarea.png",plot=p_language_parcels_all_methods,
       width = 6,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")


# All ROI methods, Language parcels ------------------------------------------------

# Creating long format (preserving raw datapoints for jitter)
response_language_area_long <- response_estimation_long %>%
  filter(area == "L Language parcels") %>%
  filter(ROI_method == "ARCV" | ROI_method == "DD")

response_language_parcels_mean <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_language_parcels_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()

response_language_parcels_paired_t <- response_language_area_long %>%
  filter(Condition != "SvR_minus_NvR") %>%
  group_by(ROI_method, parcel) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .3)

# Creating column graph with SEM bars (SvR, NvR)
p_language_parcels_all_methods <- ggplot(response_language_parcels_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             size = 1.5, shape = 21, alpha = 0.15, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "SvR_minus_NvR"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("SvR_mean" = "red", "NvR_mean" = "blue", "SvR_minus_NvR" = "green")) +
  xlab("N>R (B), S>R (R), S>R - N>R (G) in language parcel ROIs, ARCV v. double-dipping") +
  ylab("Mean t-value response in ROI masks") +
  scale_y_continuous(limits = c(-5, 16)) +
  guides(fill = "none") +
  facet_grid(ROI_method ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_language_parcels_paired_t) +
  stat_pvalue_manual(response_language_parcels_one_sample,
                     x = "Condition",
                     y.position=response_language_parcels_mean$Mean + response_language_parcels_mean$SEM + 0.7,)

p_language_parcels_all_methods

ggsave("Tuckute_response_DD_langpar.png",plot=p_language_parcels_all_methods,
       width = 9,
       height = 6,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")






# Graphing the effect of ROI_method and parcel on SvR-minus-NvR differences 
response_language_area_long <- response_estimation_long %>%
  filter(area == "L Language parcels") %>%
  filter(ROI_method == "ARCV" | ROI_method == "DD")

# 1) filtering data
response_diff_allROIs <- response_language_area_long %>%
  filter(Condition == "SvR_minus_NvR")

# 2) graphing data - boxplot
ggplot(data = response_diff_allROIs,
       aes(x = parcel, y = BOLD_response, fill = ROI_method)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = response_diff_allROIs,
       aes(x = parcel, y = BOLD_response, colour = ROI_method, group = ROI_method)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# define linear model - include all possible interactions?
lm_roixparcel_allROIs <- lm(BOLD_response ~ parcel + ROI_method + parcel:ROI_method,
                    data = response_diff_allROIs)

# check diagnostics for assumptions
resid_panel(lm_roixparcel_allROIs,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)
# Q-Q Plot is looking alright

# 7) run ANOVA
anova(lm_roixparcel_allROIs)
langparXmethod <- tukey_hsd(lm_roixparcel_allROIs)



# Graphing the effect of ROI_method (conj. ROI v. ARCV), on SvR-minus-NvR differences  
response_language_area_long <- response_estimation_long %>%
  filter(area == "L Language parcels")

# 1) filtering data
response_diff_twoROIs <- response_language_area_long %>%
  filter(Condition == "SvR_minus_NvR") %>%
  filter(ROI_method != "SnN") # toggle "N n S" to "N u S"

# 2) graphing data - boxplot
ggplot(data = response_diff_twoROIs,
       aes(x = parcel, y = BOLD_response, fill = ROI_method)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = response_diff_twoROIs,
       aes(x = parcel, y = BOLD_response, colour = ROI_method, group = ROI_method)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# 4) define linear model - include all possible interactions?
lm_roixparcel_2ROIs <- lm(BOLD_response ~ parcel + ROI_method + parcel:ROI_method,
                    data = response_diff_twoROIs)

# 5) check diagnostics for assumptions
resid_panel(lm_roixparcel_2ROIs,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)
# Q-Q Plot is not looking great...data not really normal

# 6) run ANOVA
anova(lm_roixparcel_2ROIs)


