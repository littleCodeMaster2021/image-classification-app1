classdef tUNPICHeadless < matlab.uitest.TestCase
    properties(Access = private)
        App
        ImdsTrain
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

            [test.ImdsTrain,test.ImdsVal] = splitEachLabel(imds,0.8,0.2,'randomized');

            %test.TrainedNet = load('trainedNet_Food.mat');
        end


        function trainNet(test)
            % Load a pretrained GoogLeNet network
            net = googlenet;
           
            % Resize the images to the input size of the pretrained network.
            inputSize = net.Layers(1).InputSize;

            augimdsTrain = augmentedImageDatastore(inputSize,imdsTrain);
            augimdsVal = augmentedImageDatastore(inputSize,imdsVal);

            %Define Network Architecture
            lgraph = layerGraph(net);
            
            %Define new layers specific to this data set.
            numClasses = numel(categories(test.ImdsTrain.Labels));
            newLearnableLayer = fullyConnectedLayer(numClasses, ...
                'Name','new_fc', ...
                'WeightLearnRateFactor',10, ...
                'BiasLearnRateFactor',10);

            newClassLayer = classificationLayer('Name','new_classoutput');
            
            % Replace the current layers with the new layers.
            lgraph = replaceLayer(lgraph,'loss3-classifier',newLearnableLayer);
            lgraph = replaceLayer(lgraph,'output',newClassLayer);

            %Train Network
            valFrequencyEpochs = 1;
            miniBatchSize = 50;

            numObservations = augimdsTrain.NumObservations;
            numIterationsPerEpoch = floor(numObservations/miniBatchSize);
            valFrequency = valFrequencyEpochs * numIterationsPerEpoch;

            options = trainingOptions('sgdm', ...
                'MaxEpochs',30, ...
                'InitialLearnRate',1e-4, ...
                'Shuffle','every-epoch', ...
                'ValidationData',augimdsVal, ...
                'ValidationFrequency',valFrequency, ...
                'Verbose',false, ...
                'Plots','training-progress');
           
            test.TrainedNet = trainNetwork(augimdsTrain,lgraph,options);    
        end

        function launchApp(test)
            test.App = UNPICHeadless(test.TrainedNet, test.ImdsVal);
            test.App.IsHeadless = true;
            test.addTeardown(@delete,test.App)
        end
    end

    methods (Test)
        function testImageDataTab(test)
            fprintf('testImageDataTab starts running!\n');
            % Choose Image Data tab
            test.App.MainTabGroup.SelectedTab = test.App.ImageDataTab;

            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.ImageDataTab.Title,'Image Data');

            test.verifyEqual(test.App.DataNumObsValue.Text,  num2str(length(test.ImdsVal.Labels)));
            test.verifyEqual(test.App.DataNumClassesValue.Text,  num2str(length(categories(test.ImdsVal.Labels))));

            test.verifyEqual(size(test.App.DataClassTable.Data), [length(categories(test.ImdsVal.Labels)) 2]);

            % Set DataNumObsToShow value as 16
            test.triggerValueChangedCallback(test.App.DataNumObsToShowSpinner, 16);

            % Update image and ensure it is warning free
            test.verifyWarningFree(@() test.App.updateImages());

            % Verify the UIAxes class
            test.verifyClass(test.App.DataRandomImagesUIAxes,'matlab.ui.control.UIAxes');
            disp('testImageDataTab finishes running!');
        end

        function testAccuracyTab(test)
            fprintf('testAccuracyTab starts running!\n');
            % Choose Accuracy tab
            test.App.MainTabGroup.SelectedTab = test.App.AccuracyTab;

            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.AccuracyTab.Title,'Accuracy');
            
            % Compute Network Accuracy
            test.pushButton(test.App.AccuracyButton);

            % Verify the accuracy table having correct format of data
            test.verifyEqual(size(test.App.AccuracyTable.Data), [length(categories(test.ImdsVal.Labels)) 2]);

            % Compute Confusion Matrix
            test.pushButton(test.App.ConfusionMatrixButton);

            % Switch to True vs Predict Class tab
            test.App.AccuracyTabGroup.SelectedTab = test.App.TruevsPredTab;

            % Set True class and Predicted class value as 'pizza'
            test.App.TruevsPredTrueClassDropDown.Value =  'pizza';
            test.App.TruevsPredPredictedClassDropDown.Value = 'pizza';

            % Click Random Image button
            test.pushButton(test.App.TruevsPredRandomImageButton);

            % Verify TruevsPredValue
            test.verifyEqual(test.App.TruevsPredValue.Text, 'pizza classified as pizza');

            fprintf('testAccuracyTab finishes running!\n');
        end
        function testPredictTab(test) 
              fprintf('testPredictTab starts running!\n');
            % Choose PredictTab
            test.App.MainTabGroup.SelectedTab = test.App.PredictTab;

            % % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictTab.Title,'Predict');

            % Verify the default values of widgets in predict tab
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictScoreUITable.Data);
            test.verifyEmpty(test.App.PredictImageValue.Text);
            test.verifyEmpty(test.App.PredictChooseImageFileEditField.Value);

            % Type the image path to PredictChooseImageFileEditField
            test.App.PredictChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');

            % Click random image button
            test.pushButton(test.App.PredictSingleRandomImageButton);

            % Change dropdown value as pizza
            test.triggerValueChangedCallback(test.App.PredictRandomImageClassDropDown, 'pizza');

            % Verify data in PredictScoreUITable, y-axis label of PredictHistUIAxes and PredictImageValue
            test.verifyEqual(size(test.App.PredictScoreUITable.Data), [length(categories(test.ImdsVal.Labels)) 2]);

            test.verifyEqual(test.App.PredictScoreUITable.Data{1,1},  'pizza (true class)');
            test.verifyEqual(test.App.PredictHistUIAxes.XTickLabel{1,1}, 'pizza');
            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');
            fprintf('testPredictTab finishes running!\n');
        end

        function testPredictionExplainerTab(test)
            fprintf('testPredictionExplainerTab starts running!\n');
            % Choose PredictTab
            test.App.MainTabGroup.SelectedTab = test.App.PredictionExplainerTab;
           
            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.PredictionExplainerTab.Title,'Prediction Explainer');

            % Verify that ExplainerChooseImageFileEditField is empty
            test.verifyEmpty(test.App.ExplainerChooseImageFileEditField.Value);

            % Type the image path to PredictChooseImageFileEditField
            test.App.ExplainerChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');

            % Select random image class as pizza
            test.triggerValueChangedCallback(test.App.ExplainerRandomImageClassDropDown, 'pizza');

            % Verify that random image class name is equal to true class
            % name
            test.verifyEqual(test.App.ExplainerRandomImageClassDropDown.Value, test.App.ExplainerValue.Text);

            % Verify the default value of OcclusionMasksize and OcclusionStride
            test.verifyEqual(test.App.OcclusionMasksizeSpinner.Value, 45);
            test.verifyEqual(test.App.OcclusionStrideSpinner.Value, 22);

            % Verify that random image class default value is pizza
            test.verifyEqual(test.App.PredictRandomImageClassDropDown.Value, 'pizza');
            test.verifyWarningFree(@() test.pushButton(test.App.OcclusionButton));
            test.verifyEqual(test.App.PredictImageValue.Text,  'pizza');

            % Swich to GradCAM tab
            test.App.ExplainerTabGroup.SelectedTab = test.App.GradCAMTab;

            % Verify default value in GradCAMTab dropdown widgets
            test.verifyEqual(test.App.GradCAMTargetclassDropDown.Value,  'pizza');

            test.verifyEqual(test.App.GradCAMFeatureMapDropDown.Value,  'inception_5b-output');

            test.verifyWarningFree(@() test.pushButton(test.App.GradCAMButton));

            % Switch to GradientAttributionTab
            test.App.ExplainerTabGroup.SelectedTab = test.App.GradientAttributionTab;

            % Verify default value in GradientAttributionTargetclass dropdown widget
            test.verifyEqual(test.App.GradientAttributionTargetclassDropDown.Value,  'pizza');

            test.verifyWarningFree(@() test.pushButton(test.App.GradientAttributionButton));
            fprintf('testPredictionExplainerTab finishes running!\n');
        end

        function testFeaturesTab(test)
            fprintf('testFeaturesTab starts running!\n');
            % Choose FeaturesTab
            test.App.MainTabGroup.SelectedTab = test.App.FeaturesTab;

            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.FeaturesTab.Title,'Features');
            % Verify the default value of feature choose widgets
            test.verifyEqual( ...
                test.App.FeaturesChooseLayerDropDown.Value,'conv1-7x7_s2');
            test.verifyEqual( ...
                test.App.FeaturesChooseChannelsEditField.Value,'1:4');

            % Change the feature choose channels value to 6
            test.App.FeaturesChooseChannelsEditField.Value = '1:6';

            % Switch to activation tab
            test.App.FeaturesTabGroup.SelectedTab = test.App.ActivationsTab;

            % Type the image path to ActivationsChooseImageFileEditField
            test.App.ActivationsChooseImageFileEditField.Value = fullfile(test.DataDir, 'pizza', 'crop_pizza1.jpg');

            % Verify that ActivationDistribution is empty
            test.verifyEqual(length(test.App.ActivationDistributionPanel.Children), 0);

            % Click random image button
            test.pushButton(test.App.ActivationsSingleRandomImageButton);
    
            % Select random image class as pizza
            test.triggerValueChangedCallback(test.App.ActivationsRandomImageClassDropDown, 'pizza');

            % Click compute activation button
            test.pushButton(test.App.ActivationsButton);

            % Switch to ActivationDistributionTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.ActivationDistributionTab;
  
            test.verifyEqual(test.App.ActivationDistributionRandomImageClassDropDown.Value, 'pizza');
   
            % Click compute activation distributions button
            test.pushButton(test.App.ActivationDistributionComputeButton);
  
            % Verify that ActivationDistribution has 6 channels and each
            % of them has 2 images
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);
            test.verifyEqual(test.App.ActivationDistributionPanel.Children(3).NextSeriesIndex, 2);

            % Switch to MaxActivationsTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.MaxActivationsTab;

            test.verifyEqual(test.App.MaxActivationsImagesperchannelEditField.Value, '1');

            % Set image per channel as 2
            test.App.MaxActivationsImagesperchannelEditField.Value = '2';

            % Click display max activating images button
            test.pushButton(test.App.MaxActivationsImagesButton);
 
            % Verify that ActivationDistribution has 6 sub plots
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);

            % Verify that ActivationDistribution has 6 channels
            test.verifyEqual(sum(cellfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), num2cell(test.App.ActivationDistributionPanel.Children))), 6);

            % Switch to DeepDreamTab
            test.App.FeaturesTabGroup.SelectedTab = test.App.DeepDreamTab;
       
            % Verify default value of iteration, pyramid levels and
            % verbose
            test.verifyEqual(test.App.DeepDreamIterationsSpinner.Value, 10);
            test.verifyEqual(test.App.DeepDreamPyrLvlsSpinner.Value, 2);
            test.verifyFalse(test.App.DeepDreamVerboseCheckBox.Value);
      
            % Update the deep dream iterations and PyrLvls value
            test.App.DeepDreamIterationsSpinner.Value = 2;
            test.App.DeepDreamPyrLvlsSpinner.Value = 1;
    
            % Enable verbose checkbox
            test.App.DeepDreamVerboseCheckBox.Value = true;
         
            % Click deep dream button and verify training finished in verbose results
            test.computeDeepDreamAndVerifyVerboseOutput();
            fprintf('testFeatureTab finishes running!\n');
        end

        function testtSNETab(test)
            fprintf('testtSNETab starts running!\n');
            % Choose t-SNE Tab
            test.App.MainTabGroup.SelectedTab = test.App.tSNETab;

            % Verify that the tab has the expected title
            test.verifyEqual( ...
                test.App.tSNETab.Title,'t-SNE');

            % Verify the default value of tSNE widgets
            test.verifyEqual( ...
                test.App.tSNEChooseLayerDropDown.Value,'prob');
            test.verifyEqual( ...
                test.App.tSNEIncludeEverySpinner.Value, 5);

            % Verify the tSNETable size is 9 by 2
            test.verifyEqual(size(test.App.tSNETable.Data), [length(categories(test.ImdsVal.Labels)) 2]);
            test.verifyTrue(all(cellfun(@(x) x, test.App.tSNETable.DisplayData(:,2))))

            % Choose data layer and update tSNEIncludeEvery spinner value and table
            test.App.tSNEChooseLayerDropDown.Value = 'data';
            test.App.tSNEIncludeEverySpinner.Value = 3;

            % Click tSNEUpdateTableButton
            test.pushButton(test.App.tSNEUpdateTableButton);
            % Verify that 3 true classes get included
            test.verifyEqual(sum(cellfun(@(x) x == 1, test.App.tSNETable.DisplayData(:,2))), 3);
            fprintf('testtSNETab finishes running!\n');
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
            test.pushButton(test.App.DeepDreamComputeButton);

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