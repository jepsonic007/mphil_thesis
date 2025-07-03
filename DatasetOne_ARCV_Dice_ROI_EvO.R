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

# Load and clean full dataset
dice_EvO_table <- read_csv("ARCV_Dice_ROI_EvO.csv") %>%
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
    Parcel == "LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4_modified" ~ "LInsula - LIFGorb",
    Parcel == "LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19_modified" ~ "LMFG (MD) - LIFG",
    Parcel == "LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25_modified" ~ "LParSup - LAG",
    Parcel == "LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51_modified" ~ "LPrecG - [LIFG & LMFG]",
    Parcel == "LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51_modified" ~ "LSMA - LMFG (Lang)",
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
    Dice_even_v_odd = ifelse(is.nan(Dice_even_v_odd), 0, Dice_even_v_odd))


# Across Lang Parcels --------------------------------------------------------

# Specify language-only table
dice_EvO_filtered <- dice_EvO_table %>%
  filter(Area == "L Language parcels")

# Create summarised means table
dice_EvO_means <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_even_v_odd),
    SEM = sd(Dice_even_v_odd) / sqrt(n()),
    Sample_size = n(),
    Count_Dice_gt_zero = sum(Dice_even_v_odd > 0))

# Create one-sample t-test (mu > 0) df
dice_EvO_one_sample <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_even_v_odd ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EvO_means <- ggplot(dice_EvO_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EvO_filtered, aes(x = Parcel, y = Dice_even_v_odd),
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
  xlab("Within-subject across-run Dice, across language parcels") +
  ylab("Dice") +
  scale_y_continuous(limits = c(-0, 1)) +
  guides(fill = "none") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )


p_dice_EvO_means

ggsave("report_Dice_EvO_langpar.png",plot=p_dice_EvO_means,
       width = 8,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")







# Across MD Parcels --------------------------------------------------------

# Specify language-only table
dice_EvO_filtered <- dice_EvO_table %>%
  filter(Area == "LR MD parcels")

# Create summarised means table
dice_EvO_means <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_even_v_odd),
    SEM = sd(Dice_even_v_odd) / sqrt(n()),
    Sample_size = n())

# Create one-sample t-test (mu > 0) df
dice_EvO_one_sample <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_even_v_odd ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EvO_means <- ggplot(dice_EvO_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EvO_filtered, aes(x = Parcel, y = Dice_even_v_odd),
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
  xlab("Within-subject across-run Dice, across MD Parcels") +
  ylab("Dice (mean)") +
  scale_y_continuous(limits = c(0, 1)) +
  guides(fill = "none") +
theme(
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank()
)


p_dice_EvO_means

ggsave("report_Dice_EvO_MDpar.png",plot=p_dice_EvO_means,
       width = 12,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")



# Across MD-not-lang Parcels (TOGGLED) ---------------------------------------------------

# Specify language-only table
dice_EvO_filtered <- dice_EvO_table %>%
  filter(Area == "MD minus Lang") %>%
  filter(Parcel == "LPrecG - [LIFG & LMFG]" | Parcel == "LSMA - LMFG (Lang)")

# Create summarised means table
dice_EvO_means <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_even_v_odd),
    SEM = sd(Dice_even_v_odd) / sqrt(n()),
    Sample = n())

# Create one-sample t-test (mu > 0) df
dice_EvO_one_sample <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_even_v_odd ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EvO_means <- ggplot(dice_EvO_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EvO_filtered, aes(x = Parcel, y = Dice_even_v_odd),
             position = position_jitter(width = 0.05),
             size = 1.5, shape = 21, alpha = 0.2, fill = "grey") +
  geom_errorbar(
    aes(x = Parcel, ymin = Mean - SEM, ymax = Mean + SEM),
    width = 0.2) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "LInsula - LIFGorb" = "plum2",
    "LMFG (MD) - LIFG" = "turquoise3",
    "LParSup - LAG" = "lightcoral",
    "LPrecG - [LIFG & LMFG]" = "darkseagreen3",
    "LSMA - LMFG (Lang)" = "lavenderblush2")) +
  xlab("Within-subject across-run Dice, in two MD-not-language parcels") +
  ylab("Dice") +
  scale_y_continuous(limits = c(0, 1)) +
  guides(fill = "none") +
theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
)


p_dice_EvO_means

ggsave("report_Dice_EvO_2MDnotlangmasked.png",plot=p_dice_EvO_means,
       width = 5,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")
  



# Across WB --------------------------------------------------------

# Specify language-only table
dice_EvO_filtered <- dice_EvO_table %>%
  filter(Area == "L Language parcels" | Area == "Whole-brain")

# Create summarised means table
dice_EvO_means <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  summarise(
    Mean = mean(Dice_even_v_odd),
    SEM = sd(Dice_even_v_odd) / sqrt(n()),
    Count_Zero = sum(Dice_even_v_odd == 0),
    Count_Greater_Zero = sum(Dice_even_v_odd > 0))

# Create one-sample t-test (mu > 0) df
dice_EvO_one_sample <- dice_EvO_filtered %>%
  group_by(Area, Parcel) %>%
  t_test(Dice_even_v_odd ~ 1, mu=0,alternative="greater") %>%
  add_significance()

# Create column graph
p_dice_EvO_means <- ggplot(dice_EvO_means) +
  geom_col(aes(x = Parcel, y = Mean, fill = Parcel),
           position = position_dodge(width = 0.9)) +
  geom_point(data = dice_EvO_filtered, aes(x = Parcel, y = Dice_even_v_odd),
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
  xlab("Within-subject even- & odd-run Dice similarity, in Lang Parcels and WB") +
  ylab("Dice (mean)") +
  scale_y_continuous(limits = c(-0.1, 1)) +
  guides(fill = "none") +
  stat_pvalue_manual(dice_EvO_one_sample,
                     x="Parcel",
                     y.position=dice_EvO_means$Mean + dice_EvO_means$SEM + 0.05)

p_dice_EvO_means

ggsave("Dice_EvO_langpar_WB.png",plot=p_dice_EvO_means,
       width = 8,
       height = 3,
       path="U:/Documents-U/UDrive_RAnalysis/Graphing_Dice_Tuckute")
