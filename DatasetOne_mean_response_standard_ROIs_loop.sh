#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Outputs mean response values for odd-run-signal in even-mask, then the reverse. For all 6 language parcels, all 9 MD parcels, wholebrain, wholebrain-parcels, all subjects. 

# Specify outpit .csv file
output_file="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/mean_response/standard_ROIs_response_loop.csv"

# Specify parcel_dir
parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Populate .csv file with headers
echo "subj,ROI_method,area,parcel,mean_signal_So,mean_signal_Se,mean_signal_No,mean_signal_Ne,SvR_mean,NvR_mean" >> $output_file

# Specify subject directory 
subj_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/firstlevel"

# Create list of all subject folders
cd $subj_dir
f=*

# Loops over all subject folders in subject directory
for subj in $f; do
	echo "$subj"

    for area in LR_MD_parcels L_language_parcels wholebrain_minus_L_language_parcels wholebrain; do 
	        
	        for roi_method in combination_contrast conjunction_contrast; do
	        
	            roi_mask_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_standard_contrast/${subj}/langlocSN/${area}/${roi_method}"

					if [ $area == wholebrain ]; then

						# Use fslstats to extract mean signal S>R within ROI 
						SminusR_signal=$(fslstats $subj_dir/$subj/langlocSN/spmT_0001.nii -k ${roi_mask_dir}/*${area}*mask.nii -M)

						# Use fslstats to extract mean signal N>R within ROI
						NminusR_signal=$(fslstats $subj_dir/$subj/langlocSN/spmT_0002.nii -k ${roi_mask_dir}/*${area}*mask.nii -M)

						echo "${subj},${roi_method},${area},${area},,,,,${SminusR_signal},${NminusR_signal}" >> $output_file
						echo "$subj, $area, $area done"

					else

						# Loop over each parcel binary mask, in current 'area' folder on loop
						for parcel_image in $parcel_dir/$area/*.nii; do 

							# Extract parcel name for each mask, useful for clean output
							parcel_name=$(basename $parcel_image .nii)

							# Use fslstats to extract mean signal S>R within ROI 
							SminusR_signal=$(fslstats $subj_dir/$subj/langlocSN/spmT_0001 -k $roi_mask_dir/*${parcel_name}*mask.nii -M)

							# Use fslstats to extract mean signal N>R within ROI
							NminusR_signal=$(fslstats $subj_dir/$subj/langlocSN/spmT_0002 -k $roi_mask_dir/*${parcel_name}*mask.nii -M)
							
							echo "${subj},${roi_method},${area},${parcel_name},,,,,${SminusR_signal},${NminusR_signal}" >> $output_file
							
							echo "$subj, $roi_method $area, $parcel_name done"
							echo "$(basename "$parcel_name")"
						done
					fi
            done
	done
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/top_10_percent_standard_ROIs


