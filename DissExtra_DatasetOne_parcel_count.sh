#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Counts non-zero voxels in the .nii file

output_sheet="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/voxel_counting/voxels_parcels.csv"

parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Populate .csv file with headers
echo "area,parcel,nonzero_voxel_count,parcel_volume" >> $output_sheet

for area in L_language_parcels LR_MD_parcels wholebrain_minus_L_language_parcels; do
    
    for parcel in $parcel_dir/$area/*.nii; do
        
        parcel_name=$(basename $parcel .nii)
        parcel_stats=$(fslstats $parcel_dir/$area/$parcel_name.nii -V)
        read voxel_count parcel_volume <<< $parcel_stats

        echo "${area},${parcel_name},${voxel_count},${parcel_volume}" >> $output_sheet
    
    done
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/voxel_count