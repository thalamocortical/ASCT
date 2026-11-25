function fun=licz_smtmvarBaseln(dat,mv,plev)
% estimates baseline for selected functions
% in short-time mode
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
bootnum=mv.basenum;

chans=size(dat,1);
dlug=size(dat,2);
trials=size(dat,3);

METHODS=[1,2,4,8];
meth_num = METHODS(method);

if isempty(winlen)
    winlen = dlug-winnum*winshf;
    if winlen<=0
        disp('Illegal window length');
        fun=[];
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
        fun=[];
        return
    end
end
[winlen winshf winnum]

fnumbs=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);
global FVL
fun_tot = zeros(FUNS,chans,chans,FRQPMAX,bootnum);
fun = zeros(FUNS,chans,chans,length(plev),winnum);

hnd=waitbar(0,'Calculating baseline...');
dat2=zeros(chans,winlen,trials);

fid=fopen('bootfil.dat','ab');

for win=1:winnum
    sstart = (win-1)*winshf;
    dat1=dat(:,(sstart+1):(sstart+winlen),:); % window extracted
    for boot=1:bootnum
        for ic=1:chans
            for it=1:trials
                dat2(ic,:,it)=dat1(ic,randperm(winlen),it); % window shuffled
            end
        end
        [ARr,Vr]=mvar_estimate(dat2,p,meth_num,mv);

        [s0,h0,a0]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1./fs);
        for funcnum=1:FUNS
            fun_tot(funcnum,:,:,:,boot)=FVL{fnumbs(funcnum)}.f(s0,h0,a0,0);
        end

        waitbar(((win-1)*bootnum+boot)/winnum/bootnum);

    end
    if win==1 disp(size(fun_tot)); end
    fwrite(fid,fun_tot(:),'float32');
    fun(:,:,:,:,win)=prctile(reshape(fun_tot,[FUNS,chans,chans,FRQPMAX*bootnum]),plev,4);
    waitbar(win/winnum);
end
fclose(fid);
close(hnd);
