clear;

N = 4;
D = 4;
sessions = 1:5;

seqs = containers.Map;
load gm;

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

    seq = cluster(gm,features)';
    

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
                    emotionSeq = seq(ceil(startTime/sampPeriod):floor(endTime/sampPeriod));
                    
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
                                    if (~isKey(seqs,emotion))
                                        seqs(emotion) = cell(0);
                                    end
                                    seqs(emotion) = [seqs(emotion) emotionSeq];
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

% initTrans = [0.7 0.1 0.1 0.1; ...
%              0.05 0.8 0.1 0.05; ...
%              0.3 0.05 0.6 0.05; ...
%              0.1 0.2 0.03 0.4];
% initEmis = 1/N * ones (N,N);

trans = containers.Map;
emis = containers.Map;
keys = seqs.keys;
for k = 1:length(keys)
    emotion = keys(k);
    emotionSeqs = values(seqs,emotion);
    [trans(emotion{1,1}), emis(emotion{1,1})] = hmmtrain(emotionSeqs{1,1},initTrans,initEmis,'Tolerance',1e-3);
end

save model.mat trans emis;