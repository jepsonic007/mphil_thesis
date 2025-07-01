#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI

output_dir_1="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/1_withinsubj_evenROIs_oddROIs"
output_dir_3="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/3_withinsubj_evenUodd_allROIs"

mkdir -p $output_dir_1
mkdir -p $output_dir_3

parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Specify subj's directory 
subj_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

# Create string list of all subject folders
cd $subj_dir
f=*

# == Compiling (1) within-subj evenROIs, oddROIs and (3) within-subj evenUodd all ROIs, only the ARCV masks ==

# Loops over all subject folders in subject directory
for subj in $f; do

	# For the two types of ROI mask folders
	for area in LR_MD_parcels L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do

		area_no_thresh="${area}_no_thresh"

		echo "$area $area_no_thresh"

		mkdir -p $output_dir_1/$area_no_thresh
		mkdir -p $output_dir_3/$area_no_thresh

		# Specify input directory 
		roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/$subj/langlocSN/ARCV/$area_no_thresh"

		# Create list of even-run rois from roi_dir:
		roi_even_runs=$(find "$roi_dir" -maxdepth 1 -type f -name 'SMinusN*even*mask.nii')

		# Converts list of strings into an array, with no line breaks after strings (-t)
		mapfile -t roi_even_array <<< "$roi_even_runs"

		# Same as above, but for odd run rois
		roi_odd_runs=$(find "$roi_dir" -maxdepth 1 -type f -name 'SMinusN*odd*mask.nii')
		mapfile -t roi_odd_array <<< "$roi_odd_runs"

		for path in "${roi_even_array[@]}"; do echo "$(basename "$path")"; done
		for path in "${roi_odd_array[@]}"; do echo "$(basename "$path")"; done

		if [ $area = L_language_parcels ]; then

			# Compile 6 even-run ROIs
			fslmaths ${roi_even_array[0]} -add ${roi_even_array[1]} -add ${roi_even_array[2]} -add ${roi_even_array[3]} -add ${roi_even_array[4]} -add ${roi_even_array[5]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_even_ROIs
		
			# Compile 6 odd-run ROIs
			fslmaths ${roi_odd_array[0]} -add ${roi_odd_array[1]} -add ${roi_odd_array[2]} -add ${roi_odd_array[3]} -add ${roi_odd_array[4]} -add ${roi_odd_array[5]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_odd_ROIs

		elif [ $area == LR_MD_parcels ]; then

			# Compile 18 even-run ROIs
			fslmaths ${roi_even_array[0]} -add ${roi_even_array[1]} -add ${roi_even_array[2]} -add ${roi_even_array[3]} -add ${roi_even_array[4]} -add ${roi_even_array[5]} -add ${roi_even_array[6]} -add ${roi_even_array[7]} -add ${roi_even_array[8]} -add ${roi_even_array[9]} -add ${roi_even_array[10]} -add ${roi_even_array[11]} -add ${roi_even_array[12]} -add ${roi_even_array[13]} -add ${roi_even_array[14]} -add ${roi_even_array[15]} -add ${roi_even_array[16]} -add ${roi_even_array[17]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_even_ROIs
		
			# Compile 18 odd-run ROIs
			fslmaths ${roi_odd_array[0]} -add ${roi_odd_array[1]} -add ${roi_odd_array[2]} -add ${roi_odd_array[3]} -add ${roi_odd_array[4]} -add ${roi_odd_array[5]} -add ${roi_odd_array[6]} -add ${roi_odd_array[7]} -add ${roi_odd_array[8]} -add ${roi_odd_array[9]} -add ${roi_odd_array[10]} -add ${roi_odd_array[11]} -add ${roi_odd_array[12]} -add ${roi_odd_array[13]} -add ${roi_odd_array[14]} -add ${roi_odd_array[15]} -add ${roi_odd_array[16]} -add ${roi_odd_array[17]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_odd_ROIs    
		
		elif [ $area == MD_not_language_parcels ] || [ $area = MD_parcels_top10_masked ]; then

			# Compile 5 even-run ROIs
			fslmaths ${roi_even_array[0]} -add ${roi_even_array[1]} -add ${roi_even_array[2]} -add ${roi_even_array[3]} -add ${roi_even_array[4]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_even_ROIs
		
			# Compile 5 odd-run ROIs
			fslmaths ${roi_odd_array[0]} -add ${roi_odd_array[1]} -add ${roi_odd_array[2]} -add ${roi_odd_array[3]} -add ${roi_odd_array[4]} $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_odd_ROIs    

		fi	    
		
		# Compile all even and odd-run ROIs
		fslmaths $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_even_ROIs -add $output_dir_1/$area_no_thresh/${subj}_${area_no_thresh}_compiled_all_odd_ROIs $output_dir_3/$area_no_thresh/${subj}_all_ROIs_${area_no_thresh}_evenUodd

		fslmaths $output_dir_3/$area_no_thresh/${subj}_all_ROIs_${area_no_thresh}_evenUodd -nan -bin $output_dir_3/$area_no_thresh/${subj}_all_ROIs_${area_no_thresh}_evenUodd_mask

		# To check the correct files are read
		echo "$subj done"  	            
	done
done



# == Compiling (2) within-subj evenUodd ==

# Specify output directory
output_dir_2="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/2_withinsubj_evenUodd"

modified_MD_parcels_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/MD_not_language_parcels"

# Loops over all subject folders in subject directory
for subj in $f; do

	# Loops over all four ROI location groups
	for area in LR_MD_parcels L_language_parcels wholebrain wholebrain_minus_L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do
		area_no_thresh="${area}_no_thresh"

		# Specify input directory 
		roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/$subj/langlocSN/ARCV/$area_no_thresh"
		
		# Make output directory
		mkdir -p $output_dir_2/$area_no_thresh
		
		# Loops over all possible ROI and/or wholebrain roi names	
		for parcel_image in $parcel_dir/$area/*.nii; do

			# Extract parcel name for each mask, useful for clean output
			if [ $area == wholebrain ]; then
				parcel_name="wholebrain"
			elif [ $area == MD_parcels_top10_masked ]; then
				break
			else
				parcel_name=$(basename $parcel_image .nii)
			fi

			fslmaths $subj_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_even_${parcel_name}*mask.nii -add $subj_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_odd_${parcel_name}*mask.nii $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_evenUodd
			
			fslmaths $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_evenUodd -nan -bin $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_evenUodd_mask

		done

		if [ $area == MD_parcels_top10_masked ]; then

			for parcel_image in $modified_MD_parcels_dir/*.nii; do

				parcel_name=$(basename $parcel_image .nii)

				fslmaths $subj_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_even_${parcel_name}*mask.nii -add $subj_dir/$subj/langlocSN/ARCV/$area_no_thresh/SMinusN_odd_${parcel_name}*mask.nii $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_modified_evenUodd
			
				fslmaths $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_modified_evenUodd -nan -bin $output_dir_2/$area_no_thresh/${subj}_${parcel_name}_modified_evenUodd_mask

				# To check the correct files are read
				echo "$parcel_name"
			
				done
		fi
		echo "$subj $area done"
	done
done




# == Compiling (4) across-subj evenUodd, or SnN / SuN masks ==

# Specify output directory
output_dir_4="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/4_acrosssubj_allROIs_evenUodd"

for area in LR_MD_parcels L_language_parcels wholebrain wholebrain_minus_L_language_parcels MD_not_language_parcels MD_parcels_top10_masked; do
	area_no_thresh="${area}_no_thresh"

	# Make output directory
	mkdir -p $output_dir_4

	# Specify input directory
	# NB diff. input dir needed for Lang,MD v. WB, WB-parcels.
	# This is because we want to call on all-ROIs-compiled maps for areas with multiple parcels (folder 3) and the evenUodd maps for WB and WB-parcels (folder 2)
	if [ $area == L_language_parcels ] || [ $area == LR_MD_parcels ] || [ $area == MD_not_language_parcels ] || [ $area = MD_parcels_top10_masked ]; then
	input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/3_withinsubj_evenUodd_allROIs/$area_no_thresh"
	else
	input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV_no_thresh/2_withinsubj_evenUodd/$area_no_thresh"
	fi
	
	subject_masks=$(find "$input_dir" -maxdepth 1 -type f -name '*mask.nii')
	
	# Converts list of strings into an array, with no line breaks after strings (-t)
	mapfile -t subject_mask_array <<< "$subject_masks"

	fslmaths ${subject_mask_array[0]} -add ${subject_mask_array[1]} -add ${subject_mask_array[2]} -add ${subject_mask_array[3]} -add ${subject_mask_array[4]} -add ${subject_mask_array[5]} -add ${subject_mask_array[6]} -add ${subject_mask_array[7]} -add ${subject_mask_array[8]} -add ${subject_mask_array[9]} -add ${subject_mask_array[10]} -add ${subject_mask_array[11]} -add ${subject_mask_array[12]} -add ${subject_mask_array[13]} -add ${subject_mask_array[14]} -add ${subject_mask_array[15]} -add ${subject_mask_array[16]} -add ${subject_mask_array[17]} -add ${subject_mask_array[18]} -add ${subject_mask_array[19]} -add ${subject_mask_array[20]} -add ${subject_mask_array[21]} -add ${subject_mask_array[22]} -add ${subject_mask_array[23]} $output_dir_4/all_subjects_all_ROIs_${area_no_thresh}_evenUodd
	
	fslmaths $output_dir_4/all_subjects_all_ROIs_${area_no_thresh}_evenUodd -nan -bin $output_dir_4/all_subjects_all_ROIs_${area_no_thresh}_evenUodd_mask

	# To check the correct files are read
	for path in "${subject_mask_array[@]}"; do echo "$(basename "$path")"; done
	
	echo "$area done"
done	
