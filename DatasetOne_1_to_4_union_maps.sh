#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI


# Specify output directory
output_dir_1="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/1_withinsubj_evenROIs_oddROIs"

# Specify output directory
output_dir_3="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/3_withinsubj_evenUodd_ROIs"

parcel_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois"

# Specify subj's directory 
subj_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_ARCV"

# Create string list of all subject folders
cd $subj_dir
f=*

# Loops over all subject folders in subject directory
for subj in $f; do

    # For the two types of ROI mask folders
    for area in LR_MD_parcels L_language_parcels; do

        # Make output directory
        mkdir -p $output_dir_1/ARCV_${area}

		# Make output directory
        mkdir -p $output_dir_3/ARCV_${area}

		# Specify input directory 
	    roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_ARCV/${subj}/langlocSN/${area}"

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
        	fslmaths ${roi_even_array[0]} -add ${roi_even_array[1]} -add ${roi_even_array[2]} -add ${roi_even_array[3]} -add ${roi_even_array[4]} -add ${roi_even_array[5]} $output_dir_1/ARCV_${area}/${subj}_compiled_all_even_ROIs
        
        	# Compile 6 odd-run ROIs
        	fslmaths ${roi_odd_array[0]} -add ${roi_odd_array[1]} -add ${roi_odd_array[2]} -add ${roi_odd_array[3]} -add ${roi_odd_array[4]} -add ${roi_odd_array[5]} $output_dir_1/ARCV_${area}/${subj}_compiled_all_odd_ROIs

			# Compile all even and odd-run ROIs
			fslmaths $output_dir_1/ARCV_${area}/${subj}_compiled_all_even_ROIs -add $output_dir_1/ARCV_${area}/${subj}_compiled_all_odd_ROIs $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd

			fslmaths $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd -nan -bin $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd_mask

		elif [ $area == LR_MD_parcels ]; then

			# Compile 18 even-run ROIs
        	fslmaths ${roi_even_array[0]} -add ${roi_even_array[1]} -add ${roi_even_array[2]} -add ${roi_even_array[3]} -add ${roi_even_array[4]} -add ${roi_even_array[5]} -add ${roi_even_array[6]} -add ${roi_even_array[7]} -add ${roi_even_array[8]} -add ${roi_even_array[9]} -add ${roi_even_array[10]} -add ${roi_even_array[11]} -add ${roi_even_array[12]} -add ${roi_even_array[13]} -add ${roi_even_array[14]} -add ${roi_even_array[15]} -add ${roi_even_array[16]} -add ${roi_even_array[17]} $output_dir_1/ARCV_${area}/${subj}_compiled_all_even_ROIs
        
			# Compile 18 odd-run ROIs
        	fslmaths ${roi_odd_array[0]} -add ${roi_odd_array[1]} -add ${roi_odd_array[2]} -add ${roi_odd_array[3]} -add ${roi_odd_array[4]} -add ${roi_odd_array[5]} -add ${roi_odd_array[6]} -add ${roi_odd_array[7]} -add ${roi_odd_array[8]} -add ${roi_odd_array[9]} -add ${roi_odd_array[10]} -add ${roi_odd_array[11]} -add ${roi_odd_array[12]} -add ${roi_odd_array[13]} -add ${roi_odd_array[14]} -add ${roi_odd_array[15]} -add ${roi_odd_array[16]} -add ${roi_odd_array[17]} $output_dir_1/ARCV_${area}/${subj}_compiled_all_odd_ROIs    
	    
			# Compile all even and odd-run ROIs
			fslmaths $output_dir_1/ARCV_${area}/${subj}_compiled_all_even_ROIs -add $output_dir_1/ARCV_${area}/${subj}_compiled_all_odd_ROIs $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd

			fslmaths $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd -nan -bin $output_dir_3/ARCV_${area}/${subj}_all_ROIs_${area}_evenUodd_mask

		fi	    
	    
		# To check the correct files are read

	    echo "$subj $rr done"  	            
    done

done

cd /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/Jobs/union_maps_ARCV



# Specify output directory
output_dir_2="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/2_withinsubj_evenUodd"

# Create string list of all subject folders
cd $subj_dir
f=*

# Loops over all subject folders in subject directory
for subj in $f; do

	# Loops over all four ROI location groups
    for area in LR_MD_parcels L_language_parcels wholebrain wholebrain_minus_L_language_parcels; do
    
	    # Specify input directory 
	    roi_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_ARCV/${subj}/langlocSN/${area}"
	    
	    # Make output directory
	    mkdir -p $output_dir_2/ARCV_${area}
	    
		if [ $area = wholebrain ]; then

			fslmaths $subj_dir/$subj/langlocSN/$area/SMinusN_even_${area}*mask.nii -add $subj_dir/$subj/langlocSN/$area/SMinusN_odd_${area}*mask.nii $output_dir_2/ARCV_${area}/${subj}_${area}_evenUodd
            
            fslmaths $output_dir_2/ARCV_${area}/${subj}_${area}_evenUodd -nan -bin $output_dir_2/ARCV_${area}/${subj}_${area}_evenUodd_mask
		else
			# Loops over all possible ROI and/or wholebrain roi names	
			for parcel_image in $parcel_dir/$area/*.nii; do

				parcel_name=$(basename $parcel_image .nii)

				fslmaths $subj_dir/$subj/langlocSN/$area/SMinusN_even_${parcel_name}*mask.nii -add $subj_dir/$subj/langlocSN/$area/SMinusN_odd_${parcel_name}*mask.nii $output_dir_2/ARCV_${area}/${subj}_${parcel_name}_evenUodd
				
				fslmaths $output_dir_2/ARCV_${area}/${subj}_${parcel_name}_evenUodd -nan -bin $output_dir_2/ARCV_${area}/${subj}_${parcel_name}_evenUodd_mask

				# To check the correct files are read
				echo "$parcel_name"
			
				done
		fi
		echo "$subj $area done"
	done
done

# Specify output directory
output_dir_4="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/4_acrosssubj_allROIs_evenUodd"

# Loops over two of four ROI location groups
for area in LR_MD_parcels L_language_parcels wholebrain wholebrain_minus_L_language_parcels; do

	# Make output directory
	mkdir -p $output_dir_4/ARCV_${area}

    # Specify input directory
    # NB diff. input dir needed for Lang,MD v. WB, WB-parcels.
    # This is because we want to call on all-ROIs-compiled maps for Lang and MD (folder 3) and the evenUodd maps for WB and WB-parcels (folder 2)
	if [ $area == "L_language_parcels" ] || [ $area == "LR_MD_parcels" ]; then
	input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/3_withinsubj_evenUodd_ROIs/ARCV_${area}"
	fi
	
	if [ $area == "wholebrain" ] || [ $area == "wholebrain_minus_L_language_parcels" ]; then
	input_dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/union_maps_ARCV/2_withinsubj_evenUodd/ARCV_${area}"
    fi
	
    subject_masks=$(find "$input_dir" -maxdepth 1 -type f -name '*mask.nii')
    
    # Converts list of strings into an array, with no line breaks after strings (-t)
    mapfile -t subject_mask_array <<< "$subject_masks"

	fslmaths ${subject_mask_array[0]} -add ${subject_mask_array[1]} -add ${subject_mask_array[2]} -add ${subject_mask_array[3]} -add ${subject_mask_array[4]} -add ${subject_mask_array[5]} -add ${subject_mask_array[6]} -add ${subject_mask_array[7]} -add ${subject_mask_array[8]} -add ${subject_mask_array[9]} -add ${subject_mask_array[10]} -add ${subject_mask_array[11]} -add ${subject_mask_array[12]} -add ${subject_mask_array[13]} -add ${subject_mask_array[14]} -add ${subject_mask_array[15]} -add ${subject_mask_array[16]} -add ${subject_mask_array[17]} -add ${subject_mask_array[18]} -add ${subject_mask_array[19]} -add ${subject_mask_array[20]} -add ${subject_mask_array[21]} -add ${subject_mask_array[22]} -add ${subject_mask_array[23]} $output_dir_4/ARCV_${area}/all_subjects_all_ROIs_${area}_evenUodd
	
	fslmaths $output_dir_4/ARCV_${area}/all_subjects_all_ROIs_${area}_evenUodd -nan -bin $output_dir_4/ARCV_${area}/all_subjects_all_ROIs_${area}_evenUodd_mask

    # To check the correct files are read
    for path in "${subject_mask_array[@]}"; do echo "$(basename "$path")"; done
	
	echo "$area done"
	
done