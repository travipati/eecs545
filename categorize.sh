filename='wav/temp.wav'
touch $filename

while [ 1 ]
do
    if [ $filename != $(ls -t wav/*.wav | head -n1) ]; then
        filename=$(ls -t wav/*.wav | head -n1)
        sleep 0.1
        ../opensmile-2.0-rc1/opensmile/SMILExtract -C config/ours.conf -I $filename -O wav/$(basename $filename .wav).htk
        matlab -nojvm -nodisplay -nosplash -r "categorize('wav/$(basename $filename .wav).htk');exit;"
    fi
done
