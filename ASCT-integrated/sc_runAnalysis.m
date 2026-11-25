% SC_RUNANALYSIS Run the ordinary ASCT pipeline or an optional multiverse.
% Call this script at the end of an ExSetup. Existing sc_initAnalysis calls
% remain supported. Keep the original singleverse workspace semantics.
if ~exist('multiverse','var') || ~isfield(multiverse,'mode') || ...
        strcmpi(multiverse.mode,'single')
    sc_initAnalysis;
elseif strcmpi(multiverse.mode,'multi')
    addpath(fullfile(fileparts(mfilename('fullpath')),'multiverse'));
    asctSetup=struct('rc',rc,'chan',chan,'filter',filter,'seg',seg, ...
        'ar',ar,'ica',ica,'loc',loc,'con',con,'design',design);
    if exist('begId','var'), asctSetup.begId=begId; end
    if exist('endId','var'), asctSetup.endId=endId; end
    if exist('simul','var'), asctSetup.simul=simul; end
    results=asct_multiverse_realdata(asctSetup,multiverse);
else
    error('ASCT:InvalidMode','multiverse.mode must be single or multi');
end
