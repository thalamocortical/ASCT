function v=mvar_diag_verbose(mv)
% MVAR_DIAG_VERBOSE  Decide whether the MVAR diagnostics report should be
%                    printed in the command window.
%
%   v=mvar_diag_verbose(mv)   returns 1 when at least one function is selected
%   for plotting (any of the pSpect/pCohs/pDTF/pNDTF/pdDTF/pPDC/pffDTF flags),
%   0 otherwise.
%
%   The printed report follows the result windows: with the plotting switched
%   off (batch runs, "save only" runs) the diagnostics are still computed and
%   stored in ARs.diag / ARdiag, but nothing is written to the command window.
%   The computation itself is governed by mv.diagnost, not by this function.
%
% part of the MMULTAR package (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

v=double(~isempty(getfunccalcnumbers(mv)));
