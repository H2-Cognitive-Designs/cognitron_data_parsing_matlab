function [rawDataArr,focusArr,corrupted,nonCompliance] = cog_sortRaw(data,task,justFocus,checkCompliance)
%  -- Sort Raw --
%  -- Date: 18-Mar-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Takes a raw data string and converts it to a matlab array
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  data :: Array of raw data strings
% 
%  task :: String denoting which task this came from
% 
%  justFocus :: Boolean that says just to extract the focus information
% 
%  checkCompliance :: Boolean that says to run code to check tasks for
%  compliance measures (eg really low RTs).
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%  rawDataArr :: Array of arrays of raw data
% 
%  focusArr :: Array of loss of focus values
%
%  corrupted :: Array of 0s and 1s indicating if a raw data file couldn't
%  be parsed
%  ------------------------------------------------------------------------

%% sort variables

Rawdata = data;

numRaw = size(Rawdata,1);
Rawdata = cellstr(Rawdata);
rawDataArr = cell(1,numRaw);
focusArr = cell(1,numRaw);

corrupted = zeros([numRaw,1]);

impRT = zeros(length(rawDataArr),1);
repResp = zeros(length(rawDataArr),1);
taskSpec = zeros(length(rawDataArr),1);
noResp = zeros(length(rawDataArr),1);

nonCompliance = table(...
    impRT,...
    repResp,...
    noResp,...
    taskSpec...
);
%% Loop through and process

% prog = 0;
% fprintf(1,'Computation Progress: %3d%%\n',prog);

for r=1:numRaw
%     fprintf('%d/%d\n',r,numRaw);
%     prog = ( 100*(r/numRaw) );
% 	fprintf(1,'\b\b\b\b%3.0f%%',prog);
   
    %Get this iteration of raw data
    thisRaw = Rawdata{r};
    
    % Work out if it is the legacy type (0)
    if length(regexp(thisRaw,' = ')) > 10
        type = 0;
    else
        type = 1;
    end
    
    if strcmp(task,'rs_CRT')
       
        type = 1;
        
    end
    
    %Split the string into rows
    thisRows = strsplit(thisRaw,'\\n')';

    if length(thisRows) == 1

        thisRows = strsplit(thisRaw,'\n')';
    end
    
    
    %Find the rows that pertain to the focus record
    fRecord = contains(thisRows,'Focus Record:');
    fRegained = contains(thisRows,'focus regained');
    fLost = contains(thisRows,'focus lost');
    
    focusRows = fRecord | fRegained | fLost;
    focusRows(1) = 1;
    focusRows(end) = 1;
    
    %Get rid of repeating regained rows
    rReps = strfind(fRegained',[1,1]);
    thisRows(rReps) = [];
    
    %Find the rows that pertain to the focus record
    fRecord = contains(thisRows,'Focus Record:');
    fRegained = contains(thisRows,'focus regained');
    fLost = contains(thisRows,'focus lost');
    
    focusRows = fRecord | fRegained | fLost;
    focusRows(1) = 1;
    focusRows(end) = 1;
    
    %Get rid of repeating lost rows
    lReps = strfind(fLost',[1,1]);
    thisRows(lReps) = [];
    
    %Find the rows that pertain to the focus record
    fRecord = contains(thisRows,'Focus Record:');
    fRegained = contains(thisRows,'focus regained');
    fLost = contains(thisRows,'focus lost');
    
    focusRows = fRecord | fRegained | fLost;
    focusRows(1) = 1;
    focusRows(end) = 1;
    
%     rCheck = fRegained(focusRows);
%     lCheck = fLost(focusRows);

%     rCheck = rCheck(3:end-1);
%     lCheck = lCheck(3:end-1);
%     
%     rReps = strfind(rCheck',[1,1]);
%     lReps = strfind(lCheck',[1,1]);
%     
%     fRegained_nums(rReps) = [];
%     fLost_nums(lReps) = [];
    
    %Collect these numbers
    fRegained_rows = thisRows(fRegained);
    fLost_rows = thisRows(fLost);
    
    
    
    fRegained_nums = double(...
        string(...
            strrep(...
                fRegained_rows,...
                'focus regained at ',...
                ''...
            )...
        )...
    );


%     tt = sum(tril(abs(fRegained_nums - fRegained_nums') < 100,-1),2);
%     fRegained_nums = fRegained_nums(~tt);
    
    fLost_nums = double(...
        string(...
            strrep(...
                fLost_rows,...
                'focus lost at ',...
                ''...
            )...
        )...
    );

    

    

    totalFocus = max(length(fRegained_nums),length(fLost_nums));
    
    thisFocusArr = NaN(totalFocus,2);

    if ~isempty(fRegained_nums)
        thisFocusArr(1:length(fRegained_nums),1) = fRegained_nums;
    end
    
    if ~isempty(fLost_nums)
        thisFocusArr(1:length(fLost_nums),2) = fLost_nums;
    end
    
    if justFocus == 0
%     focusRegainedArr = [focusRegainedArr;fRegained_nums];
%     focusLostArr = [focusLostArr;fLost_nums];
    
        %Remove the focus rows
        thisRows = thisRows(~focusRows);

        % Sometimes we need to remove the first row which
        % contains the composite scores for some reason
        if contains(task,'rs_SART') || ...
           contains(task,'pt_TOL') || ...
           contains(task,'pt_manipulations2D') || ...
           contains(task,'v_p_CFOG_TOL') || ...
           contains(task,'v_p_CFOG_manipulations2D') || ...
           contains(task,'v_p_CFOG_switchingStroop') || ...
           strcmp(task,'v_p_switchingStroop') || ...
           strcmp(task,'v_p_blocks')
            
            thisRows = thisRows(2:end);
            
        end

        if contains(task,'v_colourFrame')
            if ~contains(thisRows{1},'correctResponse')
                thisRows{1} = strrep(thisRows{1},'t\tr','t	r');
                thisRows{1} = strrep( ...
                    thisRows{1}, ...
                    'score	correct	tcol', ...
                    'score	correctResponse	tcol' ...
                );
                thisRows{1} = strrep( ...
                    thisRows{1}, ...
                    'trials	correct	nincorrect', ...
                    'trials	ncorrect	nincorrect' ...
                );
            end
        end

        % Fix for the pt_prospectiveMemoryWords having category as a header
        % but not in the actual data

        if strcmp(task,'pt_prospectiveMemoryWords_1_immediate')
            thisRows(1) = {strrep(thisRows{1},'	category','')};
        end

        % v_p_blocks is pretty messed up so lets try to rectify here
        prev_main_row_ind = 1;
        if strcmp(task,'v_p_blocks')

            for rr=1:length(thisRows)

                

                if contains(thisRows{rr},"crateClicked")
                    this_crate_row = thisRows{rr};
                    crate_clicked = strrep(this_crate_row,"crateClicked = ","");
                    
                    if prev_main_row_ind == 1
                        thisRows{rr-prev_main_row_ind} = strcat(thisRows{rr-prev_main_row_ind},"	","cratesClicked = ",crate_clicked);
                    else
                        thisRows{rr-prev_main_row_ind} = strcat(thisRows{rr-prev_main_row_ind},",",crate_clicked);
                    end

                    prev_main_row_ind = prev_main_row_ind + 1;

                else

                    prev_main_row_ind = 1;

                end

            end

            thisRows(cellfun(@(x) contains(x,"crateClicked"),thisRows)) = [];


        end
        

        %Social Learning is especially fucked so we have to massage it
        if strcmp(task,'rs_socialLearning1')
            thisRows = strrep(...
                thisRows,...
                ':on',...
                ''...
            );
            thisRows = strrep(...
                thisRows,...
                ':off',...
                ''...
            );
            thisRows = strrep(...
                thisRows,...
                ':score',...
                ''...
            );
            thisRows = strrep(...
                thisRows,...
                'truecorrect',...
                'true'...
            );
            thisRows = strrep(...
                thisRows,...
                'falsecorrect',...
                'false'...
            );
            thisRows = strrep(...
                thisRows,...
                ':correct',...
                ''...
            );
            thisRows = strrep(...
                thisRows,...
                'trialcount',...
                ''...
            );
        end


        numRows = size(thisRows,1);

        if numRows>0 && ~isempty(thisRows)

            % Split the columns up
            for i=1:size(thisRows,1)
%                 if isempty(thisRows)
%                     tt=5;
%                 end
                

                tmpRow = strsplit(thisRows{i},'\\t');
                

                if length(tmpRow) == 1
                    % tmpRow = strsplit(thisRows{i},'\t');
                    tmpRow = regexp(thisRows{i},'\t','split');
                end

                if contains(task,'v_colourFrame') && length(tmpRow) == 16
                    tmpRow = [tmpRow(1:8),{'???'},tmpRow(9:end)];
                end


                    
                thisRows{i} = tmpRow;
            end

            % Get rid of trailing tab on spotter raw data

            if contains(task,'v_p_spotter')
                thisRows{1}(12) = [];
            end
            
            if strcmp(task,'BI_forager') || strcmp(task,'v_forager')
               if length(thisRows{1}) == 14
                   
                   thisRows{1}(14) = [];
                   
               end
                
            elseif strcmp(task,'BI_leadBalloon')
                if length(thisRows{1}) == 13
                   
                   thisRows{1}(13) = [];
                   
               end
            elseif strcmp(task,'BI_spotter')
                if length(thisRows{1}) == 12
                   
                   thisRows{1}(12) = [];
                   
               end
            elseif strcmp(task,'BI_ticTacNo')
                if length(thisRows{1}) == 16
                   
                   thisRows{1}(16) = [];
                   
               end
            elseif strcmp(task,'BI_triangles')
                if length(thisRows{1}) == 15
                   
                   thisRows{1}(15) = [];
                   
               end
            elseif strcmp(task,'rs_switchingStroop')
                for rr=1:length(thisRows)
                    current_row = thisRows{rr};
                    if isempty(current_row{end})
                        current_row = current_row(1:end-1);
                        thisRows{rr} = current_row;
                    end
                end
            end

            % More social learning massaging
            if strcmp(task,'rs_socialLearning1')


                for l=1:length(thisRows)

                    if l==1
                        thisRows{l} = {...
                            'score',...
                            'correct',...
                            'timeRespEnabled',...ƒ
                            'timeRespMade',...
                            'RT',...
                            'correctAnswer',...
                            'trialcount',...
                            'fvect',...
                            'svect'...
                        };
                    else
                        tmpRow = cell([1,9]);

                        tmpRow{1} = thisRows{l}(1);
                        tmpRow{2} = thisRows{l}(2);
                        tmpRow{3} = thisRows{l}(3);
                        tmpRow{4} = thisRows{l}(4);
                        tmpRow{5} = thisRows{l}(5);
                        tmpRow{6} = thisRows{l}(6);
                        tmpRow{7} = thisRows{l}(7);

                        fvectCol = find(contains(thisRows{l},':fvect'));
                        svectCol = find(contains(thisRows{l},':svect'));

                        fvect = thisRows{l}(8:fvectCol);
                        tmpRow{8} = strjoin(strrep(fvect,':fvect',''));


                        svect = thisRows{l}(fvectCol+1:svectCol);
                        tmpRow{9} = strjoin(strrep(svect,':svect',''));

                        thisRows{l} = tmpRow;

                    end
                end
                % Make it skip the next processing step
                type=2;

            elseif strcmp(task,'rs_cardPairs') || strcmp(task,'ti_cardPairs')
                  if length(thisRows{1}) == 11

                      thisRows{1}(11) = [];

                  end

            elseif strcmp(task,'rs_pictureCompletion')

                for l=1:length(thisRows)
                    if length(thisRows{l}) == 14

                        tmp = thisRows{l}(1:7);
                        tmp2 = thisRows{l}(8:end);

                        insert = {'NaN'};

                        newRow = [tmp,insert,tmp2];

                        thisRows{l} = newRow;

                    end

                end




            end


            % Prepare the legacy type for processing
            if type==0

                 % Check all rows have the same size
                sizeMat = cellfun(@(x) size(x,2),thisRows);


                % This code takes the intermittent level row in the slider task and
                % conglomerates it into the rest of the rows
                if strcmp(task,'rs_slider')
                    levelRows = cellfun(...
                        @(x) size(x,2)==10,...
                        thisRows...
                        );

                    for k=1:length(thisRows)

                        if levelRows(k)
                            addOn = thisRows{k};
                        else
                            thisRows{k} = [addOn,thisRows{k}];
                        end


                    end

                    thisRows(levelRows) = [];

                elseif strcmp(task,'Trail Making')

                    thisRows(sizeMat ~= 7) = [];

                elseif strcmp(task,'v_p_CFOG_switchingStroop') || ...
                        strcmp(task,'v_p_switchingStroop')

                    for row=1:length(thisRows)
 
                        if length(thisRows{row}) == 1
                            block = char(string(row-1));
                        else
                            thisRows{row} = [{['Block = ',block]},thisRows{row}];
                        end

                    end

                    thisRows(sizeMat == 1) = [];

              
                elseif strcmp(task,'i4i_emotionStroop')

                    thisRows(1) = [];

                    for row=1:length(thisRows)
 
                        if length(thisRows{row}) == 1
                            block = string(row-1);
                        else
                            thisRows{row} = [{strcat('Block = ',block)},thisRows{row}];
                        end

                    end

                    thisRows(sizeMat(2:end) == 1) = [];

                elseif strcmp(task,'Bees')
    
                    for i=1:length(thisRows)

                        this_row = thisRows{i};

                        if length(this_row) == 10
                            conc_rows = this_row;
                        else
                            thisRows{i} = cat(2,thisRows{i},conc_rows);
                        end
                    end

                    thisRows(sizeMat == 10) = [];

                    
                end


                % Get headers
                sizeMat = cellfun(@(x) size(x,2),thisRows);
                if sum(abs(diff(sizeMat)))==0
                    topRow = thisRows{1};
                    headers = {};

                    for i=1:size(topRow,2)
                        thisCell = topRow{i};
                        theseParts = strsplit(thisCell,' = ');
                        headers{i} = theseParts{1};

                        equalString = strcat(headers{i}," = ");

                        thisRows = cellfun(...
                            @(x) strrep(string(x),equalString,''),...
                            thisRows,...
                            'UniformOutput',...
                            false...
                        );

                    end
                else
                    error('Not all rows are the same size!');
                end

                thisRows = cellfun(...
                    @(x) cellstr(x),...
                    thisRows,...
                    'UniformOutput',...
                    false...
                );

                thisRows = [{headers};thisRows];


            elseif type==1
                % Typo in the raw data of the four towers tasks misaligned the
                % headers
                if strcmp(task,'DRI_fourTowers')
                    
                    headerRow = thisRows{1};
                    
                    if any(strcmp(headerRow,'correctlocation'))

                        headerRow = strrep(...
                            headerRow,...
                            'correct',...
                            sprintf('ncorrect')...
                        );

                        faultyCell = find(strcmp(headerRow,'ncorrectlocation'));
                        headerRow_b = headerRow(1:faultyCell-1);
                        headerRow_a = headerRow(faultyCell+1:end);

                        headerRow = [...
                            headerRow_b,...
                            {'correct'},...
                            {'location'},...
                            headerRow_a...
                        ];


                        thisRows{1} = strrep(...
                            thisRows{1},...
                            'ncorrectlocation',...
                            sprintf('correct\tlocation')...
                        );

                        thisRows{1} = headerRow;
                    else
                        
                        thisRows{1} = strrep(...
                            thisRows{1},...
                            'correctResponse',...
                            'correct'...
                        );
                        
                    end

                end


                sizeMat = cellfun(@(x) size(x,2),thisRows);
                if sum(abs(diff(sizeMat)))==0

                else
                    warning('Not all rows the same size');
                end

            end

            % Standardise header names for RT and correct
            if strcmp(task,'rs_contextTask')
                thisRows{1} = strrep(...
                    thisRows{1},...
                    'Time spent emotion',...
                    sprintf('RT')...
                );
            elseif contains(task,'rs_mallasMemoryShort')

                thisRows{1} = strrep(...
                    thisRows{1},...
                    'nameRT',...
                    sprintf('RT')...
                );

                thisRows{1} = [thisRows{1},'correct'];

                for x=2:size(thisRows,1)

                    if strcmp(thisRows{x}{2},thisRows{x}{5})
                        thisRows{x}{end+1} = 'true';
                    else
                        thisRows{x}{end+1} = 'false';
                    end

                end

            elseif strcmp(task,'rs_mindInTheEyes')
                thisRows{1} = [thisRows{1},'correct'];

                for x=2:size(thisRows,1)

                    thisCorrect = strcmp(thisRows{x}(2),thisRows{x}(3));
                    if thisCorrect
                        thisRows{x}{end+1} = 'true';
                    else
                        thisRows{x}{end+1} = 'false';
                    end

                end

            elseif strcmp(task,'rs_slider')

                thisRows{1} = strrep(...
                    thisRows{1},...
                    'completed?',...
                    sprintf('correct')...
                );

                thisRows{1} = strrep(...
                    thisRows{1},...
                    'RT',...
                    sprintf('RT_trial')...
                );

                thisRows{1} = strrep(...
                    thisRows{1},...
                    'timeTaken',...
                    sprintf('RT')...
                );

            elseif strcmp(task,'rs_verbalAnalogies')
                thisRows{1} = strrep(...
                    thisRows{1},...
                    'Accuracy',...
                    sprintf('correct')...
                );
            elseif strcmp(task,'rs_CRT')
                for x=1:length(thisRows)
                    thisRow = thisRows{x};

                    if contains(thisRow{1},'stimNumber = ')

                        level = thisRow{1};
                        level = strsplit(level,' = ');
                        level = level{2};

                        jitter = 'NaN';

                        side = strsplit(thisRow{2},' = ');
                        side = side{2};

                        sideClicked = 'NaN';
                        correct = 'TIMEOUT';
                        missClick = '0';
                        trm = 'NaN';

                        if length(thisRow) > 3
                            tre = thisRow{10};
                        else
                            tre = 'NaN';
                        end

                        rt = 'NaN';

                        newRow = {...
                            level,...
                            jitter,...
                            side,...
                            sideClicked,...
                            correct,...
                            missClick,...
                            trm,...
                            tre,...
                            rt...
                        };

                    thisRows{x} = newRow;

                    end

                end
            elseif strcmp(task,'rs_pictureCompletion')

                for l=1:length(thisRows)

                    thisRow = thisRows{l};

                    if l == 1

                        thisRow{end+1} = 'RT';

                    else

                        thisRow{end+1} = ...
                            double(string(thisRow{14})) - ...
                            double(string(thisRow{10}));

                    end

                    thisRows{l} = thisRow;

                end

            elseif strcmp(task,'rs_switchingStroop')

                if (length(thisRows{1}) == 12 && length(thisRows{2}) == 16)

                    thisRows{1} = cat(2,thisRows{1},{'ltext','lfill','rtext','rfill'});

                end
                   

            end


            % Make a holder for the array
            thisRawArr = cell([length(thisRows),size(thisRows{1},2)]);
            for i=1:size(thisRawArr,1)
                if length(thisRawArr(i,:)) == length(thisRows{i})
                    thisRawArr(i,:) = thisRows{i};
                else
                    warning('Adding corrupted row');
                    corrupCell = cell([1,length(thisRawArr(i,:))]);

                    for k=1:length(corrupCell)
                        corrupCell{k} = 'Corrupted';
                    end
                    thisRawArr(i,:) = corrupCell;
                    corrupted(r) = 1;
                end
            end
        else

            thisRawArr = {};

        end
        
        % Problem with rs_verbalAnalogies where raw data on the end is 
    
        if contains(task,'rs_SART') && type==0
            stim = double(string(thisRawArr(2:end,2)));
            targ = double(string(thisRawArr(2:end,3)));
            click = string(thisRawArr(2:end,4));
            
            clickLog = nan(size(click));
            clickLog(strcmp(click,'true')) = 1;
            clickLog(strcmp(click,'false')) = 0;
            
            targTrial = stim == targ;
            
            correct = nan(size(targTrial));            
            correct(targTrial == clickLog) = 0;
            correct(targTrial ~= clickLog) = 1;
            
            correctString = ['correct';cellstr(string(correct))];
            
            thisRawArr = [...
                thisRawArr(:,1:4),...
                correctString,...
                thisRawArr(:,5:end)...
            ];
            
        end

        % Latin square task has two headers the same name, change the second 
        % one to indicate it is the colour
        if contains(task,'rs_latinSquare')

            thisRawArr{1,13} = 'targetarray_colour';

        end

    
        % Pop this raw data array into the contianer for all of them
        rawDataArr{r} = thisRawArr;
    end
    focusArr{r} = thisFocusArr;
end


%% Check the compliance
if checkCompliance
   
  
    
    % Check if the same response key was pressed loads of times

    responseKey = {...
        'DRI_fourTowers','button';
        'rs_CRT','Side Clicked';
        'rs_PAL','response';
        'rs_TOL','response';                 
        'rs_contextTask','responseEmotion';               
        'rs_emotionDiscrim','response';                       
        'rs_emotionalControl','response';                     
        'rs_featureMatching','respondedID';                      
        'rs_manipulations2D','Response';                      
        'rs_oddOneOut','response';
        'rs_pictureCompletion','Button Selected';                    
        'rs_prospectiveMemoryObjects_1_delayed','responseGridIdx';   
        'rs_prospectiveMemoryObjects_1_immediate','responseGridIdx'; 
        'rs_prospectiveMemoryWords_1_delayed',{{'target','correct'},'logical(double(string($1))) & strcmp(string($2),"true")'};     
        'rs_prospectiveMemoryWords_1_immediate',{{'target','correct'},'logical(double(string($1))) & strcmp(string($2),"true")'};   
        'rs_prospectiveMemoryWords_2_delayed',{{'target','correct'},'logical(double(string($1))) & strcmp(string($2),"true")'};     
        'rs_prospectiveMemoryWords_2_immediate',{{'target','correct'},'logical(double(string($1))) & strcmp(string($2),"true")'};   
        'rs_switchingStroop','response';                    
        'rs_verbalAnalogies',{{'correctAnswer','correct'},'strcmp(string($1),"true") & strcmp(string($2),"true")'};                      
        'rs_verbalReasoning','response';    
    };




    % set default reaction time threshold
    rtThresh = 100;
    shortRtTask = 100;
    longRtTask = 400;
    
    % Task specific checks
    if strcmp(task,'rs_motorControl')
        % Check to see if the person just clicked the same spot on the
        % screen over and over
        
        

        for r=1:length(rawDataArr)
            
            if isempty(rawDataArr{r})
                nonCompliance.repResp(r) = nonCompliance.repResp(r) + 1;
            else
                responseX_col = strcmp(rawDataArr{r}(1,:),'response X');
                responseY_col = strcmp(rawDataArr{r}(1,:),'response Y');

                thisRaw = rawDataArr{r};
                thisRX = double(string(thisRaw(2:end,responseX_col)));
                thisRY = double(string(thisRaw(2:end,responseY_col)));

                stdX = std(thisRX);
                stdY = std(thisRY);

                ttX = std(double(string(thisRaw(2:end,2))));
                ttY = std(double(string(thisRaw(2:end,3))));

                if stdX < (ttX/2) || stdY < (ttY/2)
                    nonCompliance.repResp(r) = nonCompliance.repResp(r) + 1;
                end
            end
            
            
        end
    elseif strcmp(task,'rs_blocks')

        probeStringCol = strcmp(rawDataArr{1}(1,:),'probe');
        blockClickedCol = strcmp(rawDataArr{1}(1,:),'Block Clicked');

        for r=1:length(rawDataArr)

            thisProbe = rawDataArr{r}(2:end,probeStringCol);
            thisClicked = rawDataArr{r}(2:end,blockClickedCol);

            thisProbeMat = str2num(cell2mat(thisProbe)); %#ok<ST2NM>

            thisClickedMat = double(string(thisClicked));

            thisBlockMat = thisProbeMat == thisClickedMat;

            sus = sum(thisBlockMat,1) ./ size(thisBlockMat,1);

            if max(sus) > 0.8
%                 rawDataArr{r};
%                 imagesc(thisBlockMat);
%                 fprintf('GOTCHA\n');

                nonCompliance.repResp(r) = nonCompliance.repResp(r) + 1;

            end
        end


    elseif strcmp(task,'rs_digitSpan_short')

        targetCol = strcmp(rawDataArr{1}(1,:),'Target');
        responseCol = strcmp(rawDataArr{1}(1,:),'Response');

        for r=1:length(rawDataArr)

            thisRaw = rawDataArr{r};

            target = thisRaw(2:end,targetCol);
            response = thisRaw(2:end,responseCol);

            target = cellfun(...
                @(x) x(2:end),...
                target,...
                'UniformOutput', false...
            );

            response = cellfun(...
                @(x) x(2:end),...
                response,...
                'UniformOutput',false...
            );

            target = cellfun(...
                @(x) double(string(strsplit(x,'_'))),...
                target,...
                'UniformOutput',false...
            );

            response = cellfun(...
                @(x) double(string(strsplit(x,'_'))),...
                response,...
                'UniformOutput',false...
            );

            respLength = cellfun(...
                @(x) length(x),...
                response...
            );

            responseMat = nan([length(response),max(respLength)]);
            targetMat = nan([length(target),max(respLength)]);

            for t=1:size(target,1)

                thisResp = response{t};
                responseMat(t,1:respLength(t)) = thisResp;

                thisTarg = target{t};
                targetMat(t,1:respLength(t)) = thisTarg;


            end

             sameCheck = abs(diff(responseMat,1));
             sameCheckLog = nansum(sameCheck,2) == 0;

             if any(sameCheckLog)

                 if sum(sameCheckLog) == 1

                     offendingTarget = targetMat(...
                         find(sameCheckLog)+1,...
                         ~isnan(targetMat(find(sameCheckLog)+1,:))...
                     );

                    offendingResponse = responseMat(...
                         find(sameCheckLog)+1,...
                         ~isnan(responseMat(find(sameCheckLog)+1,:))...
                     );

                 else



                 end




                 if sum(sameCheckLog) > 2 %|| any(offendingTarget ~= offendingResponse)

                     rawDataArr{r};

                     fprintf('GOTACH\n');

                 end

             end


        end


    elseif strcmp(task,'rs_targetDetection')
        % Check if the participant was stabbing wildly on the screen
        % getting many more false alarms than correct responses
        for r=1:length(rawDataArr)
            
            
            thisDataArr = rawDataArr{r};
            
            if isempty(thisDataArr)
                nonCompliance.taskSpec(r) = nonCompliance.taskSpec(r) + 1;
            else
                correctCol = strcmp(thisDataArr(1,:),'correct');

                correct = thisDataArr(2:end,correctCol);
                correct = strcmp(correct,'true');

                acc = sum(correct)/length(correct);
                if acc < 0.5
                    nonCompliance.taskSpec(r) = nonCompliance.taskSpec(r) + 1;
                end
            end
            
            
        end
    end



    if strcmp(task,'rs_verbalAnalogies')
        rtThresh = 500;
    elseif strcmp(task,'DRI_fourTowers')
        rtThresh = 1000;                         
    elseif strcmp(task,'rs_CRT')
        rtThresh = shortRtTask;                                 
    elseif strcmp(task,'rs_SRT')
        rtThresh = shortRtTask;                                 
    elseif strcmp(task,'rs_TOL')
        rtThresh = 1000;                                 
    elseif strcmp(task,'rs_manipulations2D')
        rtThresh = 700;                     
    elseif strcmp(task,'rs_motorControl')
        rtThresh = 225;                        
    elseif strcmp(task,'rs_prospectiveMemoryObjects_1_delayed')
        rtThresh = 500;
    elseif strcmp(task,'rs_prospectiveMemoryObjects_1_immediate')
        rtThresh = 500;
    elseif strcmp(task,'rs_spatialSpan')
        rtThresh = longRtTask;                         
    elseif strcmp(task,'rs_targetDetection')
        rtThresh = 440;   
    elseif strcmp(task,'BBC_wordDefinitions')
        rtThresh = longRtTask;
    end

    

    for r=1:length(rawDataArr)

        % --- Check for no responses --- %
          
        if size(rawDataArr{r},1) > 1
            nonCompliance.noResp(r) = 0;


            % --- Check for fast reaction times --- %
            thisRaw = rawDataArr{r};
            rtCol = strcmp(thisRaw(1,:),'RT');
            thisRTs = double(string(thisRaw(2:end,rtCol)));
            thisRTs = thisRTs(~isnan(thisRTs));

            impossible = thisRTs < rtThresh;
            impossibleProp = sum(impossible)/length(thisRTs);

            if impossibleProp > 0.4
                nonCompliance.impRT(r) = nonCompliance.impRT(r) + 1;
            end

            % --- Check for repetitive responses --- %
            % Get name of column for responses
            taskIdx = strcmp(responseKey(:,1),task);


            % extract it from raw data
            if any(taskIdx)

                respColHeader = responseKey{taskIdx,2};
                if isa(respColHeader,'cell')

                    variables = respColHeader{1};
                    formula = respColHeader{2};

                    varStruct = struct();

                    for v=1:length(variables)
                        vHandle = strcat('v',string(v));
                        fHandle = strcat('$',string(v));

                        thisColIdx = strcmp(rawDataArr{r}(1,:),variables{v});
        %                 varStruct.(vHandle) = double(string(rawDataArr{r}(2:end,colIdx)));
        %                 if all(isnan(varStruct.(vHandle)))
        %                     varStruct.(vHandle) = grp2idx(...
        %                         categorical(...
        %                             string(rawDataArr{r}(2:end,colIdx))...
        %                         )...
        %                     );
        %                 end
                        varStruct.(vHandle) = rawDataArr{r}(2:end,thisColIdx);
                        formula = strrep(...
                            formula,...
                            fHandle,...
                            strcat('varStruct.',vHandle)...
                        );

                    end

                    responseData = eval(formula);

                else

                    colIdx = strcmp(rawDataArr{r}(1,:),respColHeader);
                    responseData = double(string(rawDataArr{r}(2:end,colIdx)));
                    if all(isnan(responseData))
                        responseData = grp2idx(...
                            categorical(...
                                string(rawDataArr{r}(2:end,colIdx))...
                            )...
                        );
                    end


                end

        %         responseDiff = diff(responseData);
                responseTab = tabulate(responseData);

                if isa(responseTab,'cell')
                    maxPerc = max([responseTab{:,3}]);
                else
                    maxPerc = max(responseTab(:,3));
                end


                if maxPerc > 80

                    nonCompliance.repResp(r) = nonCompliance.repResp(r) + 1;

                end

        %         if (sum(responseDiff == 0)/length(responseDiff)) > 0.8
        % 
        %             rawDataArr{r};
        %             fprintf('GOTCHA\n');
        %         end

            end
        else
            nonCompliance.noResp(r) = 1;
        end
    end
end


end