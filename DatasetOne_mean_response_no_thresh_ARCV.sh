#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

# ---- Outputs mean response values for odd-run-signal in even-mask, then the reverse. For all 6 language parcels, all 9 MD parcels, wholebrain, wholebrain-parcels, all subjects. 

# Specify outpit .csv file
output_file="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/mean_response/ARCV_no_thresh_loop.csv"
rm -rf $output_file

# Specify parcel_dir
parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Populate .csv file with headers
echo "subj,ROI_method,area,parcel,mean_signal_So,mean_signal_Se,mean_signal_No,mean_signal_Ne,SvR_mean,NvR_mean" >> $output_file

# Specify subject directory 
subj_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/firstlevel"

# Specify top10 mask dir
top10_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

# Specifies modified MD_parcel dir
MD_not_language_parcels_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/MD_not_language_parcels"

# Create list of all subject folders
cd $subj_dir
f=*

# Loops over all subject folders in subject directory
for subj in $f; do

	echo "$subj"

	# For the groups of ROI mask folders
	for area in L_language_parcels wholebrain LR_MD_parcels wholebrain_minus_L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do

		area_no_thresh="${area}_no_thresh"

		# Extract the .nii binary mask for each parcel
		for parcel_image in $parcel_dir/$area/*bin*.nii; do

			# Extract parcel name for each mask, useful for clean output
			if [ $area == wholebrain ]; then
                parcel_name="wholebrain"
			elif [ $area == MD_parcels_top10_masked ]; then
				break
			else
				parcel_name=$(basename $parcel_image .nii)
			fi

			# Use fslstats to extract mean signal S>r (odd run) within ROI (even run)
			mean_signal_So=$(fslstats $subj_dir/$subj/langlocSN/spmT_0007.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_even_${parcel_name}_top10_percent_mask.nii -M)

			# Use fslstats to extract mean signal S>r (even run) within ROI (odd run)
			mean_signal_Se=$(fslstats $subj_dir/$subj/langlocSN/spmT_0008.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_odd_${parcel_name}_top10_percent_mask.nii -M)

			# Use fslstats to extract mean signal N>r (odd run) within ROI (even run)
			mean_signal_No=$(fslstats $subj_dir/$subj/langlocSN/spmT_0009.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_even_${parcel_name}_top10_percent_mask.nii -M)
		
			# Use fslstats to extract mean signal N>r (even run) within all ROIs (odd run)
			mean_signal_Ne=$(fslstats $subj_dir/$subj/langlocSN/spmT_0010.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_odd_${parcel_name}_top10_percent_mask.nii -M)

			echo "${subj},ARCV,${area},${parcel_name},${mean_signal_So},${mean_signal_Se},${mean_signal_No},${mean_signal_Ne}" >> $output_file
			echo "$subj, $area, $parcel_name done"
			# "subj,ROI_method,area,parcel,mean_signal_So,mean_signal_Se,mean_signal_No,mean_signal_Ne,SvR_mean,NvR_mean" >> $output_file

		done

		if [ $area == MD_parcels_top10_masked ]; then

			for parcel_image in $MD_not_language_parcels_dir/*.nii; do

				parcel_name=$(basename $parcel_image .nii)

				# Use fslstats to extract mean signal S>r (odd run) within ROI (even run)
				mean_signal_So=$(fslstats $subj_dir/$subj/langlocSN/spmT_0007.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_even_${parcel_name}*_top10_percent_mask.nii -M)

				# Use fslstats to extract mean signal S>r (even run) within ROI (odd run)
				mean_signal_Se=$(fslstats $subj_dir/$subj/langlocSN/spmT_0008.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_odd_${parcel_name}*_top10_percent_mask.nii -M)

				# Use fslstats to extract mean signal N>r (odd run) within ROI (even run)
				mean_signal_No=$(fslstats $subj_dir/$subj/langlocSN/spmT_0009.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_even_${parcel_name}*_top10_percent_mask.nii -M)
			
				# Use fslstats to extract mean signal N>r (even run) within all ROIs (odd run)
				mean_signal_Ne=$(fslstats $subj_dir/$subj/langlocSN/spmT_0010.nii -k $top10_dir/${subj}/langlocSN/ARCV/${area_no_thresh}/SMinusN_odd_${parcel_name}*_top10_percent_mask.nii -M)

				echo "${subj},ARCV,${area},${parcel_name},${mean_signal_So},${mean_signal_Se},${mean_signal_No},${mean_signal_Ne}" >> $output_file
				echo "$subj, $area, $parcel_name done"
				# "subj,ROI_method,area,parcel,mean_signal_So,mean_signal_Se,mean_signal_No,mean_signal_Ne,SvR_mean,NvR_mean" >> $output_file

			done
		fi
	done
done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/top_10_percent_no_thresh

