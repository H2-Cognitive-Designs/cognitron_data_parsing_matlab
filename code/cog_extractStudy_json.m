function [] = cog_extractStudy_json(pathToJSON,pathToMat,varargin)
%  -- Cognitron - Extract Study (JSON) --
%  -- Date: 10-Jan-2022 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Extracts studies from the JSON download format of cognitron website
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  pathToJSON :: Path to the directory containing the JSON files to be
%  converted
% 
%  pathToMat :: Path to the directory to save out the files
% 
%  pathToQfiles :: OPTIONAL VARIABLE: this is the path to your local copy 
%  of the task code repo qFiles folder so that the code can add the actual
%  question text to the questionnaire key.
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%   :: 
% 
%  ------------------------------------------------------------------------

%% Parse the arguments

p = inputParser;

dirExists = @(x) exist(x,'dir') == 7;

addParameter(p,'pathToQfiles','',dirExists);

parse(p,varargin{:});

pathToQfiles = p.Results.pathToQfiles;

%% Run the code
[paths,files] = util_getPaths(pathToJSON);
numFiles = length(paths);

% Get different studies

tmp = cellfun(@(x) strsplit(x,'_'),files,'UniformOutput',false);
studies = categorical(cellfun(@(x) x{1},tmp,'UniformOutput',false));
studies_u = unique(studies);
fileIdx = double(string(cellfun(@(x) x{2},tmp,'UniformOutput',false)));


% Check if progress log already exists
pathToProgLog = fullfile(pathToMat,'progLog.mat');
progLogExist = exist(...
    pathToProgLog,...
    'file'...
);

% IF IT EXISTS
if progLogExist == 2
    load(fullfile(pathToMat,'progLog'),'progLog');
    
    % Add any new files to the progLog
    for s=1:length(paths)
        
        idx = strcmp(progLog.paths,paths{s});
        
        if ~any(idx)
           
            tmpTable = table();
            tmpTable.paths = paths{s};
            tmpTable.studies = studies(s);
            tmpTable.fileIdx = fileIdx(s);
            tmpTable.processed = 0;
            tmpTable.reprocess = 0;
            tmpTable.process = 0;
            
            progLog = [progLog;tmpTable];
            
        end
        
    end
    
else
    progLog = table(paths,studies,fileIdx);
    
    progLog.processed = zeros(height(progLog),1);
    progLog.reprocess = zeros(height(progLog),1);
    
    for s=1:length(studies_u)
        
        thisStudy_maxIdx = max(...
            progLog.fileIdx(...
                progLog.studies == studies_u(s)...
            )...
        );
       
        progLog.reprocess(...
            progLog.studies == studies_u(s) & ...
            progLog.fileIdx == thisStudy_maxIdx...
        ) = 1;
            
        
    end
end

% Decide what to process this round
process = progLog.processed == 0 | progLog.reprocess;
progLog.process = process;

% Reset the reprocesses for next time
progLog.reprocess = zeros(height(progLog),1);
for s=1:length(studies_u)
        
    thisStudy_maxIdx = max(...
        progLog.fileIdx(...
            progLog.studies == studies_u(s)...
        )...
    );

    progLog.reprocess(...
        progLog.studies == studies_u(s) & ...
        progLog.fileIdx == thisStudy_maxIdx...
    ) = 1;


end


% For each file in the JSON directory
 for f=1:numFiles
    
    thisPath = paths{f};
    [~,thisFile] = fileparts(thisPath);
    thisSite = strsplit(thisFile,'_');
    thisSite = thisSite(1);
    
    pathIdx = strcmp(progLog.paths,thisPath);
    if progLog.process(pathIdx) == 1
    
        fileNum = find(pathIdx);

        fprintf('\n--- Processing File %d: %s\n',fileNum,files{f});
        
        % Extract the first line
        fid = fopen(paths{f});
        firstLine = textscan(fid,'%s', 1, 'Delimiter','¿');
        fclose(fid);

        % Make a datastore
        ttds = tabularTextDatastore(...
            paths{f},...
            'FileExtensions',{'.json'},...
            'Delimiter',{'¿'}...
        );

        ttds.VariableNames = {...
            'json'...
        };

        ttds.SelectedVariableNames = {...
            'json'...
        };


        ttds.SelectedFormats = {...
            '%s'...
        };
    
%         ttds.ReadVariableNames = true;
%         ttds.NumHeaderLines = 1;
        

        ttds.ReadSize = 10000;
        chunk = 0;
        while ttds.hasdata

            fprintf('\n-- Chunk %d\n',chunk);

            % Increment the chunk
            chunk = chunk+1;
            % Load the rows
            
            
            theseRows = ttds.read;
            
            if chunk == 1
                theseRows.json(1:height(theseRows)+1) = ...
                    [firstLine{1};theseRows.json];
            end
            numRows = height(theseRows);

            % Convert the cells to strings
            theseRows.json = string(theseRows.json);
            
            fprintf('chunkSize: %d\n',numRows);

            % Decode the line by line JSON to matlab structs
            metaData = rowfun(...
                @(x) jsondecode(x),...
                theseRows,...
                'OutputVariableNames','meta'...
            );

            % Run through the meta-data and pull out those rows that are in
            % the new format where data is embedded inside data.

            for m=1:length(metaData.meta)


           

                this_data = metaData.meta(m).data;

                if isfield(this_data,"data")
                    
                    metaData.meta(m).user_id = metaData.meta(m).data.userstring;
                    metaData.meta(m).DEVICEID = metaData.meta(m).data.DEVICEID;
                    metaData.meta(m).salt = metaData.meta(m).data.salt;
                    metaData.meta(m).data = jsondecode(metaData.meta(m).data.data);
                else

                    metaData.meta(m).salt = "";
                    metaData.meta(m).DEVICEID = "";
                end




            end

            % --- Make a table of the data --- %
            vars = {...
                'interview_uuid',...
                'date',...
                'os',...
                'device',...
                'browser',...
                'task_id',...
                'user_id',...
                'user_code',...
                'user_uuid',...
                'salt',...
                'DEVICEID',...
                'data'...
            };

            dTable = cell(height(metaData),length(vars));
            for i=1:numRows
                for j=1:length(vars)

                    dTable{i,j} = metaData{i,'meta'}.(vars{j});
                end
            end

            dTable = array2table(...
                dTable,...
                'VariableNames',...
                vars...
            );
        
            % Add the site name to the table
            dTable.site = repmat(thisSite,[height(dTable),1]);

            % Swap the user_id field with the user_uuid field and delete
            % the user_uuid field
            dTable.user_id = dTable.user_uuid;
            dTable.user_uuid = [];

            % --- Mark each row as questionnaire or task --- %
            % Look at the survey ID field
            % If it starts with q_ mark 1 (as questionnaire)
            % If not then mark 0 (as task)
            
            taskIDs = {};
            
            for i=1:height(dTable)
                if isfield(dTable{i,'data'}{1},'taskID')
                    taskIDs{i} = dTable{i,'data'}{1}.taskID;
                else
                    taskIDs(i) = dTable{i,'task_id'};

                end
            end
            
            dTable.task_id = taskIDs';

            type = contains(extractBefore(dTable.task_id,3),'q_');
            dTable.type = type;

            % --- Convert column types --- %
            dTable.task_id = categorical(dTable.task_id);
            dTable.user_id = categorical(dTable.user_id);


            % --- Seperate out the tasks from the questionnaires --- %

            tTable = dTable(dTable.type == 0,:);
            tTable.type = [];
            numT = height(tTable);
            qTable = dTable(dTable.type == 1,:);
            qTable.type = [];
            numQ = height(qTable);

            %%% --- Process the tasks and questionnaires seperately --- %%%
            

             for type = 0:1

                if type == 0

                    data = tTable;
                    vars = {...
                        'timeStamp';
                        'dynamicDifficulty';
                        'taskName';
                        'taskID';
                        'startTime';
                        'endTime';
                        'duration';
                        'version';
                        'SummaryScore';
                        'Scores';
                        'Rawdata';
                        'exited';
                        'timeOffScreen';
                        'focusLossCount';
                        'type';
                        'userID';
                    };


                else

                    data = qTable;

                    vars = {...
                        'timeStamp';
                        'startTime';
                        'endTime';
                        'duration';
                        'taskID';
                        'version';
                        'type';
                        'SummaryScore';
                        'Scores';
                        'RespObject';
                        'sequenceObj';
                        'userID';
                    };

                end


                numVar = length(vars);

                % Create a temporary cell array to contain the data variables
                % Run through and collect data from the data output
                tmpCell = cell(height(data),numVar);

                for t = 1:height(data)

                    thisData = data.data{t};

                    for v = 1:length(vars)

                        if isfield(thisData,vars{v})
                            tmpCell{t,v} = thisData.(vars{v});
                        end

                    end
                end

                % Convert the temporary cell array into a table
                taskDataTable = array2table(...
                    tmpCell,...
                    'VariableNames',vars...
                );

                % Combine the meta data table with the data output table
                data = [data,taskDataTable];
                data.data = [];

                % --- Run through each task and extract their scores --- %


                % Remove empty task IDs
                [~,empty] = util_getUniqueWithEmpty(data.taskID);
                data(empty,:) = []; 


                % Get all the taskIDs

                taskIDs = unique(data.taskID);
%                 allSurveys = union(allSurveys,taskIDs);
                numTasks = length(taskIDs);

                % Run through each task in turn
                for t=1:numTasks
                    if t==numTasks
                        fprintf('%s\n',taskIDs{t});
                    else
                        fprintf('%s, ',taskIDs{t});
                    end
                    

                    thisTask = taskIDs(t);

                    thisData = data(...
                        strcmp(data.taskID,string(thisTask)),...
                        :...
                    );
                
                    % Get rid of null start times
                    [~,empty] = util_getUniqueWithEmpty(thisData.startTime);
                    thisData(empty,:) = [];
                
                    numData = height(thisData);

                    % Get all unique scores in this chunk
                    scores = {};
                    for d=1:numData
                        if ~strcmp(thisData.Scores{d},'Not Available')
                            if isempty(thisData.Scores{d})
                                thisScores = fieldnames(struct());
                            else
                                thisScores = fieldnames(thisData.Scores{d});
                            end

                            scores = union(scores,thisScores);
                        end
                        
                    end

                    numScores = length(scores);

                    % Gather all the scores
                    tmpScores = cell(numData,numScores);
                    for d=1:numData
                        for s=1:numScores

                            if isfield(thisData.Scores{d},scores{s})
                                tmpScores{d,s} = ...
                                    thisData.Scores{d}.(scores{s});
                            end
                        end
                    end

                    % Convert to table
                    sTable = array2table(...
                        tmpScores,...
                        'VariableNames',scores...
                    );

                    % Combine with task table
                    thisData = [thisData,sTable];


                    %%% --- Process the RespObj for questionnaires --- %%%
                    % Check its a questionnaire
                    if type == 1

                        % Note down all possible options for a question 
                        % output
                        rVars = {...
                            'qNum';
                            'Q';
                            'R';
                            'S';
                            'on';
                            'off';
                            'RT';
                            'arch'
                        };


                        % Detect all the different questions in this
                        % questionnaire
                        
                        allQs = {};
                        allInsts = {};
                        keyObj = struct();
                        instNum = 1;
                        
                        qTables = cell([height(thisData),1]);
                        
                        % Run through all instances of this questionnaire
                        % in this chunk
                        for q=1:height(thisData)
                           
%                             fprintf('%d\n',q);k
                            
                            % Get the response object for this instance of
                            % the questionnaire
                            thisQ = thisData.RespObject{q};

                            % Check whether the question has been hashed or
                            % not
                            if isfield(thisQ,'hashType')
                                hashType = thisQ.hashType;
                                thisQ = rmfield(thisQ,'hashType');
                            else
                                hashType = 'null';
                            end

                            
                            
                            % Get the list of question numbers for this
                            % instance of the questionnaire

                            if isfield(thisQ,'Q0')
                                thisQs = fieldnames(thisQ);
                                qDataType = 'old';
                            elseif isfield(thisQ,'questions')
                                thisQs = fieldnames(thisQ.questions);
                                qDataType = 'new';
                            else
                                thisQs = fieldnames(thisQ);
                                qDataType = 'adaptive';
                            end

                            % Look through the question texts and replace
                            % any empty question texts

                            if strcmp(qDataType,'old')
                                q_fields = fieldnames(thisQ);
                                for qf=1:length(q_fields)
                                    if isempty(thisQ.(q_fields{qf}).Q)
                                        thisQ.(q_fields{qf}).Q = char(strcat(...
                                            'EMPTY_QUESTION_TEXT_',...
                                            string(qf-1)...
                                        ));
                                    end
                                end
                            end
                            
                            
                            % Make a table to collect the responses
                            thisQTable = table();
                            
                            for r=1:length(rVars)
                                thisQTable.(rVars{r}) = cell(...
                                    [length(thisQs),1]...
                                );
                            end
                            
                            
                            if isempty(thisQs)
                                thisData.RespObject{q}.instNum = 0;
                            else
                            
                                % Get the list of question texts for this
                                % instance of the questionnaire
                                thisQTs = {};
                                for p=1:length(thisQs)
                            
                                    if strcmp(qDataType,'old') || strcmp(qDataType,'adaptive')
                                        thisQTs{p} = thisQ.(thisQs{p}).Q;

                                        for r=1:length(rVars)

                                            if isfield(thisQ.(thisQs{p}),rVars{r})
                                                thisQTable.(rVars{r}){p} = ...
                                                    thisQ.(thisQs{p}).(rVars{r});
                                            end
                                        end

                                        thisQuestionText = thisQ.(thisQs{p}).Q;
%                                         if isempty(thisQuestionText)
%                                             thisQuestionText = strcat( ...
%                                                 'EMPTY_QUESTION_TEXT_', ...
%                                                 string(p) ...
%                                             );
%                                         end
                                    else
                                        if isa(thisQ.questions.(thisQs{p}),'logical')
                                            fprintf('Setting Question Text to ???logical??? as the question in the data is a logical\n');
                                            thisQTs{p} = '???logical???';
                                            thisQuestionText = '???logical???';
                                        else
                                            thisQTs{p} = thisQ.questions.(thisQs{p}){1};
                                            thisQuestionText = thisQ.questions.(thisQs{p}){1};
                                        end

                                        for r=1:length(rVars)

                                            if strcmp(rVars{r},'qNum')
                                                thisQTable.(rVars{r}){p} = double(string(strrep(thisQs{p},'x','')));
                                            elseif strcmp(rVars{r},'Q')
                                                thisQTable.(rVars{r}){p} = thisQuestionText;
                                            elseif strcmp(rVars{r},'R')
                                                
                                                thisAnswers = fieldnames(thisQ.answers.(thisQs{p}));
                                                if all(strcmp(thisAnswers,'FreeText'))
                                                    thisQTable.(rVars{r}){p} = thisQ.answers.(thisQs{p}).FreeText;
                                                else
                                                    for a=1:length(thisAnswers)
                                                        thisA_log = thisQ.answers.(thisQs{p}).(thisAnswers{a});
                                                        if thisA_log
                                                            thisQTable.(rVars{r}){p} = thisAnswers{a};
                                                            thisQTable.S{p} = a-1;
                                                        end
                                                    end
                                                end
                                                
                                            elseif strcmp(rVars{r},'RT')
                                                if isfield(thisQ,'rts')
                                                    thisQTable.(rVars{r}){p} = thisQ.rts.(thisQs{p});
                                                else
                                                    fprintf('No RTs in Q\n')
                                                    thisQTable.(rVars{r}){p} = NaN;
                                                end
                                            end


                                            
%                                             if isfield(thisQ.questions.(thisQs{p}),rVars{r})
%                                                 thisQTable.(rVars{r}){p} = ...
%                                                     thisQ.(thisQs{p}).(rVars{r});
%                                             end
                                        end

                                        
                                    end
                                    
                                    
                                    
                                    
                                    

                                    % Also start collecting all question 
                                    % texts from across all the instances
                                    allQs = union(...
                                        allQs,...
                                        thisQuestionText,...
                                        'stable'...
                                    );
                                end
                                thisQTable.Q = categorical(thisQTable.Q);

                                qTables{q} = thisQTable;

                                % Combine the question numbers and question
                                % texts for this instance of the 
                                % questionnaire
                                thisInst = [...
                                    categorical(thisQs),...
                                    categorical(thisQTs')...
                                ];

                                if isempty(allInsts)

                                    % Make a table of the question numbers 
                                    % and question texts and set this as 
                                    % the first version of the 
                                    % questionnaire
                                    qNum = thisInst(:,1);
                                    qText = thisInst(:,2);
                                    keyObj.version1 = table(...
                                        qNum,...
                                        qText...
                                    );

                                    thisData.RespObject{q}.instNum = 1;

                                    instNum = instNum + 1;
                                    allInsts{1} = thisInst;
                                else
                                    % For all previously indicated 
                                    % instances of this questionnaire
                                    for i=1:length(allInsts)

                                        % Get the previous instance
                                        prevInst = allInsts{i}(:,2);

                                        % Check if it has the same number 
                                        % of questions as this instance
                                        check1 = ...
                                            size(prevInst,1) == ...
                                            size(thisInst,1);

                                        % If it does 
                                        if check1
                                            % Check if the questions are 
                                            % the same
                                            check2 = ...
                                                all(...
                                                    prevInst == thisInst(:,2)...
                                                );
                                        else
                                            check2 = 0;
                                        end

                                        % If the previous instance is the same
                                        % as the present instance then set the
                                        % version number for this instance to
                                        % that of the previous instance
                                        if check1 && check2
                                            thisData.RespObject{q}.instNum = i;
                                            break;
                                        end

                                        if i==length(allInsts)
                                            allInsts{end+1} = thisInst;

                                            instString = strcat(...
                                                'version',...
                                                string(instNum)...
                                            );


                                            qNum = thisInst(:,1);
                                            qText = thisInst(:,2);
                                            keyObj.(instString) = table(...
                                                qNum,...
                                                qText...
                                            );
                                            thisData.RespObject{q}.instNum = ...
                                                instNum;

                                            instNum = instNum+1;
                                        end

                                    end
                                end
                            end
                        end
                        
                        
                        % Make a key
                        qText = categorical(unique(allQs,'stable'))';
                        idx = 1:length(qText);
                        idx = idx';
                        
                        
                        keyObj.key = table(...
                            qText,...
                            idx...
                        );


                        % Make strings for headers in data table
                        qStrings = string(...
                            repmat(rVars,[height(keyObj.key),1])...
                        );

                        qStrings2 = string(...
                            repmat(keyObj.key.idx,[1,length(rVars)])'...
                        );

                        qStrings = categorical(...
                            strcat(...
                                'Q',...
                                string(qStrings2(:)),...
                                '_',...
                                qStrings...
                            )...
                        );


                        % Make a cell array to collect the responses
                        tmpCell = cell(...
                            height(thisData),...
                            length(qStrings)...
                        );
                    
                        % Record which instantiation of the questionnaire
                        % this was
                        instOrder = nan([height(thisData),1]);
                        
                        % Collect the responses
                        for q=1:height(thisData)
%                             fprintf('%d\n',q);
                            % Get the qTable for this instance
                            thisQTable = qTables{q};

                            if isempty(thisQTable)
                                instOrder(q) = 0;
                            else
                                % Match the question text with the key
                                [lia,locb] = ismember(...
                                    thisQTable.Q,...
                                    keyObj.key.qText...
                                );
                                
                            
                                % Get the keyIdx strings
                                keyIdx = keyObj.key.idx(locb(lia));
                                keyIdx_block = repmat(...
                                    keyIdx,...
                                    [1,length(rVars)]...
                                );
                            
                                stringIdx = strcat(...
                                    'Q',...
                                    string(keyIdx_block),...
                                    '_'...
                                );
                            
                                rVars_block = repmat(rVars',[size(stringIdx,1),1]);
                                
                                qString_block = strcat(...
                                    stringIdx,...
                                    rVars_block...
                                );
                            
                                this_qStrings = categorical(qString_block(:));
                                thisQTable_cell = struct2table(...
                                    util_cellerise(...
                                        table2struct(...
                                            thisQTable,...
                                            'ToScalar',true...
                                        )...
                                    )...
                                );
                                
                                this_rVec = thisQTable_cell{:,:}(:);
                                
                                % Add the responses to the cell array
                                [lia,locb] = ismember(qStrings,this_qStrings);
                                tmpCell(q,lia) = this_rVec(locb(lia));
                                
                                
                                
                                % Get the response object for this instance
                                thisQ_obj = thisData.RespObject{q};
                                % Get the instNumber
                                instOrder(q) = thisQ_obj.instNum;
                            end

                            
                           

                        end

                        % Turn the array into a table
                        tmpTable = array2table(...
                            tmpCell,...
                            'VariableNames',...
                            string(qStrings)...
                        );
                    
                        tmpTable.qVersion = instOrder;

                        % Add to the data table
                        thisData = [thisData,tmpTable];
                        thisData.RespObject = [];

                    end




                    thisData.Scores = [];
                    thisStruct = table2struct(thisData,'ToScalar',true);

                    % --- Save out this process --- %
                    % Check if temp directory exists
                    filePath = fullfile(pathToMat,string(thisTask));
                    if exist(filePath,'dir') == 0
                        mkdir(filePath)
                    end

                    util_saveStructMin(...
                        thisStruct,...
                        fullfile(filePath,...
                            strcat(...
                                string(fileNum),...
                                '_',...
                                string(chunk),...
                                '.mat'...
                            )...
                         )...
                    );
                
                    if type == 1
                       
                        save(...
                            fullfile(filePath,...
                                strcat(...
                                    string(fileNum),...
                                    '_',...
                                    string(chunk),...
                                    '.mat'...
                                )...
                            ),...
                            '-append',...
                            'keyObj'...
                        );
                        
                        
                    end

                end
            end
        end

        % Log that a file has been completed
        progLog.processed(pathIdx) = 1;
        save(pathToProgLog,'progLog');
    end
end
clear theseRows tTable thisData metaData dTable deviceInfo qTable tmpCell

%% Combine the chunks into a single files


dirs = dir(pathToMat);
dirs = dirs(~contains({dirs.name},{'.','..'}),:);
dirs = dirs([dirs.isdir],:);


% Run through each survey
for t=1:height(dirs)
    fprintf('\n--- Combining %s\n',dirs(t).name);
    
    % If a file already exists from a previous processing run then plop it
    % in the directory for processing
    
    if exist(fullfile(dirs(t).folder,strcat(dirs(t).name,'.mat'))) == 2
       
        source = fullfile(...
            dirs(t).folder,...
            strcat(dirs(t).name,'.mat')...
        );
        
    
        dest = fullfile(...
            dirs(t).folder,...
            dirs(t).name,...
            strcat(dirs(t).name,'.mat')...
        );
    
    
        movefile(source,dest);
        
    end
    
    
    

    [paths] = util_getPaths(...
        fullfile(dirs(t).folder,dirs(t).name)...
    );


    numPaths = length(paths);
    
    thisTask = dirs(t).name;
    type = contains(thisTask,'q_');
    
    % Run through all the temporary files
    for p=1:numPaths
        fprintf('%d/%d - %s\n',p,numPaths,paths{p});
        
        
       
        if p == 1
            allData = load(paths{p});
            
            
            % Change the name of the date field to serverDate
            if isfield(allData,'date')
                allData.serverDate = allData.date;
                allData = rmfield(allData,'date');
            end
            
            allData = util_cellerise(allData);
            
            if isfield(allData,'keyObj')
               
                keyObj = allData.keyObj;
                fields = fieldnames(keyObj);
                numVs = sum(contains(fields,'version'));
                allData = rmfield(allData,'keyObj');
                
            end
            allTable = struct2table(allData);
        else
            thisData = load(paths{p});
            
            % Change the name of the date field to serverDate
            if isfield(thisData,'date')
                thisData.serverDate = thisData.date;
                thisData = rmfield(thisData,'date');
            end
            
            thisData = util_cellerise(thisData);
            if isfield(thisData,'keyObj')
                
                thisKeyObj = thisData.keyObj;
                thisData = rmfield(thisData,'keyObj');
                qVersion = [thisData.qVersion{:}];
                qVersionTmp = qVersion;
                
                fields = fieldnames(thisKeyObj);
                thisVs = sum(contains(fields,'version'));
                
                % Run through all the questionnaire versions in this
                % chunk of questionnaires
                for vv=1:thisVs
                    % Compare it against all the versions in the master key
                    for v=1:numVs
                        
                        
                        v1 = keyObj.(strcat('version',string(v)));
                        v2 = thisKeyObj.(strcat('version',string(vv)));
                        
                        check1 = height(v1) == height(v2);
                        
                        if check1
                            check2 = all(v1.qText == v2.qText);
                        else
                            check2 = 0;
                        end
                        
                        if check1 && check2
                            qVersionTmp(...
                                qVersion == vv...
                            ) = v;
                        
                            break;
                        else
                            if v == numVs
                                newInstString = strcat(...
                                    'version',...
                                    string(numVs+1)...
                                );

                                keyObj.(newInstString) = v2;

                                fields = fieldnames(keyObj);
                                numCurrentVs = sum(contains(fields,'version'));
                                numVs = numCurrentVs;
                                qVersionTmp(...
                                    qVersion == vv...
                                ) = numVs;
                            end
                        end
                    end
                end
                thisData.qVersion = num2cell(qVersionTmp)';
                
                % Now we need to reconcile the two actual keys and swap the
                % column names around so that they match across the two
                % chunks
                
                % Make a new key by combining the two old keys
                allKey = keyObj.key;
                thisKey = thisKeyObj.key;
                
                newKey = union(allKey(:,1),thisKey(:,1),'stable');
                newKey.idx = (1:height(newKey))';
                
                
                % Detect the idx for the allTable
                [lia,locb] = ismember(newKey.qText,allKey.qText);
                newKey.allKeyIdx(lia) = allKey.idx(locb(lia));
                
                 % Detect the idx for the thisTable
                [lia,locb] = ismember(newKey.qText,thisKey.qText);
                newKey.thisKeyIdx(lia) = thisKey.idx(locb(lia));
                
                
                % Replace the column headers in the two tables to reflect
                % the new key
                thisTable = struct2table(thisData);
                
                allVars = allTable.Properties.VariableNames;
                thisVars = thisTable.Properties.VariableNames;
                
                allVars_conv = allVars;
                thisVars_conv = thisVars;
                
                newString = strcat('Q',string(newKey.idx),'_');
                allString = strcat('Q',string(newKey.allKeyIdx),'_');
                thisString = strcat('Q',string(newKey.thisKeyIdx),'_');
                
                for i=1:height(newKey)
                   
                    % Detect the old value 
                    allIdx = contains(...
                        allVars,...
                        allString{i}...
                    );
                
                    thisIdx = contains(...
                        thisVars,...
                        thisString{i}...
                    );
                
                    % Replace it with the new value
                    allVars_conv(allIdx) = strrep(...
                        allVars(allIdx),...
                        allString{i},...
                        newString{i}...
                    );
                
                    thisVars_conv(thisIdx) = strrep(...
                        thisVars(thisIdx),...
                        thisString{i},...
                        newString{i}...
                    );
                    
                    
                end
                
                % Replace the variable names
                allTable.Properties.VariableNames = allVars_conv;
                thisTable.Properties.VariableNames = thisVars_conv;
                
                % Replace the key
                newKey.allKeyIdx = [];
                newKey.thisKeyIdx = [];
                keyObj.key = newKey;
                
            else
                thisTable = struct2table(thisData);
            end
            
            
            
            
            
            try 
                [allTable;thisTable];
            catch
                
                allVars = allTable.Properties.VariableNames;
                thisVars = thisTable.Properties.VariableNames;
                varDiffs1 = setdiff(...
                    allVars,...
                    thisVars...
                );
            
                varDiffs2 = setdiff(...
                    thisVars,...
                    allVars...
                );
            
                varDiffs = [varDiffs1,varDiffs2];
                % Add columns to allTable that are not in thisTable
                for k=1:length(varDiffs)
                   
                    if ~any(ismember(allVars,varDiffs(k)))
                        allTable.(varDiffs{k}) = repmat(...
                            {''},...
                            [height(allTable),1]...
                        );
                    elseif ~any(ismember(thisVars,varDiffs(k)))
                        thisTable.(varDiffs{k}) = repmat(...
                            {''},...
                            [height(thisTable),1]...
                        );
                    end
                end
            end
            
            try
                allTable = [allTable;thisTable];
            catch
               fprintf('Could not combine!');
            end
            
        end
        
        
    end
    
    % Convert all the variables to their minimal data state
    
    % Split out the os, device and browser cells 
    deviceInfo = allTable(:,{'os','device','browser'});
    allTable(:,{'os','device','browser'}) = [];

    % Log the variable names
    varNames = allTable.Properties.VariableNames;

    % Convert to minimal size data
    thisData_tmp = varfun(...
        @(x) util_conToMin(x,1),...
        allTable...
    );
    thisData_tmp.Properties.VariableNames = varNames;
    
    
    % Reintroduce the device info
    allTable = [thisData_tmp,deviceInfo];
    
    
    % Remove Duplicate Rows
    [~,idx] = unique(allTable(:,{'startTime','user_id'}),'rows');
    allTable = allTable(idx,:);
    
    % Order by startTime
    allTable = sortrows(allTable,'startTime');
    
    % Save the full struct
    allStruct = table2struct(allTable,'ToScalar',true);
    util_saveStructMin(...
        allStruct,...
        fullfile(pathToMat,strcat(string(thisTask),'.mat'))...
    );

    % If questionnaire, add back in the keyObj and try to convert the key
    if type == 1
        
        save(...
            fullfile(pathToMat,strcat(string(thisTask),'.mat')),...
            '-append',...
            'keyObj'...
        );
        
        if ~isempty(pathToQfiles)
           
            % Convert the IDs to question text
            cog_q_convertKey(...
                fullfile(...
                    dirs(t).folder,...
                    dirs(t).name...
                ),...
                fullfile(...
                    pathToQfiles,...
                    strcat(...
                        dirs(t).name,...
                        '.json'...
                    )...
                ),...
                1 ...
            );
        
            % Disambiguate the question text where necessary
            
            load(...
                fullfile(...
                    dirs(t).folder,...
                    dirs(t).name...
                ),...
                'keyObj'...
            );
        
            disamKey = cog_q_disambiguateKey(...
                keyObj.key...
            );
        
            keyObj.key = disamKey;
            
            save(...
                fullfile(pathToMat,strcat(string(thisTask),'.mat')),...
                '-append',...
                'keyObj'...
            );
        end
    end

    
    % Delete temporary files
    rmdir(fullfile(pathToMat,string(thisTask)),'s');
    
    

end