function [ emotion ] = categorize_svm( filename )

mfcfile = fopen( filename, 'r', 'b' );
% filename

nSamples = fread( mfcfile, 1, 'int32' );
sampPeriod = fread( mfcfile, 1, 'int32' )*1E-7;
sampSize = 0.25*fread( mfcfile, 1, 'int16' );
parmKind = fread( mfcfile, 1, 'int16' );

features = fread( mfcfile, [ sampSize, nSamples ], 'float' ).';

fclose( mfcfile );

load svm;
C = svmpredict(zeros(length(features),1),features,svmModel);

count = zeros(length(emotions),1);
for i = 1:length(emotions)
    count(i) = sum(C==i);
end

[prob, idx] = sort(count,'descend');
prob = prob/sum(prob);
topEmotions = emotions(idx);
emotion = topEmotions(1);
disp(emotion{1,1});
end