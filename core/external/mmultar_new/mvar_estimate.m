function [A,V]=mvar_estimate(dat,p,meth_num,mv)
% MVAR_ESTIMATE  Fit a MVAR model with the estimator selected in the GUI.
%
%   [A,V]=mvar_estimate(dat,p,meth_num,mv)
%
%   dat      - data, chans x npts x trials
%   p        - model order
%   meth_num - estimator code (the METHODS table of the LICZ_* functions):
%                1  correlation (Yule-Walker)
%                2  modified correlation
%                4  covariance (forward least squares)
%                8  LWR - multichannel Levinson-Wiggins-Robinson lattice
%   mv       - multar values structure (normalization flags)
%
%   A - coefficients chans x chans x p,  x(t) = sum_k A(:,:,k)*x(t-k) + e(t)
%   V - residual covariance matrix, chans x chans
%
%   Codes 1,2,4 go through COUNTCORR / COUNTCOV and the normal equations;
%   code 8 goes to LWR, a lattice algorithm that keeps separate forward and
%   backward predictors.  Code 8 used to mean the modified covariance method
%   (COUNTCOV with iwhat=8), which assumes the backward coefficients equal the
%   forward ones - true only for time-reversible processes, and badly violated
%   by directed couplings.  That branch of COUNTCOV is still in the file but is
%   no longer reached from the pipeline.
%
%   All four estimators accept multitrial data: LWR fits one model to all the
%   trials, accumulating the innovation covariances across them.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(dat,1);

if meth_num==8
    % Same normalization that COUNTCORR applies internally, so that every
    % method sees the same data (matters in short-time mode, where the window
    % mean is removed window by window).  Loop bounds come from the actual size
    % of the array, not from mv.chans / mv.recl.
    d=dat;
    nt=size(d,2);
    tr=size(d,3);
    if isfield(mv,'norm0') && mv.norm0
        mnd=mean(d,2);
        for tt=1:tr
            for cc=1:chans
                d(cc,:,tt)=d(cc,:,tt)-mnd(cc,1,tt);
            end
        end
    end
    if isfield(mv,'norm1') && mv.norm1
        sdd=std(d,0,2);
        for tt=1:tr
            for cc=1:chans
                d(cc,:,tt)=d(cc,:,tt)/sdd(cc,1,tt);
            end
        end
    end
    if isfield(mv,'norm2') && mv.norm2 && tr>1
        mnd=mean(d,3);
        for nn=1:nt
            for cc=1:chans
                d(cc,nn,:)=d(cc,nn,:)/mnd(cc,nn,:);
            end
        end
    end
    [A,V]=lwr(d,p);
    return
end

if meth_num<4
    [rleft,rright,r]=countCorr(dat,p,meth_num,mv);
else
    [rleft,rright,r]=countCov(dat,p,meth_num);
end
xres=linsolve(rleft,rright);
mip=chans*p;
V=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,r,chans);
AR=reshape(xres,[chans p chans]);
A=permute(AR,[3 1 2]);
