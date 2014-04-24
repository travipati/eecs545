clear;

N = 4;

mfcfile = fopen( 'features/Ses01F_impro01.mfcc.htk', 'r', 'b' );

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
    
    n=length(a(1,:));
    T=length(seq);

    for i=1:n        
        m(1,i)=b(i,seq(1))*pi(i);
    end
    for t=1:(T-1)  
        for j=1:n
            z=0;
            for i=1:n
                z=z+a(i,j)*m(t,i);
            end
            m(t+1,j)=z*b(j,seq(t+1));
        end
    end
    for i=1:n       
        p(k)=p(k)+m(T,i);        
    end
end

[prob, idx] = sort(p);
prob = prob/sum(prob);
emotions = keys(idx);