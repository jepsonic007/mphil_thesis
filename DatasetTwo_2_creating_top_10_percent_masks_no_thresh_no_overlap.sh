#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting binarised voxels, representing top 10% active voxels (highest t-values) after localiser contrasts (S>N, H>E) and 4 againist-fix contrasts (S>F, N>F, H>F, E>F)
# Script loops over all subjects, both localisers, finding top 10% in all ROIs/areas

# Specify ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois"
MD_parcel_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois/LR_MD_parcels"
language_parcel_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois/L_language_parcels"
modified_MD_parcel_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois/MD_not_language_parcels"
modified_language_parcel_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois/language_not_MD_parcels"

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
        
        for area in MD_not_language_parcels language_not_MD_parcels MD_parcels_top10_masked language_parcels_top10_masked; do

            # Create output directory
            mkdir -p $output_dir/$subjID/$contrast/$area

            if [ $area == "MD_not_language_parcels" ] || [ $area == "language_not_MD_parcels" ]; then

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
            
            elif [ $area == "MD_parcels_top10_masked" ] ; then

                for roi_image in $MD_parcel_dir/LInsula_bin*.nii $MD_parcel_dir/LMFG_bin*.nii $MD_parcel_dir/LParSup_bin*.nii $MD_parcel_dir/LPrecG_bin*.nii $MD_parcel_dir/LSMA_bin*.nii; do

                    # Extract name
                    roi_name=$(basename $roi_image .nii)

                    if [[ $roi_name == LInsula* ]]; then p=LInsula_bin_-33_21_-0_not_LIFGorb_bin_-47_27_-4
                    elif [[ $roi_name == LMFG* ]]; then p=LMFG_bin_-41_32_29_not_LIFG_bin_-50_19_19
                    elif [[ $roi_name == LParSup* ]]; then p=LParSup_bin_-19_-67_50_not_LAG_bin_-43_-68_25
                    elif [[ $roi_name == LPrecG* ]]; then p=LPrecG_bin_-46_8_32_not_LIFG_bin_-50_19_19_not_LMFG_bin_-43_-0_51
                    elif [[ $roi_name == LSMA* ]]; then p=LSMA_bin_-28_1_59_not_LMFG_bin_-43_-0_51
                    fi

                    # Registers ROI mask with t-map
                    flirt -in $modified_MD_parcel_dir/$p.nii -ref $output_dir/$subjID/$contrast/LR_MD_parcels/${contrast}_${roi_name}_top10_percent_mask -out $output_dir/$subjID/$contrast/MD_parcels_top10_masked/${p}_${contrast}_${roi_name}_registered -applyxfm -usesqform -interp nearestneighbour

		            # Saves tranformed mask to output dir
                    fslmaths $output_dir/$subjID/$contrast/LR_MD_parcels/${contrast}_${roi_name}_top10_percent_mask.nii -mas $output_dir/$subjID/$contrast/MD_parcels_top10_masked/${p}_${contrast}_${roi_name}_registered -bin $output_dir/$subjID/$contrast/MD_parcels_top10_masked/${contrast}_${p}_modified_top10_percent_mask
                    
                    echo "$subjID $contrast $area $p done!!"

                    rm -rf $output_dir/$subjID/$contrast/MD_parcels_top10_masked/*registered*

                done

            elif [ $area == "language_parcels_top10_masked" ] ; then

                for roi_image in $language_parcel_dir/LAG*.nii $language_parcel_dir/LIFG_bin*.nii $language_parcel_dir/LIFGorb_bin*.nii $language_parcel_dir/LMFG_bin*.nii; do

                    # Extract name
                    roi_name=$(basename $roi_image .nii)

                    if [[ $roi_name == LAG* ]]; then p=LAG_bin_-43_-68_25_not_LParSup_bin_-19_-67_50
                    elif [[ $roi_name == LIFG_bin* ]]; then p=LIFG_bin_-50_19_19_not_LMFG_bin_-41_32_29_not_LPrecG_bin_-46_8_32
                    elif [[ $roi_name == LIFGorb_bin* ]]; then p=LIFGorb_bin_-47_27_-4_not_LInsula_bin_-33_21_-0
                    elif [[ $roi_name == LMFG_bin* ]]; then p=LMFG_bin_-43_-0_51_not_LPrecG_bin_-46_8_32_not_LSMA_bin_-28_1_59
                    fi

                    # Registers ROI mask with t-map
                    flirt -in $modified_language_parcel_dir/$p.nii -ref $output_dir/$subjID/$contrast/L_language_parcels/${contrast}_${roi_name}_top10_percent_mask -out $output_dir/$subjID/$contrast/language_parcels_top10_masked/${p}_${contrast}_${roi_name}_registered -applyxfm -usesqform -interp nearestneighbour

		            # Saves tranformed mask to output dir
                    fslmaths $output_dir/$subjID/$contrast/L_language_parcels/${contrast}_${roi_name}_top10_percent_mask.nii -mas $output_dir/$subjID/$contrast/language_parcels_top10_masked/${p}_${contrast}_${roi_name}_registered -bin $output_dir/$subjID/$contrast/language_parcels_top10_masked/${contrast}_${p}_modified_top10_percent_mask
                    
                    echo "$subjID $contrast $area $p done!!"

                    rm -rf $output_dir/$subjID/$contrast/language_parcels_top10_masked/*registered*

                done
            fi
        done
    done
done

