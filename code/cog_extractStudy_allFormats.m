function [] = cog_extractStudy_allFormats(pathToJSON,pathToOutputDir)
%  -- Extract Study - All Formats --
%  -- Date: 16-Mar-2022 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Function for extracting the site download data (JSON (with raw)). It will
%  output the .mat files, process the raw data and export those to csv and
%  also export the .mat files to csv
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  pathToJSON :: Path to the directory full of the JSON files downloaded
%  from the site
% 
%  pathToOutputDir :: Path to an empty directory within which the function
%  will make 3 directories, one for the .mat files, one for the raw data
%  and one for the .csv files
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%   :: 
% 
%  ------------------------------------------------------------------------

%% Check the paths

% Check that all files in the pathToJSON are .json files
[files] = util_getPaths(pathToJSON);
[~,~,ext] = fileparts(files);

if any(~strcmp(ext,'.json'))
    error('Some files in pathToJSON directory are not JSON files.')
end

% Check that the directory at pathToOutputDir is empty
% contentCheck = struct2table(dir(pathToOutputDir));
% 
% contentCheck(strcmp(contentCheck.name,'.'),:) = [];
% contentCheck(strcmp(contentCheck.name,'..'),:) = [];
% contentCheck(strcmp(contentCheck.name,'.DS_Store'),:) = [];
% 
% if ~isempty(contentCheck)
% 
%     error('Directory at pathToOutputDir is not empty.');
% 
% end

%% Make the output directory structure



pathToMat = fullfile(pathToOutputDir,'mat');
pathToCSV = fullfile(pathToOutputDir,'csv');
pathToRaw = fullfile(pathToOutputDir,'raw');

% mkdir(pathToMat);
% mkdir(pathToCSV);
% mkdir(pathToRaw);
%% Convert the JSON into .mat files

cog_extractStudy_json(...
    pathToJSON,...
    pathToMat...
);


%% If the data uses q_ID_clearStorage then link the user names

[paths,IDs] = util_getPaths(pathToMat);

if any(strcmp(IDs,'q_ID_clearStorage') | strcmp(IDs,'q_c3nl_username'))
   
    if any(strcmp(IDs,'q_ID_clearStorage'))
        idQ = 'q_ID_clearStorage';
    else
        idQ = 'q_c3nl_username';
    end
    
    % Load the ID data and the site data
    idData = load(...
        fullfile(...
            pathToMat,...
            idQ...
        ),...
        'user_id',...
        'Q1_R',...
        'site',...
        'startTime'...
    );

    idData = struct2table(idData);
    idData = unique(idData,'rows');
    
    
    % Run through the other tasks and make a userID key for them
    for s=1:length(IDs)
       
        user_data = load(...
            paths{s},...
            'user_id',...
            'site',...
            'startTime'...
        );

        user_data.user_id = categorical(user_data.user_id);
    
        userInputID = cell([length(user_data.user_id),1]);
    
        for u=1:length(user_data.user_id)

            this_user = user_data.user_id(u);
            this_site = user_data.site(u);
            this_startTime = user_data.startTime(u);
            
           
            thisKey = idData(...
                idData.user_id == this_user &...
                idData.site == this_site & ...
                idData.startTime < this_startTime,...
                :...
            );
            
            if height(thisKey) > 0
                theseUsers = strjoin(string(thisKey.Q1_R),',');
                userInputID{u} = theseUsers;
            else
%                 fprintf('nuts');
            end
            
        end
        
        save(...
            paths{s},...
            '-append',...
            'userInputID'...
        );
        
    end
    
end


%% Process the Raw data files

taskIdxs = ~contains(IDs,'q_');
taskPaths = paths(taskIdxs);
taskIDs = IDs(taskIdxs);

for t=1:length(taskIDs)

    fprintf('processing: %s - %d\n',taskIDs{t},t);
    
    load(...
        taskPaths{t},...
        'startTime',...
        'user_id',...
        'Rawdata'...
    );
%     try
        [rawDataArr,focusArr,corrupted,nonCompliance] = cog_sortRaw(...
            Rawdata,...
            taskIDs{t},...
            0,...
            1 ...
        );
    
        thisRawDir = fullfile(...
            pathToRaw,...
            taskIDs{t}...
        );
    
        mkdir(...
            thisRawDir...
        );


        empty = cellfun(@(x) isempty(x),rawDataArr);
        rawDataArr(empty) = [];
    
        for r=1:length(rawDataArr)
           
            thisRaw = cell2table(...
                rawDataArr{r}(2:end,:),...
                'VariableNames',rawDataArr{r}(1,:)...
            );
        
            writetable(...
                thisRaw,...
                fullfile(...
                    thisRawDir,...
                    strcat(...
                        'raw_',...
                        string(user_id(r)),...
                        '_',...
                        string(startTime(r)),...
                        '.xlsx'...
                    )...
                )...
            );
            
        end
%     catch
%         warning('Could not process raw data for %s',taskIDs{t});
%     end
    
end


%% Convert the .mat files to csv files

getRid = {...
    'os',...
    'device',...
    'browser',...
    'Rawdata',...
    'dynamicDifficulty'...
};

for s=1:length(paths)
   
    thisData = load(...
        paths{s}...
    );

    if contains(IDs{s},'q_')
        key = thisData.keyObj.key;
        
        writetable(...
            key,...
            fullfile(...
                pathToCSV,...
                strcat(...
                    IDs{s},...
                    '_key.xlsx'...
                )...
            )...
        );
        
        thisData = rmfield(thisData,'keyObj');
    end

    
    
    % Remove troublesome variables
    for g=1:length(getRid)
        if isfield(thisData,getRid{g})
            thisData = rmfield(thisData,getRid{g});
        end
    end
    
    
    thisData = struct2table(thisData);


%     Sort out the responses field for the csv of IDED (it is a double if
%     the person didn't fail and a cell array if they did fail so write
%     table freaks out.
    [~,taskID] = fileparts(paths{s});
    if strcmp(taskID,'i4i_IDED')
        
        responseCatch = {};
        for i=1:height(thisData)
            thisResponse = thisData.responses{i};
            if isa(thisResponse,"double")
                rString = '';
                for j=1:length(thisResponse)
                    
                    
                    rString = [rString,char(string(thisResponse(j))),'_'];
                   
                end
            elseif isa(thisResponse,"cell")
                rString = '';
                for j=1:length(thisResponse)
                    
                    if isempty(thisResponse{j})
                        rString = [rString,' _'];
                    else
                        rString = [rString,char(string(thisResponse{j})),'_'];
                    end
                end
            end
            responseCatch{i} = rString;
        end
        thisData.responses = responseCatch';

    end
    
    writetable(...
        thisData,...
        fullfile(...
            pathToCSV,...
            strcat(...
                IDs{s},...
                '.xlsx'...
            )...
        )...
    );

    
    
end

end