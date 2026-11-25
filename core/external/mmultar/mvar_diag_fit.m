function [d,A,V]=mvar_diag_fit(dat,p,meth_num,mv,verbose,label)
% MVAR_DIAG_FIT  Fit a MVAR model with the package estimator and run the
%                goodness-of-fit diagnostics (whiteness + stability) on it.
%
%   [d,A,V]=mvar_diag_fit(dat,p,meth_num,mv,verbose,label)
%
%   dat      - data chans x npts x trials
%   p        - model order
%   meth_num - estimator code as used by COUNTCORR/COUNTCOV
%              (1 correlation, 2 modified correlation, 4 covariance,
%               8 modified covariance); default 1, the value actually used
%              by LICZ_MTMVAR
%   mv       - the multar values structure (needed by COUNTCORR for the
%              normalization flags)
%   verbose  - 1 (default) print the report
%   label    - string shown in the report header
%
%   d - diagnostics structure (see MVAR_DIAGNOSTICS)
%   A - fitted coefficients chans x chans x p
%   V - residual covariance matrix from the estimator
%
%   Useful on its own, e.g. to check a model before/after choosing the order:
%       mv.pord=7; mvar_diag_fit(dat,7,1,mv);
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if nargin<3 || isempty(meth_num), meth_num=1; end
if nargin<5 || isempty(verbose), verbose=1; end
if nargin<6, label=''; end

chans=size(dat,1);
[A,V]=mvar_estimate(dat,p,meth_num,mv);

d=mvar_diagnostics(dat,A,[],[],verbose,label);
