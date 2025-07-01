#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting binarised voxels, representing top 10% active voxels (highest t-values) after localiser contrasts (S>N, H>E) and 4 againist-fix contrasts (S>F, N>F, H>F, E>F)
# Script loops over all subjects, both localisers, finding top 10% in all ROIs/areas

# Specify ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois"

# Specify output directory where output masks will be saved
output_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/top_10_percent_no_thresh"

# Specify directories where GLMs (localiser contrasts, against-fix contrasts) are stored:
loc_glm_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/individual_activation_maps/activation_maps"
fix_glm_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/individual_activation_maps/activation_maps_X_v_Fix"

# Loop over a set of files in glm_dir (one for each subject), therefore running analysis on each subject once
for subj_file in $loc_glm_dir/*_H_v_E_conmap.hdr; do # Each subj only has one '*_H_v_E_conmap.hdr' file

    # Extract subjID
    ID=$(basename $subj_file _H_v_E_conmap.hdr) 
    subjID="subj_${ID}"
    echo "$subjID"
    echo "$ID"
    
    # For each tmap.img file (from MD loc, Lang loc, all 4 against-fixation contrasts)
    for tmap in $loc_glm_dir/${ID}_H_v_E_tmap.img $loc_glm_dir/${ID}_S_v_N_tmap.img $fix_glm_dir/${ID}*Fix_tmap.img; do
        
        echo "$(basename "$tmap")"
        
        if [[ $tmap == *H_v_E* ]]; then
            contrast=H_v_E
        elif [[ $tmap == *S_v_N* ]]; then
            contrast=S_v_N
        elif [[ $tmap == *E_v_F* ]]; then
            contrast=E_v_F
        elif [[ $tmap == *H_v_F* ]]; then
            contrast=H_v_F
        elif [[ $tmap == *S_v_F* ]]; then
            contrast=S_v_F
        elif [[ $tmap == *N_v_F* ]]; then
            contrast=N_v_F
        fi
        
        echo "$contrast"
        
        # Create output directory
        mkdir -p $output_dir/$subjID/$contrast
        
        for area in MD_not_language_parcels; # wholebrain LR_MD_parcels L_language_parcels wholebrain_minus_LR_MD_parcels wholebrain_minus_L_language_parcels; do
            
            # Create output directory
            mkdir -p $output_dir/$subjID/$contrast/$area

            # No mask used for WB. This 'if-continue-fi' sections diverts from main loop, which incl. masks 
            if [ $area == wholebrain ]; then
            
                # Get the 90th percentile threshold
                threshold_value=$(fslstats $tmap -P 90)

                # Apply the threshold to image, outputting top 10% most active voxels
                fslmaths $tmap -thr $threshold_value $output_dir/$subjID/$contrast/$area/${contrast}_${area}_top10_percent

		        # Creates binary image of top 10% active voxels
                fslmaths $output_dir/$subjID/$contrast/$area/${contrast}_${area}_top10_percent -nan -bin $output_dir/$subjID/$contrast/$area/${contrast}_${area}_top10_percent_mask
                
                echo "$subjID $contrast $area done"
                continue 
            fi

            # Extract the .nii binary mask for each roi
            for roi_image in $roi_dir/$area/*bin*.nii; do
                
                # Extract roi name for each mask, useful for clean output naming
                roi_name=$(basename $roi_image .nii)
            
                # Registers ROI mask with t-map
                flirt -in $roi_image -ref $tmap -out $output_dir/$subjID/$contrast/$area/${roi_name}_bin_registered_${contrast} -applyxfm -usesqform -interp nearestneighbour

		        # Saves tranformed mask to output dir
                fslmaths $tmap -mas $output_dir/$subjID/$contrast/$area/${roi_name}_bin_registered_${contrast} -nan $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name}

                # Get the 90th percentile threshold
                threshold_value=$(fslstats $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name} -P 90)

                # Apply the threshold to image, outputting top 10% most active voxels
                fslmaths $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name} -thr $threshold_value $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name}_top10_percent

		        # Creates binary image with only top 10% active voxels
                fslmaths $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name}_top10_percent -nan -bin $output_dir/$subjID/$contrast/$area/${contrast}_${roi_name}_top10_percent_mask
                
                # Remove the registered masks
                rm -rf $output_dir/$subjID/$contrast/$area/${roi_name}_bin_registered_${contrast}.nii
                
                echo "$subjID $contrast $area $roi_name done!!"

            done
        done
    done
done

cd /group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/jobs/top_10_percent_no_thresh
