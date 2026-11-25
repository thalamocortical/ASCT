function st=mvar_stability(A)
% MVAR_STABILITY  Stability (stationarity) test of a fitted MVAR model.
%
%   st=mvar_stability(A)
%
%   A - MVAR coefficients, chans x chans x p (field ARs.coefs),
%       model x(t) = sum_k A(:,:,k)*x(t-k) + e(t)
%
%   st.eigenvalues - eigenvalues of the companion matrix, (chans*p) x 1
%   st.max_modulus - largest modulus of an eigenvalue
%   st.stable      - 1 when max_modulus < 1, otherwise 0
%   st.margin      - 1 - max_modulus, distance from the unit circle
%   st.n_outside   - number of eigenvalues with modulus >= 1
%
%   The process is stable (and the estimated model stationary) when all the
%   roots of det(I - sum_k A_k z^k)=0 lie OUTSIDE the unit circle, which is
%   equivalent to all eigenvalues of the companion matrix lying INSIDE it.
%   max_modulus very close to 1 (say > 0.98) signals a model on the verge of
%   instability - typically non-stationary data, too high a model order, or
%   too short a data window; spectra and DTF/PDC computed from such a model
%   are unreliable.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(A,1);
p=size(A,3);

F=zeros(chans*p,chans*p);
for k=1:p
    F(1:chans,(k-1)*chans+1:k*chans)=A(:,:,k);
end
if p>1
    F(chans+1:end,1:chans*(p-1))=eye(chans*(p-1));
end

ev=eig(F);
st.eigenvalues=ev;
st.max_modulus=max(abs(ev));
st.stable=double(st.max_modulus<1);
st.margin=1-st.max_modulus;
st.n_outside=sum(abs(ev)>=1);
