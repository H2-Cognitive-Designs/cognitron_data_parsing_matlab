function [outStruct] = util_cellerise(inStruct)
%  -- Cellerise --
%  -- Date: 26-Jan-2022 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Takes a struct and converts all non-cell fields to cells
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  inStruct :: Struct to cellerise
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%  outStruct :: Cellerised struct
% 
%  ------------------------------------------------------------------------

fields = fieldnames(inStruct);
    
for f=1:length(fields)
    if ~isa(inStruct.(fields{f}),'cell')


        if isa(inStruct.(fields{f}),'numeric') || isa(inStruct.(fields{f}),'logical')
            container = num2cell(inStruct.(fields{f}));
        elseif isa(inStruct.(fields{f}),'categorical')
            container = cellstr(string(inStruct.(fields{f})));
        elseif isa(inStruct.(fields{f}),'string')
            container = cellstr(inStruct.(fields{f}));
        elseif isa(inStruct.(fields{f}),'char')
            container = cellstr(inStruct.(fields{f}));
        else
            if ~strcmp(fields{f},'keyObj')
                warning(...
                    'Could not convert %s of type %s',...
                    fields{f},...
                    class(inStruct.(fields{f}))...
                );
            end
            container = inStruct.(fields{f});
        end

        inStruct.(fields{f}) = container;

    end

end

outStruct = inStruct;