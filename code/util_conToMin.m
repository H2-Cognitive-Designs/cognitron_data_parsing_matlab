function [outVar,inClass,outClass] = util_conToMin(inVar,SorD)
%  -- Convert to minimum size --
%  -- Date: 26-Jan-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Converts a variable to its minimal file size
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  inVar :: Input variable, must be array or matrix
% 
%  SorD :: Boolean to indicate if floats should be saved as doubles or
%  singles (0=single,1=double)
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%  outVar :: Output variable
% 
%  ------------------------------------------------------------------------

inClassCheck = 1;

if isa(inVar,'table')
    error('Variable is a table, please extract contents before inserting');
end

if isa(inVar,'logical')
   inClass = 'logical';
   outClass = 'logical';
end

if isa(inVar,'categorical')
   inClass = 'categorical';
   outClass = 'categorical';
end

if isa(inVar,'struct')
   inClass = 'struct';
   outClass = 'struct';
end



if isa(inVar,'cell')
    if inClassCheck
        inClass = 'cell';
        inClassCheck = 0;
    end
    
    % Get classes of cells
    classes = cellfun(...
        @(x) class(x),...
        inVar,...
        'UniformOutput', false...
    );

    tabs = tabulate(classes);
    %% Unpack cells within cells
    check = 0;
    while any(strcmp(tabs(:,1),'cell'))
    
        
    
        % Unpack cells in cells
        cellIdx = strcmp(classes,'cell');
        cells = inVar(cellIdx);
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

        inVar(cellIdx) = cells;
        classes = cellfun(...
            @(x) class(x),...
            inVar,...
            'UniformOutput', false...
        );

        tabs = tabulate(classes);
        
        check = check+1;
        
        if check > 100
            outVar = inVar;
            inClass = 'cell';
            outClass = 'cell';
            return;
        end
        
    end
    
%     [~,maxIdx] = max([tabs{:,3}]);
%     maxClass = tabs(maxIdx,1);

    %% Check for impossible conversions ie vectors in cells or structs in 
    % cells
    impossible = 0;

    classes = cellfun(@(x) class(x),inVar,'UniformOutput',false);
    lengths = cellfun(@(x) length(x),inVar);

    floatLengths = lengths(ismember(classes,{'double','single'}));
    maxLength = max(floatLengths);

    if maxLength > 1
        impossible = 1;
    end

    if any(strcmp(classes,'struct'))
        impossible = 1;
    end

    if ~impossible
    
        %% Get a handle on empty cells

        emptyCells = cellfun(@(x) isempty(x),inVar);

        % Get classes of full cells
        fullClasses = cellfun(...
            @(x) class(x),...
            inVar(~emptyCells),...
            'UniformOutput', false...
        );
        
        noFull = 0;
        if ~isempty(fullClasses)
            fullTabs = tabulate(fullClasses);
        else
            noFull = 1;
            fullTabs = {};
        end

        if size(fullTabs,1) == 1 && ~noFull

            fullClass = fullTabs{1,1};

            % If the full class is double then make all empty cells doubles
            if strcmp(fullClass,'double')
                inVar(emptyCells) = {NaN};

    %             lengths = cellfun(@(x) length(x),inVar);
    %             
    %             if max(lengths) == 1
                inVar = double(string(inVar));
    %             else
    %                 fprintf('Cell of vectors present');
    %             end




            % If the full class is char then make all empty cells chars
            elseif strcmp(fullClass,'char')
                inVar(emptyCells) = {''};

            end

        elseif isempty(fullTabs)

    %         fprintf('No full cell classes\n');

            inVar(:) = {''};
            outClass = 'Empty Character';
        elseif size(fullTabs,1) > 1
%             fprintf('%d full classes present\n',size(fullTabs,1));

            fullCells = inVar(~emptyCells);

            if all(ismember({'char','double'},fullTabs(:,1)))

                if any(strcmp(fullTabs(:,1),'double'))
                    % Check to see if all doubles are NaNs
                   doubleCells = fullCells(strcmp(fullClasses,'double'));
                   doubleDoubles = double(string(doubleCells));
                   nanIdx = isnan(doubleDoubles);

                   if all(nanIdx)
                       doubleEmpty = 1;
                   else
                       doubleEmpty = 0;
                   end

                end


                if any(strcmp(fullTabs(:,1),'char'))

                    
                    charCells = fullCells(strcmp(fullClasses,'char'));
                    
                    % Are they all nan?
                    nanChars = strcmp(charCells,'nan');
                    
                    % Check to see if all characters are empty
                    emptyChars = cellfun(@(x) isempty(x),charCells);

                    if all(emptyChars | nanChars) 
                       charEmpty = 1;
                   else
                       charEmpty = 0;
                   end

                end

                if charEmpty && ~doubleEmpty
                    % Characters are empty and doubles not so convert to double
                    charCells(emptyChars) = {NaN};
                    inVar(strcmp(fullClasses,'char')) = charCells;

                    inVar(emptyCells) = {NaN};

                    inVar = double(string(inVar));



                elseif ~charEmpty && ~doubleEmpty
                    % Both are full
%                     fprintf('Both valid characters and valid doubles present\n');


                elseif charEmpty && doubleEmpty
                    % Both are empty
                    fprintf('Both are empty?!?\n');

                    inVar(emptyCells) = {''};
                    outClass = 'Empty Character';
                elseif ~charEmpty && doubleEmpty
                    % Doubles are NaNs so convert to character
                    doubleCells(nanIdx) = {''};
                    inVar(strcmp(fullClasses,'double')) = doubleCells;

                    inVar(emptyCells) = {''};

                end
            end





        end
        
    else
        outClass = 'cell';
    end
    
    
end


if isa(inVar,'cell') && ~impossible
    
    % Test to see if the characters are Yes and No to convert to
    % logical
    yes = strcmpi(inVar,'Yes');
    no = strcmpi(inVar,'No');
    if all(yes | no)
        inVar = strcmpi(inVar,'Yes');
        outClass = 'logical';
    else
        
        % Try to convert to double
        try
            doubleCheck = double(string(inVar));
            nanCheck = isnan(doubleCheck);

            
            if sum(nanCheck == emptyCells)/length(inVar)*100 == 100
                inVar = doubleCheck;
                outClass = 'double';
                if all(nanCheck == emptyCells)
                    
                else
                    warning('Deleted some values character values that were in a double')

                end


            else
                % Try to convert to categorical
                uVals = unique(inVar);
                if length(uVals) < 200
                    inVar = categorical(inVar);
                    outClass = 'categorical';
                else

                    outClass = 'cell';

                end
            end
        catch
            outClass = 'cell';
        end
        
        
    end
end
    
if isa(inVar,'double') || isa(inVar,'single') 
    if inClassCheck
        inClass = 'float';
        inClassCheck = 0;
    end
    
    
    if sum(floor(inVar)==inVar) == length(inVar)
        if min(inVar) > -1
            inVar = uint64(inVar);
            outClass = 'uint64';
        else
            inVar = int64(inVar);
            outClass = 'int64';
        end
    else
        if SorD
            if isa(inVar,'single')
                inVar = double(inVar);
            end
            outClass = 'double';
        else
            if isa(inVar,'double')
                inVar = single(inVar);
            end
            outClass = 'single';
        end
    end
end
    
if isa(inVar,'integer')
    if inClassCheck
        inClass = 'int';
        inClassCheck = 0;
    end
    
    if min(inVar) > -1
        
        if max(abs(inVar)) < 256
            inVar = uint8(inVar);
            outClass = 'uint8';
        elseif max(abs(inVar)) < 65536
            inVar = uint16(inVar);
            outClass = 'uint16';
        elseif max(abs(inVar)) < 4294967296
            inVar = uint32(inVar);
            outClass = 'uint34';
        else
            outClass = 'uint64';
        end
        
    else
        
        if max(inVar) < 256
            inVar = int8(inVar);
            outClass = 'int8';
        elseif max(inVar) < 65536
            inVar = int16(inVar);
            outClass = 'int16';
        elseif max(inVar) < 4294967296
            inVar = int32(inVar);
            outClass = 'int34';
        else
            outClass = 'int64';
        end
        
    end
end

outVar = inVar;