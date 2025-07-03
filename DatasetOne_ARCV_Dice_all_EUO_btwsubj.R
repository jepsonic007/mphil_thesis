library(tidyverse)
library(ggplot2)
library(ggResidpanel)
library(tidyr)
library(rstatix)
library(dplyr)
library(patchwork)
library(ggpubr)
library(stringr)
setwd("U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")

# Load full dataset
dice_EUO_btwsubj_table <- read_csv("ARCV_Dice_all_EUO_btwsubj.csv") %>%
  mutate(Parcel = case_when(
    Parcel == "LMFG_bin_-41_32_29" ~ "LMFG (MD)",
    Parcel == "LMFG_bin_-43_-0_51" ~ "LMFG (Lang)",
    Parcel == "wholebrain" ~ "Whole-brain",
    Parcel == "LParInf_anterior_bin_-46_-38_46" ~ "LParInf ant",
    Parcel == "LParInf_bin_-41_-54_49" ~ "LParInf",
    Parcel == "RParInf_anterior_bin_46_38_46" ~ "RParInf ant",
    Parcel == "RParInf_bin_41_54_49" ~ "RParInf",
    Parcel == "wholebrain_minus_L_language_Parcels_bin" ~ "WB minus Lang",
    Parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula - LIFGorb",
    Parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) - LIFG",
    Parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup - LAG",
    Parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG - [LIFG & LMFG]",
    Parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA - LMFG (Lang)",
    Parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4" ~ "LInsula - LIFGorb",
    Parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19" ~ "LMFG (MD) - LIFG",
    Parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25" ~ "LParSup - LAG",
    Parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51" ~ "LPrecG - [LIFG & LMFG]",
    Parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51" ~ "LSMA - LMFG (Lang)",
    TRUE ~ Parcel,  # Keeps original value if no condition matches
  ),
  Parcel = str_remove(Parcel, "_.*"),
  Area = case_when(
    Area == "LR_MD_parcels" ~ "LR MD parcels",
    Area == "wholebrain" ~ "Whole-brain",
    Area == "wholebrain_minus_L_language_parcels" ~ "WB minus Lang",
    Area == "L_language_parcels" ~ "L Language parcels",
    Area == "MD_not_language_parcels" ~ "MD minus Lang",
    Area == "MD_Parcels_top10_masked" ~ "MD parcels top 10 masked",
    TRUE ~ Area
  ),
  Dice_all_EUO_btw_subj = ifelse(is.nan(Dice_all_EUO_btw_subj), 0, Dice_all_EUO_btw_subj))



# Across Lang parcels --------------------------------------------------------

# Specify language-only table
dice_EUO_btwsubj_filtered <- dice_EUO_btwsubj_table %>%
  filter(Area == "L Language parcels")

# Create summarised means table
dice_EUO_btwsubj_means <- dice_EUO_btwsubj_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_all_EUO_btw_subj),
    SEM = sd(Dice_all_EUO_btw_subj) / sqrt(n()),
    Sample_size = n())

# Create one-sample t-test (mu > 0) df
dice_EUO_btwsubj_one_sample <- dice_EUO_btwsubj_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_all_EUO_btw_subj ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EUO_btwsubj_means <- ggplot(dice_EUO_btwsubj_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EUO_btwsubj_filtered, aes(x = Parcel, y = Dice_all_EUO_btw_subj),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.2, fill = "grey") +
  geom_errorbar(
    aes(x = Parcel, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("LAG" = "steelblue",
                               "LAntTemp" = "lemonchiffon3",
                               "LIFG" = "darkseagreen",
                               "LIFGorb" = "indianred",
                               "LMFG (Lang)" = "mediumpurple",
                               "LPostTemp" = "lightsalmon3")) +
  xlab("Between-subject Dice, across language parcels") +
  ylab("Dice") +
  scale_y_continuous(limits = c(-0, 1)) +
  guides(fill = "none") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )


p_dice_EUO_btwsubj_means

ggsave("report_Dice_EUO_langpar.png",plot=p_dice_EUO_btwsubj_means,
       width = 8,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")



# Across Lang parcels + WB  --------------------------------------------------------

# Specify language-only table
dice_EUO_btwsubj_filtered <- dice_EUO_btwsubj_table %>%
  filter(Area == "L Language parcels" | Area == "Whole-brain")

# Create summarised means table
dice_EUO_btwsubj_means <- dice_EUO_btwsubj_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_all_EUO_btw_subj),
    SEM = sd(Dice_all_EUO_btw_subj) / sqrt(n()),
    Count_Zero = sum(Dice_all_EUO_btw_subj == 0),
    Count_Greater_Zero = sum(Dice_all_EUO_btw_subj > 0))

# Create one-sample t-test (mu > 0) df
dice_EUO_btwsubj_one_sample <- dice_EUO_btwsubj_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_all_EUO_btw_subj ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EUO_btwsubj_means <- ggplot(dice_EUO_btwsubj_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EUO_btwsubj_filtered, aes(x = Parcel, y = Dice_all_EUO_btw_subj),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.2, fill = "grey") +
  geom_errorbar(
    aes(x = Parcel, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("LAG" = "steelblue",
                               "LAntTemp" = "lemonchiffon3",
                               "LIFG" = "darkseagreen",
                               "LIFGorb" = "indianred",
                               "LMFG (Lang)" = "mediumpurple",
                               "LPostTemp" = "lightsalmon3")) +
  xlab("Between-subject Dice similarity") +
  ylab("Dice") +
  scale_y_continuous(limits = c(-0, 1)) +
  guides(fill = "none") +
  stat_pvalue_manual(dice_EUO_btwsubj_one_sample,
                     x="Parcel",
                     y.position=dice_EUO_btwsubj_means$Mean + dice_EUO_btwsubj_means$SEM + 0.05) +
  theme(axis.text.x = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
)

p_dice_EUO_btwsubj_means

ggsave("report_Dice_EUO_langpar_WB.png",plot=p_dice_EUO_btwsubj_means,
       width = 8,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")






# Across MD parcels --------------------------------------------------------

# Specify language-only table
dice_EUO_btwsubj_table_MD <- dice_EUO_btwsubj_table %>%
  filter(Area == "LR MD parcels")

# Create summarised means table
dice_EUO_MD_parcels_means <- dice_EUO_btwsubj_table_MD %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_all_EUO_btw_subj),
    SEM = sd(Dice_all_EUO_btw_subj) / sqrt(n()),
    Count_Zero = sum(Dice_all_EUO_btw_subj == 0),
    Count_Greater_Zero = sum(Dice_all_EUO_btw_subj > 0))

# Create one-sample t-test (mu > 0) df
dice_EUO_MD_parcels_one_sample <- dice_EUO_btwsubj_table_MD %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_all_EUO_btw_subj ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EUO_MD_parcels_means <- ggplot(dice_EUO_MD_parcels_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EUO_btwsubj_table_MD, aes(x = Parcel, y = Dice_all_EUO_btw_subj),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.2, fill = "grey") +
  geom_errorbar(
    aes(x = Parcel, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "LACC"         = "steelblue2",       # more saturated than lightsteelblue1
    "LInsula"      = "plum2",            # unchanged
    "LMFG (MD)"    = "turquoise3",       # richer than paleturquoise3
    "LMFGorb"      = "hotpink3",         # deeper than lightpink3
    "LParInf ant"  = "orchid",           # deeper than thistle3
    "LParInf"      = "cyan3",            # more vivid than lightcyan3
    "LParSup"      = "lightcoral",       # stronger than mistyrose3
    "LPrecG"       = "darkseagreen3",    # richer than honeydew3
    "LSMA"         = "lavenderblush2",   # slightly more intense than lavenderblush3
    "RACC"         = "steelblue2",
    "RInsula"      = "plum2",
    "RMFG"         = "turquoise3",
    "RMFGorb"      = "hotpink3",
    "RParInf ant"  = "orchid",
    "RParInf"      = "cyan3",
    "RParSup"      = "lightcoral",
    "RPrecG"       = "darkseagreen3",
    "RSMA"         = "lavenderblush2"
  )) +
  xlab("Between-subject evenUodd mask Dice similarity, in MD parcels") +
  ylab("Dice (mean)") +
  scale_y_continuous(limits = c(-0.1, 1)) +
  guides(fill = "none") +
  stat_pvalue_manual(dice_EUO_MD_parcels_one_sample,
                     x="Parcel",
                     y.position=dice_EUO_MD_parcels_means$Mean + dice_EUO_MD_parcels_means$SEM + 0.05)

p_dice_EUO_MD_parcels_means

ggsave("Dice_EUO_MDpar.png",plot=p_dice_EUO_MD_parcels_means,
       width = 12,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")


