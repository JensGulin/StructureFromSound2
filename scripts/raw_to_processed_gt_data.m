%% Reading in file

mics = zeros(11,3,30);
%addpath('./Mocap_data/2022_05_07/mocap/1_LABELED/Ilayda_rot_003_may07/Data');
addpath('../raw_data/')
addpath('../processed_data/')



%C = fileread(strcat('speech0001','.tsv'));

%filename = 'speech0001';
filenames = ["music0001","speech0001","speech0002","speech0003","speech0004","music0002","music0003", "music0004"];
filenames = "Grid0110";

for filename = filenames

[headers,data] = read_data_and_header(strcat(filename,'.tsv'));





%%

mic_pos = cell(11,1);
for mic = 1:11



    mic_pos_temp = cell(2,1);
    counter = 1;
    for RL = {"R","L"}
        if mic > 9
            header = strcat("mic",num2str(mic),RL{1}, " ");
        else
            header = strcat("mic0",num2str(mic),RL{1}, " ");
        end
    
        for xi = 1:length(headers)
            if headers{xi} == strcat(header, "X")
                break
            end
            if xi == length(headers)
                error(strcat("Didn't find mic: ",strcat(header, "X")));
            end
        end

        for yi = 1:length(headers)
            if headers{yi} == strcat(header, "Y")
                break
            end
            if yi == length(headers)
                error(strcat("Didn't find mic: ",strcat(header, "Y")));
            end
        end

        for zi = 1:length(headers)
            if headers{zi} == strcat(header, "Z")
                break
            end
            if zi == length(headers)
                error(strcat("Didn't find mic: ",strcat(header, "Z")));
            end
        end

        mic_pos_temp{counter} = [data{xi},data{yi},data{zi}];
        counter = counter + 1;
    
    end

    mic_pos{mic} = (mic_pos_temp{1} + mic_pos_temp{2})/2;
    
end


for i = 1:length(headers)
    if headers{i} == "Time"
        break
    end
    if i == length(headers)
        error("Didn't find time")
    end
end

time = data{i};



speaker_pos_temp = cell(4,1);
for speaker = 1:4

    header = strcat("speaker",num2str(speaker), " ");
    for xi = 1:length(headers)
            if headers{xi} == strcat(header, "X")
                break
            end
            if xi == length(headers)
                error(strcat("Didn't find: ",strcat(header, "X")));
            end
        end

        for yi = 1:length(headers)
            if headers{yi} == strcat(header, "Y")
                break
            end
            if yi == length(headers)
                error(strcat("Didn't find: ",strcat(header, "Y")));
            end
        end

        for zi = 1:length(headers)
            if headers{zi} == strcat(header, "Z")
                break
            end
            if zi == length(headers)
                error(strcat("Didn't find: ",strcat(header, "Z")));
            end
        end
    
        speaker_pos_temp{speaker} = [data{xi},data{yi},data{zi}];
        
end
q = speaker_pos_temp;
speaker_pos = [];
for ii = 1:length(q{1})
    
    w = [];
    for i = 1:4
        w = [w;q{i}(ii,:)];
    end
    
    if sum(w == 0,'all') > 2
        speaker_pos(ii,:) = nan(1,3);
        continue
    end
    
    
    mean_dist = [];
    for i = 1:4
        mean_dist = [mean_dist, mean(vecnorm((w(i,:) - w)')')];
    end
    [maxv,maxi] = max(mean_dist); % maxi is the mic which is distant from the other 3
    
    [maxv2,maxi2] = max(vecnorm((w(maxi,:) - w)')');
    [minv2,mini2] = mink(vecnorm((w(maxi,:) - w)')',2);
    mini2 = mini2(2);
    
    
    wpoint = w(mini2,:);
    wvec1 = w(maxi,:);
    wvec2 = w(maxi2,:);
    w_to_proj = w(setdiff(1:4,[mini2,maxi,maxi2]),:);
    
    p1 = wvec1 - wpoint;
    p2 = wvec2 - wpoint;
    p3 = w_to_proj - wpoint;
    pn = cross(p1,p2);
    
    mic_center = wpoint + p3 - pn*(pn*p3'/(pn*pn'));
    
    speaker_pos(ii,:) = mic_center;

end
%% Packaging values in a struct

target_folder = strcat("../processed_data/",filename);

if ~exist(target_folder, 'dir')
    mkdir(target_folder);
end

sfs.speaker = speaker_pos;
sfs.mics = mic_pos;

sfs.time = time;

save(strcat(target_folder,"/data_struct.mat"),"sfs");

% packaging values in csv


csvwrite(strcat(target_folder,"/speaker.csv"),sfs.speaker);
csvwrite(strcat(target_folder,"/time.csv"),sfs.time);
for i = 1:11
    csvwrite(strcat(target_folder,"/mic_",num2str(i),".csv"),sfs.mics(i));
end

XYZ = ["_x","_y","_z"];
range_conv = 1/1000; % mm to meter
header = [1:11]';
header = reshape(["mic" + string(header) + XYZ]',[],1)';
header = ["time", header, "speaker" + XYZ];
header = strjoin(header, ',');
%write header to file
fname = strcat(target_folder,"/gt_positions.csv")
fid = fopen(fname,'w'); 
fprintf(fid,'%s\n',header);
fclose(fid);
%write data to end of file
dlmwrite(fname,[time,[sfs.mics{:}].*range_conv,sfs.speaker.*range_conv],'-append');


end












