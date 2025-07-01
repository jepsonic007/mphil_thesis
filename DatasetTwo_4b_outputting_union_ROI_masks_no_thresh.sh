#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting binarised ROI voxels. These ROI voxels are either the overlap or the intersection of these two sets: the overlap of SvF-NvF and the overlap of HvF-EvF.
# Script loops over all subjects.

# Specify ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois"

# Specify output directory where output masks will be saved
top10_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/top_10_percent_no_thresh"

cd $top10_dir
f=*

# Loop over a set of files in glm_dir (one for each subject), therefore running analysis on each subject once
for subjID in $f; do # Each subj only has one '*_H_v_E_conmap.hdr' file
        
        for area in wholebrain_minus_L_language_parcels_top_677_vox wholebrain LR_MD_parcels L_language_parcels wholebrain_minus_LR_MD_parcels wholebrain_minus_L_language_parcels language_not_MD_parcels language_parcels_top10_masked MD_not_language_parcels MD_parcels_top10_masked wholebrain_minus_L_language_parcels_top_677_vox wholebrain_minus_LR_MD_parcels_top_677_vox wholebrain_top_677_vox; do

            for top10_mask in $top10_dir/$subjID/S_v_F/$area/*mask.nii; do

                if [ $area == wholebrain_minus_L_language_parcels_top_677_vox ] || [ $area == wholebrain_minus_LR_MD_parcels_top_677_vox ] || [ $area == wholebrain_top_677_vox ]; then
                    parcel_name=$(basename $top10_mask _mask.nii)
                else
                    parcel_name=$(basename $top10_mask _top10_percent_mask.nii)
                fi
                parcel_name=${parcel_name:6} # Removes 'S_v_F_' from head of name
                echo "$parcel_name"

                # Create binarised mask of the union of S>N and H>E top 10% active voxel masks
	            fslmaths $top10_dir/$subjID/S_v_N/$area/S_v_N_${parcel_name}*mask.nii -add $top10_dir/$subjID/H_v_E/$area/H_v_E_${parcel_name}*mask.nii -nan -bin $top10_dir/$subjID/union_ROIs/$area/SvN_U_HvE_${parcel_name}_mask.nii

                # Create binarised mask of the intersection of S>N and H>E top 10% active voxel masks
	            fslmaths $top10_dir/$subjID/S_v_N/$area/S_v_N_${parcel_name}*mask.nii -mul $top10_dir/$subjID/H_v_E/$area/H_v_E_${parcel_name}*mask.nii -nan -bin $top10_dir/$subjID/union_ROIs/$area/SvN_n_HvE_${parcel_name}_mask.nii

                echo "$subjID's all four maps in $parcel_name done"

            done 
        done
done



