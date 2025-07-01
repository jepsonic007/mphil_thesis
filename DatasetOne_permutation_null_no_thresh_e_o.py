import numpy as np
import os
import nibabel as nib
import pandas as pd
from nilearn.image import resample_to_img
from scipy.ndimage import center_of_mass, rotate
import cc3d
import random
import os
from sklearn.metrics import jaccard_score  # Used as a proxy to validate DICE logic
from nilearn import plotting
import matplotlib.pyplot as plt
import pandas as pd

# === Define Dice function ===
def dice_coefficient(mask1, mask2):
    """Compute the DICE coefficient between two binary masks."""
    intersection = np.sum(mask1 * mask2)
    size1 = np.sum(mask1)
    size2 = np.sum(mask2)
    if size1 + size2 == 0:
        return np.nan
    return (2.0 * intersection)/(size1 + size2)

# Read in .csv containing 'real' Dice scores (MD and lang parcels)
df_real_Dice = pd.read_csv("/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/Dice_analysis/ARCV_Dice_ROI_EvO_MDnotlang.csv")

# Define output_dirs
csv_output_dir = "/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/random_permutations_e_o"
null_output_dir = "/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/random_permutations_e_o/no_thresh_maps"

# For first array (appending csv output every iteration, with cluster-random Dice coefficients)
iteration_subject = []
iteration_area = []
iteration_parcel = []
iteration_run_order = []
iteration_dice_scores = []
iteration_iteration = []
# For second array (appending csv output every 1000 iterations, with null p-value)
null_subject = []
null_area = []
null_parcel = []
null_run = []
null_real_Dice = []
null_count_gt_list = []
null_count_lt_list = []
null_p_value_list = []

# Create empty flags for error tallies
iteration_masks_with_cluster_overlap = 0
failed_attempts_gt_100 = 0

# === Obtain list of subj_codes from subdir for loop ===
top10_dir = "/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh"
subdir_list = os.listdir(top10_dir)
# subdir_list = ['subj_834','subj_837']
print(f"{subdir_list}")

# area_list = ['LR_MD_parcels', 'L_language_parcels']
area_list = ['MD_not_language_parcels', 'MD_parcels_top10_masked']

# Set max iteration
max_iteration = 1000

for area in area_list:

    # Initialise empty array for single-subject distribution and empty array for DICE values
    if area == "L_language_parcels":
        all_parcels_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/other/all_L_lang_parcels.nii")
    if area == "LR_MD_parcels":
        all_parcels_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Assem_et_al_2020_renamed/data/roi_parcels/other/all_LR_MD_parcels.nii")
    if area == "MD_not_language_parcels" or "MD_parcels_top10_masked":
        all_parcels_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/other/all_MD_not_language_parcels.nii")
    all_parcels_data = all_parcels_img.get_fdata().astype(np.uint8)
    null_distribution_across_subj = np.zeros_like(all_parcels_data, dtype=np.uint16)

    parcel_dir = f"/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/{area}"
    parcel_list = os.listdir(parcel_dir)
    print(f"{parcel_list}")

    # Looping across subjects
    for subj in subdir_list:
        print(f"{subj}")
        null_distribution_subj = np.zeros_like(all_parcels_data, dtype=np.uint16)

        # os.makedirs(f"{null_output_dir}/{subj}", exist_ok=True)
        # Above line only needed if outputting single-subject nulls, which we don't need at this stage

        # Looping across 6 language parcels
        for parcel in parcel_list:

            parcel_name = parcel.removesuffix(".nii")
            if area == "MD_parcels_top10_masked":
                parcel_name_no_modified = parcel_name
                parcel_name = f"{parcel_name}_modified"
            print(f"{parcel_name}")

            # Load ROI image
            if area == "MD_parcels_top10_masked":
                roi_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/{area}/{parcel_name_no_modified}.nii")
            else:
                roi_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois/{area}/{parcel_name}.nii")
            roi_data = roi_img.get_fdata().astype(np.uint8)
            affine = roi_img.affine
            header = roi_img.header 

            # ooping across even and odd clusters
            for run in ['even', 'odd']:# 'odd']: # Add in [, 'odd'], and ensure looped files are formatted and read-in appropriately 

                print(f"{run}")

                # Load and resample cluster image
                cluster_img = nib.load(f"/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/{subj}/langlocSN/ARCV/{area}_no_thresh/SMinusN_{run}_{parcel_name}_top10_percent_mask.nii")
                resamp = resample_to_img(cluster_img, roi_img, interpolation='nearest')
                cluster_data = resamp.get_fdata().astype(np.uint8)

                # Convert cluster map as binary mask
                original_cluster_mask = (cluster_data > 0).astype(np.uint8)

                # Returns labelled 3D array, where each distinct cluster is assigned a label
                labeled = cc3d.connected_components(cluster_data.astype(np.uint8), connectivity=26)

                # Extracts number of clusters
                num_clusters = labeled.max()
                print(f"Found {num_clusters} clusters")

                # Create empty array for later p-value calculation
                rand_dice_1000 = []

                # === Repeat process X times ===
                for i in range(max_iteration):

                    # Initialise empty array for each iteration
                    iteration_mask = np.zeros_like(roi_data)

                    for cluster_id in range(1, num_clusters + 1):
                        
                        # Binarise current cluster
                        cluster_mask = (labeled == cluster_id).astype(np.uint8)

                        # Skip empty clusters
                        if cluster_mask.sum() == 0:
                            continue

                        # Compute center of mass (and round that value)
                        com = center_of_mass(cluster_mask)
                        com_rounded = tuple(np.round(com).astype(int))

                        # Randomly rotate 0, 90, 180, or 270 degrees along random axis
                        k = random.choice([0, 1, 2, 3])
                        axis = random.choice([(0, 1), (0, 2), (1, 2)]) # XY, XZ, YZ
                        rotated_cluster = rotate(cluster_mask, angle=90*k, axes=axis, reshape=False, order=0)

                        # Obtain all coordinates within parcel
                        roi_voxel_indices = np.argwhere(roi_data == 1)
                        
                        # Introduce flags
                        failed_attempts = 0
                        success = False
                        max_attempts = 100

                        while not success and failed_attempts < max_attempts:
                            
                            # Find random point in parcel, shift COM (and all other voxels proportionately) to that position
                            target_voxel = roi_voxel_indices[np.random.choice(len(roi_voxel_indices))]
                            shift = target_voxel - np.round(center_of_mass(rotated_cluster)).astype(int)
                            shifted_coords = np.argwhere(rotated_cluster) + shift

                            # Count how many shifted coords fall inside the parcel
                            inside_count = sum(roi_data[x, y, z] == 1 for x, y, z in shifted_coords)
                            total_voxels = len(shifted_coords)
                            inside_ratio = inside_count / total_voxels

                            # %-within-parcel-constraint: reject cluster if less than certain % of voxels are inside the parcel
                            if inside_ratio < 0.2:
                                failed_attempts += 1
                                print(f"{subj} {parcel_name}, {run}: Less than 20% of cluster is inside parcel. Permutation rejected")
                                continue # Ends current iteration of loop, moves onto the next

                            # Create empty shifted mask
                            shifted_mask = np.zeros_like(roi_data)
                            
                            # Introduce flag
                            overlap = False

                            # No-overlap constraint: for all the coordinates in the shifted_coords array
                            for x, y, z in shifted_coords:
                                if iteration_mask[x, y, z] == 0:
                                    shifted_mask[x, y, z] = 1
                                else:
                                    overlap = True
                                    break # Ends current for loop, moving onto next lines, i.e. 'if overlap...'
                            
                            # No-overlap constraint: ends current attempt at randomising cluster, moving onto next while loop iteration
                            if overlap:
                                failed_attempts += 1
                                print(f"{subj} {parcel_name}, {run}: Cluster overlaps with previously placed cluster. Cluster rejected.")
                                continue
                            
                            # Once shifted_coords have all been copied (successfully) into shifted_mask
                            shifted_mask = shifted_mask * roi_data # ?? Removes cluster voxels outside the parcel boundary 
                            iteration_mask += shifted_mask
                            success = True
                        
                        if failed_attempts > max_attempts:
                            print(f"Max attempts achieved. Skipping this cluster on iteration {i+1}")
                            failed_attempts_gt_100 += 1
                            continue

                    if np.any(iteration_mask > 1):
                        print(f"Error: clusters overlap")
                        iteration_masks_with_cluster_overlap += 1
                        continue
                    
                    # Indicate whether iteration was added
                    print(f"{subj} {parcel_name}, {run}: Iteration {i+1}/{max_iteration} added to null.")

                    null_distribution_subj += iteration_mask
                    dice = dice_coefficient(original_cluster_mask, iteration_mask)

                    # Append per-iteration outputs
                    iteration_dice_scores.append(dice)
                    iteration_subject.append(subj)
                    iteration_area.append(area)
                    iteration_parcel.append(parcel_name)
                    iteration_run_order.append(run)
                    iteration_iteration.append(i + 1)

                    rand_dice_1000.append(dice) # Needed to store 1000 Dice for next step, not for direct array output

                # After 1000 iterations, get real Dice and compute empirical p-value
                real_match = df_real_Dice[
                    (df_real_Dice['Subject'] == subj) &
                    (df_real_Dice['Area'] == area) &
                    (df_real_Dice['Parcel'] == parcel_name)]

                if not real_match.empty:
                    real_dice = real_match['Dice_even_v_odd'].values[0]
                    count_gt = np.sum(np.array(rand_dice_1000) >= real_dice)
                    count_lt = np.sum(np.array(rand_dice_1000) < real_dice)
                    p_val = count_gt / max_iteration
                else:
                    real_dice = np.nan
                    count_gt = np.nan
                    p_val = np.nan

                # Append results for null values output (once per subj-parcel-run)
                null_subject.append(subj)
                null_area.append(area)
                null_parcel.append(parcel_name)
                null_run.append(run)
                null_real_Dice.append(real_dice)
                null_count_gt_list.append(count_gt)
                null_count_lt_list.append(count_lt)
                null_p_value_list.append(p_val)

        # Save null distribution image (1 for each subject, each area, compiling across 1000 iterations per parcel)
        # null_img = nib.Nifti1Image(null_distribution_subj.astype(np.uint16), affine=affine, header=header)
        # nib.save(null_img, f"{null_output_dir}/{subj}/{subj}_{area}_null_distribution_{max_iteration}_evenUodd_20thresh.nii.gz")
        null_distribution_across_subj += null_distribution_subj

    # Save across-subject null image (1 for each area, compiling across subj)
    across_subj_img = nib.Nifti1Image(null_distribution_across_subj.astype(np.uint16), affine=affine, header=header)
    nib.save(across_subj_img, f"{null_output_dir}/across_subject_{area}_null_20thresh_eo.nii.gz")

# Save DICE scores + null comparison
df_table = pd.DataFrame({
    'subject': iteration_subject,
    'area' : iteration_area,
    'parcel': iteration_parcel,
    'run': iteration_run_order,
    'iteration': iteration_iteration,
    'dice_score': iteration_dice_scores
})
df_table.to_csv(f"{csv_output_dir}/randomised_dice_20thresh_eo_MDnotlang.csv", index=False)

# Save p-value summary
df_pvals = pd.DataFrame({
    'subject': null_subject,
    'area' : null_area,
    'parcel': null_parcel,
    'run': null_run,
    'real_dice' : null_real_Dice,
    'count_null_gt_real' : null_count_gt_list,
    'count_null_lt_real' : null_count_lt_list,
    'p_value': null_p_value_list
})
df_pvals.to_csv(f"{csv_output_dir}/real_vs_null_dice_20thresh_results_eo_MDnotlang.csv", index=False)

# Print error tallies:
print(f"{failed_attempts_gt_100}")
print(f"{iteration_masks_with_cluster_overlap}")
