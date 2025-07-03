#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Counts non-zero voxels in the .nii file

output_sheet="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/voxel_counting/voxels_ARCV_top_10_no_thresh.csv"

mask_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Populate .csv file with headers
echo "subj,area,parcel,run,map,nonzero_voxel_count,parcel_volume,max_t_value" >> $output_sheet

cd $mask_dir
f=*

for subj in $f; do

    # For the two types of ROI mask folders
    for area in L_language_parcels LR_MD_parcels wholebrain wholebrain_minus_L_language_parcels; do

        area_no_thresh="${area}_no_thresh"

		# Extract the .nii binary mask for each parcel, 
        for parcel_image in $parcel_dir/$area/*bin*.nii; do
        # NB. when area = wholebrain, the 'for' loop runs once despite no .nii files in $roi_dir/wholebrain dir

            if [ $area == wholebrain ]; then 
                parcel_name="wholebrain"
            else
                # Extract roi name from each parcel mask, useful for clean output naming
                parcel_name=$(basename $parcel_image .nii)

            fi

            for run in even odd; do

                # Voxels in top10% mask
                count_stats=$(fslstats $mask_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_${run}_${parcel_name}_top10_percent.nii -V)
                read voxel_count cluster_volume <<< $count_stats

                intensity_stats=$(fslstats $mask_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_${run}_${parcel_name}_top10_percent.nii -R)
                read min max <<< $intensity_stats
                
                echo "${subj},${area},${parcel_name},${run},top10%,${voxel_count},${cluster_volume},${max}" >> $output_sheet
                # echo "subj,area,parcel,run,map,nonzero_voxel_count,parcel_volume,max_t_value" >> $output_sheet

            done
            echo "$subj $area $parcel_name done"
        done
    done
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/voxel_count