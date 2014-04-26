for f in ../IEMOCAP_full_release/Session?/dialog/wav/*_impro*
do
    ../opensmile-2.0-rc1/opensmile/SMILExtract -C config/ours.conf -I $f -O features/$(basename $f .wav).htk
done

