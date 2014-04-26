
recDuration = 2; 
recObj = audiorecorder

count = 1; 
while count <= 10
    recordblocking(recObj, recDuration);
    y = getaudiodata(recObj);
    wavwrite(y, ['recording' num2str(count)]);
    plot(y)
    
    count = count + 1; 
    if count == 10
        count = 1; 
    end
end




%play(recObj);
%pause(recDuration);



