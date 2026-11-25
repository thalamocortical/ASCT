function oord=estimateModelOrder(dat,method,trial_mode,mv)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(dat,1);
npts=size(dat,2);
trials=size(dat,3);

METHODS=[1,2,4,8];
meth_num = METHODS(method);

MAXORDER=20;
MAXCRIT=2;
if trial_mode~=0
    %dat=squeeze(dat(:,:,1)); % just the first trial
    tr_num=trials;
else
    tr_num=1;
end
CRIT=zeros(MAXCRIT,MAXORDER,tr_num);
rdmsg_h=waitbar(0,'Estimating criteria...');
for tr=1:tr_num
    for ord=1:MAXORDER
        if trial_mode~=0
            dat1=squeeze(dat(:,:,tr));
        else
            dat1=dat;
        end
        [ARr,Vr]=mvar_estimate(dat1,ord,meth_num,mv);

        %CRIT(1,ord)=log(det(Vr))+2*ord*chans/npts; % AIC
        K=ord*chans*chans+chans*(chans-1); %number of estimated parameters (coefs and variance)
        dvr=abs(det(Vr));  % for a case of numerical instabilities (sometimes)
        CRIT(1,ord,tr)=log(dvr)+2*K/npts; % AIC
        CRIT(2,ord,tr)=dvr*((npts+chans*ord)/(npts-chans*ord))^chans; % FPE
        waitbar(((tr-1)*MAXORDER+ord)/MAXORDER/tr_num);
    end
end
close(rdmsg_h);
[handle,xOrder]=selOptmalOrder('String','AIC',CRIT,MAXORDER);
oord=cell2mat(xOrder);
