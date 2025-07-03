#!/bin/bash

#load prebuilt fsl module
module load fsl/6.0.7
#output extension
FSLOUTPUTTYPE=NIFTI


output_sheet="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/voxel_hist/vox_hist_unthresh_masked.csv"
rm -rf $output_sheet

# Populate .csv file with headers
echo "t_values,definition,subj,area,parcel" >> $output_sheet

top10dir="/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"

cd $top10dir

f=*
for subj in $f; do

    for area in L_language_parcels LR_MD_parcels; do

        for parcel in $top10dir/$subj/langlocSN/ARCV/${area}_no_thresh/SMinusN_even_*_top10_percent_mask.nii; do

            parcel_name=$(basename $parcel _top10_percent_mask.nii)
            parcel_name="${parcel_name:13}"
            echo "$parcel_name"

            fslmeants -i /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/${subj}/langlocSN/ARCV/${area}_no_thresh/SMinusN_even_${parcel_name}.nii \
                -m /group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/${area}/${parcel_name}.nii --transpose --showall \
                | sed 's/ /,/g' \
                | grep -v '^$' \
                | awk -F',' -v definition="unthresh" -v subj="$subj" -v area="$area" -v parcel="$parcel_name" -v run="$run" '{print $4 "," definition "," subj "," area "," parcel "," run}' >> $output_sheet
        
        done
    done
done
# sed ... replaces ' ' with ','
# grep removes any empty lines before outputting, necessary for column alignment
# awk uses , to separate values
# -v passes subj variable into new subj variable
# print $4 prints 4th column from fslmeants (t-values) and subj_ID
