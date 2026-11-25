function p=mvar_chi2sf(x,v)
% MVAR_CHI2SF  Upper tail probability of the chi-square distribution.
%
%   p=mvar_chi2sf(x,v)  returns p = P(X > x) for X ~ chi2 with v degrees
%   of freedom.  Implemented with GAMMAINC (core MATLAB), so the
%   Statistics Toolbox is NOT required.
%
%   x - statistic value(s), any size
%   v - degrees of freedom (scalar, v > 0)
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

p=ones(size(x));
if v<=0
    p(:)=NaN;
    return
end
ix=(x>0) & isfinite(x);
p(ix)=gammainc(x(ix)/2,v/2,'upper');
p(isnan(x))=NaN;
