#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI


# Specify output directory
output_dir_1="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_standard_ROIs_no_thresh/1_withinsubj_allROIs"
output_dir_2="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_standard_ROIs_no_thresh/2_acrosssubj_allROIs"

# Specify subj's directory 
subj_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

# Create string list of all subject folders
cd $subj_dir
f=*




# == Compiling (1) within-subject all parcels in SnN and SuN masks ==

# Loops over all subject folders in subject directory
for subj in $f; do

	for roi_method in SuN SnN; do
		
		# For the two types of ROI mask folders
		for area in LR_MD_parcels L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do

			area_no_thresh="${area}_no_thresh"

			echo "$area $area_no_thresh"

			mkdir -p $output_dir_1/$roi_method/$area_no_thresh

			# Specify input directory 
			roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/$subj/langlocSN/$roi_method/$area_no_thresh"

			# Create list of even-run rois from roi_dir:
			roi_list=$(find "$roi_dir" -maxdepth 1 -type f -name '*mask.nii')

			# Converts list of strings into an array, with no line breaks after strings (-t)
			mapfile -t roi_list_array <<< "$roi_list"

			for path in "${roi_list_array[@]}"; do echo "$(basename "$path")"; done

			if [ $area = L_language_parcels ]; then

				# Compile 6 even-run ROIs
				fslmaths ${roi_list_array[0]} -add ${roi_list_array[1]} -add ${roi_list_array[2]} -add ${roi_list_array[3]} -add ${roi_list_array[4]} -add ${roi_list_array[5]} $output_dir_1/$roi_method/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_ROIs
			
			elif [ $area == LR_MD_parcels ]; then

				# Compile 18 even-run ROIs
				fslmaths ${roi_list_array[0]} -add ${roi_list_array[1]} -add ${roi_list_array[2]} -add ${roi_list_array[3]} -add ${roi_list_array[4]} -add ${roi_list_array[5]} -add ${roi_list_array[6]} -add ${roi_list_array[7]} -add ${roi_list_array[8]} -add ${roi_list_array[9]} -add ${roi_list_array[10]} -add ${roi_list_array[11]} -add ${roi_list_array[12]} -add ${roi_list_array[13]} -add ${roi_list_array[14]} -add ${roi_list_array[15]} -add ${roi_list_array[16]} -add ${roi_list_array[17]} $output_dir_1/$roi_method/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_ROIs
			
			elif [ $area == MD_not_language_parcels ] || [ $area = MD_parcels_top10_masked ]; then

				# Compile 5 even-run ROIs
				fslmaths ${roi_list_array[0]} -add ${roi_list_array[1]} -add ${roi_list_array[2]} -add ${roi_list_array[3]} -add ${roi_list_array[4]} $output_dir_1/$roi_method/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_ROIs
			
			fi	    
		
			echo "$subj done"  	            
		done
	done
done


# == Compining (2) across-subject maps ==

for roi_method in SuN SnN; do

	for area in LR_MD_parcels L_language_parcels wholebrain wholebrain_minus_L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do
		area_no_thresh="${area}_no_thresh"

		# Make output directory
		mkdir -p $output_dir_2

		# Obtain one brain-map per subject
		# NB diff. input dir needed for Lang,MD,MD-not-lang,MD-masked-not-lang, since single-subj files exist in different folders (and folder structures) compared to WB and WB-not-lang single-subject files
		if [ $area == L_language_parcels ] || [ $area == LR_MD_parcels ] || [ $area == MD_not_language_parcels ] || [ $area = MD_parcels_top10_masked ]; then
			input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_standard_ROIs_no_thresh/1_withinsubj_allROIs/$roi_method/$area_no_thresh"
			subject_masks=$(find "$input_dir" -maxdepth 1 -type f -name '*all_ROIs.nii')
			mapfile -t subject_mask_array <<< "$subject_masks" # Converts list of strings into an array, with no line breaks after strings (-t)
		else
			subject_mask_array=()
			for subj in $f; do
				input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/$subj/langlocSN/$roi_method/$area_no_thresh"
				subject_mask=$(find $input_dir -maxdepth 1 -type f -name '*_top10_percent_mask.nii')
				subject_mask_array+=("$subject_mask")
			done
		fi	
	
		for path in "${subject_mask_array[@]}"; do echo "$(basename "$path")"; done

		fslmaths ${subject_mask_array[0]} -add ${subject_mask_array[1]} -add ${subject_mask_array[2]} -add ${subject_mask_array[3]} -add ${subject_mask_array[4]} -add ${subject_mask_array[5]} -add ${subject_mask_array[6]} -add ${subject_mask_array[7]} -add ${subject_mask_array[8]} -add ${subject_mask_array[9]} -add ${subject_mask_array[10]} -add ${subject_mask_array[11]} -add ${subject_mask_array[12]} -add ${subject_mask_array[13]} -add ${subject_mask_array[14]} -add ${subject_mask_array[15]} -add ${subject_mask_array[16]} -add ${subject_mask_array[17]} -add ${subject_mask_array[18]} -add ${subject_mask_array[19]} -add ${subject_mask_array[20]} -add ${subject_mask_array[21]} -add ${subject_mask_array[22]} -add ${subject_mask_array[23]} $output_dir_2/all_subjects_all_ROIs_${roi_method}_${area_no_thresh}_evenUodd
		
		fslmaths $output_dir_2/all_subjects_all_ROIs_${roi_method}_${area_no_thresh}_evenUodd -nan -bin $output_dir_2/all_subjects_all_ROIs_${roi_method}_${area_no_thresh}_evenUodd_mask

		# To check the correct files are read
		for path in "${subject_mask_array[@]}"; do echo "$(basename "$path")"; done
		
		echo "$area done"
	done	
done

