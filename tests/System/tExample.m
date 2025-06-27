classdef tExample < matlab.unittest.TestCase
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
            test.addTeardown(@delete,test.App)
        end
    end

    methods (Test)
        function testImageDataTab(test)
            % Choose Image Data tab
            test.App.MainTabGroup.SelectedTab = test.App.ImageDataTab;

            disp('1');

            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.ImageDataTab.Title,'Image Data');
            disp('2');

            test.verifyEqual(test.App.DataNumObsValue.Text,  num2str(length(test.ImdsVal.Labels)));
            disp('3');
            test.verifyEqual(test.App.DataNumClassesValue.Text,  num2str(length(categories(test.ImdsVal.Labels))));
            disp('4');
            test.verifyEqual(size(test.App.DataClassTable.Data), [length(categories(test.ImdsVal.Labels)) 2]);

            disp('5');
            % Set DataNumObsToShow value as 16
            test.triggerValueChangedCallback(test.App.DataNumObsToShowSpinner, 16);
            disp('6');
            % Update image and ensure it is warning free
            test.verifyWarningFree(@() test.App.updateImages());
            disp('7');
            % Verify the UIAxes class
            test.verifyClass(test.App.DataRandomImagesUIAxes,'matlab.ui.control.UIAxes');
            disp('testImageDataTab finishes running!');

            % Choose Accuracy tab
            test.App.MainTabGroup.SelectedTab = test.App.AccuracyTab;
            disp('8');
            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.AccuracyTab.Title,'Accuracy');
            disp('9');
            % Compute Network Accuracy
            test.App.runAccuracyButtonPushedCallback();
            %test.pushButton(test.App.AccuracyButton);
            disp('10');
            % Verify the accuracy table having correct format of data
            test.verifyEqual(size(test.App.AccuracyTable.Data), [length(categories(test.ImdsVal.Labels)) 2]);
            disp('11');
            % Compute Confusion Matrix
            %test.pushButton(test.App.ConfusionMatrixButton);
            disp('12');
            % Switch to True vs Predict Class tab
            test.App.AccuracyTabGroup.SelectedTab = test.App.TruevsPredTab;
            disp('13');
            % Set True class and Predicted class value as 'pizza'
            test.App.TruevsPredTrueClassDropDown.Value =  'pizza';
            test.App.TruevsPredPredictedClassDropDown.Value = 'pizza';
            disp('14');
            % Click Random Image button
            %test.pushButton(test.App.TruevsPredRandomImageButton);
            disp('15');
            % Verify TruevsPredValue
            test.verifyEqual(test.App.TruevsPredValue.Text, 'pizza classified as pizza');
            disp('16');
            disp('testAccuracyTab finishes running!');

            % Choose PredictTab
            test.App.MainTabGroup.SelectedTab = test.App.PredictTab;
            disp('17');
            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictTab.Title,'Predict');
            disp('18');
            % Verify the default values of widgets in predict tab
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictImageValue.Text);
            test.verifyEmpty(test.App.PredictChooseImageFileEditField.Value);
            disp('19');
            % Type the image path to PredictChooseImageFileEditField
            test.App.PredictChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');
            disp('20');
            % Click random image button
            %test.pushButton(test.App.PredictSingleRandomImageButton);
            disp('21');
            % Change dropdown value as pizza
            test.triggerValueChangedCallback(test.App.PredictRandomImageClassDropDown, 'pizza');
            disp('22');
            % Verify data in PredictScoreUITable, y-axis label of PredictHistUIAxes and PredictImageValue
            test.verifyEqual(size(test.App.PredictScoreUITable.Data), [length(categories(test.ImdsVal.Labels)) 2]);
            disp('23');
            test.verifyEqual(test.App.PredictScoreUITable.Data{1,1},  'pizza (true class)');
            test.verifyEqual(test.App.PredictHistUIAxes.XTickLabel{1,1}, 'pizza');
            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');
            disp('testPredictTab finishes running!');
            disp('24');
            % Choose PredictTab
            test.App.MainTabGroup.SelectedTab = test.App.PredictionExplainerTab;
            disp('25');
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictionExplainerTab.Title,'Prediction Explainer');
            disp('26');
            % Verify that ExplainerChooseImageFileEditField is empty
            test.verifyEmpty(test.App.ExplainerChooseImageFileEditField.Value);
            disp('27');
            % Type the image path to PredictChooseImageFileEditField
            test.App.ExplainerChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');
            disp('28');
            % Select random image class as pizza
            test.triggerValueChangedCallback(test.App.ExplainerRandomImageClassDropDown, 'pizza');
            disp('29');
            % Verify that random image class name is equal to true class
            % name
            test.verifyEqual(test.App.ExplainerRandomImageClassDropDown.Value, test.App.ExplainerValue.Text);

            disp('30');
            % Verify the default value of OcclusionMasksize and OcclusionStride
            test.verifyEqual(test.App.OcclusionMasksizeSpinner.Value, 45);
            disp('31');
            test.verifyEqual(test.App.OcclusionStrideSpinner.Value, 22);
            disp('32');
            % Verify that random image class default value is pizza
            test.verifyEqual(test.App.PredictRandomImageClassDropDown.Value, 'pizza');
            disp('33');
            %test.verifyWarningFree(@() test.pushButton(test.App.OcclusionButton));
            disp('34');
            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');
            disp('35');
            % Swich to GradCAM tab
            test.App.ExplainerTabGroup.SelectedTab = test.App.GradCAMTab;
            disp('36');
            % Verify default value in GradCAMTab dropdown widgets
            test.verifyEqual(test.App.GradCAMTargetclassDropDown.Value,  'pizza');
            disp('37');
            test.verifyEqual(test.App.GradCAMFeatureMapDropDown.Value,  'inception_5b-output');
            disp('38');
            %test.verifyWarningFree(@() test.pushButton(test.App.GradCAMButton));
            disp('39');
            % Switch to GradientAttributionTab
            test.App.ExplainerTabGroup.SelectedTab = test.App.GradientAttributionTab;
            disp('40');
            % Verify default value in GradientAttributionTargetclass dropdown widget
            test.verifyEqual(test.App.GradientAttributionTargetclassDropDown.Value,  'pizza');
            disp('41');
            %test.verifyWarningFree(@() test.pushButton(test.App.GradientAttributionButton));
            disp('testPredictionExplainerTab finishes running!');
            disp('42');

            % Choose FeaturesTab
            test.App.MainTabGroup.SelectedTab = test.App.FeaturesTab;
            disp('43');
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.FeaturesTab.Title,'Features');
            disp('4');
            % Verify the default value of feature choose widgets
            test.verifyEqual( ...
                test.App.FeaturesChooseLayerDropDown.Value,'conv1-7x7_s2');
            disp('45');
            test.verifyEqual( ...
                test.App.FeaturesChooseChannelsEditField.Value,'1:4');
            disp('46');
            % Change the feature choose channels value to 6
            test.App.FeaturesChooseChannelsEditField.Value = '1:6';
            disp('47');
            % Switch to activation tab
            test.App.FeaturesTabGroup.SelectedTab = test.App.ActivationsTab;
            disp('48');
            % Type the image path to ActivationsChooseImageFileEditField
            test.App.ActivationsChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');
            disp('49');
            % Verify that ActivationDistribution is empty
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 0);
            disp('50');
            % Click random image button
            %test.pushButton(test.App.ActivationsSingleRandomImageButton);
            disp('51');
            % Select random image class as pizza
            test.triggerValueChangedCallback(test.App.ActivationsRandomImageClassDropDown, 'pizza');
            disp('52');
            % Click compute activation button
            %test.pushButton(test.App.ActivationsButton);
            disp('53');
            % Switch to ActivationDistributionTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.ActivationDistributionTab;
            disp('54');
            test.verifyEqual(test.App.ActivationDistributionRandomImageClassDropDown.Value, 'pizza');
            disp('55');
            % Click compute activation distributions button
            %test.pushButton(test.App.ActivationDistributionComputeButton);
            disp('56');
            % Verify that ActivationDistribution has 6 channels
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);
            disp('57');
            % Switch to MaxActivationsTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.MaxActivationsTab;
            disp('58');
            test.verifyEqual(test.App.MaxActivationsImagesperchannelEditField.Value, '1');
            disp('59');
            % Set image per channel as 2
            test.App.MaxActivationsImagesperchannelEditField.Value = '2';
            disp('60');
            % Click display max activating images button
            %test.pushButton(test.App.MaxActivationsImagesButton);
            disp('61');
            % Verify that ActivationDistribution has 6 sub plots
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);
            disp('62');
            % Verify that ActivationDistribution has 6 channels and each
            % of them has 2 images
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);
            test.verifyEqual(test.App.ActivationDistributionPanel.Children(3).NextSeriesIndex, 2);
            disp('63');
            % Switch to DeepDreamTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.DeepDreamTab;
            disp('64');
            % Verify default value of iteration, pyramid levels and
            % verbose
            test.verifyEqual(test.App.DeepDreamIterationsSpinner.Value, 10);
            test.verifyEqual(test.App.DeepDreamPyrLvlsSpinner.Value, 2);
            test.verifyFalse(test.App.DeepDreamVerboseCheckBox.Value);
            disp('65');
            % Update the deep dream iterations and PyrLvls value
            test.App.DeepDreamIterationsSpinner.Value = 2;
            test.App.DeepDreamPyrLvlsSpinner.Value = 1;
            disp('66');
            % Enable verbose checkbox
            test.App.DeepDreamVerboseCheckBox.Value = true;
            disp('67');
            % Click deep dream button and verify training finished in verbose results
            test.computeDeepDreamAndVerifyVerboseOutput();
            disp('testFeatureTab finishes running!');
            disp('68');
            % Choose t-SNE Tab
            test.App.MainTabGroup.SelectedTab = test.App.tSNETab;
            disp('69');
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.tSNETab.Title,'t-SNE');
            disp('70');
            % Verify the default value of tSNE widgets
            test.verifyEqual( ...
                test.App.tSNEChooseLayerDropDown.Value,'prob');
            test.verifyEqual( ...
                test.App.tSNEIncludeEverySpinner.Value, 5);
            disp('71');
            % Verify the tSNETable size is 9 by 2
            test.verifyEqual(size(test.App.tSNETable.Data), [length(categories(test.ImdsVal.Labels)) 2]);
            test.verifyTrue(all(cellfun(@(x) x, test.App.tSNETable.DisplayData(:,2))))
            disp('72');
            % Choose data layer and update tSNEIncludeEvery spinner value and table
            test.App.tSNEChooseLayerDropDown.Value = 'data';
            test.App.tSNEIncludeEverySpinner.Value = 3;
            disp('73');
            % Click tSNEUpdateTableButton
            %test.pushButton(test.App.tSNEUpdateTableButton);
            % Verify that 3 true classes get included
            test.verifyEqual(sum(cellfun(@(x) x == 1, test.App.tSNETable.DisplayData(:,2))), 3);

            % Click compute t-SNE button
            %test.pushButton(test.App.tSNEButton);
            disp('74');
            % Verify that tSNE plot only shows values belonging to 3 true classes
            test.verifyEqual(length(test.App.tSNEUIAxes.Legend.String), 3);
            disp('testtSNETab finishes running!');

            disp('75');
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
            %test.pushButton(test.App.DeepDreamComputeButton);

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

        function pushButton(~, button)
            buttonPushedFcn = button.ButtonPushedFcn;
            buttonPushedFcn(button, matlab.ui.eventdata.ButtonPushedData);
        end
    end

end

% constraints
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