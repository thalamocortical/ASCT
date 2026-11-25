%function [s,h,a,AR_tot]=licz_smtmvar(dat,mv)
function [s,h,a,ARs]=licz_smtmvar(dat,mv)
% estimates AR model parameters and spectrum, model transfer matrix
% for short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

global FRQPMAX

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;
winlen=mv.winlen;
winshf=mv.winshf;
winnum=mv.winnum;

chans=size(dat,1);
dlug=size(dat,2);

METHODS=[1,2,4,8];
meth_num = METHODS(method);

if isempty(winlen)
    winlen = dlug-winnum*winshf;
    if winlen<=0
        disp('Illegal window length');
        s=[]; h=[]; a=[]; AR_tot=[]; ARs=[];
        return
    end
end
if isempty(winshf)
    winshf = floor((dlug-winlen)/winnum);
end
if isempty(winnum)
    winnum = floor((dlug-winlen)/winshf);
    if winnum<=0
        disp('Illegal number of windows');
        s=[]; h=[]; a=[]; AR_tot=[]; ARs=[];
        return
    end
end
[winlen winshf winnum]

s = zeros(chans,chans,FRQPMAX,winnum);
h = zeros(chans,chans,FRQPMAX,winnum);
a = zeros(chans,chans,FRQPMAX,winnum);
if mv.sAR
    AR_tot=zeros(chans,chans,p,winnum);
    V_tot=zeros(chans,chans,winnum);
else
    AR_tot=[];
    V_tot=[];
end

% --- goodness of fit of the model: residual whiteness and stability ---
docheck = ~isfield(mv,'diagnost') || mv.diagnost;
if docheck
    diagw=cell(1,winnum);
end

hnd=waitbar(0,'Processing windows...');
for win=1:winnum
    sstart = (win-1)*winshf;

    [ARr,Vr]=mvar_estimate(dat(:,(sstart+1):(sstart+winlen),:),p,meth_num,mv);

    if mv.incl_instant
        [ARb0,ARb,Vb]=instant_caus_sub1(ARr,Vr);
        [s(:,:,:,win),h(:,:,:,win),a(:,:,:,win)]=mult_ar_calc(ARb,Vb,frqmin,frqmax,1/fs);
    else
        [s(:,:,:,win),h(:,:,:,win),a(:,:,:,win)]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1/fs);
    end
    if mv.sAR
        AR_tot(:,:,:,win)=ARr;
        V_tot(:,:,win)=Vr;
    end
    if docheck
        diagw{win}=mvar_diagnostics(dat(:,(sstart+1):(sstart+winlen),:),ARr,[],[],0,...
            sprintf('window %d',win));
    end
    waitbar(win/winnum);
end
close(hnd);
ARs.coefs=AR_tot;
ARs.V=V_tot;

if docheck
    ARs.diag=[diagw{:}];
    if mvar_diag_verbose(mv)
        mvar_diag_report(ARs.diag,sprintf('%s p=%d,',mv.fname,p));
    end
end
