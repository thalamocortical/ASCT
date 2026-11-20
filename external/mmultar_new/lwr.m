function [Ahat,V]=lwr(y,p)
% LWR  Multichannel Levinson-Wiggins-Robinson (Morf) lattice estimator of the
%      parameters of a MVAR model.
%
%   [Ahat,V]=lwr(y,p)
%
%   y    - data, chans x npts x trials (trials optional)
%   p    - model order
%
%   Ahat - MVAR coefficients, chans x chans x p, in the convention used by the
%          whole package:   x(t) = sum_k Ahat(:,:,k)*x(t-k) + e(t)
%   V    - covariance matrix of e(t), chans x chans
%
%   The recursion keeps separate normalized forward (A) and backward (B)
%   predictors and a sequence of reflection-coefficient matrices, so unlike the
%   modified covariance method (COUNTCOV with iwhat=8) it does NOT assume that
%   the backward coefficients equal the forward ones.  That assumption only
%   holds for time-reversible processes and fails for directed couplings.
%
%   Several realizations (trials) are supported: one model is fitted to all of
%   them, the innovation covariance matrices entering the reflection
%   coefficients being accumulated across trials.  Products never cross a trial
%   boundary.
%
%   References: Morf, Vieira, Lee, Kailath (1978) IEEE Trans. Geosci. Electron.
%   16:85; Marple, Digital Spectral Analysis, ch. 15.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(y);
chans=sz(1);
npts=sz(2);
if length(sz)>2
    trials=sz(3);
else
    trials=1;
end
if npts<=p+1
    error('lwr: data length (%d) too short for model order %d',npts,p);
end

A=zeros(p+1,p+2,chans,chans);
B=zeros(p+1,p+2,chans,chans);

% Order-0 normalized predictors.  y*y' is used instead of XCORR so that no
% Signal Processing Toolbox is needed, and the sums are divided by the number
% of terms: the reflection coefficients are scale invariant, but V is not, so
% the recursion has to start from a mean square rather than a raw sum of
% squares - otherwise V comes out too large by a factor of about npts.
CA=zeros(chans,chans);
CB=zeros(chans,chans);
for tr=1:trials
    yt=y(:,:,tr);
    CA=CA+yt(:,2:end)*yt(:,2:end)';
    CB=CB+yt(:,1:end-1)*yt(:,1:end-1)';
end
CA=CA/(trials*(npts-1));
CB=CB/(trials*(npts-1));
A(1,1,:,:)=inv(chol(CA,'lower'));
B(1,1,:,:)=inv(chol(CB,'lower'));

for n=0:p-1
    % Normalized innovations of order n, accumulated over trials.  The sums over
    % time are vectorized; ef(:,t)=sum_k A_k*y(:,t-k), eb(:,t)=sum_k B_{n-k}*y(:,t-k).
    ren =zeros(chans,chans);
    rrn =zeros(chans,chans);
    rern=zeros(chans,chans);
    for tr=1:trials
        yt=y(:,:,tr);
        ef=zeros(chans,npts);
        eb=zeros(chans,npts);
        for k=0:n
            Ak=reshape(A(n+1,k+1,:,:),chans,chans);
            Bk=reshape(B(n+1,n-k+1,:,:),chans,chans);
            ef(:,1+k:npts)=ef(:,1+k:npts)+Ak*yt(:,1:npts-k);
            eb(:,1+k:npts)=eb(:,1+k:npts)+Bk*yt(:,1:npts-k);
        end
        EF=ef(:,n+2:npts)';
        EB=eb(:,n+1:npts-1)';
        ren =ren +EF'*EF;
        rrn =rrn +EB'*EB;
        rern=rern+EF'*EB;
    end

    % normalized reflection coefficient of order n+1 (scale invariant, so the
    % number of accumulated terms cancels)
    ron=inv(chol(ren,'lower'))*rern*(inv(chol(rrn,'lower')))';

    % update the normalized predictors
    iPn=inv(chol(eye(chans)-ron*ron' ,'lower'));
    iQn=inv(chol(eye(chans)-ron'*ron ,'lower'));
    for k=0:n+1
        Ak =reshape(A(n+1,k+1,:,:),chans,chans);
        Bk =reshape(B(n+1,k+1,:,:),chans,chans);
        Ack=reshape(A(n+1,n-k+2,:,:),chans,chans);   % A^(n)_{n+1-k}
        Bck=reshape(B(n+1,n-k+2,:,:),chans,chans);   % B^(n)_{n+1-k}
        A(n+2,k+1,:,:)=iPn*(Ak-ron *Bck);
        B(n+2,k+1,:,:)=iQn*(Bk-ron'*Ack);
    end
end

% The recursion yields the NORMALIZED forward predictor of order p:
%     e(t) = sum_{k=0..p} A^(p)_k * y(t-k),   cov(e) = I
% so the model coefficients and the residual covariance follow from
%     Ahat_k = -A0^-1 * A^(p)_k ,   V = A0^-1 * A0^-T
A0=reshape(A(p+1,1,:,:),chans,chans);
Ahat=zeros(chans,chans,p);
for k=1:p
    Ahat(:,:,k)=-(A0\reshape(A(p+1,k+1,:,:),chans,chans));
end
A0i=inv(A0);
V=A0i*A0i';
