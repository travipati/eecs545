clear;

N = 4;
D = 4;
K = 10;
sessions = 1:5;
emotions = cell(0);
xdata = [];
ydata = [];

featureDir = 'features/';
featureFiles = dir(featureDir);
totalFeatures = [];
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
    totalFeatues = [totalFeatues; features];

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
                                    if (length(find(ismember(emotions,emotion))) == 0)
                                            emotions = [emotions emotion];
                                    end
                                    xdata = [xdata; x];
                                    [n d] = size(x);
                                    y = cell(n,1);
                                    for j = 1:n
                                        y(j) = cellstr(emotion);
                                    end
                                    ydata = [ydata; y];
%                                     if (length(find(ismember(emotions,emotion))) == 0)
%                                             emotions = [emotions emotion];
%                                     end
%                                     xdata = [xdata x];
%                                     ydata = [ydata emotion];
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
    svmStruct = svmtrain(xdata(idx~=k,:),ydata(idx~=k,:));
    C = svmclassify(svmStruct,xdata(idx==k,:));
    errRate = sum(ydata(idx==k)~=C)/length(ydata(idx~=k));
    if (errRate < bestRage)
        svmModel = svmStruct;
        bestErrRate = errRate;
    end
end
C = svmclassify(svmModel,xdata);
errRate = sum(ydata~=C)/length(ydata);
conMat = confusionmat(ydata,C);

save svm.mat svmModel;
    
% gm = gmdistribution.fit(totalFeatures,D,'Regularize',1e-12);
% save gm.mat gm;
% 
% initTrans = rand(N,D);
% s = sum(initTrans');
% for i = 1:N
%     initTrans(i,:) = initTrans(i,:) ./ s(i);
% end
% initEmis = rand(N);
% s = sum(initEmis');
% for i = 1:N
%     initEmis(i,:) = initEmis(i,:) ./ s(i);
% end
% 
% idx = crossvalind('Kfold', length(xdata), K);
% bestErrRate = 1;
% for i = 1:K
%     transTrain = containers.Map;
%     emisTrain = containers.Map;
%     for k = 1:length(emotions)
%          emotion = emotions(k);
%     %     emotionSeqs = values(seqs,emotion);
%     %     [trans(emotion{1,1}), emis(emotion{1,1})] = hmmtrain(emotionSeqs{1,1},initTrans,initEmis,'Tolerance',1e-3);
%         idx = find(ismember(ydata,emotions(k)));
%         [transTrain(emotion{1,1}), emisTrain(emotions{1,1})] = hmmtrain(cluster(gm,xdata(idx,:))',initTrans,initEmis,'Tolerance',1e-3);
%     end
%     
%     pi = 1/N * ones(N,1);
%     p = zeros(length(keys),1);
%     for k = 1:length(keys)
%         emotion = keys(k);
%         a = transTrain(emotion{1,1});
%         b = emisTrain(emotion{1,1});
% 
%         T=length(seq);
%         d = zeros(T,N);
%         for i=1:N    
%             d(1,i)=b(i,seq(1))*pi(i);
%         end
%         for t=1:(T-1)  
%             for j=1:N
%                 z=0;
%                 for i=1:N
%                     z=z+a(i,j)*d(t,i);
%                 end
%                 d(t+1,j)=z*b(j,seq(t+1));
%             end
%         end
% 
%         p(k) = sum(d(T,:));
%     end
% 
%     p = p/sum(p);
%     [prob, idx] = sort(p,'descend');
%     emotions = keys(idx);
%     emotion = emotions(1);
%     disp(emotion{1,1});
%     
%     C = svmclassify(svmStruct,xdata(idx==i,:));
%     errRate = sum(ydata(idx==i)~=C)/length(ydata(idx~=i));
%     if (errRate < bestRage)
%         svmModel = svmStruct;
%         bestErrRate = errRate;
%     end
% end
% C = svmclassify(svmModel,xdata);
% errRate = sum(ydata~=C)/length(ydata);
% conMat = confusionmat(ydata,C);
% 
% save model.mat trans emis;