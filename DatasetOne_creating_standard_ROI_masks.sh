#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting ROI masks using standard contrasts: overlap of S>R and N>R, and conj. of S>R and N>R

# Specifies ROI directory
roi_dir="/group/mlr-lab/Ryan_Jexsipson/Tuckute_2024preprint/data/roi_parcels/rois"

# Specifies output directory where output masks will be saved
output_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

# Specifies directory where GLMs are stored
glm_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/firstlevel"

# Specifies MD_parcel dir
MD_parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/LR_MD_parcels"

# Specified MD_not_lang_parcels_dir
MD_not_language_parcels_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/MD_not_language_parcels"

cd $output_dir
f=* # Assigns all files/directories in wd to variable 'f', NB these are now 'subj_', not 'firstlevel_'

for subj in $f; do
    echo $subj
    for task_dir in langlocSN; do
        
	    for area in L_language_parcels wholebrain LR_MD_parcels wholebrain_minus_L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do

            area_no_thresh="${area}_no_thresh"

            # Creates output directory
            mkdir -p $output_dir/${subj}/${task_dir}/SuN/$area_no_thresh
            mkdir -p $output_dir/${subj}/${task_dir}/SnN/$area_no_thresh
            
            # Loops over each unqiue mask image
            for mask_image in $output_dir/$subj/$task_dir/standard_contrast/$area_no_thresh/S*top10_percent_mask.nii; do
                
                # Extract ROI name. 'basename' removes file path, 'mask.nii' removes suffix
                parcel_name=$(basename $mask_image _top10_percent_mask.nii)
                parcel_name=${parcel_name:2} # Drop first two elements in string, i.e. 'S_' or 'N_', which is needed for ROI matching below
                
                echo $parcel_name
            
                # Create ROI binary masks using the combination of S>R and N>R masks
	            fslmaths $output_dir/$subj/$task_dir/standard_contrast/$area_no_thresh/N_${parcel_name}_top10_percent_mask -add $output_dir/$subj/$task_dir/standard_contrast/$area_no_thresh/S_${parcel_name}_top10_percent_mask -nan -bin $output_dir/$subj/$task_dir/SuN/$area_no_thresh/SuN_${parcel_name}_top10_percent_mask

                # Create ROI binary masks using the conjunction/union of S>R and N>R masks
	            fslmaths $output_dir/$subj/$task_dir/standard_contrast/$area_no_thresh/N_${parcel_name}_top10_percent_mask -mul $output_dir/$subj/$task_dir/standard_contrast/$area_no_thresh/S_${parcel_name}_top10_percent_mask -nan -bin $output_dir/$subj/$task_dir/SnN/$area_no_thresh/SnN_${parcel_name}_top10_percent_mask

            done 

        done

    done

done



