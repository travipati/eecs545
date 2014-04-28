filename='wav/temp.wav'
touch $filename

i=0
while [ 1 ]
do
    if [ $filename != $(ls -t wav/*.wav | head -n1) ]; then
        echo "-----------------" $((i++)) "-----------------"
        filename=$(ls -t wav/*.wav | head -n1)
        sleep 0.1
        ../opensmile-2.0-rc1/opensmile/SMILExtract -C config/ours.conf -I $filename -O wav/$(basename $filename .wav).htk &> /dev/null
        matlab -nojvm -nodisplay -nosplash -nodesktop -r "categorize_svm('wav/$(basename $filename .wav).htk');exit;" | tail +13
    fi
done
