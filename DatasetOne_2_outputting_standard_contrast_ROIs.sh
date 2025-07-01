#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting ROI masks using standard contrasts: overlap of S>R and N>R, and conj. of S>R and N>R

output_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_standard_contrast"

cd $output_dir
f=* # Assigns all files/directories in wd to variable 'f', NB these are now 'subj_', not 'firstlevel_'
for subj in $f; do
    echo $subj
    for task_dir in langlocSN; do
        
        for area in wholebrain LR_MD_parcels L_language_parcels wholebrain_minus_L_language_parcels; do

            # Creates output directory
            mkdir -p $output_dir/${subj}/${task_dir}/${area}/combination_contrast/
            mkdir -p $output_dir/${subj}/${task_dir}/${area}/conjunction_contrast/
            
            # Loops over all 'r' items, which is each *mask.nii including full file path
            for parcel_image in $output_dir/${subj}/${task_dir}/${area}/*mask.nii; do
            # NB masks were used here, but non-mask could also be used. either way, output is binarised
                
                # Extract ROI name. 'basename' removes file path, 'mask.nii' removes suffix
                parcel_name=$(basename $parcel_image .nii)
                parcel_name=${parcel_name:2} # Drop first two elements in string, i.e. 'S_' or 'N_', which is needed for ROI matching below
                
                echo $parcel_name
            
                # Create ROI binary masks using the combination of S>R and N>R masks
	            fslmaths $output_dir/${subj}/${task_dir}/${area}/N_${parcel_name} -add $output_dir/${subj}/${task_dir}/${area}/S_${parcel_name} -nan -bin $output_dir/${subj}/${task_dir}/${area}/combination_contrast/NplusS_${parcel_name}

                # Create ROI binary masks using the conjunction/union of S>R and N>R masks
	            fslmaths $output_dir/${subj}/${task_dir}/${area}/N_${parcel_name} -mul $output_dir/${subj}/${task_dir}/${area}/S_${parcel_name} -nan -bin $output_dir/${subj}/${task_dir}/${area}/conjunction_contrast/NmultS_${parcel_name}

            done 

        done

    done

done



