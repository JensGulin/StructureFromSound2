%% Run raw_to_processed_gt_data first then this file

data_folder = "../raw_data/";
folder_names = ["speech1","speech2","speech3","speech4","music1","music2","music3", "music4"];
%folder_names = ["speech1"]
%folder_names = "music4"

output_folder_base = "../processed_data/";

for ii = folder_names
    folder_name = strcat(data_folder,ii,"/");
    output_folder = strcat(output_folder_base,ii,"/");
    
    % Sync gives us when the audio recoding should have its time zero
    [y,fs] = audioread(strcat(folder_name,"Sync.wav"));
    ydiff = y(2:end) - y(1:end-1);
    [maxv,first_index_to_keep] = max(ydiff);


    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
    

    %Finding time to cut the recoding at the end based on for how long a
    %time we have ground_truth
    temp = convertStringsToChars(ii);
    gt_folder = strcat(temp(1:end-1),"000",temp(end));

    gt_folder = strcat(output_folder_base,gt_folder,"/");
    load(strcat(gt_folder,"data_struct.mat"));
    
    length_of_audio = 96e3*(sfs.time(end) + 1);
    last_index_to_keep = min(first_index_to_keep + length_of_audio, length(y));

    files = dir(strcat(folder_name,'*.wav'));

    for i = 1:length(files)
        filename = files(i).name;
        [y,fs] = audioread(strcat(folder_name,filename));
        
        y_keep = y(first_index_to_keep:last_index_to_keep);
        % Saving new file
        
        audiowrite(strcat(output_folder, filename),y_keep,fs)
    end

end


