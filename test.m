load data;
svmModel = svmtrain(ydata(idx~=1,:),xdata(idx~=1,:), '-t 0');
save svm.mat svmModel emotions;

C = svmpredict(ydata,xdata,svmModel);
errRate = sum(ydata~=C)/length(ydata);
conMat = confusionmat(ydata,C);