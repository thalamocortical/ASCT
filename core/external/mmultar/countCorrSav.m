function [rleft_tot,rright_tot,r_tot]=countCorrSav(x,ip,iwhat,mv)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
%
% Per-trial correlation matrices for the bootstrap, counterpart of COUNTCORR.
%
% mv carries the normalization flags (norm0/norm1/norm2) and is applied to the
% data exactly as in COUNTCORR, so that the bootstrap estimates are built from
% the same data as the ordinary ones.  Unlike COUNTCORR the normalization loops
% run over the actual size of x instead of mv.chans / mv.recl; the result is
% identical whenever x is the whole record, and correct also in short-time mode
% where x is a single window shorter than mv.recl.

sdt=size(x);
m=sdt(1);
n=sdt(2);
if length(sdt)>2
    trials=sdt(3);
else
    trials=1;
end

%-------------------------------
if mv.norm0
    mnd=mean(x,2);
    for tt=1:trials
        for cc=1:m
            x(cc,:,tt)=x(cc,:,tt)-mnd(cc,1,tt);
        end
    end
end
if mv.norm1
    sdd=std(x,0,2);
    for tt=1:trials
        for cc=1:m
            x(cc,:,tt)=x(cc,:,tt)/sdd(cc,1,tt);
        end
    end
end
if mv.norm2
    if trials>1
        mnd=mean(x,3);
        for nn=1:n
            for cc=1:m
                x(cc,nn,:)=x(cc,nn,:)/mnd(cc,nn,:);
            end
        end
    end
end
%--------------------

mip=m*ip;

rleft=zeros(mip,mip);
rright=zeros(mip,m);
r=zeros(m,m);
rleft_tot=zeros(mip,mip,trials);
rright_tot=zeros(mip,m,trials);
r_tot=zeros(m,m,trials);

for trial=1:trials
    for k=1:ip
        if iwhat==1
            corrscale=1/n;
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        elseif iwhat==2
            corrscale=1/(n-k);
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        end

        rright((k-1)*m+1:(k-1)*m+1+m-1,:)=r(:,:);

        if k<ip
            for i=1:ip-k
                rleft((k+i-1)*m+1:(k+i-1)*m+1+m-1,(i-1)*m+1:(i-1)*m+1+m-1)=r(:,:);
                rleft((i-1)*m+1:(i-1)*m+1+m-1,(k+i-1)*m+1:(k+i-1)*m+1+m-1)=r(:,:)';
            end
        end
    end

    corrscale=1/n;
    r(:,:)=DGEMM_symul('N','T',m,m,n,corrscale,x(:,:,trial),m,x(:,:,trial),m,0,0,m);

    for k=1:ip
        rleft((k-1)*m+1:(k-1)*m+1+m-1,(k-1)*m+1:(k-1)*m+1+m-1)=r(:,:);
    end

    rleft_tot(:,:,trial)=rleft;
    rright_tot(:,:,trial)=rright;
    r_tot(:,:,trial)=r;
end
