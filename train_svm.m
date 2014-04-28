clear;

K = 10;
sessions = 1;
emotions = cell(0);
xdata = [];
ydata = [];

featureDir = 'features/';
featureFiles = dir(featureDir);
for i = 1:length(featureFiles)
    if (~ismember(str2double(featureFiles(i).name(4:5)),sessions))
        continue;    
    else
        ses = str2double(featureFiles(i).name(4:5));
    end
        
    
    mfcfile = fopen( strcat(featureDir,featureFiles(i).name), 'r', 'b' );

    nSamples = fread( mfcfile, 1, 'int32' );
    sampPeriod = fread( mfcfile, 1, 'int32' )*1E-7;
    sampSize = 0.25*fread( mfcfile, 1, 'int16' );
    parmKind = fread( mfcfile, 1, 'int16' );

    features = fread( mfcfile, [ sampSize, nSamples ], 'float' ).';

    fclose( mfcfile );
    
    genderFile = {strcat('f',int2str(ses)); strcat('m',int2str(ses))};
    gender = {'Female'; 'Male'};
    
    for g = 1:length(gender)
    try   
        periods = strfind(featureFiles(i).name,'.');
        file = strcat('../IEMOCAP_full_release/Session',int2str(ses),'/dialog/EmoEvaluation/Self-evaluation/', ...
            featureFiles(i).name(1:periods(1)-1),'_',genderFile(g),'.anvil');
        tree = xmlread(file{1,1});
    catch
        continue;
    end
    
    annotation = tree.getChildNodes.item(0);
    body = tree.getElementsByTagName('body').item(0);
    tracks = body.getElementsByTagName('track');
    numTracks = tracks.getLength;
    for trackCount = 1:numTracks
        trackAtts = tracks.item(trackCount-1).getAttributes;
        numTrackAtts = trackAtts.getLength;
        for trackAttCount = 1:numTrackAtts
            if (strcmp(trackAtts.item(trackAttCount-1).getName, 'name')&& ...
                    strcmp(trackAtts.item(trackAttCount-1).getValue, strcat(gender(g),'.Emotion')))
                els = tracks.item(trackCount-1).getElementsByTagName('el');
                numEls = els.getLength;
                for elCount = 1:numEls
                    elAtts = els.item(elCount-1).getAttributes;
                    numElAtts = elAtts.getLength;
                    for elAttCount = 1:numElAtts
                        if (strcmp(elAtts.item(elAttCount-1).getName, 'start'))
                            startTime = str2double(elAtts.item(elAttCount-1).getValue);
                        end
                        if (strcmp(elAtts.item(elAttCount-1).getName, 'end'))
                            endTime = str2double(elAtts.item(elAttCount-1).getValue);
                        end
                    end
                    e = floor(endTime/sampPeriod);
                    if (e > length(features))
                        e = length(features);
                    end
                    x = features(ceil(startTime/sampPeriod):e,:);
                    
                    attributes = els.item(elCount-1).getElementsByTagName('attribute');
                    numAttributes = attributes.getLength;
                    for attributeCount = 1:numAttributes
                    attributeAtts = attributes.item(attributeCount-1).getAttributes;
                    numAttributeAtts = attributeAtts.getLength;
                        for attributeAttCount = 1:numAttributeAtts
                            if (strcmp(attributeAtts.item(attributeAttCount-1).getName, 'name'))
                                if (~strcmp(attributeAtts.item(attributeAttCount-1).getValue, 'Overlap') && ...
                                        strcmp(attributes.item(attributeCount-1).getTextContent, 'true'))
                                    emotion = char(attributeAtts.item(attributeAttCount-1).getValue);
                                    if (strcmp(emotion,'Other') || strcmp(emotion,'Neutral state'))
                                        continue;
                                    elseif strcmp(emotion,'Frustration')
                                        emotion = 'Anger';
                                    elseif strcmp(emotion,'Excited')
                                        emotion = 'Surprise';
                                    end
                                    if (length(find(ismember(emotions,emotion))) == 0)
                                            emotions = [emotions emotion];
                                    end
                                    xdata = [xdata; x];
                                    [n d] = size(x);
                                    y = [];
                                    y(1:n,1) = find(ismember(emotions,emotion));
                                    ydata = [ydata; y];
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    end
end

[n d] = size(xdata);
idx = crossvalind('Kfold', n, K);
bestErrRate = 1;
for k = 1:K
    k
    svmStruct = svmtrain(ydata(idx~=k),xdata(idx~=k,:));
    
    C = svmpredict(ydata(idx==k),xdata(idx==k,:),svmStruct);
    errRate = sum(ydata(idx==k)~=C)/length(ydata(idx==k));
    if (errRate < bestErrRate)
        svmModel = svmStruct;
        bestErrRate = errRate;
    end
end

C = svmpredict(ydata,xdata,svmModel);
errRate = sum(ydata~=C)/length(ydata);
conMat = confusionmat(ydata,C);

save svm.mat svmModel emotions;