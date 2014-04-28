
recDuration = 5;
recPause = 0;
recObj = audiorecorder

count = 1; 
while count <= 10
    recordblocking(recObj, recDuration);
    y = getaudiodata(recObj);
    wavwrite(y, ['wav/recording' num2str(count)]);
    pause(recPause);    
    %plot(y)
    
    count = count + 1; 
    if count == 10
        count = 1; 
    end
end




%play(recObj);
%pause(recDuration);



