function sc_foofEstim_exec(inFile, outFile)
    % Compiled wrapper for sc_foofEstim (requires Signal Processing Toolbox at compile time)
    % in.mat:  sig_temp, trialLength, Fs
    % out.mat: pk, loc, wid, prom

    load(inFile, 'sig_temp', 'trialLength', 'Fs');
    [pk, loc, wid, prom] = sc_foofEstim(sig_temp, trialLength, Fs);   % ORYGINAŁ, bez zmian
    save(outFile, 'pk', 'loc', 'wid', 'prom');
end