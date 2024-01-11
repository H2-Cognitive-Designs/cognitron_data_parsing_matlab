function [] = util_saveStructMin(struc,outFile)
%  -- Save Structure Minimum --
%  -- Date: 11-Mar-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  Tries to save a matlab structure without the -v7.3 flag and if that fails
%  saves it with the flag
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  struc :: Structure to save
% 
%  outFile :: File to save to
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%   :: 
% 
%  ------------------------------------------------------------------------

warning('error','MATLAB:save:sizeTooBigForMATFile');

try
    save(outFile,'-struct','struc');
catch err
    if strcmp(err.identifier,'MATLAB:save:sizeTooBigForMATFile')
        save(...
            outFile,...
            '-struct',...
            'struc',...
            '-v7.3'...
            );
    else
        fprintf('%s\n',err.identifier);
    end
end