function prepare( xtrain, ytrain, xtest, ytest, xcv, ycv, param )

if param.norm_type == 1
    [xtrain, mu_X, VAR] = trainNormalize([xcv xtrain]);
    xcv = xtrain(:,1:size(xcv,2));
    xtrain = xtrain(:,size(xcv,2)+1:end);
    xtest = testNormalize(xtest,mu_X,VAR);
elseif param.norm_type == 2
    [xtrain, mu_X, VAR] = trainNormalize2([xcv xtrain]);
    xcv = xtrain(:,1:size(xcv,2));
    xtrain = xtrain(:,size(xcv,2)+1:end);
    xtest = testNormalize2(xtest,mu_X,VAR);    
else
    error('wrong type of normalization selected');
end

param = rmfield(param,'norm_type');

xtrain = real(xtrain);
xtest = real(xtest);
xcv = real(xcv);


no = 50;

err_tr = zeros(1,no);
err_ts = zeros(1,no);
fv_tr = zeros(1,no);
fv_ts = zeros(1,no);
etime = zeros(1,no);
nep = zeros(1,no);


for i=1:no
    
    eetime = tic;
    model = LDNN_train(xtrain, ytrain, xcv, ycv, param);
    etime(i) = toc(eetime);
    
    output = LDNN_predict(xtrain, model);
    output_t = LDNN_predict(xtest, model);    
    
    err_tr(i) = sum(output>0.5 ~= ytrain)/numel(ytrain);    
    err_ts(i) = sum(output_t>0.5 ~= ytest)/numel(ytest);

    [a,b,c,d] = confusion_mat(output,ytrain,0.5);
    [at,bt,ct,dt] = confusion_mat(output_t,ytest,0.5);
    
    fv_tr(i) = f_value(b,c,d);
    fv_ts(i) = f_value(bt,ct,dt);
    nep(i) = model.n_epochs;
end

fprintf('\nTraining time: %f  \n\n',mean(etime));

fprintf('mean of epochs: %f  \n',mean(nep));
fprintf('min of epochs: %f  \n',min(nep));
fprintf('max of epochs: %f  \n\n',max(nep));

fprintf('mean training error: %f  \n',mean(err_tr));
fprintf('min training error: %f  \n',min(err_tr));
fprintf('max training error: %f  \n\n',max(err_tr));

fprintf('mean training fval: %f  \n',mean(fv_tr));
fprintf('min training fval: %f  \n',min(fv_tr));
fprintf('max training fval: %f  \n\n',max(fv_tr));

fprintf('mean test error: %f  \n',mean(err_ts));
fprintf('min test error: %f  \n',min(err_ts));
fprintf('max test error: %f  \n\n',max(err_ts));

fprintf('mean test fval: %f  \n',mean(fv_ts));
fprintf('min test fval: %f  \n',min(fv_ts));
fprintf('max test fval: %f  \n\n',max(fv_ts));


end

