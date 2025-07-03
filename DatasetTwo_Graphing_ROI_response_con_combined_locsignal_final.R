library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(ggpubr)
setwd("U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")

# Loading full dataset (all four locations, all 5 ROI definitions), from U-Drive version
response_estimation_table <- read_csv("mean_response_loop_no_thresh_conmap.csv") %>%
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
      # MD-not-lang names (top 10)
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula m LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) m LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup m LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG m [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA m LMFG (Lang)",
      # MD-not-lang names (top 10 masked)
      parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4_modified" ~ "LInsula m LIFGorb",
      parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19_modified" ~ "LMFG (MD) m LIFG",
      parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25_modified" ~ "LParSup m LAG",
      parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51_modified" ~ "LPrecG m [LIFG & LMFG]",
      parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51_modified" ~ "LSMA m LMFG (Lang)",
      # lang-not-MD names
      parcel == "LAG_bin_-43_-68_25_not_LParSup_bin_-19_-67_50" ~ "LAG m LParSup",
      parcel == "LIFG_bin_-50_19_19_not_LMFG_bin_-41_32_29_not_LPrecG_bin_-46_8_32" ~ "LIFG m [LMFG & LPrecG]",
      parcel == "LIFGorb_bin_-47_27_-4_not_LInsula_bin_-33_21_-0" ~ "LIFGorb m LIns",
      parcel == "LMFG_bin_-43_-0_51_not_LPrecG_bin_-46_8_32_not_LSMA_bin_-28_1_59" ~ "LMFG m LPrecG",
      # lang-not-MD names (top 10 masked)
      parcel == "LAG_bin_-43_-68_25_not_LParSup_bin_-19_-67_50_modified" ~ "LAG m LParSup",
      parcel == "LIFG_bin_-50_19_19_not_LMFG_bin_-41_32_29_not_LPrecG_bin_-46_8_32_modified" ~ "LIFG m [LMFG & LPrecG]",
      parcel == "LIFGorb_bin_-47_27_-4_not_LInsula_bin_-33_21_-0_modified" ~ "LIFGorb m LIns",
      parcel == "LMFG_bin_-43_-0_51_not_LPrecG_bin_-46_8_32_not_LSMA_bin_-28_1_59_modified" ~ "LMFG m LPrecG",
      TRUE ~ parcel  # Keeps original value if no condition matches
    ),
    parcel = str_remove(parcel, "_.*"),
    area = case_when(
      area == "L_language_parcels" ~ "L Language parcels",
      area == "LR_MD_parcels" ~ "LR MD parcels",
      area == "wholebrain" ~ "Wholebrain",
      area == "wholebrain_minus_L_language_parcels" ~ "WB minus Lang",
      area == "wholebrain_minus_LR_MD_parcels" ~ "WB minus MD",
      area == "wholebrain_top_677_vox" ~ "Wholebrain (top 677)",
      area == "wholebrain_minus_L_language_parcels_top_677_vox" ~ "WB minus Lang (top 677)",
      area == "wholebrain_minus_LR_MD_parcels_top_677_vox" ~ "WB minus MD (top 677)",
      area == "MD_not_language_parcels" ~ "MD minus Lang (top 10)",
      area == "MD_parcels_top10_masked" ~ "MD minus Lang (top 10 masked)",
      area == "language_not_MD_parcels" ~ "Lang minus MD (top 10)",
      area == "language_parcels_top10_masked" ~ "Lang minus MD (top 10 masked)",
      TRUE ~ area
    ),
    ROI_definition = case_when(
      ROI_definition == "SvFuNvF_U_HvFuEvF" ~ "Top 10% SuN and HuE",
      ROI_definition == "SvFuNvF_n_HvFuEvF" ~ "Top 10% SuN conj. HuE",
      ROI_definition == "SvN_n_HvE" ~ "Top 10% SvN conj. HvE",
      ROI_definition == "SvN_U_HvE" ~ "Top 10% SvN and HvE",
      TRUE ~ ROI_definition),
    SvF_minus_NvF = SvF_mean - NvF_mean,
    HvF_minus_EvF = HvF_mean - EvF_mean,
    SvN_minus_HvE = SvF_minus_NvF - HvF_minus_EvF)


full_response <- response_estimation_table %>%
  pivot_longer(cols = c(SvF_mean, NvF_mean, SvF_minus_NvF, HvF_mean, EvF_mean, HvF_minus_EvF,SvN_minus_HvE), names_to = "Condition", values_to = "BOLD_response") %>%
  mutate(signal_domain = ifelse(Condition  %in% c("SvF_mean", "NvF_mean", "SvF_minus_NvF"),
                                "language_signal", "MD_signal")) %>%
  filter(ROI_definition == "Top 10% SuN and HuE" | ROI_definition == "Top 10% SuN conj. HuE" | ROI_definition == "Top 10% SvN conj. HvE" | ROI_definition == "Top 10% SvN and HvE") %>%
  filter(BOLD_response == as.numeric(BOLD_response)) %>%
  mutate(
    Condition = case_when(
      Condition == "SvF_mean" ~ "Sentence > Rest",
      Condition == "NvF_mean" ~ "Nonwords > Rest",
      Condition == "SvF_minus_NvF" ~ "Sentence - Nonwords",
      Condition == "HvF_mean" ~ "Hard > Rest",
      Condition == "EvF_mean" ~ "Easy > Rest",
      Condition == "HvF_minus_EvF" ~ "Hard - Easy",
      Condition == "SvN_minus_HvE" ~ "(Sentence - Nonwords) - (Hard - Easy)"))













# SvN n HvE --------------------------------------

# LANG PAR
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SvN conj. HvE") %>%
  filter(area == "L Language parcels")

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  left_join(
    response_mean %>% select(ROI_definition, area, parcel, Condition, Mean, SEM),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + SEM + 0.05)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.1)

# Column graphs
p_lang_SvN_HvE_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-0.08, 1.4)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.5,
                     tip.length = 0.001) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.5,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_lang_SvN_HvE_response

ggsave("report_Assem_SvN_HvE_langpar_conj.png",plot=p_lang_SvN_HvE_response,
       width = 12,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")

# 1) filtering data
filtered_full_response <- filtered_full_response %>%
  filter(Condition == "(Sentence - Nonwords) - (Hard - Easy)")

# 2) graphing data - boxplot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response, colour = ROI_definition, group = ROI_definition)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# define linear model - include all possible interactions?
lm_langParcelxBOLD <- lm(BOLD_response ~ parcel,
                     data = filtered_full_response)

# Check diagnostics for assumptions
resid_panel(lm_langParcelxBOLD,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)

# 7) run ANOVA
anovalangParcelxBOLD <- anova(lm_langParcelxBOLD)
ParcelxBOLD <- tukey_hsd(lm_langParcelxBOLD)






# LMD parcels --------
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SvN conj. HvE") %>%
  filter(area == "LR MD parcels") %>%
  filter(startsWith(parcel, "L"))

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  left_join(
    response_mean %>% select(ROI_definition, area, parcel, Condition, Mean, SEM),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + SEM + 0.05)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance()
  add_y_position(fun = "mean_se", step.increase=0.1)

# Column graphs
p_LMD_SvN_HvE_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-0.65, 2.8)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.2,
                     tip.length = 0.001) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.2,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_LMD_SvN_HvE_response

ggsave("report_Assem_SvN_HvE_LMD_conj.png",plot=p_LMD_SvN_HvE_response,
       width = 12,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")

# 1) filtering data
filtered_full_response <- filtered_full_response %>%
  filter(Condition == "(Sentence - Nonwords) - (Hard - Easy)")

# 2) graphing data - boxplot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response, colour = ROI_definition, group = ROI_definition)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# define linear model - include all possible interactions?
lm_LMDParcelxBOLD <- lm(BOLD_response ~ parcel,
                         data = filtered_full_response)

# Check diagnostics for assumptions
resid_panel(lm_LMDParcelxBOLD,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)

# 7) run ANOVA
anovaLMDParcelxBOLD <- anova(lm_LMDParcelxBOLD)
ParcelxBOLD <- tukey_hsd(lm_LMDParcelxBOLD)






# RMD parcels --------
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SvN conj. HvE") %>%
  filter(area == "LR MD parcels") %>%
  filter(startsWith(parcel, "R"))

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  left_join(
    response_mean %>% select(ROI_definition, area, parcel, Condition, Mean, SEM),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + SEM+ 0.1)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.15)

# Column graphs
p_RMD_SvN_HvE_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-1.2, 3.2)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.5,
                     tip.length = 0.001) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.5,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_RMD_SvN_HvE_response

ggsave("report_Assem_SvN_HvE_RMD_conj.png",plot=p_RMD_SvN_HvE_response,
       width = 12,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")


# 1) filtering data
filtered_full_response <- filtered_full_response %>%
  filter(Condition == "(Sentence - Nonwords) - (Hard - Easy)")

# 2) graphing data - boxplot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response)) +
  geom_boxplot()

# 3) graphing data - scatter plot
ggplot(data = filtered_full_response,
       aes(x = parcel, y = BOLD_response, colour = ROI_definition, group = ROI_definition)) +
  geom_jitter(width = 0.05) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line")

# define linear model - include all possible interactions?
lm_RMDParcelxBOLD <- lm(BOLD_response ~ parcel,
                        data = filtered_full_response)

# Check diagnostics for assumptions
resid_panel(lm_RMDParcelxBOLD,
            plots = c("resid", "qq", "ls", "cookd"),
            smoother = TRUE)

# 7) run ANOVA
anovaRMDParcelxBOLD <- anova(lm_RMDParcelxBOLD)
ParcelxBOLD <- tukey_hsd(lm_RMDParcelxBOLD)








# All lang parcels ----------------------
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SuN and HuE" | ROI_definition == "Top 10% SuN conj. HuE") %>%
  filter(area == "L Language parcels")

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()))

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  left_join(
    response_mean %>% select(ROI_definition, area, parcel, Condition, Mean),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + 0.3)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.2)

# Column graphs
p_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-0.5, 4)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.5,
                     tip.length = 0.01) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.5,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response

ggsave("report_Assem_SuN_HuE_langpar.png",plot=p_response,
       width = 12,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")





# All LMD parcels ----------------------
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SuN and HuE" | ROI_definition == "Top 10% SuN conj. HuE") %>%
  filter(area == "LR MD parcels"  & startsWith(parcel, "L"))

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()),
    .groups = "drop")

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance()  %>%
  left_join(
    response_mean %>% select(ROI_definition, parcel, Condition, Mean, SEM),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + SEM + 0.1)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.2)

# Column graphs
p_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-2, 5.5)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.5,
                     tip.length = 0.01) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.5,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response

ggsave("report_Assem_SuN_HuE_LMDpar.png",plot=p_response,
       width = 12,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")



# All RMD parcels ----------------------
filtered_full_response <- full_response %>%
  filter(ROI_definition == "Top 10% SuN and HuE" | ROI_definition == "Top 10% SuN conj. HuE") %>%
  filter(area == "LR MD parcels"  & startsWith(parcel, "R"))

response_mean <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  summarise(
    Mean = mean(BOLD_response),
    SEM = sd(BOLD_response) / sqrt(n()),
    .groups = "drop")

response_mean$Condition <- factor(response_mean$Condition,
                                  levels = c("Sentence > Rest",
                                             "Nonwords > Rest",
                                             "Sentence - Nonwords",
                                             "Hard > Rest",
                                             "Easy > Rest",
                                             "Hard - Easy",
                                             "(Sentence - Nonwords) - (Hard - Easy)"))

filtered_full_response$Condition <- factor(filtered_full_response$Condition,
                                           levels = c("Sentence > Rest",
                                                      "Nonwords > Rest",
                                                      "Sentence - Nonwords",
                                                      "Hard > Rest",
                                                      "Easy > Rest",
                                                      "Hard - Easy",
                                                      "(Sentence - Nonwords) - (Hard - Easy)"))

response_one_sample <- filtered_full_response %>%
  group_by(ROI_definition, area, parcel, Condition) %>%
  t_test(BOLD_response ~ 1, mu=0,alternative="two.sided") %>%
  add_significance() %>%
  left_join(
    response_mean %>% select(ROI_definition, parcel, Condition, Mean),
    by = c("ROI_definition", "parcel", "Condition")
  ) %>%
  mutate(
    y.position = ifelse(Mean < 0, 0.1, Mean + 0.3)
  )

response_paired_t <- filtered_full_response %>%
  filter(Condition != "Sentence - Nonwords" & Condition != "Hard - Easy" & Condition != "(Sentence - Nonwords) - (Hard - Easy)") %>%
  group_by(ROI_definition, area, parcel, signal_domain) %>%
  t_test(BOLD_response ~ Condition, paired = TRUE, alternative = "two.sided") %>%
  add_significance() %>%
  add_y_position(fun = "mean_se", step.increase=0.2)

# Column graphs
p_response <- ggplot(response_mean) +
  geom_col(aes(x = Condition, y = Mean, fill = Condition),
           position = position_dodge(width = 0.9)) +
  geom_point(data = filtered_full_response,
             aes(x = Condition, y = BOLD_response),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.01, fill = "grey") +
  geom_errorbar(
    aes(x = Condition, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Sentence > Rest" = "red",
    "Nonwords > Rest" = "blue",
    "Sentence - Nonwords" = "green",
    "Hard > Rest" = "pink",
    "Easy > Rest" = "cyan",
    "Hard - Easy" = "green",
    "(Sentence - Nonwords) - (Hard - Easy)" = "darkgreen"
  )) +
  xlab("") +
  ylab("Mean BOLD response in ROI masks") +
  scale_y_continuous(limits = c(-2, 5)) +
  facet_grid(ROI_definition ~ parcel) +
  theme(axis.text.x = element_blank()) +
  stat_pvalue_manual(response_paired_t,
                     size = 2.5,
                     tip.length = 0.01) +
  stat_pvalue_manual(response_one_sample,
                     x = "Condition",
                     size = 2.5,
                     y.position = response_one_sample$y.position) +
  theme(axis.text.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

p_response

ggsave("report_Assem_SuN_HuE_RMDpar.png",plot=p_response,
       width = 12,
       height = 4,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_ROI_response_Assem_con")



