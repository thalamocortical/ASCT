function mvar_diag_report(d,label)
% MVAR_DIAG_REPORT  Print the MVAR goodness-of-fit diagnostics.
%
%   mvar_diag_report(d)        - d is one structure returned by MVAR_DIAGNOSTICS
%   mvar_diag_report(darr)     - darr is an array/cell array of such structures
%                                (e.g. one per short-time window or per trial);
%                                a compact summary over all of them is printed
%   mvar_diag_report(d,label)  - prepend a label to the header
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if nargin<2, label=''; end
if iscell(d)
    d=[d{:}];
end

if numel(d)>1
    n=numel(d);
    mx=zeros(1,n); pv=zeros(1,n); fo=zeros(1,n);
    for i=1:n
        mx(i)=d(i).stability.max_modulus;
        pv(i)=d(i).whiteness.p_LiMcLeod;
        fo(i)=d(i).whiteness.frac_out;
    end
    alpha=d(1).whiteness.alpha;
    unst=find(mx>=1);
    nonw=find(pv<=alpha);
    fprintf('\n--- MVAR diagnostics, %d fits %s---\n',n,[label ' ']);
    fprintf('  order p=%d, channels=%d, residual points per fit=%d\n',...
        d(1).p_order,d(1).chans,d(1).whiteness.N);
    fprintf('  stability : max|eig| in [%.4f %.4f], unstable fits: %d of %d',...
        min(mx),max(mx),numel(unst),n);
    if ~isempty(unst)
        fprintf('  -> %s',mat2str(reshape(unst,1,[])));
    end
    fprintf('\n');
    fprintf('  whiteness : Li-McLeod p in [%.4g %.4g], rejected (p<=%.3g) in %d of %d fits',...
        min(pv),max(pv),alpha,numel(nonw),n);
    if ~isempty(nonw) && numel(nonw)<=20
        fprintf('  -> %s',mat2str(reshape(nonw,1,[])));
    end
    fprintf('\n');
    fprintf('  acf points outside the 95%% band: mean %.1f%% (expected ~5%%)\n',100*mean(fo));
    if isempty(unst) && isempty(nonw)
        fprintf('  VERDICT: all fits stable, residual whiteness not rejected.\n');
    else
        fprintf('  VERDICT: %d fit(s) unstable, %d fit(s) with non-white residuals - check model order / window length / stationarity.\n',...
            numel(unst),numel(nonw));
    end
    fprintf('\n');
    return
end

st=d.stability;
wh=d.whiteness;
hdr=d.label;
if ~isempty(label), hdr=[label ' ' hdr]; end
fprintf('\n--- MVAR diagnostics %s---\n',[hdr ' ']);
fprintf('  model     : p=%d, channels=%d, %d point(s) x %d trial(s), %d coefficients, %.1f data points per coefficient\n',...
    d.p_order,d.chans,d.npts,d.trials,d.n_param,d.pts_per_param);
if d.pts_per_param<10
    fprintf('              WARNING: fewer than 10 data points per coefficient - risk of overfitting\n');
end
if st.stable
    verd='STABLE';
else
    verd='UNSTABLE';
end
fprintf('  stability : max|eig(companion)|=%.4f  ->  %s (margin %.4f, %d eigenvalue(s) outside)\n',...
    st.max_modulus,verd,st.margin,st.n_outside);
if st.stable && st.margin<0.02
    fprintf('              WARNING: root very close to the unit circle - model nearly non-stationary\n');
end
if wh.white
    verd='white residuals (H0 not rejected)';
else
    verd='residuals NOT white';
end
fprintf('  whiteness : lags h=%d, df=%d, N=%d residual points\n',wh.h,wh.df,wh.N);
fprintf('              Li-McLeod Q=%.1f, p=%.4g  ->  %s at alpha=%.3g\n',...
    wh.LiMcLeod,wh.p_LiMcLeod,verd,wh.alpha);
fprintf('              Hosking   Q=%.1f, p=%.4g\n',wh.Hosking,wh.p_Hosking);
fprintf('              acf values outside +-%.4f band: %.1f%% (expected ~5%%)\n',...
    wh.acf_band,100*wh.frac_out);
if ~isempty(wh.chan_nonwhite)
    fprintf('              channels with non-white residuals (Ljung-Box, df=%d): %s\n',...
        wh.df_chan,mat2str(reshape(wh.chan_nonwhite,1,[])));
end
fprintf('              max |instantaneous residual correlation| = %.3f\n',wh.max_abs_inst);
if d.ok
    fprintf('  VERDICT   : model acceptable - stable and residuals indistinguishable from white noise.\n');
else
    fprintf('  VERDICT   : model questionable - increase the order / shorten the window / check stationarity\n');
    fprintf('              before interpreting the spectrum, DTF, PDC etc.\n');
end
fprintf('\n');
