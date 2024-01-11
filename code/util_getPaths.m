function [filePaths,fileNames] = util_getPaths(pathToDir)
%  -- Get Paths --
%  -- Date: 13-Jan-2021 --
% 
%  DESCRIPTION ------------------------------------------------------------
%  This funciton takes a directory and returns the paths of all files that
%  are not directories
%  ------------------------------------------------------------------------
% 
%  INPUTS -----------------------------------------------------------------
%  pathToDir :: Path to the directory of interest
% 
%  ------------------------------------------------------------------------
% 
%  OUTPUTS ----------------------------------------------------------------
%  filePaths :: Array of file paths
% 
%  fileNames :: Array of file names
% 
%  ------------------------------------------------------------------------

fileStruct = dir(pathToDir);
filesOfInterest = [fileStruct.isdir]==0;

dsStoreIdx = strcmp({fileStruct.name},'.DS_Store');
filesOfInterest(dsStoreIdx == 1) = 0;

numTasks = sum(filesOfInterest);
paths = {fileStruct(filesOfInterest).folder};
files = {fileStruct(filesOfInterest).name};

filePaths = cell([numTasks,1]);
fileNames = cell([numTasks,1]);
for i=1:numTasks
    filePaths{i} = fullfile(paths{i},files{i});
    [~,fileNames{i},~] = fileparts(filePaths{i});
end

%Get rid of DS_Store
ds_idx = contains(filePaths,'/.DS_Store');
filePaths(ds_idx) = [];

%Get rid of progLog
pl_idx = contains(filePaths,'/progLog.mat');
filePaths(pl_idx) = [];
fileNames(pl_idx) = [];

%Get file names


end