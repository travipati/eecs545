clear;

N = 4;
D = 4;

features_dir = dir('features');
 
% for i = 1:length(infiles)
    mfcfile = fopen( '../opensmile-2.0-rc1/opensmile/output/output.mfcc.htk', 'r', 'b' );

    nSamples = fread( mfcfile, 1, 'int32' );
    sampPeriod = fread( mfcfile, 1, 'int32' )*1E-7;
    sampSize = 0.25*fread( mfcfile, 1, 'int16' );
    parmKind = fread( mfcfile, 1, 'int16' );

    features = fread( mfcfile, [ sampSize, nSamples ], 'float' ).';

    fclose( mfcfile );

    tree = xmlread('../IEMOCAP_full_release\Session1\dialog\EmoEvaluation\Categorical\Ses01F_impro01_e2.anvil');
    body = tree.getElementsByTagName('body');
    tracks = body.getChildNodes;
    numTracks = tracks.getLength;
    for t = 1:numTracks
        if (strcmp(tracks.item(t-1).getNodeName, 'Female.Emotion'))
        end
    end
    
    gm = gmdistribution.fit(features,D,'Regularize',1e-12);
    seq = cluster(gm,features);
% end

trans = 1/D * ones(N,D);
emis = 1/N * ones(N);

[estTR,estE] = hmmtrain(seq,trans,emis);