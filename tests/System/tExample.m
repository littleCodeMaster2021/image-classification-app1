classdef tExample < matlab.uitest.TestCase
    properties(Access = private)
        App
        ImdsVal
        TrainedNet
        DataDir
    end

    methods (TestClassSetup)
        function addParentFolderPath(~)
            currentDir = pwd;
            currentPath = split(string(currentDir),["\","/"]);
            parentPath = currentPath(1:end-3);
            addpath(genpath(fullfile(parentPath{:})));
        end

        function loadAppData(test)
            rng default
            test.DataDir = fullfile(tempdir,"ExampleFoodImageDataset");
            url = "https://ssd.mathworks.com/supportfiles/nnet/data/ExampleFoodImageDataset.zip";

            if ~exist(test.DataDir,"dir")
                mkdir(test.DataDir);
            end
            downloadExampleFoodImagesData(url, test.DataDir);

            imds = imageDatastore(test.DataDir, ...
                'IncludeSubfolders',true, ...
                'LabelSource','foldernames');

            [~,test.ImdsVal] = splitEachLabel(imds,0.8,0.2,'randomized');

            test.TrainedNet = load('trainedNet_Food.mat');
        end

        function launchApp(test)
            test.App = UNPIC(test.TrainedNet.trainedNet, test.ImdsVal);
            test.addTeardown(@delete,test.App);
        end
    end

    methods (Test)
        function testImageDataTab(test)
            test.verifyEqual(1+1, 2);
            disp('test 1 finish');
            % Choose Image Data tab
            test.App.MainTabGroup.SelectedTab = test.App.ImageDataTab;

            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.ImageDataTab.Title,'Image Data');
                       
            disp('test 2 finish');
        end
    end

    methods(Access = private)
        function computeDeepDreamAndVerifyVerboseOutput(test)
            % Test point to verify additional info is displayed with the
            % Verbose NV pair.
            test.applyFixture(iWorkingFolderFixture());

            logFilename = 'Verbose.log';
            diary(logFilename);
            
            % Click deep dream button
            test.App.DeepDreamComputeButton.ButtonPushedFcn(test.App.DeepDreamComputeButton,[]);

            diary off;
            logFile = fileread(logFilename);
            test.verifyTrue(contains(logFile, ...
                'Training finished: Max epochs completed'));
        end

        function triggerValueChangedCallback(~, widget, newValue)

            % 1. Change the value
            widget.Value = newValue;

            % 2. Create a fake event data structure
            event = struct('Source', widget, 'EventName', 'ValueChanged');

            % 3. Call the callback manually
            widget.ValueChangedFcn(widget, event);
        end
    end

end

% constraints
function constraint = iEventually(varargin)
constraint = matlab.unittest.constraints.Eventually(varargin{:});
end

function constraint = iScreenshot(varargin)
constraint = matlab.unittest.diagnostics.ScreenshotDiagnostic(varargin{:});
end

function constraint = iIsEqualTo(varargin)
constraint = matlab.unittest.constraints.IsEqualTo(varargin{:});
end

function fixture = iWorkingFolderFixture(varargin)
fixture = matlab.unittest.fixtures.WorkingFolderFixture(varargin{:});
end

% helper functions
function downloadExampleFoodImagesData(url,dataDir)
% Download the Example Food Image data set, containing 978 images of
% different types of food split into 9 classes.

% Copyright 2019 The MathWorks, Inc.

fileName = "ExampleFoodImageDataset.zip";
fileFullPath = fullfile(dataDir,fileName);

% Download the .zip file into a temporary directory.
if ~exist(fileFullPath,"file")
    fprintf("Downloading MathWorks Example Food Image dataset...\n");
    fprintf("This can take several minutes to download...\n");
    websave(fileFullPath,url);
    fprintf("Download finished...\n");
else
    fprintf("Skipping download, file already exists...\n");
end

% Unzip the file.
%
% Check if the file has already been unzipped by checking for the presence
% of one of the class directories.
exampleFolderFullPath = fullfile(dataDir,"pizza");
if ~exist(exampleFolderFullPath,"dir")
    fprintf("Unzipping file...\n");
    unzip(fileFullPath,dataDir);
    fprintf("Unzipping finished...\n");
else
    fprintf("Skipping unzipping, file already unzipped...\n");
end
fprintf("Finish loading ExampleFoodImagesData.\n");

end