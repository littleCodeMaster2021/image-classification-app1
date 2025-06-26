classdef tUNPIC < matlab.uitest.TestCase
    properties(Access = private)
        App
        ImdsVal
        TrainedNet
        DataDir
    end

    methods (TestClassSetup)
        function addParentFolderPath(~)
            currentDir = pwd;
            disp(currentDir);
            currentPath = split(currentDir,["\","/"]);
            disp(currentDir);
            parentPath = currentPath(1:end-2);
            disp(parentPath);
            addpath(fullfile(parentPath{:}));
            disp(fullfile(parentPath{:}));
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
            test.assertThat(@() test.App.UNPICUIFigure.Visible, iEventually(iIsEqualTo(matlab.lang.OnOffSwitchState.on)), ...
                'UNPICUIFigure should be visible.');
            test.addTeardown(@delete,test.App)
        end
    end

    methods (Test)
        function testImageDataTab(test)
            % Choose Image Data tab
            test.choose(test.App.ImageDataTab);
            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.ImageDataTab.Title,'Image Data');

            test.verifyEqual(test.App.DataNumObsValue.Text,  num2str(length(test.ImdsVal.Labels)));
            test.verifyEqual(test.App.DataNumClassesValue.Text,  num2str(length(categories(test.ImdsVal.Labels))));
            test.verifyEqual(size(test.App.DataClassTable.Data), [length(categories(test.ImdsVal.Labels)) 2]);

            test.verifyEqual(test.App.DataNumObsToShowSpinner.Value, 16);


            test.type(test.App.DataNumObsToShowSpinner, 4)
            test.verifyEqual(test.App.DataNumObsToShowSpinner.Value, 4);

            test.verifyWarningFree(@() test.App.updateImages());
        end

        function  testAccuracyTab(test)
            % Choose Accuracy tab
            test.choose(test.App.AccuracyTab);
            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.AccuracyTab.Title,'Accuracy');

            % Compute Network Accuracy
            test.press(test.App.AccuracyButton);

            % Verify the accuracy table having correct format of data
            test.verifyThat(@() size(test.App.AccuracyTable.Data), ...
                iEventually(iIsEqualTo([length(categories(test.ImdsVal.Labels)) 2])), iScreenshot('prefix','AccuracyTable_'));

            % Compute Confusion Matrix
            test.press(test.App.ConfusionMatrixButton)

            test.verifyClass( test.App.ConfusionMatrixPanel.Children,'mlearnlib.graphics.chart.ConfusionMatrixChart');


            % Switch to True vs Predict Class tab
            test.choose(test.App.TruevsPredTab);

            % Set True class and Predicted class value as 'pizza'
            test.choose(test.App.TruevsPredTrueClassDropDown, 'pizza');
            test.choose(test.App.TruevsPredPredictedClassDropDown, 'pizza');

            % Click Random Image button
            test.press(test.App.TruevsPredRandomImageButton);

            % Verify TruevsPredValue
            test.verifyThat(@() test.App.TruevsPredValue.Text, ...
                iEventually(iIsEqualTo('pizza classified as pizza')), iScreenshot('prefix','WaitUntil_TruevsPredResult_'));
        end

        function testPredictTab(test)
            % Choose PredictTab
            test.choose(test.App.PredictTab);
            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictTab.Title,'Predict');

            % Verify the default values of widgets in predict tab
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictImageValue.Text);
            test.verifyEmpty(test.App.PredictChooseImageFileEditField.Value);

            % Type the image path to PredictChooseImageFileEditField
            test.type(test.App.PredictChooseImageFileEditField, fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg'));

            % Click random image button
            test.press(test.App.PredictSingleRandomImageButton);

            % Verify that random image class name is equal to true class
            % name
            test.verifyEqual(test.App.PredictRandomImageClassDropDown.Value, test.App.PredictImageValue.Text);

            % Select random image class as pizza
            test.choose(test.App.PredictRandomImageClassDropDown, 'pizza');

            % Verify data in PredictScoreUITable, y-axis label of PredictHistUIAxes and PredictImageValue
            test.verifyThat(@()  size(test.App.PredictScoreUITable.Data), ...
                iEventually(iIsEqualTo([length(categories(test.ImdsVal.Labels)) 2])), iScreenshot('prefix','PredictScoreUITable_'));

            test.verifyEqual(test.App.PredictScoreUITable.Data{1,1},  'pizza (true class)');
            test.verifyEqual(test.App.PredictHistUIAxes.XTickLabel{1,1}, 'pizza');
            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');
        end

        function testPredictionExplainerTab(test)
            % Choose PredictTab
            test.choose(test.App.PredictionExplainerTab);
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictionExplainerTab.Title,'Prediction Explainer');

            % Verify that ExplainerChooseImageFileEditField is empty
            test.verifyEmpty(test.App.ExplainerChooseImageFileEditField.Value);


            % Type the image path to PredictChooseImageFileEditField
            test.type(test.App.ExplainerChooseImageFileEditField, fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg'));

            % Click random image button
            test.press(test.App.ExplainerSingleRandomImageButton)

            % Select random image class as pizza
            test.choose(test.App.ExplainerRandomImageClassDropDown, 'pizza');

            % Verify that random image class name is equal to true class
            % name
            test.verifyEqual(test.App.ExplainerRandomImageClassDropDown.Value, test.App.ExplainerValue.Text);


            % Verify the default value of OcclusionMasksize and OcclusionStride
            test.verifyEqual(test.App.OcclusionMasksizeSpinner.Value, 45);
            test.verifyEqual(test.App.OcclusionStrideSpinner.Value, 22);

            % Verify that random image class default value is pizza
            test.verifyEqual(test.App.PredictRandomImageClassDropDown.Value, 'pizza');


            test.verifyWarningFree(@() test.press(test.App.OcclusionButton))

            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');


            % Swich to GradCAM tab
            test.choose(test.App.GradCAMTab)

            test.verifyEqual(test.App.GradCAMTargetclassDropDown.Value,  'pizza');
            test.verifyEqual(test.App.GradCAMFeatureMapDropDown.Value,  'inception_5b-output');

            test.verifyWarningFree(@() test.press(test.App.GradCAMButton))

            % Switch to GradientAttributionTab
            test.choose(test.App.GradientAttributionTab);

            test.verifyEqual(test.App.GradientAttributionTargetclassDropDown.Value,  'pizza');
            test.verifyWarningFree(@() test.press(test.App.GradientAttributionButton));
        end

        function testFeatureTab(test)
            % Choose FeaturesTab
            test.choose(test.App.FeaturesTab);
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.FeaturesTab.Title,'Features');

            % Verify the default value of feature choose widgets
            test.verifyEqual( ...
                test.App.FeaturesChooseLayerDropDown.Value,'conv1-7x7_s2');
            test.verifyEqual( ...
                test.App.FeaturesChooseChannelsEditField.Value,'1:4');

            % Change the feature choose channels value to 6
            test.type(test.App.FeaturesChooseChannelsEditField, '1:6');

            % Switch to activation tab
            test.choose(test.App.ActivationsTab);

            % Type the image path to ActivationsChooseImageFileEditField
            test.type(test.App.ActivationsChooseImageFileEditField,  fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg'));

            % Verify that ActivationDistribution is empty
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 0);

            % Click random image button
            test.press(test.App.ActivationsSingleRandomImageButton);

            % Select random image class as pizza
            test.choose(test.App.ActivationsRandomImageClassDropDown, 'pizza');

            % Click compute activation button
            test.press(test.App.ActivationsButton);

            % Switch to ActivationDistributionTab
            test.choose(test.App.ActivationDistributionTab);

            test.verifyEqual( test.App.ActivationDistributionRandomImageClassDropDown.Value, 'pizza');

            % Click compute activation distributions button
            test.press(test.App.ActivationDistributionComputeButton);

            % Verify that ActivationDistribution has 6 channels
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 6);

            % Switch to MaxActivationsTab
            test.choose(test.App.MaxActivationsTab);

            test.verifyEqual(test.App.MaxActivationsImagesperchannelEditField.Value, '1');

            % Set image per channel as 2
            test.type(test.App.MaxActivationsImagesperchannelEditField, '2');

            % Click display max activating images button
            test.press(test.App.MaxActivationsImagesButton);
            % Verify that ActivationDistribution has 6 sub plots
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 6);

            % Verify that ActivationDistribution has 6 channels and each
            % of them has 2 images
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 6);
            test.verifyEqual(test.App.ActivationDistributionPanel.Children(1).NextSeriesIndex, 2);

            % Switch to DeepDreamTab
            test.choose(test.App.DeepDreamTab);

            % Verify default value of iteration, pyramid levels and
            % verbose
            test.verifyEqual(test.App.DeepDreamIterationsSpinner.Value, 10);
            test.verifyEqual(test.App.DeepDreamPyrLvlsSpinner.Value, 2);
            test.verifyFalse(test.App.DeepDreamVerboseCheckBox.Value);

            % Update the deep dream iterations and PyrLvls value
            test.type(test.App.DeepDreamIterationsSpinner, 2);
            test.type(test.App.DeepDreamPyrLvlsSpinner, 1);

            % Enable verbose checkbox
            test.press(test.App.DeepDreamVerboseCheckBox);

            % Click deep dream button and verify training finished in verbose results
            test.computeDeepDreamAndVerifyVerboseOutput();
        end

        function testtSNETab(test)
            % Choose t-SNE Tab
            test.choose(test.App.tSNETab);
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.tSNETab.Title,'t-SNE');

            % Verify the default value of tSNE widgets
            test.verifyEqual( ...
                test.App.tSNEChooseLayerDropDown.Value,'prob');
            test.verifyEqual( ...
                test.App.tSNEIncludeEverySpinner.Value, 5);

            % Verify the tSNETable size is 9 by 2
            test.verifyThat(@() size(test.App.tSNETable.Data), ...
                iEventually(iIsEqualTo([length(categories(test.ImdsVal.Labels)) 2])), iScreenshot('prefix','tSNETable_'));
            test.verifyTrue(all(cellfun(@(x) x, test.App.tSNETable.DisplayData(:,2))))

            % Choose data layer and update tSNEIncludeEvery spinner value and table
            test.choose(test.App.tSNEChooseLayerDropDown, 'data');
            test.type(test.App.tSNEIncludeEverySpinner, 3);
            test.press(test.App.tSNEUpdateTableButton);

            % Verify that 3 true classes get included
            test.verifyEqual(sum(cellfun(@(x) x == 1, test.App.tSNETable.DisplayData(:,2))), 3);

            % Click compute t-SNE button
            test.press(test.App.tSNEButton)

            % Verify that tSNE plot only shows values belonging to 3 true classes
            test.verifyEqual(length(test.App.tSNEUIAxes.Legend.String), 3);
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
            test.press(test.App.DeepDreamComputeButton);
            diary off;
            logFile = fileread(logFilename);
            test.verifyTrue(contains(logFile, ...
                'Training finished: Max epochs completed'));
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