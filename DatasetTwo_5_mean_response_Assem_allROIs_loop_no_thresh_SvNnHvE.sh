#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Outputs mean response from four tmaps (SvF, NvF, HvF, EvF) in the top10%-tvalue-defined ROIs (SvN, HvE, union, intersection)
# Loops over all subjects, all four contrasts, four sets of ROIs, all areas, incl all ROI parcels 

# Specify signal_dir
signal_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/individual_activation_maps/activation_maps_X_v_Fix"

# Specify parcel_dir
parcel_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/rois"

# Specify output .csv file
output_file="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/results/mean_response/mean_response_SvN_n_HvE_conmap.csv"

# Populate .csv file with headers
echo "subj,area,ROI_definition,parcel,SvF_mean,NvF_mean,HvF_mean,EvF_mean,SvF_minus_NvF,HvF_minus_EvF" >> $output_file

# Specify subject directory 
top10_dir="/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/top_10_percent_no_thresh"

# Create variable containing all subject codes
cd $top10_dir
f=*

# Loops over all subject codes
for subjID in $f; do
	
	if [[ ! $subjID == *subj_* ]]; then continue
	fi
    
    # Extract ID number
    ID=${subjID:5}
    echo "$ID"

    # Loops over all 6 areas
    for area in LR_MD_parcels L_language_parcels language_not_MD_parcels MD_not_language_parcels; do
	            
        echo "$subjID $area"
        
        # Loops over all 4 ROI definitions
        for roi_def in SvN_n_HvE SvN_U_HvE; do

            echo "$subjID ${roi_def}"
            
            roi_dir=$top10_dir/$subjID/union_ROIs/$area
            
            # for the unique number of parcels, in the current area on loop, based on top10% mask files
            for top10_mask in $top10_dir/$subjID/union_ROIs/$area/SvN_n_HvE_*mask.nii; do

                parcel_name=$(basename $top10_mask _mask.nii)
                parcel_name=${parcel_name:10} # Removes 'S_v_F_' from head of name
                echo "$parcel_name"
            
                # Define mask, based on current subj, area and roi_definition on loop
                roi_mask=$roi_dir/${roi_def}_${parcel_name}*mask.nii
            
                # Extract mean signal S_v_F within ROI mask
                S_v_F_response=$(fslstats $signal_dir/${ID}_S_v_Fix_conmap.img -k $roi_mask -M)

                # Extract mean signal N_v_F within ROI mask
                N_v_F_response=$(fslstats $signal_dir/${ID}_N_v_Fix_conmap.img -k $roi_mask -M)

                # Extract mean signal H_v_F within ROI mask 
                H_v_F_response=$(fslstats $signal_dir/${ID}_H_v_Fix_conmap.img -k $roi_mask -M)

                # Extract mean signal E_v_F within ROI mask 
                E_v_F_response=$(fslstats $signal_dir/${ID}_E_v_Fix_conmap.img -k $roi_mask -M)
            
                # Export response estimation to .csv file
                echo "${subjID},${area},${roi_def},${parcel_name},${S_v_F_response},${N_v_F_response},${H_v_F_response},${E_v_F_response}" >> $output_file
                echo "${subjID} ${area}, ${roi_def} done"
        
            done
        done
	done
done


