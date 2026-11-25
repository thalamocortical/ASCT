% C Author: Rafal Kus <rkus@fuw.edu.pl>, (C) 2005
% C CORRELCOV computes covariance matrices needed by 
% C covariance and modificated covariance alorithms, which estimates
% C Multivariate Autoregressive Model's coefficients.
function [rleft_tot,rright_tot,r_tot]=countCorr(x,ip,iwhat,mv)

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
    lc=mv.chans;
    for tt=1:trials
        for cc=1:lc
            x(cc,:,tt)=x(cc,:,tt)-mnd(cc,1,tt);
        end
    end
end
if mv.norm1
    sdd=std(x,0,2);
    lc=mv.chans;
    for tt=1:trials
        for cc=1:lc
            x(cc,:,tt)=x(cc,:,tt)/sdd(cc,1,tt);
        end
    end
end
if mv.norm2 
    if trials>1
        mnd=mean(x,3);
        % Loop bounds come from the actual size of x (m channels, n points),
        % not from mv.chans / mv.recl: in short-time mode x is a single window
        % shorter than mv.recl, and the old bound ran past the end of the array.
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
rleft_tot=zeros(mip,mip);
rright_tot=zeros(mip,m);
r_tot=zeros(m,m);

for trial=1:trials
    for k=1:ip
        if iwhat==1
            corrscale=1/n;
            nn=n-k;
            %disp([1,m,nn,k+1,k+nn-1+1])
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
            %disp(r)
        elseif iwhat==2
            corrscale=1/(n-k);
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        end

        %disp([2,k,m,(k-1)*m+1,(k-1)*m+1+m-1]);
        rright((k-1)*m+1:(k-1)*m+1+m-1,:)=r(:,:);

        if k<ip
            for i=1:ip-k
                %disp([3,k,m,(k+i-1)*m+1,(k+i-1)*m+1+m-1,(i-1)*m+1,(i-1)*m+1+m-1]);
                rleft((k+i-1)*m+1:(k+i-1)*m+1+m-1,(i-1)*m+1:(i-1)*m+1+m-1)=r(:,:);
                %disp([4,k,m,(i-1)*m+1,(i-1)*m+1+m-1,(k+i-1)*m+1,(k+i-1)*m+1+m-1]);
                rleft((i-1)*m+1:(i-1)*m+1+m-1,(k+i-1)*m+1:(k+i-1)*m+1+m-1)=r(:,:)';
            end
        end
    end

    corrscale=1/n;
    %disp([5,m,n]);
    r(:,:)=DGEMM_symul('N','T',m,m,n,corrscale,x(:,:,trial),m,x(:,:,trial),m,0,0,m);

    for k=1:ip
        %disp([6,k,m,(k-1)*m+1,(k-1)*m+1+m-1,(k-1)*m+1,(k-1)*m+1+m-1]);
        rleft((k-1)*m+1:(k-1)*m+1+m-1,(k-1)*m+1:(k-1)*m+1+m-1)=r(:,:);
    end

    rleft_tot=rleft_tot+rleft;
    rright_tot=rright_tot+rright;
    r_tot=r_tot+r;
end

if trials>1
    rleft_tot=rleft_tot/trials;
    rright_tot=rright_tot/trials;
    r_tot=r_tot/trials;
end
