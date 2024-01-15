# Cognitron Data Parsing for Matlab

## Step 1: Log on to the cognitron website (https://www.cognitron.co.uk).
- If you do not have login details or you have forgotten your password, please contact support@h2cd.co.uk
- If this is the first time you are logging in, then you will need to set up 2-factor authentication by downloading an authenticator app and linking that app with the QR code provided by cognitron
- If you have already done this, then please go ahead and authenticate to get access to your account


## Step 2: Navigate to the downloads page
- This can be found via a button in the top right of the screen or by navigating directly to https://www.cognitron.co.uk/download
- You should see a list of data sets that you have access to; if this page is empty, please contact support@h2cd.co.uk

## Step 3: Download the data you wish to process
- Select the JSON (including Raw) format from the top right dropdown menu
- Click on the dataset that you want to download. It should appear in the processing section while it is processing. You can leave and even close the page while waiting for it to be processed.
- When it is done processing it will turn green; if an error occurs, it will go red; if this happens, please contact support@h2cd.co.uk
- Once it has turned green, click on the green banner, this should start your file downloading.
- The file that is downloaded should be in your downloads folder and should be a zip file. Unzip this file and place it in a directory for holding.

## Step 4: Process the data file (Use masterParsingFunction.m)
 - If you have followed the above instructions correctly, all you should need to do now is to run this function in Matlab with the path to the data file that you just saved above and a path to where you want the output to go, where three output directories (mat, csv and raw) will be created to save the parsed data in to.

