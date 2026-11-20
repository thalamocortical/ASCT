function [res,V,N]=mvar_residuals(dat,A)
% MVAR_RESIDUALS  One-step prediction errors (residuals) of a fitted MVAR model.
%
%   [res,V,N]=mvar_residuals(dat,A)
%
%   dat - data, chans x npts x trials (the same array that was used for the fit,
%         i.e. after the normalizations applied in MULTAR1M)
%   A   - MVAR coefficients, chans x chans x p  (field ARs.coefs),
%         model convention of the package:
%              x(t) = sum_k A(:,:,k)*x(t-k) + e(t)
%
%   res - residuals, chans x (npts-p) x trials; residuals are computed
%         separately for every trial, the first p points of each trial are
%         skipped so that no residual mixes data across trial boundaries
%   V   - residual covariance matrix estimated from res, chans x chans
%         (comparable with ARs.V returned by the estimator)
%   N   - total number of residual time points, trials*(npts-p)
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(dat,1);
npts=size(dat,2);
trials=size(dat,3);
p=size(A,3);

if npts<=p
    error('mvar_residuals: data length (%d) not greater than model order (%d)',npts,p);
end
if size(A,1)~=chans || size(A,2)~=chans
    error('mvar_residuals: coefficient array does not match the number of channels');
end

res=zeros(chans,npts-p,trials);
for tr=1:trials
    x=dat(:,:,tr);
    e=x(:,p+1:npts);
    for k=1:p
        e=e-A(:,:,k)*x(:,p+1-k:npts-k);
    end
    res(:,:,tr)=e;
end

N=trials*(npts-p);
R=reshape(res,chans,N);
V=(R*R')/N;
