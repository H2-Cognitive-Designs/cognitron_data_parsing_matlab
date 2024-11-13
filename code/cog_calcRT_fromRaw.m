function [] = cog_calcRT_fromRaw(pathToFiles)
%  -- Calculate RT measures from raw data --
%  -- Date: 09-Mar-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Takes raw data from a given file and attempts to calculate the median
%  reaction time from that raw data
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  pathToFiles :: Array of paths to mat files
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%   :: 
% 
%  ------------------------------------------------------------------------

numFiles = length(pathToFiles);


for i=1:numFiles
   
    fprintf('Processing: %d - %s\n',i,pathToFiles{i});
    [~,task] = fileparts(pathToFiles{i});
    
    data = load(pathToFiles{i},'RawdataArr');
    
    if isfield(data,'RawdataArr')
        
    else
        load(pathToFiles{i},'Rawdata');
        numData = length(Rawdata);
        
        RT_median = zeros([numData,1]);
        RT_mean = zeros([numData,1]);
        RT_std = zeros([numData,1]);
        
        RT_median_cor = zeros([numData,1]);
        RT_mean_cor = zeros([numData,1]);
        RT_std_cor = zeros([numData,1]);

        RT_median_incor = zeros([numData,1]);
        RT_mean_incor = zeros([numData,1]);
        RT_std_incor = zeros([numData,1]);
        
        
        RT_median(RT_median==0) = NaN;
        RT_mean(RT_mean==0) = NaN;
        RT_std(RT_std==0) = NaN;

        RT_median_cor(RT_median_cor==0) = NaN;
        RT_mean_cor(RT_mean_cor==0) = NaN;
        RT_std_cor(RT_std_cor==0) = NaN;

        RT_median_incor(RT_median_incor==0) = NaN;
        RT_mean_incor(RT_mean_incor==0) = NaN;
        RT_std_incor(RT_std_incor==0) = NaN;
        
%         acc_calc = nan([numData,1]);
        
        focusArrAll = cell([numData,1]);
        
        
%         wb = waitbar(0,task);
        for j=1:numData
            if mod(j,5000) == 0
                fprintf('%d/%d\n',j,numData);
            end
%             waitbar(j/numData);
            [dataArr,focusArr,corrupted,nComp] = cog_sortRaw(...
                Rawdata(j),...
                task,...
                0,...
                1 ...
            );
            
            if j==1
               
                nCompAll = nComp;
                
            else
                
                nCompAll = [nCompAll;nComp];
                
            end
        
            focusArrAll(j) = focusArr;
            
            if isempty(dataArr{1}) || corrupted(1)
                fprintf('No Raw Data or Raw data corrupted!\n');
            else
                dataTab = cell2table(...
                    dataArr{1}(2:end,:),...
                    'VariableNames',...
                    dataArr{1}(1,:)...
                );


                if strcmp(task,'BI_forager')
                    rtCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'stim_on_response_offset'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct_response'...
                    );
                    
                elseif any(contains(task,'CTET'))

                    dataTab(strcmp(dataTab.VAS,'VAS'),:) = [];

                    should_respond = strcmp( ...
                        dataTab.StimOnClick, ...
                        'true' ...
                    );

                    did_respond = strcmp( ...
                        dataTab.NoResponse, ...
                        'false' ...
                    );

                    correct_response = should_respond & did_respond;
                    incorrect_response = ~should_respond & did_respond;

                    dataTab.correct_col = nan([height(dataTab),1]);
                    dataTab.correct_col(correct_response == 1) = 1;
                    dataTab.correct_col(incorrect_response == 1) = 0;

                    rtCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct_col'...
                    );
                    
                elseif any(contains(task,'spotter'))
                    rtCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'reaction_time'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct'...
                    );
                    
                elseif strcmp(task,'BI_triangles')
                    rtCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct_response'...
                    );
                    
                elseif strcmp(task,'bi_CGT')
                    rtCol = contains(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'Correct'...
                    );

                elseif strcmp(task,'v_verbalAnalogies_balanced_short')
                    rtCol = contains(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'Accuracy'...
                    );
                    
                
                elseif strcmp(task,'pt_TOL')
                    rtCol = contains(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    dataTab.correct = [
                        double(string(dataTab.Score{1}))
                        diff(double(string(dataTab.Score)))
                    ];

                    

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct'...
                    );
                    
                
                else
                    rtCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'RT'...
                    );

                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'correct'...
                    );

                end
                
            
                if strcmp(task,'rs_SRT') || strcmp(task,'v_SRT')
                    correctCol = strcmp(...
                        dataTab.Properties.VariableNames,...
                        'Time Out'...
                    );
                end

                if any(rtCol)
                    rt = double(string(dataTab{:,rtCol}));
                    if any(isnan(rt))
                        numNans = sum(isnan(rt));
    %                     fprintf('-- %d detected\n',numNans);
                    end

                else
                    fprintf('No RT column found\n');
                end
                
                

                if any(correctCol)
                    
                    if strcmp(task,'rs_SRT') || strcmp(task,'v_SRT')
                        cor = string(~double(string(dataTab{:,4})));
                    else
                        cor = string(dataTab{:,correctCol});
                    end
                    
                    
                    if strcmp(task,'rs_cardPairs')
                   
                        na = strcmp(cor,'not applicable');
                        
                        rt_comp = [];
                        
                        for l=1:length(na)
                           
                            if na(l)
                                rt_comp(end+1) = rt(l) + rt(l+1);
                            end
                            
                        end
                        
                        rt = rt_comp;
                        cor = cor(~na);

                    elseif strcmp(task,'BI_spotter') || strcmp(task,'v_spotter')
                       
                        trialCol = strcmp(dataArr{1}(1,:),'trial');
                        vasRows = strcmp(dataArr{1}(:,trialCol),'VAS');
                        
                        cor = dataArr{1}(~vasRows,correctCol);
                        cor = string(cor(2:end));
                        
                        rt = dataArr{1}(~vasRows,rtCol);
                        rt = double(string(rt(2:end)));

                    elseif strcmp(task,'v_spotter_v2')
                       
                        vasRows = strcmp(dataTab.trial_in_block,'VAS');
                        
                        cor = dataTab{~vasRows,correctCol};
                        cor = string(cor);

                        rt = dataTab{~vasRows,rtCol};
                        rt = double(string(rt));
                        
                        
                    elseif strcmp(task,'BI_triangles')
                       
                        respCol = strcmp(dataArr{1}(1,:),'time_responded');
                        nanRows = strcmp(dataArr{1}(:,respCol),'NaN');
                        
                        cor = dataArr{1}(~nanRows,correctCol);
                        cor = string(cor(2:end));
                        
                        rt = dataArr{1}(~nanRows,rtCol);
                        rt = double(string(rt(2:end)));
                        
                    elseif strcmp(task,'bi_CGT')
                       
                        rt = dataArr{1}(2:end,rtCol);
                        rt = double(string(rt));
                        rt = sum(rt,2);
                    end
                    
                    cor = strrep(cor,'false','0');
                    cor = strrep(cor,'true','1');
                    cor = strrep(cor,'N/A','0');
                    cor = strrep(cor,'Time Out','0');
                    cor = strrep(cor,'TIMEOUT','0');
                    cor = double(cor);
%                     acc_calc(j) = sum(cor);
                else
                    fprintf('No correct column found\n');
                end




                



                if ~contains(task,'motorControl') && ~strcmp(task,'mt_CTET')

                    RT_median(j) = median(rt,'omitnan');
                    RT_mean(j) = mean(rt,'omitnan');
                    RT_std(j) = std(rt,'omitnan');


                    cor = logical(cor);
                    rt_cor = rt(cor);
                    rt_incor = rt(~cor);

                    RT_median_cor(j) = median(rt_cor,'omitnan');
                    RT_mean_cor(j) = mean(rt_cor,'omitnan');
                    RT_std_cor(j) = std(rt_cor,'omitnan');

                    RT_median_incor(j) = median(rt_incor,'omitnan');
                    RT_mean_incor(j) = mean(rt_incor,'omitnan');
                    RT_std_incor(j) = std(rt_incor,'omitnan');
                elseif strcmp(task,'mt_CTET')

                    RT_median(j) = median(rt(~isnan(cor)),'omitnan');
                    RT_mean(j) = mean(rt(~isnan(cor)),'omitnan');
                    RT_std(j) = std(rt(~isnan(cor)),'omitnan');

                    rt_cor = rt(cor == 1);
                    rt_incor = rt(cor == 0);

                    RT_median_cor(j) = median(rt_cor,'omitnan');
                    RT_mean_cor(j) = mean(rt_cor,'omitnan');
                    RT_std_cor(j) = std(rt_cor,'omitnan');

                    RT_median_incor(j) = median(rt_incor,'omitnan');
                    RT_mean_incor(j) = mean(rt_incor,'omitnan');
                    RT_std_incor(j) = std(rt_incor,'omitnan');


                elseif contains(task,'motorControl')

                    RT_median(j) = median(rt,'omitnan');
                    RT_mean(j) = mean(rt,'omitnan');
                    RT_std(j) = std(rt,'omitnan');

                end
            end
        end
    end
    
    nComp_RT = logical(nCompAll.impRT);
    nComp_repResp = logical(nCompAll.repResp);
    nComp_taskSpec = logical(nCompAll.taskSpec);
    nComp_noResp = logical(nCompAll.noResp);
   
    save(...
        pathToFiles{i},...
        '-append',...
        'RT_median',...
        'RT_mean',...
        'RT_std',...
        'RT_median_cor',...
        'RT_mean_cor',...
        'RT_std_cor',...
        'RT_median_incor',...
        'RT_mean_incor',...
        'RT_std_incor',...
        'nComp_RT',...
        'nComp_repResp',...
        'nComp_taskSpec',...
        'nComp_noResp',...
        'focusArrAll'...
    );

%     close(wb);
   
end
    