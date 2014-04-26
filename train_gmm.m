clear;

D = 4;
sessions = 1:5;

featureDir = 'features/';
featureFiles = dir(featureDir);
totalFeatures = [];
for i = 1:length(featureFiles)
    if (~ismember(str2double(featureFiles(i).name(4:5)),sessions))
        continue;
    end
    
    mfcfile = fopen( strcat(featureDir,featureFiles(i).name), 'r', 'b' );

    nSamples = fread( mfcfile, 1, 'int32' );
    sampPeriod = fread( mfcfile, 1, 'int32' )*1E-7;
    sampSize = 0.25*fread( mfcfile, 1, 'int16' );
    parmKind = fread( mfcfile, 1, 'int16' );

    features = fread( mfcfile, [ sampSize, nSamples ], 'float' ).';
    totalFeatures = [totalFeatures; features];

    fclose( mfcfile );
end
    
gm = gmdistribution.fit(totalFeatures,D,'Regularize',1e-12);
save gm.mat gm;