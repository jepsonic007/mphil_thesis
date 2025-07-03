library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(ggpubr)
setwd("U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# Load full dataset, rename parcels and areas for graph output
response_estimation_table <- read_csv("combined_no_thresh_response.csv") %>%
  mutate(
    parcel = case_when(
      parcel == "LMFG_bin_-41_32_29" ~ "LMFG (MD)",
      parcel == "LMFG_bin_-43_-0_51" ~ "LMFG (Lang)",
      parcel == "wholebrain" ~ "Whole-brain",
      parcel == "LParInf_anterior_bin_-46_-38_46" ~ "LParInf ant",
      parcel == "LParInf_bin_-41_-54_49" ~ "LParInf",
      parcel == "RParInf_anterior_bin_46_38_46" ~ "RParInf ant",
      parcel == "RParInf_bin_41_54_49" ~ "RParInf",
      parcel == "wholebrain_minus_L_language_parcels_bin" ~ "WB minus Lang",
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula minus LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) minus LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup minus LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG minus [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA minus LMFG (Lang)",
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4_modified" ~ "LInsula minus LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19_modified" ~ "LMFG (MD) minus LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25_modified" ~ "LParSup minus LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51_modified" ~ "LPrecG minus [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51_modified" ~ "LSMA minus LMFG (Lang)",
      TRUE ~ parcel  # Keeps original value if no condition matches
    ),
    parcel = str_remove(parcel, "_.*"),
    area = case_when(
      area == "LR_MD_parcels" ~ "LR MD parcels",
      area == "wholebrain" ~ "Wholebrain",
      area == "wholebrain_minus_L_language_parcels" ~ "Outside lang. parcels",
      area == "L_language_parcels" ~ "L Language parcels",
      area == "MD_not_language_parcels" ~ "MD minus Lang",
      area == "MD_parcels_top10_masked" ~ "MD parcels top 10 masked",
      TRUE ~ area
    ),
    ROI_method = case_when(
      ROI_method == "ARCV" ~ "Top 10% S-N",
      ROI_method == "SuN" ~ "Top 10% S and N",
      ROI_method == "SnN" ~ "Top 10% S conj. N",
      TRUE ~ ROI_method)) %>%
  mutate(across(
    c(mean_signal_So, mean_signal_Se, mean_signal_No, mean_signal_Ne, SvR_mean, NvR_mean),
    ~ ifelse(is.na(.) | is.nan(.), 0, .)
  )) %>%
  mutate(
    SvR_mean = ifelse(ROI_method == "Top 10% S-N", (mean_signal_So + mean_signal_Se)/2, SvR_mean),
    NvR_mean = ifelse(ROI_method == "Top 10% S-N", (mean_signal_No + mean_signal_Ne)/2, NvR_mean),
    SvR_minus_NvR = SvR_mean - NvR_mean) %>%
  select(-c(mean_signal_So, mean_signal_Se, mean_signal_No, mean_signal_Ne))

# Create long format (preserving raw datapoints for jitter)
response_estimation_long <- response_estimation_table %>%
  pivot_longer(cols = c(SvR_mean,NvR_mean,SvR_minus_NvR), names_to = "Condition", values_to = "BOLD_response") %>%
  mutate(
    Condition = case_when(
      Condition == "SvR_mean" ~ "Sentence > Rest",
      Condition == "NvR_mean" ~ "Nonwords > Rest",
      Condition == "SvR_minus_NvR" ~ "Sentence - Nonwords")
    )



# Top 10% S-N, language area & parcels -----------------------------------------

# Filter data:
response_long_filtered <- response_estimation_long %>%
  filter(area == "L Language parcels") %>%
  filter(ROI_method == "Top 10% S-N")

# Analysis & graphing -- across parcels:
# Create data frame containing means
response_mean <- response_long_filtered %>%
  group_by(Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n())
  )

# Create data frame containing one-sample t-tests
response_one_sample <- response_long_filtered %>%
  group_by(Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()

# Create data frame containing paired t-tests
response_paired_t <- response_long_filtered %>%
  filter(Condition != "Sentence - Nonwords") %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .5)

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_mean$Condition <- factor(response_mean$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_long_filtered$Condition <- factor(response_long_filtered$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

# Create column graph
p_language_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_long_filtered,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.01),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_long_filtered %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj,parcel)),
            color = "gray60", alpha = 0.2) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value in functional ROIs, across language parcels") +
  scale_y_continuous(limits = c(-1.5, 9), breaks = seq(-1.5, 9, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ area) +
  stat_pvalue_manual(response_paired_t) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     y.position=response_mean$Mean + response_mean$SEM + 0.5,) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_language_response

ggsave("report_Tuckute_response_langarea.png",plot=p_language_response,
       width = 5,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")


# Analysis & graphing -- by individual parcels:
# Create data frame containing means
response_par_mean <- response_long_filtered %>%
  group_by(parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Create data frame containing one-sample t-tests
response_par_one_sample <- response_long_filtered %>%
  group_by(parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()

# Create data frame containing paired t-tests
response_par_paired_t <- response_long_filtered %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(parcel) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .2)

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_par_mean$Condition <- factor(response_par_mean$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_long_filtered$Condition <- factor(response_long_filtered$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

# Create column graph
p_language_response_par <- ggplot(response_par_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_long_filtered,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.01),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_long_filtered %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.3) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value in functional ROIs, by parcel") +
  scale_y_continuous(limits = c(-1.5, 9), breaks = seq(-1.5, 9, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ parcel) +
  stat_pvalue_manual(response_par_paired_t) +
  stat_pvalue_manual(response_par_one_sample,
                     x = "Condition",
                     y.position=response_par_mean$Mean + response_par_mean$SEM + 0.5) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_language_response_par

ggsave("report_Tuckute_response_langpar.png",plot=p_language_response_par,
       width = 8,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")


# One-way ANOVA
# 1) filtering data
response_long_filtered <- response_long_filtered %>%
  filter(Condition == "Sentence - Nonwords") %>%
  filter(parcel != "LAG")

# 2) graphing data - boxplot
ggplot(data = response_long_filtered,
       aes(x = parcel, y = BOLD_response)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = response_long_filtered,
       aes(x = parcel, y = BOLD_response, colour = ROI_method, group = ROI_method)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# define linear model - include all possible interactions?
lm_ParcelxBOLD <- lm(BOLD_response ~ parcel,
                            data = response_long_filtered)

# Check diagnostics for assumptions
resid_panel(lm_ParcelxBOLD,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)

# 7) run ANOVA
obj <- anova(lm_ParcelxBOLD)
ParcelxBOLD <- tukey_hsd(lm_ParcelxBOLD)






# All 3 ROIs, language area & parcels -----------------------------------------

# Filter data:
response_long_filtered <- response_estimation_long %>%
  filter(area == "L Language parcels") %>% # filter area
  filter(ROI_method %in% c("Top 10% S-N", "Top 10% S and N", "Top 10% S conj. N")) %>% # filter ROI def.
  mutate(
    ROI_method = factor(ROI_method, levels = c(
      "Top 10% S-N",
      "Top 10% S and N",
      "Top 10% S conj. N")
  )) # establish factor levels

# Analysis & graphing -- across parcels:
# Create data frame containing means
response_all_ROIs_mean <- response_long_filtered %>%
  group_by(ROI_method, area, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_all_ROIs_mean$Condition <- factor(response_all_ROIs_mean$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_long_filtered$Condition <- factor(response_long_filtered$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

# Create data frame containing one-sample t-tests
response_all_ROIs_one_sample <- response_long_filtered %>%
  group_by(ROI_method, area, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se")

# Create data frame containing paired t-tests
response_all_ROIs_paired_t <- response_long_filtered %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .3)

# Create column graph
p_language_all_methods <- ggplot(response_all_ROIs_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_long_filtered,
             aes(x = Condition, y = BOLD_response),
             size = 1.5, shape = 21, alpha = 0.05, fill = "grey") +
  geom_line(data = response_long_filtered %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj,parcel)),
            color = "gray60", alpha = 0.15) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 17), breaks = seq(-0, 15, by = 5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ ROI_method) +
  stat_pvalue_manual(response_all_ROIs_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_all_ROIs_one_sample,
                     x = "Condition",
                     size = 3) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_language_all_methods

ggsave("report_Tuckute_response_langarea_allmethods.png",plot=p_language_all_methods,
       width = 7,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# Analysis & graphing -- by individual parcels:
# Create data frame containing means
response_all_ROIs_par_mean <- response_long_filtered %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_all_ROIs_par_mean$Condition <- factor(response_all_ROIs_par_mean$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_long_filtered$Condition <- factor(response_long_filtered$Condition,
  levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

# Create data frame containing one-sample t-tests
response_all_ROIs_par_one_sample <- response_long_filtered %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se")

# Create data frame containing paired t-tests
response_all_ROIs_par_paired_t <- response_long_filtered %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, parcel) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase = .3)

# Create column graph
p_language_parcels_all_methods <- ggplot(response_all_ROIs_par_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_long_filtered,
             aes(x = Condition, y = BOLD_response),
             size = 1.5, shape = 21, alpha = 0.15, fill = "grey") +
  geom_line(data = response_long_filtered %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 17), breaks = seq(-0, 15, by = 5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(ROI_method ~ parcel) +
  stat_pvalue_manual(response_all_ROIs_par_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_all_ROIs_par_one_sample,
                     x = "Condition",
                     size = 3) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )


p_language_parcels_all_methods

ggsave("report_Tuckute_response_langpar_allmethods_FLIPAX.png",plot=p_language_parcels_all_methods,
       width = 8,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# ANOVA

# 1) filtering data
response_diff_allROIs <- response_long_filtered %>%
  filter(Condition == "Sentence - Nonwords")

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
lm_ParcelxBOLDxROIdef <- lm(BOLD_response ~ parcel + ROI_method + parcel:ROI_method,
                    data = response_diff_allROIs)

# check diagnostics for assumptions
resid_panel(lm_ParcelxBOLDxROIdef,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)

# 7) run ANOVA
ParcelxBOLDxROIdef_anova <- anova(lm_ParcelxBOLDxROIdef)
ParcelxBOLDxROIdef <- tukey_hsd(lm_ParcelxBOLDxROIdef)





# Top 10% S-N, MD area & parcels -----------------------------------------

# Across parcels:
# Create long format (preserving raw datapoints for jitter)
response_languageMD_area_long <- response_estimation_long %>%
  filter(area == "L Language parcels" | area == "LR MD parcels") %>%
  filter(ROI_method == "Top 10% S-N")

response_languageMD_area_mean <- response_languageMD_area_long %>%
  group_by(ROI_method, area, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_languageMD_area_mean$Condition <- factor(response_languageMD_area_mean$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_languageMD_area_long$Condition <- factor(response_languageMD_area_long$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_languageMD_area_one_sample <- response_languageMD_area_long %>%
  group_by(ROI_method, area, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()  %>%
  add_y_position(fun = "mean_se")

response_languageMD_area_one_sample <- response_languageMD_area_one_sample %>%
  left_join(
    response_languageMD_area_mean %>%
      select(ROI_method, area, Condition, Mean, SEM),
    by = c("ROI_method", "area", "Condition")
  )

response_languageMD_area_paired_t <- response_languageMD_area_long %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, area) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.3)


# Creating column graph with SEM bars (SvR, NvR)
p_response_language_area_WB_WBminus <- ggplot(response_languageMD_area_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_languageMD_area_long,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.00),
             size = 1.5, shape = 21, alpha = 0.06, fill = "grey") +
  geom_line(data = response_languageMD_area_long %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj,parcel)),
            color = "gray60", alpha = 0.05) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 6), breaks = seq(-1.5, 6, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ area) +
  stat_pvalue_manual(response_languageMD_area_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_languageMD_area_one_sample,
                     x = "Condition",
                     size = 3) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response_language_area_WB_WBminus

ggsave("report_Tuckute_response_langMDarea.png",plot=p_response_language_area_WB_WBminus,
       width = 6,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# By individual MD parcels: all R
# Creating long format (preserving raw datapoints for jitter)
response_language_area_long <- response_estimation_long %>%
  filter(area == "LR MD parcels" & startsWith(parcel, "R")) %>%
  filter(ROI_method == "Top 10% S-N")

response_language_area_mean$Condition <- factor(response_language_area_mean$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))


response_language_area_mean <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_language_area_long$Condition <- factor(response_language_area_long$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_language_area_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.3)

response_language_area_one_sample <- response_language_area_mean %>%
  left_join(
    response_language_area_mean %>%
      select(ROI_method, area, parcel, Condition, Mean, SEM),
    by = c("ROI_method", "area", "parcel", "Condition")
  )

response_language_area_paired_t <- response_language_area_long %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, parcel, area) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.6)

# Creating column graph with SEM bars (SvR, NvR)
p_response_language_area_WB_WBminus <- ggplot(response_language_area_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.00),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 6), breaks = seq(-1.5, 6, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ parcel) +
  stat_pvalue_manual(response_language_area_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_language_area_one_sample,
                     x = "Condition") +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response_language_area_WB_WBminus

ggsave("report_Tuckute_response_RMDpar.png",plot=p_response_language_area_WB_WBminus,
       width = 9.5,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")


# By individual parcels: all L MD
response_language_area_long <- response_estimation_long %>%
  filter(area == "LR MD parcels" & startsWith(parcel, "L")) %>%
  filter(ROI_method == "Top 10% S-N")

response_language_area_mean$Condition <- factor(response_language_area_mean$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_language_area_mean <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_language_area_long$Condition <- factor(response_language_area_long$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_language_area_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se")

response_language_area_paired_t <- response_language_area_long %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, parcel, area) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.3)

# Creating column graph with SEM bars (SvR, NvR)
p_response_language_area_WB_WBminus <- ggplot(response_language_area_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.00),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 6.2), breaks = seq(-1.5, 6, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ parcel) +
  stat_pvalue_manual(response_language_area_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_language_area_one_sample,
                     x = "Condition") +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response_language_area_WB_WBminus

ggsave("report_Tuckute_response_LMDpar.png",plot=p_response_language_area_WB_WBminus,
       width = 9.5,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")



# By individual parcels: 4 sig skewing
# Creating long format (preserving raw datapoints for jitter)
response_language_area_long <- response_estimation_long %>%
  filter(ROI_method == "Top 10% S-N") %>%
  filter(area == "LR MD parcels") %>%
  filter(
    str_starts(parcel, "LACC") |
      str_starts(parcel, "LPrecG") |
      str_starts(parcel, "LSMA") |
      str_starts(parcel, "RPrecG")
  )

response_language_area_mean <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_language_area_mean$Condition <- factor(response_language_area_mean$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_language_area_long$Condition <- factor(response_language_area_long$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_language_area_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se")

response_language_area_paired_t <- response_language_area_long %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, parcel, area) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.3)

# Creating column graph with SEM bars (SvR, NvR)
p_response_language_area_WB_WBminus <- ggplot(response_language_area_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.00),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 6.2), breaks = seq(-1.5, 6, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ parcel) +
  stat_pvalue_manual(response_language_area_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_language_area_one_sample,
                     x = "Condition") +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response_language_area_WB_WBminus

ggsave("report_Tuckute_response_4MDpar.png",plot=p_response_language_area_WB_WBminus,
       width = 7,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")

# ANOVA
# 1) filtering data
response_diff_allROIs <- response_language_area_long %>%
  filter(Condition == "Sentence - Nonwords")

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
lm_MDparxBOLD <- lm(BOLD_response ~ parcel,
                    data = response_diff_allROIs)

# check diagnostics for assumptions
resid_panel(lm_MDparxBOLD,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)
# Q-Q Plot is looking alright

# 7) run ANOVA
anova(lm_MDparxBOLD)
MDparXmeth <- tukey_hsd(lm_roixparcel_allROIs)



# By individual parcels: MD-not-lang
# Creating long format (preserving raw datapoints for jitter)
response_language_area_long <- response_estimation_long %>%
  filter(ROI_method == "Top 10% S-N") %>%
  filter(area == "MD minus Lang")

response_language_area_mean <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

# Set order of 'Condition', in both mean data frame and raw, filtered data frame
response_language_area_mean$Condition <- factor(response_language_area_mean$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))
response_language_area_long$Condition <- factor(response_language_area_long$Condition, levels = c("Sentence > Rest", "Nonwords > Rest", "Sentence - Nonwords"))

response_language_area_one_sample <- response_language_area_long %>%
  group_by(ROI_method, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se")

response_language_area_paired_t <- response_language_area_long %>%
  filter(Condition != "Sentence - Nonwords") %>%
  group_by(ROI_method, parcel, area) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.35)

# Creating column graph with SEM bars (SvR, NvR)
p_response_language_area_WB_WBminus <- ggplot(response_language_area_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = response_language_area_long,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.00),
             size = 1.5, shape = 21, alpha = 0.1, fill = "grey") +
  geom_line(data = response_language_area_long %>% filter(Condition != "Sentence - Nonwords"),
            aes(x = Condition, y = BOLD_response, group = interaction(subj)),
            color = "gray60", alpha = 0.25) +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("Sentence > Rest" = "red", "Nonwords > Rest" = "blue", "Sentence - Nonwords" = "green")) +
  xlab("") +
  ylab("Mean t-value across ROI masks") +
  scale_y_continuous(limits = c(-1.5, 6.2), breaks = seq(-1.5, 6, by = 1.5)) + # Sets axis limits, sets tick range & how often they appear, i.e. 1.5 intervals
  facet_grid(. ~ parcel) +
  stat_pvalue_manual(response_language_area_paired_t,
                     size = 3) +
  stat_pvalue_manual(response_language_area_one_sample,
                     x = "Condition") +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response_language_area_WB_WBminus

ggsave("report_Tuckute_response_MDnotlangpar.png",plot=p_response_language_area_WB_WBminus,
       width = 11,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Tuckute")








