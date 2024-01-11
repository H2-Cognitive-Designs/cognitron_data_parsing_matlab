function [uArr,emptyOrNaN_idx,inArr_clean,inArr_conv] = util_getUniqueWithEmpty(inArr)
%  -- Get Unique (With Empty) --
%  -- Date: 19-Jan-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Gets unique values in a cell array containing empty cells
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  inArr :: Array in
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%  uArr :: Unique values in inArr
%
%  emptyOrNaN_idx :: Indices of empty or NaN values in inArr
%
%  inArr_clean :: inArr with NaNs and empties removed
%
%  ------------------------------------------------------------------------


if isa(inArr,'cell')
    
   
    % Get classes of cells
    classes = cellfun(...
        @(x) class(x),...
        inArr,...
        'UniformOutput', false...
    );

    tabs = tabulate(classes);
    %% Unpack cells within cells
    while any(strcmp(tabs(:,1),'cell'))
    
    
        % Unpack cells in cells
        cellIdx = strcmp(classes,'cell');
        cells = inArr(cellIdx);
        for c=1:length(cells)

            thisCell = cells{c};

            if length(thisCell) > 1
                thisClasses = cellfun(...
                    @(x) class(x),...
                    thisCell,...
                    'UniformOutput', false...
                );

                % If all double
                if all(strcmp(thisClasses,'double'))

                % If all char
                elseif all(strcmp(thisClasses,'char'))

                    joined = strjoin(thisCell,',');
                    cells{c} = joined;

                end


            else
                cells{c} = thisCell{1};
            end



        end

        inArr(cellIdx) = cells;
        classes = cellfun(...
            @(x) class(x),...
            inArr,...
            'UniformOutput', false...
        );

        tabs = tabulate(classes);
        
    end
    
    
    % Get a handle on empty cells
    emptyOrNaN_idx = zeros(size(inArr));
    
    classes = cellfun(...
        @(x) class(x),...
        inArr,...
        'UniformOutput', false...
    );

    % find empty character cells
    charCells_idx = strcmp(classes,'char');
    if any(charCells_idx)
        charCells = inArr(charCells_idx);

        charCells_nan = strcmpi(charCells,'nan');
        charCells_undefined = strcmpi(charCells,'<undefined>');
        charCells_empty = cellfun(@(x) isempty(x), charCells);

        charCells_all = charCells_nan | charCells_undefined | charCells_empty;

        emptyOrNaN_idx(charCells_idx) = charCells_all;
    end
    % find empty double or single cells
    floatCells_idx = ismember(classes,{'double','single'});
    
    if any(floatCells_idx)
        floatCells = inArr(floatCells_idx);

        floatCells_empty = cellfun(@(x) isempty(x),floatCells);
        floatCells(floatCells_empty) = {NaN};

        floatCells_nan = cellfun(...
            @(x) isnan(x),...
            floatCells...
        );



        floatCells_all = floatCells_nan | floatCells_empty;

        emptyOrNaN_idx(floatCells_idx) = floatCells_all;
    end
    % find empty or undefined categorical
    catCells_idx = strcmp(inArr,'categorical');
    
    if any(catCells_idx)
        catCells = inArr(catCells_idx);

        catCells_undefined = cellfun(@(x) ismissing(x),catCells);
        catCells_empty = cellfun(@(x) x == '',catCells);

        catCells_all = catCells_undefined | catCells_empty;

        emptyOrNaN_idx(catCells_idx) = catCells_all;
    end
    
elseif isa(inArr,'string')
    
    emptyOrNaN_idx = cellfun(@(x) isempty(x),inArr);
    
    
elseif isa(inArr,'float')
    emptyOrNaN_idx = isnan(inArr);
    
elseif isa(inArr,'integer')
    emptyOrNaN_idx = zeros(size(inArr))';
elseif isa(inArr,'categorical')
    emptyOrNaN_idx = isundefined(inArr);
elseif isa(inArr,'logical')
    emptyOrNaN_idx = zeros(size(inArr));
end



emptyOrNaN_idx = logical(emptyOrNaN_idx);
inArr_clean = inArr(~emptyOrNaN_idx);


try
    uArr = unique(inArr_clean);
catch
%     warning('Trying to extract contents');
    
    inArr_num = string(inArr_clean);
    uArr = unique(inArr_num);
end



