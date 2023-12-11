function [col_names, data_crop] = read_data_and_header(path)
    C = fileread(path);
    line_breaks = strfind(C,sprintf('\n'));
    line_breaks = [1 line_breaks];

    rows = cell(length(line_breaks) -1,1);
    ntabs = zeros(length(line_breaks) -1,1);


    for i = 2:(length(rows)+1)
        rows{i-1} = C((line_breaks(i-1)+1):(line_breaks(i) - 2)); % For some 
        ntabs(i-1) = length(strfind(rows{i-1},sprintf('\t')));
    end

    [n_columns,data_start] = max(ntabs);


    col_names = cell(1,n_columns);

    header_tabs = [1,strfind(rows{data_start},sprintf('\t'))];
    for i = 1:n_columns
        col_names{i} = rows{data_start}((header_tabs(i)+1):(header_tabs(i+1)-1));
    end
    fid = fopen(path);
    data = textscan(fid, strcat('%f %f %f',repmat(' %f %f %f %s',1,(length(col_names) -3)/4)), 'HeaderLines', 14,'Delimiter',{'\t'});

    counter = 1;
    while size(data{end},1) == 0
        fid = fopen(path);
        data = textscan(fid, strcat('%f %f %f',repmat(' %f %f %f %s',1,(length(col_names) -3)/4)), 'HeaderLines', 14 + counter,'Delimiter',{'\t'});
        counter = counter + 1;
        if counter > 100
            error(strcat("The file: ", path, " Has too much missing data at start"));
        end
    end
    
    temp = length(data{1});
    for i = 1:size(data,2)
        temp = min(temp, length(data{i}));
    end
    
    for i = 1:size(data,2)
        data_crop{i} = data{i}((length(data{i}) - temp + 1):(end-1));
    end 

    fclose(fid);
end