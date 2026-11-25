function wh=mvar_whiteness(res,p,h,alpha)
% MVAR_WHITENESS  Portmanteau tests of residual whiteness for a MVAR model.
%
%   wh=mvar_whiteness(res,p,h,alpha)
%
%   res   - residuals, chans x nsamp x trials (output of MVAR_RESIDUALS)
%   p     - order of the fitted MVAR model
%   h     - highest lag entering the portmanteau statistics
%           (default min(max(2*p,20),floor(nsamp/4)), always forced > p)
%   alpha - significance level, default 0.05
%
%   Null hypothesis: the residuals are a white (serially uncorrelated)
%   process, i.e. the model has absorbed the whole linear structure of the
%   data.  A SMALL p-value means the residuals are NOT white and the model
%   (usually its order) is inadequate.
%
%   wh.N            - number of residual time points used
%   wh.h, wh.df     - lags used and degrees of freedom, chans^2*(h-p)
%   wh.LiMcLeod     - Li-McLeod portmanteau statistic
%   wh.p_LiMcLeod   - its p-value, chi2 with wh.df degrees of freedom
%   wh.Hosking      - Hosking (Ljung-Box type) multivariate statistic
%   wh.p_Hosking    - its p-value
%   wh.white        - 1 when p_LiMcLeod > alpha (whiteness not rejected)
%   wh.LB_chan      - per-channel univariate Ljung-Box statistics (chans x 1)
%   wh.p_LB_chan    - their p-values, chi2 with wh.df_chan = h-p
%   wh.chan_nonwhite- indices of channels with p_LB_chan <= alpha
%   wh.acf          - residual autocorrelation functions, chans x h
%   wh.acf_band     - 1.96/sqrt(N), the 95% white-noise band of the acf
%   wh.frac_out     - fraction of acf values falling outside that band
%                     (about 0.05 for white residuals)
%   wh.V            - residual covariance matrix (lag 0)
%   wh.Rinst        - zero-lag (instantaneous) residual correlation matrix
%   wh.max_abs_inst - largest absolute off-diagonal element of Rinst; large
%                     values indicate a common source / volume conduction /
%                     reference effect rather than a directed interaction
%
%   The multivariate statistics use tr(C_l' * C_0^-1 * C_l * C_0^-1), which is
%   invariant under any invertible linear transformation of the residuals; the
%   result is therefore the same for the model with and without the
%   instantaneous term (see INSTANT_CAUS_SUB1).
%
%   Note on the finite-sample behaviour: with the correlation (Yule-Walker)
%   estimator used by default in this package the coefficients are slightly
%   biased in short records, which leaves a small amount of correlation in the
%   residuals; the test is then somewhat liberal (it rejects whiteness a little
%   too often).  Checked by simulation of a known MVAR(3) process: at 4000
%   points per channel the rejection rate at alpha=0.05 was about 0.12, at
%   16000 points about 0.075.  Treat a borderline p-value in a short window as
%   inconclusive rather than as proof of a bad model.
%
%   References: Hosking (1980) J.Am.Stat.Assoc. 75:602-608;
%   Li & McLeod (1981) J.R.Stat.Soc.B 43:231-239;
%   Lutkepohl, New Introduction to Multiple Time Series Analysis, sec. 4.4.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(res,1);
nsamp=size(res,2);
trials=size(res,3);
N=nsamp*trials;

if nargin<4 || isempty(alpha), alpha=0.05; end
if nargin<3 || isempty(h)
    h=min(max(2*p,20),floor(nsamp/4));
end
h=max(h,p+1);
h=min(h,nsamp-1);
if h<=p
    error('mvar_whiteness: residual series too short (%d points) for order %d',nsamp,p);
end

% cross-covariance matrices of the residuals, lags 0..h
% (products never cross a trial boundary)
C=zeros(chans,chans,h+1);
for l=0:h
    S=zeros(chans,chans);
    for tr=1:trials
        e=res(:,:,tr);
        S=S+e(:,l+1:nsamp)*e(:,1:nsamp-l)';
    end
    C(:,:,l+1)=S/N;
end
C0=C(:,:,1);
if rcond(C0)<eps
    C0i=pinv(C0);
else
    C0i=inv(C0);
end

Qbp=0;
Qlb=0;
for l=1:h
    Cl=C(:,:,l+1);
    trl=trace(Cl'*C0i*Cl*C0i);
    Qbp=Qbp+trl;
    Qlb=Qlb+trl/(N-l);
end
Qbp=N*Qbp;        % multivariate Box-Pierce
Qlb=N*N*Qlb;      % Hosking / multivariate Ljung-Box

df=chans*chans*(h-p);

wh.N=N;
wh.chans=chans;
wh.p_order=p;
wh.h=h;
wh.df=df;
wh.alpha=alpha;
wh.BoxPierce=Qbp;
wh.LiMcLeod=Qbp+chans*chans*h*(h+1)/(2*N);
wh.p_LiMcLeod=mvar_chi2sf(wh.LiMcLeod,df);
wh.Hosking=Qlb;
wh.p_Hosking=mvar_chi2sf(Qlb,df);
wh.white=double(wh.p_LiMcLeod>alpha);

% per-channel univariate Ljung-Box on residual autocorrelations
d0=diag(C0);
acf=zeros(chans,h);
for l=1:h
    acf(:,l)=diag(C(:,:,l+1))./d0;
end
lags=1:h;
LB=zeros(chans,1);
for c=1:chans
    LB(c)=N*(N+2)*sum((acf(c,:).^2)./(N-lags));
end
dfc=max(h-p,1);
wh.df_chan=dfc;
wh.LB_chan=LB;
wh.p_LB_chan=mvar_chi2sf(LB,dfc);
wh.chan_nonwhite=find(wh.p_LB_chan<=alpha);
wh.acf=acf;
wh.acf_band=1.96/sqrt(N);
wh.frac_out=mean(abs(acf(:))>wh.acf_band);

% instantaneous residual correlations
wh.V=C0;
sd=sqrt(d0);
wh.Rinst=C0./(sd*sd');
M=abs(wh.Rinst)-eye(chans);
wh.max_abs_inst=max(M(:));
