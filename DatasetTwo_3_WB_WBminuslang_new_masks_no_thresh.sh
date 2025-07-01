#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Finds highest t-values in WB and WB-minus-lang, taking new voxel # instead of top 10%, outputting active masks

# Specify ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois"

# Specify output directory where output masks will be saved
output_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/top_10_percent_no_thresh"

# Specify directories where GLMs (localiser contrasts, against-fix contrasts) are stored:
loc_glm_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/individual_activation_maps/activation_maps"
fix_glm_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/individual_activation_maps/activation_maps_X_v_Fix"

top_n_voxels=677

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
        
        for area in wholebrain wholebrain_minus_LR_MD_parcels wholebrain_minus_L_language_parcels; do
            
            area_top_vox="${area}_top_677_vox"

            # Create output directory
            rm -rf $output_dir/$subjID/$contrast/$area_top_vox
            mkdir -p $output_dir/$subjID/$contrast/$area_top_vox

            # No mask used for WB. This 'if-continue-fi' sections diverts from main loop, which incl. masks 
            if [ $area == wholebrain ]; then

                parcel_name="wholebrain"
                
                output_sheet_1=$output_dir/$subjID/$contrast/$area_top_vox/full_meants_list.csv
                output_sheet_2=$output_dir/$subjID/$contrast/$area_top_vox/t_list.csv
                # Get all t-values values in a list, sort into descending numerical order (-gr), extract 677th row value
                fslmeants -i $tmap --transpose --showall | sed 's/ /,/g' >> $output_sheet_1
                awk -F',' '{print $4}' $output_sheet_1 > $output_sheet_2
                threshold_t_value=$(sort -gr $output_sheet_2 | sed -n 677p) # Selects the 677th row in the .csv

                fslmaths $tmap -thr $threshold_t_value $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}_top_${top_n_voxels}_vox

                rm -rf $output_sheet_1
                rm -rf $output_sheet_2

                echo "$threshold_t_value"
                echo "$subjID $contrast $area $parcel_name done!!"

            else

                # Extract the .nii binary mask for each roi
                for parcel_image in $roi_dir/$area/*bin*.nii; do
                    
                    # Extract roi name for each mask, useful for clean output naming
                    parcel_name=$(basename $parcel_image .nii)
                
                    # Registers ROI mask with t-map
                    flirt -in $parcel_image -ref $tmap -out $output_dir/$subjID/$contrast/$area_top_vox/${parcel_name}_bin_registered_${contrast} -applyxfm -usesqform -interp nearestneighbour

                    # Saves tranformed mask to output dir
                    fslmaths $tmap -mas $output_dir/$subjID/$contrast/$area_top_vox/${parcel_name}_bin_registered_${contrast} -nan $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}

                    output_sheet_1=$output_dir/$subjID/$contrast/$area_top_vox/full_meants_list.csv
                    output_sheet_2=$output_dir/$subjID/$contrast/$area_top_vox/t_list.csv
                    # Get all t-values values in a list, sort into descending numerical order (-gr), extract 677th row value
                    fslmeants -i $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name} --transpose --showall | sed 's/ /,/g' >> $output_sheet_1
                    awk -F',' '{print $4}' $output_sheet_1 > $output_sheet_2
                    threshold_t_value=$(sort -gr $output_sheet_2 | sed -n 677p) # Selects the 677th row in the .csv
                
                    fslmaths $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name} -thr $threshold_t_value $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}_top_${top_n_voxels}_vox

                    echo "$threshold_t_value"
                    echo "$subjID $contrast $area $parcel_name done!!"

                    rm -rf $output_sheet_1
                    rm -rf $output_sheet_2

                    # Remove the registered masks
                    rm -rf $output_dir/$subjID/$contrast/$area_top_vox/${parcel_name}_bin_registered_${contrast}.nii
                    rm -rf $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}.nii
                    
                done
            fi

            # Creates binary image with only top 10% active voxels
            fslmaths $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}_top_${top_n_voxels}_vox -nan -bin $output_dir/$subjID/$contrast/$area_top_vox/${contrast}_${parcel_name}_top_${top_n_voxels}_vox_mask
                    
        done
    done
done

cd /group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/jobs/highest_t_WB_WBminus
