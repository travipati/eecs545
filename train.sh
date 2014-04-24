for f in ../IEMOCAP_full_release/Session1/dialog/wav/*_impro*
do
    ../opensmile-2.0-rc1/opensmile/SMILExtract -C ../opensmile-2.0-rc1/opensmile/config/MFCC12_E_D_A.conf -I $f -O features/$(basename $f .wav).mfcc.htk
done

