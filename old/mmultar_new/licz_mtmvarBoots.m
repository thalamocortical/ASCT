%function [fun,AR_tot,H_tot]=licz_mtmvarBoots(dat,mv,plev)
function [fun,ARs]=licz_mtmvarBoots(dat,mv,plev)
% calculates bootstraped percentiles for selected functions
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;
bootnum=mv.bootnum;
bootsiz=mv.bootpool;

chans=size(dat,1);
if length(size(dat))>2
    trials=size(dat,3);
else
    trials=1;
end
if trials==1
    errordlg('Only one trial available for bootstrap');
    fun=[];
    ARs=[];
    return
end

METHODS=[1,2,4,8];
meth_num = METHODS(method);

global FRQPMAX
if bootsiz>trials
    bootsiz=trials;
    disp(sprintf('Bootsrap pool size changed to %d',bootsiz));
    %mv.bootpool=bootsiz;
end

fnumbs=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);
global FVL
fun_boot = zeros(chans,chans,FRQPMAX,FUNS,bootnum);
fun = zeros(chans,chans,FRQPMAX,FUNS,length(plev));
if mv.sAR
    AR_tot=zeros(chans,chans,p,length(plev));
    H_tot=complex(zeros(chans,chans,FRQPMAX,length(plev)));
    V_tot=zeros(chans,chans,length(plev));
    AR_boot=zeros(chans,chans,p,bootnum);
    H_boot=zeros(chans,chans,FRQPMAX,bootnum);
    V_boot=zeros(chans,chans,bootnum);
else
    AR_tot=[];
    H_tot=[];
    V_tot=[];
end


% For methods 1-4 the per-trial correlation matrices are computed once and the
% resamples only average them.  The LWR lattice estimator (meth_num==8) has no
% such representation, so its recursion is recomputed from the resampled trials
% inside the loop - the same resampling, but considerably slower.
if meth_num==8
    rleft_tot=[]; rright_tot=[]; r_tot=[];
elseif meth_num<4
    [rleft_tot,rright_tot,r_tot]=countCorrSav(dat,p,meth_num,mv);
else
    [rleft_tot,rright_tot,r_tot]=countCovSav(dat,p,meth_num);
end
% --- goodness of fit of the model: residual whiteness and stability ---
% (evaluated once for the model fitted to the whole data set, not for the
%  individual bootstrap resamples)
if ~isfield(mv,'diagnost') || mv.diagnost
    mvdiag=mvar_diag_fit(dat,p,meth_num,mv,mvar_diag_verbose(mv),...
        sprintf('%s p=%d',mv.fname,p));
else
    mvdiag=[];
end

hnd=waitbar(0,'Calculating bootstrap...');
for boot=1:bootnum
    ix=m_randint(1,bootnum,[1 bootsiz]);
    %ix=randi([1 bootsiz],[1,bootnum]);
    if meth_num==8
        [ARr,Vr]=mvar_estimate(dat(:,:,ix),p,meth_num,mv);
    else
        rleft=mean(rleft_tot(:,:,ix),3);
        rright=mean(rright_tot(:,:,ix),3);
        r=mean(r_tot(:,:,ix),3);

        xres=linsolve(rleft,rright);
        mip=chans*p;
        Vr=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,r,chans);
        AR=reshape(xres,[chans p chans]);
        ARr=permute(AR,[3 1 2]);
    end

    if mv.incl_instant
        [ARb0,ARb,Vb]=instant_caus_sub1(ARr,Vr);
        [s0,h0,a0]=mult_ar_calc(ARb,Vb,frqmin,frqmax,1/fs);
    else
        [s0,h0,a0]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1/fs);
    end
    for funcnum=1:FUNS
        fun_boot(:,:,:,funcnum,boot)=FVL{fnumbs(funcnum)}.f(s0,h0,a0,0);
    end
    if mv.sAR
        H_boot(:,:,:,boot)=h0;
        if mv.incl_instant
            AR_boot(:,:,:,boot)=ARb;
            V_boot(:,:,boot)=Vb;
        else
            AR_boot(:,:,:,boot)=ARr;
            V_boot(:,:,boot)=Vr;
        end
    end
    waitbar(boot/bootnum);
end
fun(:,:,:,:,:)=prctile(fun_boot,plev,5);
if mv.sAR
    AR_tot=prctile(AR_boot,plev,4);
    H_tot=prctile(H_boot,plev,4);
    V_tot=prctile(V_boot,plev,3);
end
close(hnd);
ARs.coefs=AR_tot;
ARs.H=H_tot;
ARs.V=V_tot;
ARs.diag=mvdiag;
