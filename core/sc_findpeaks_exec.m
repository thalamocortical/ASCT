function sc_findpeaks_exec(inFile, outFile)
    % in.mat:  data - signal
    %          args - cell with argument - value pairs
    %          nOut - number of outputs
    % out.mat: out  - cell {1 x nOut}

    load(inFile, 'data', 'args', 'nOut');
    out = cell(1, nOut);
    [out{:}] = findpeaks(data, args{:});     % args unpack into regular funciton arguemnts
    save(outFile, 'out');
end