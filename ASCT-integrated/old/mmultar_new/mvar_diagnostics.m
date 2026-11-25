function d=mvar_diagnostics(dat,A,h,alpha,verbose,label)
% MVAR_DIAGNOSTICS  Goodness-of-fit diagnostics of a fitted MVAR model:
%                   residual whiteness and model stability.
%
%   d=mvar_diagnostics(dat,A)
%   d=mvar_diagnostics(dat,A,h,alpha,verbose,label)
%
%   dat     - data used for the fit, chans x npts x trials
%   A       - MVAR coefficients chans x chans x p (field ARs.coefs)
%   h       - highest lag of the portmanteau tests (default, see MVAR_WHITENESS)
%   alpha   - significance level, default 0.05
%   verbose - 1 (default) print a short report, 0 keep silent
%   label   - string added to the printed report (file name, window number...)
%
%   d.stability - output of MVAR_STABILITY (companion matrix eigenvalues)
%   d.whiteness - output of MVAR_WHITENESS (portmanteau tests)
%   d.V_res     - residual covariance matrix computed from the residuals
%   d.ok        - 1 when the model is stable AND the whiteness hypothesis is
%                 not rejected; this is the single flag to look at before
%                 interpreting spectra, DTF, PDC etc.
%   d.label, d.p_order, d.chans, d.npts, d.trials, d.n_param, d.pts_per_param
%                 - bookkeeping; pts_per_param = trials*npts/(p*chans^2) should
%                   be comfortably above 10, otherwise the fit is overfitted
%
%   See also MVAR_RESIDUALS, MVAR_WHITENESS, MVAR_STABILITY, MVAR_DIAG_REPORT.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if nargin<3, h=[]; end
if nargin<4 || isempty(alpha), alpha=0.05; end
if nargin<5 || isempty(verbose), verbose=1; end
if nargin<6, label=''; end

chans=size(dat,1);
npts=size(dat,2);
trials=size(dat,3);
p=size(A,3);

[res,Vres]=mvar_residuals(dat,A);

d.label=label;
d.chans=chans;
d.npts=npts;
d.trials=trials;
d.p_order=p;
d.n_param=p*chans*chans;
d.pts_per_param=trials*npts/d.n_param;
d.V_res=Vres;
d.stability=mvar_stability(A);
d.whiteness=mvar_whiteness(res,p,h,alpha);
d.ok=double(d.stability.stable && d.whiteness.white);

if verbose
    mvar_diag_report(d);
end
