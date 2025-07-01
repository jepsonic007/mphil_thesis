% Calculating Dice within-subject, even- odd-run similarity, in all top 10% masks, across all subj

% Creating list of subjects from subject directory
subj_dir = dir('/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh'); % Get list of all items in the directory
subj_folder_names = {subj_dir([subj_dir.isdir] & ~ismember({subj_dir.name}, {'.', '..'})).name}'; % Extract folder names only (exclude '.' and '..')
subj_code = subj_folder_names(contains(subj_folder_names, 'subj_')); % Find folders that contain 'firstlevel_'

% Creating list of areas from directory
area_dir = dir('/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/roi_parcels/rois'); % Get list of all items in the directory
area_names = {area_dir([area_dir.isdir] & ~ismember({area_dir.name}, {'.', '..'})).name}; % Extract folder names only (exclude '.' and '..')
area_names_no_thresh = strcat(area_names, '_no_thresh')

% Create empty structure for Table
Subject = {};
Area = {};
Parcel = {};
Dice_even_v_odd = []; % [] indicates numeric data type

for subj=1:length(subj_code);
    
    disp([subj_code{subj}])
    
    for area=1:length(area_names);

        % Create list of top 10% masks/parcels from directory, based on current area iteration
        mask_dir = dir(['/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/', subj_code{subj}, '/langlocSN/ARCV/', area_names_no_thresh{area}, '/']);
        mask_names = fullfile({mask_dir.name});
        mask_names = mask_names(~ismember(mask_names, {'.', '..'}));
        mask_names = mask_names(contains(mask_names, '_top10_percent_mask.nii')); % Extracts all top10% masks
        mask_names = mask_names(contains(mask_names, 'SMinusN_even')); % Extracts only even masks, so we have one mask on loop
        mask_names = extractBefore(mask_names,'_top10_percent_mask.nii');
        mask_names = extractAfter(mask_names, 'SMinusN_even_');

        for parcel=1:length(mask_names);

            % Load binary masks
            image1 = niftiread(['/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/', subj_code{subj}, '/langlocSN/ARCV/', area_names_no_thresh{area}, '/SMinusN_even_', mask_names{parcel}, '_top10_percent_mask.nii']);
            image2 = niftiread(['/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/data/top_10_percent_no_thresh/', subj_code{subj}, '/langlocSN/ARCV/', area_names_no_thresh{area}, '/SMinusN_odd_', mask_names{parcel}, '_top10_percent_mask.nii']);
            
            % Check that the two masks have the same dimensions
            if ~isequal(size(image1), size(image2))
                error('Masks do not have the same dimensions');
            end

            % Calculate the Dice coefficient
            overlapping_nonzero_voxels = sum(image1(:) & image2(:));  % (:) converts matrix into a column, & returns T if corresponding rows both contain nonzero value, sum returns total T's
            sum_nonzero_voxels = sum(image1(:)) + sum(image2(:));   % Returns total number of nonzero voxels from both columns
            dice_coefficient = (2 * overlapping_nonzero_voxels)/sum_nonzero_voxels;    % Calculate Dice

            disp(['Dice coefficient: ', num2str(dice_coefficient)]); % num2str needed, since [] will only concatenate strings

            % Add current information on loop to columns, later outputted to Table
            Subject{end + 1,1} = subj_code{subj};
            Area{end + 1,1} = area_names{area};
            Parcel{end + 1,1} = mask_names{parcel};
            Dice_even_v_odd(end + 1,1) = dice_coefficient;

        end
    end
end


% Create table
T = table(Subject,Area, Parcel, Dice_even_v_odd);

% Write table to existing file
writetable(T, '/group/mlr-lab/Ryan_Jepson/Tuckute_2024preprint/results/Dice_analysis/ARCV_Dice_ROI_EvO.csv', 'Delimiter',',','QuoteStrings',true);