clear;

N = 4;
D = 4;
K = 10;
sessions = 1;
emotions = cell(0);
xdata = cell(0);
ydata = cell(0);

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
    totalFeatures = [totalFeatures; features];

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
                                    ydata = [ydata; emotion];
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

gm = gmdistribution.fit(totalFeatures,D,'Regularize',1e-12);
save gm.mat gm;

seqs = cell(0);
for i = 1:length(xdata)
    x = xdata(i);
    seqs = [seqs; cluster(gm,x{1,1})'];
end

initTrans = rand(N,D);
s = sum(initTrans');
for i = 1:N
    initTrans(i,:) = initTrans(i,:) ./ s(i);
end
initEmis = rand(N);
s = sum(initEmis');
for i = 1:N
    initEmis(i,:) = initEmis(i,:) ./ s(i);
end

idx = crossvalind('Kfold', length(xdata), K);
bestErrRate = 1;
for i = 1:K
    i
    
    transTrain = containers.Map;
    emisTrain = containers.Map;
    for k = 1:length(emotions)
        emotion = emotions(k);
        e = find(ismember(ydata(idx~=i),emotion));
        [transTrain(emotion{1,1}), emisTrain(emotion{1,1})] = hmmtrain(seqs(e),initTrans,initEmis,'Tolerance',1e-3);
    end
    
    C = cell(length(seqs(idx==i)),1);
    for l = 1:length(seqs(idx==i));
        seq = seqs(l);
        seq = seq{1,1};
        pi = 1/N * ones(N,1);
        p = zeros(length(emotions),1);
        for k = 1:length(emotions)
            emotion = emotions(k);
            a = transTrain(emotion{1,1});
            b = emisTrain(emotion{1,1});

            T=length(seq);
            d = zeros(T,N);
            for ii=1:N    
                d(1,ii)=b(ii,seq(1))*pi(ii);
            end
            for t=1:(T-1)  
                for j=1:N
                    z=0;
                    for ii=1:N
                        z=z+a(ii,j)*d(t,ii);
                    end
                    d(t+1,j)=z*b(j,seq(t+1));
                end
            end

            p(k) = sum(d(T,:));
        end

        p = p/sum(p);
        [prob, e] = sort(p,'descend');
        emotions = emotions(e);
        C(l) = emotions(1);
    end
    
    s = 0;
    y = ydata(idx==i);
    for j = 1:length(y)
        s1 = y(j);
        s1 = s1{1,1};
        s2 = C(j);
        s2 = s2{1,1};
        if (strcmp(s1,s2) ~= 1)
            s = s + 1;
        end
    end
    errRate = s/length(ydata(idx==i));
    if (errRate < bestErrRate)
        trans = transTrain;
        emis = emisTrain;
        bestErrRate = errRate;
    end
end

C = cell(length(seqs),1);
for l = 1:length(seqs);
    seq = seqs(l);
    seq = seq{1,1};
    pi = 1/N * ones(N,1);
    p = zeros(length(emotions),1);
    for k = 1:length(emotions)
        emotion = emotions(k);
        a = trans(emotion{1,1});
        b = emis(emotion{1,1});

        T=length(seq);
        d = zeros(T,N);
        for ii=1:N    
            d(1,ii)=b(ii,seq(1))*pi(ii);
        end
        for t=1:(T-1)  
            for j=1:N
                z=0;
                for ii=1:N
                    z=z+a(ii,j)*d(t,ii);
                end
                d(t+1,j)=z*b(j,seq(t+1));
            end
        end

        p(k) = sum(d(T,:));
    end

    p = p/sum(p);
    [prob, e] = sort(p,'descend');
    emotions = emotions(e);
    C(l) = emotions(1);
end

s = 0;
for j = 1:length(ydata)
    s1 = ydata(j);
    s1 = s1{1,1};
    s2 = C(j);
    s2 = s2{1,1};
    if (strcmp(s1,s2) ~= 1)
        s = s + 1;
    end
end
errRate = s/length(ydata);
conMat = confusionmat(ydata,C);

save model.mat trans emis;