function sc_features_exec(inFile, outFile)
    % Compiled wrapper: SPT-dependent features for ALL components of one ICA iteration
    % Uses ORIGINAL sc_eyePeaks and sc_foofEstim -> identical results
    load(inFile, 'sig', 'Fs', 'trialLength', 'nTica');
    nIC = size(sig,1);

    peaks_per_min = zeros(1,nIC); peaksNum = zeros(1,nIC); meanPLoc = nan(1,nIC);
    maxPeak = nan(1,nIC); maxProm = nan(1,nIC); maxWidth = nan(1,nIC);

    for comps = 1:nIC
        sig_temp = sig(comps,:);

        num_peaks_in_window  = sc_eyePeaks(sig_temp, Fs);
        peaks_per_min(comps) = sum(num_peaks_in_window)/(nTica/(60*Fs));

        [pk, loc, wid, prom] = sc_foofEstim(sig_temp, trialLength, Fs);
        peaksNum(comps) = length(pk);
        meanPLoc(comps) = mean(loc);
        if ~isempty(pk)
            maxPeak(comps)  = max(pk);
            maxProm(comps)  = max(prom);
            maxWidth(comps) = max(wid);
        end
    end
    save(outFile, 'peaks_per_min','peaksNum','meanPLoc','maxPeak','maxProm','maxWidth');
end