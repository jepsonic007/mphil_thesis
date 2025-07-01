#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# Outputting ROI masks using the more standard contrast: S+N>R, which loops over L Lang parcels, LR MD parcels, WB, WB-L Lang parcels

# Specifies ROI directory
roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Specifies output directory where output masks will be saved
output_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_standard_contrast"

# Specifies directory where GLMs are stored
glm_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/firstlevel"

# Changes working directory to GLM folders
cd $glm_dir
f=* # Assigns all files/directories in wd to variable 'f'

for subj in $f; do
    echo $subj
    for task_dir in langlocSN; do
	
	    # Creates output directory
	    # e.g. .../top_10_percent_standard_contrast/subj_X/langlocSN/wholebrain
    	mkdir -p $output_dir/${subj}/${task_dir}/
	
	    # For the two t-maps from langlocSN folder, assigns t-maps to new 't' variable     
        for tmap in spmT_0001.nii spmT_0002.nii; do        
    
            if   [ $tmap == "spmT_0001.nii" ]; then t=S
            elif [ $tmap == "spmT_0002.nii" ]; then t=N
            fi

            # Thresholds t-maps to positive values only
            fslmaths $glm_dir/$subj/${task_dir}/${tmap} -thr 0 $output_dir/$subj/${task_dir}/${t}_0thr

            # For the two types of ROI mask folders
            for area in wholebrain LR_MD_parcels L_language_parcels wholebrain_minus_L_language_parcels; do
                
                mkdir -p $output_dir/${subj}/${task_dir}/${area}/
	
                # No mask used for WB. This 'if-else' sections diverts unmasked/WB from main loop
                if [ $area == wholebrain ]; then
            
                    # Get the 90th percentile threshold
		            threshold_value=$(fslstats $output_dir/$subj/${task_dir}/${t}_0thr -P 90)

                    # Apply 10% active voxels threshold to image
                    fslmaths $output_dir/$subj/${task_dir}/${t}_0thr -thr $threshold_value $output_dir/$subj/$task_dir/$area/${t}_${area}_top10_percent

                    # Apply 10% active voxels threshold to image (mask output)
                    fslmaths $output_dir/$subj/$task_dir/$area/${t}_${area}_top10_percent -nan -bin $output_dir/$subj/$task_dir/$area/${t}_${area}_top10_percent_mask

                    echo "$subj $area $t done"
                
                else

                    # Extract the .nii binary mask for each parcel
                    for parcel_image in $roi_dir/$area/*bin*.nii; do

                        # Extract roi name for each mask, useful for clean output naming
                        parcel_name=$(basename $parcel_image .nii)

                        # Registers ROI mask with t-map
                        flirt -in $parcel_image -ref $glm_dir/$subj/${task_dir}/${tmap} -out $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_registered -applyxfm -usesqform -interp nearestneighbour
                        
                        # Saves tranformed mask to output dir
                        fslmaths $output_dir/$subj/${task_dir}/${t}_0thr -mas $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_registered -nan $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}

                        # Get the 90th percentile threshold
                        threshold_value=$(fslstats $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name} -P 90)

                        # Apply the threshold to image, outputting top 10% most active voxels
                        fslmaths $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name} -thr $threshold_value $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_top10_percent

                        # Creates binary image with only top 10% active voxels
                        fslmaths $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_top10_percent -nan -bin $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_top10_percent_mask

                        # Remove the registered mask
                        rm -rf $output_dir/${subj}/${task_dir}/${area}/${t}_${parcel_name}_registered.nii

                        echo "$subj $area $t $parcel_name done!!"
                    done
                fi
            done
        done
    done
    rm -rf $output_dir/${subj}/${task_dir}/*0thr.nii
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/top_10_percent_standard_ROIs

