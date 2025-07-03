#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Counts non-zero voxels in the .nii file

output_sheet="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/voxel_counting/voxels_ARCV_top_20_thresh.csv"

ARCV_mask_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Populate .csv file with headers
echo "subj,area,parcel,run,map,nonzero_voxel_count,parcel_volume,max_t_value" >> $output_sheet

cd $ARCV_mask_dir
f=*

for subj in $f; do

    for area in L_language_parcels LR_MD_parcels wholebrain_minus_L_language_parcels wholebrain MD_not_language_parcels; do
        
        area_top_20_percent="${area}_top_20_percent"

        if [ $area == "wholebrain" ]; then
            
            for run in even odd; do

                # Voxels in top20% mask
                mask_stats_top20=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${area}_top20_percent.nii -V)
                read voxel_count cluster_volume <<< $mask_stats_top20
                mask_stats_intensity=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${area}_top20_percent.nii -R)
                read min max <<< $mask_stats_intensity
                echo "${subj},${area},${area},${run},top20%,${voxel_count},${cluster_volume},${max}" >> $output_sheet

                # Voxels in pos-threshholded mask
                mask_stats_pos=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${area}.nii -V)
                read voxel_count cluster_volume <<< $mask_stats_pos
                mask_stats_intensity=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${area}.nii -R)
                read min max <<< $mask_stats_intensity
                echo "${subj},${area},${area},${run},pos_threshold,${voxel_count},${cluster_volume},${max}" >> $output_sheet
            
                echo "$subj $area $area $run"
            done

        else

            for parcel in $parcel_dir/$area/*.nii; do

                parcel_name=$(basename $parcel .nii)

                for run in even odd; do

                    # Voxels in top20% mask
                    mask_stats_top20=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${parcel_name}_top20_percent.nii -V)
                    read voxel_count cluster_volume <<< $mask_stats_top20
                    mask_stats_intensity=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${parcel_name}_top20_percent.nii -R)
                    read min max <<< $mask_stats_intensity
                    echo "${subj},${area},${parcel_name},${run},top20%,${voxel_count},${cluster_volume},${max}" >> $output_sheet

                    # Voxels in pos-threshholded mask
                    mask_stats_pos=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${parcel_name}.nii -V)
                    read voxel_count cluster_volume <<< $mask_stats_pos
                    mask_stats_intensity=$(fslstats $ARCV_mask_dir/$subj/langlocSN/ARCV/$area_top_20_percent/SMinusN_${run}_${parcel_name}.nii -R)
                    read min max <<< $mask_stats_intensity
                    echo "${subj},${area},${parcel_name},${run},pos_threshold,${voxel_count},${cluster_volume},${max}" >> $output_sheet
                
                    echo "$subj $area $parcel_name $run"

                done
            done  
        fi
    done
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/voxel_count