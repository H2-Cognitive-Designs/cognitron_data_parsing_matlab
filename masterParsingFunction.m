function [] = masterParsingFunction(path_to_data_directory,path_to_output_directory)

%% Master script 

% Step 1: Log on to the cognitron website (https://www.cognitron.co.uk).
%
%   - If you do not have log in details or you have forgotten your password
%   please contact Will at wt512@ic.ac.uk
%
%   - If this is the first time you are logging in then you will need to
%   set up 2 factor authentication by downloading an authenticator app and
%   linking that app with the qr code provided by cognitron
%
%   - If you have already done this then please go ahead and authenticate
%   to get access to your account


% Step 2: Navigate to the downloads page
%   - This can be found via a button in the top right of the screen or by
%   navigating directly to https://www.cognitron.co.uk/download
%   - You should see a list of data sets that you have access to, if this
%   page is empty please contact Will at wt512@ic.ac.uk

% Step 3: Download the data you wish to process
%
%   - Select the JSON (include Raw) format from the top right dropdown menu
%
%   - Click on the dataset that you want to download. It should appear in
%   the processing section while it is processing. You can leave and even
%   close the page while you wait for it to finish processing.
%
%   - When it is done processing it will turn green, if an error occurs it
%   will go red, if this happens please contact Will at wt512@ic.ac.uk
%
%   - Once it has turned green, click on the green banner, this should
%   start your file downloading.
%
%   - The file that is downloaded should be in your downloads folder and
%   should be a zip file. Unzip this file and place it in a directory for
%   holding.

% Step 4: Process the data file 
%
%   - If you have followed the above instuctions correctly, all you should
%   need to do now is to run this function in matlab with the path to the
%   data file that you just saved above and a path to where you want the
%   output to go, where three output directories (mat, csv and raw) will be
%   created to save the parsed data in to.


%% Change the current path to that of this script
if(~isdeployed)
  cd(fileparts(which(mfilename)));
  addpath('code');
end

%% Check that the data file exists

files = dir(path_to_data_directory);
files = files([files.isdir] == 0);
files = files(~strcmp({files.name},'.DS_Store') == 1);

if isempty(files)
    error('There is no data file in the "site" folder');
end

for f=1:length(files)
    if contains(files(f).name,'.gz')
        error('The data file %s in the data directory is still compressed, please uncompress it before continuing',files(f).name);
    elseif (~contains(files(f).name,'.json'))
        error('The data file %s in the data directory is not a .json file, please make sure there are only files you want to parse in the data directory',files(f).name);
    end
end

%% Check that the output directory is empty

if exist(fullfile(path_to_output_directory,'mat'),'dir') == 7
    prompt = "The mat output directory already exists, would you like to wipe its content in order to continue? Y/N [Y]: ";
    txt = input(prompt,"s");
    if isempty(txt)
        txt = 'Y';
    end

    if (strcmp(upper(txt),"Y"))
        rmdir(fullfile(path_to_output_directory,'mat'),'s')
        mkdir(fullfile(path_to_output_directory,'mat'));
    else
        error("The output directories have to be empty in order to continue");
    end
else
    mkdir(fullfile(path_to_output_directory,'mat'));
end


if exist(fullfile(path_to_output_directory,'csv'),'dir') == 7
    prompt = "The csv output directory already exists, would you like to wipe its content in order to continue? Y/N [Y]: ";
    txt = input(prompt,"s");
    if isempty(txt)
        txt = 'Y';
    end

    if (strcmp(upper(txt),"Y"))
        rmdir(fullfile(path_to_output_directory,'csv'),'s')
        mkdir(fullfile(path_to_output_directory,'csv'));
    else
        error("The output directories have to be empty in order to continue");
    end
else
    mkdir(fullfile(path_to_output_directory,'csv'));
end


if exist(fullfile(path_to_output_directory,'raw'),'dir') == 7
    prompt = "The raw output directory already exists, would you like to wipe its content in order to continue? Y/N [Y]: ";
    txt = input(prompt,"s");
    if isempty(txt)
        txt = 'Y';
    end

    if (strcmp(upper(txt),"Y"))
        rmdir(fullfile(path_to_output_directory,'raw'),'s')
        mkdir(fullfile(path_to_output_directory,'raw'));
    else
        error("The output directories have to be empty in order to continue");
    end
else
    mkdir(fullfile(path_to_output_directory,'raw'));
end

%% Change the name of the files to work with my parsing functions


% [~,fileNames] = util_getPaths(path_to_data_directory);

for f=1:length(files)

    thisFile = files(f).name;
    suffixPresent = regexp(thisFile,'_[0-9].json');

    
    

    if isempty(suffixPresent)

        movefile(...
            fullfile(...
                files(f).folder,...
                files(f).name...
            ),...
            fullfile(...
                files(f).folder,...
                strcat(...
                    thisFile,...
                    '_1.json'...
                )...
            )...
        );

    end

end


%% Run the parsing functions

addpath('./code/');


cog_extractStudy_allFormats(...
    path_to_data_directory,...
    path_to_output_directory...
);


    