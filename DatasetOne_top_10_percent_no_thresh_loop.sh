#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Finds top 10% active voxels (from pos. t-values) after S-N and outputs this as a mask

# Specifies ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Specifies output directory where output masks will be saved
output_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

# Specifies directory where GLMs are stored
glm_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/firstlevel"

# Specify MD parcel dir
MD_parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/LR_MD_parcels"

# Changes working directory to GLM folders
cd $glm_dir
f=* # Assigns all files/directories in wd to variable 'f'

for subj in $f; do
    
    echo $subj
    for task_dir in langlocSN; do
	
        for contrast in ARCV standard_contrast; do

            # Assign the a list of tmaps, depending on the contrast on loop
            if [ $contrast == ARCV ]; then
                tmaps="spmT_0011.nii spmT_0012.nii"
            else
                tmaps="spmT_0001.nii spmT_0002.nii"
            fi

            # Unified for-loop over the selected tmaps
            for tmap in $tmaps; do

                # Map tmap to variable `t`
                if [ $contrast == ARCV ]; then
                    if [ $tmap == spmT_0011.nii ]; then t=SMinusN_odd
                    elif [ $tmap == spmT_0012.nii ]; then t=SMinusN_even
                    fi
                else
                    if [ $tmap == spmT_0001.nii ]; then t=S
                    elif [ $tmap == spmT_0002.nii ]; then t=N
                    fi
                fi

                # For the groups of ROI mask folders
                for area in L_language_parcels LR_MD_parcels wholebrain_minus_L_language_parcels MD_not_language_parcels wholebrain; do

                    area_no_thresh="${area}_no_thresh"

                    echo "$area $area_no_thresh $tmap $t $contrast $task_dir $subj"

                    # Creates output directory
                    mkdir -p $output_dir/$subj/$task_dir/$contrast/$area_no_thresh

                    # Extract the .nii binary mask for each parcel, 
                    for parcel_image in $roi_dir/$area/*bin*.nii; do
                    # NB. when area = wholebrain, the 'for' loop runs once despite no .nii files in $roi_dir/wholebrain dir

                        if [ $area == wholebrain ]; then 

                            parcel_name="wholebrain"
                            
                            # Get the 90th percentile threshold
                            threshold_value=$(fslstats $glm_dir/$subj/$task_dir/$tmap -P 90)

                            # Apply the threshold to image for the top 10% most active voxels
                            fslmaths $glm_dir/$subj/$task_dir/$tmap -thr $threshold_value $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_top10_percent

                        else

                            # Extract roi name from each parcel mask, useful for clean output naming
                            parcel_name=$(basename $parcel_image .nii)

                            # Registers ROI mask with t-map
                            flirt -in $parcel_image -ref $glm_dir/$subj/$task_dir/$tmap -out $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_registered -applyxfm -usesqform -interp nearestneighbour

                            # Uses registered parcel to mask tmap, saving output
                            fslmaths $glm_dir/$subj/$task_dir/$tmap -mas $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_registered -nan $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}

                            # Get the 90th percentile threshold
                            threshold_value=$(fslstats $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name} -P 90)

                            # Apply the threshold to image for the top 10% most active voxels
                            fslmaths $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name} -thr $threshold_value $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_top10_percent

                            # Remove the registered mask
                            rm -rf $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_registered.nii
                        
                        fi

                        # Creates binarised image of top 10% t-values
                        fslmaths $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_top10_percent -nan -bin $output_dir/$subj/$task_dir/$contrast/$area_no_thresh/${t}_${parcel_name}_top10_percent_mask

                        echo "$subj $contrast $area $t $parcel_name done!!"

                    done
                done
            done
        done
    done    
done

