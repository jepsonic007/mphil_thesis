#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Subtracts out language parcels and all not-language-parcels areas from across-subjects top10% active ARCV wholebrain evenUodd map.
# Outputs both as new modified across-subjects maps and binarised masks

# Specify wholebrain union map
wholebrain_union_map="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/4_acrosssubj_allROIs_evenUodd/all_subjects_all_ROIs_wholebrain_no_thresh_evenUodd"

# Specify output directory
output_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/5_wholebrain_subtractions"



# --- 1 of 2: masking top10% whole-brain with language parcels
# Specify language parcels mask
language_parcels_mask="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/other/all_L_lang_parcels.nii"

# Register parcels mask with wholebrain union map
flirt -in $language_parcels_mask -ref $wholebrain_union_map -out $output_dir/registered_language_parcels_mask -applyxfm -usesqform -interp nearestneighbour

# Output wholebrain masked with parcels (or subtracting all not-parcels)
fslmaths $wholebrain_union_map -mas $output_dir/registered_language_parcels_mask -nan $output_dir/ARCV_allsubj_wholebrain_no_thresh_parcels_masked

# Output wholebrain parcels-masked, binarised version
fslmaths $output_dir/ARCV_allsubj_wholebrain_no_thresh_parcels_masked -nan -bin $output_dir/ARCV_allsubj_wholebrain_no_thresh_parcels_masked_bin



# --- 2 of 2: masking top10% whole-brain with inverted language parcels
# Specify inverted language parcels mask
inverted_language_parcels_mask="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/wholebrain_minus_L_language_parcels/wholebrain_minus_L_language_parcels_bin.nii"

# Register inverted parcels mask with wholebrain union map
flirt -in $inverted_language_parcels_mask -ref $wholebrain_union_map -out $output_dir/registered_inv_language_parcels_mask -applyxfm -usesqform -interp nearestneighbour

# Output wholebrain masked with inverted parcels (or subtracting all parcels)
fslmaths $wholebrain_union_map -mas $output_dir/registered_inv_language_parcels_mask -nan $output_dir/ARCV_allsubj_wholebrain_no_thresh_not_parcels_masked

# Output wholebrain subtracting parcels, binarised version
fslmaths $output_dir/ARCV_allsubj_wholebrain_no_thresh_not_parcels_masked -nan -bin $output_dir/ARCV_allsubj_wholebrain_no_thresh_not_parcels_masked_bin


rm -rf $output_dir/registered*


echo "job done :)"
