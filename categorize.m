function [ emotion ] = categorize( filename )
N = 4;

mfcfile = fopen( filename, 'r', 'b' );

nSamples = fread( mfcfile, 1, 'int32' );
sampPeriod = fread( mfcfile, 1, 'int32' )*1E-7;
sampSize = 0.25*fread( mfcfile, 1, 'int16' );
parmKind = fread( mfcfile, 1, 'int16' );

features = fread( mfcfile, [ sampSize, nSamples ], 'float' ).';

fclose( mfcfile );

load gm;
seq = cluster(gm,features)';

load model;
keys = trans.keys;
pi = 1/N * ones(N,1);
p = zeros(length(keys),1);
for k = 1:length(keys)
    emotion = keys(k);
    a = trans(emotion{1,1});
    b = emis(emotion{1,1});
    
    T=length(seq);
    d = zeros(T,N);
    for i=1:N    
        d(1,i)=b(i,seq(1))*pi(i);
    end
    for t=1:(T-1)  
        for j=1:N
            z=0;
            for i=1:N
                z=z+a(i,j)*d(t,i);
            end
            d(t+1,j)=z*b(j,seq(t+1));
        end
    end

    p(k) = sum(d(T,:));
end

p = p/sum(p);
[prob, idx] = sort(p,'descend');
emotions = keys(idx);
emotion = emotions(1);
disp(emotion{1,1});
end