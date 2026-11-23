
function num_peaks_in_window = sc_eyePeaks(sig_temp,Fs,rc)
    % This function computes bumer of peaks on a signal to estimate the Heart
    % and Eye components. Requires current Signal and Sampling Frequency
    % Returns number of peaks for each 5s window
    %~ MD
    
    % rmpath('/opt/MATbox/emegs3.3/emegs2dLib') % Temporarily disable path to avoid conflicts of matlab native findpeaks with that of Jurgen

    
    hasSPT = license('test','Signal_Toolbox') && ~isempty(ver('signal')) && license('checkout',"Signal_Toolbox");

    if ispc
        fpExe = fullfile(rc.asctdir, 'compiled', 'sc_findpeaks_exec.exe');
    else
        fpExe = fullfile(rc.asctdir, 'compiled', 'run_sc_findpeaks_exec.sh');
    end



    num_peaks_in_window = zeros(round(length(sig_temp)/(5*Fs)),1); % 5s Time windows
    for windows = 1:round(length(sig_temp)/(5*Fs))
        try
            current_window = sig_temp((windows-1)*5*Fs +1:windows*5*Fs);
        catch
            current_window = sig_temp((windows-1)*5*Fs +1:end);
        end


        fpArgs = {'MinPeakHeight', std(current_window)*5};


        if hasSPT % If we have signal processing toolbox ready
            [peaks ,~,~,~] = findpeaks( current_window, fpArgs{:});
            [peaks2,~,~,~] = findpeaks(-current_window, fpArgs{:});
        else
            % --- 1: peaks ---
            tmpIn_1 = [tempname(rc.tmpDir) '.mat'];  tmpOut_1 = [tempname(rc.tmpDir) '.mat'];
            data = current_window;  args = fpArgs;  nOut = 4;
            save(tmpIn_1, 'data', 'args', 'nOut');

            % --- 2: troughs ---
            tmpIn_2 = [tempname(rc.tmpDir) '.mat'];  tmpOut_2 = [tempname(rc.tmpDir) '.mat'];
            data = -current_window;                              % MINUS: doliny
            save(tmpIn_2, 'data', 'args', 'nOut');

            if ispc
                
                cmd_1 = sprintf('"%s" "%s" "%s"', fpExe, tmpIn_1, tmpOut_1);
                cmd_2 = sprintf('"%s" "%s" "%s"', fpExe, tmpIn_2, tmpOut_2);
            else
                cmd_1 = sprintf('GLIBC_TUNABLES=glibc.rtld.execstack=2 "%s" "%s" "%s" "%s"', fpExe, matlabroot, tmpIn_1, tmpOut_1);
                cmd_2 = sprintf('GLIBC_TUNABLES=glibc.rtld.execstack=2 "%s" "%s" "%s" "%s"', fpExe, matlabroot, tmpIn_2, tmpOut_2);
  
            end

            [st_1, out_1] = system(cmd_1);
            if st_1 ~= 0, error('findpeaks exec failed:\n%s', out_1); end
            R_1 = load(tmpOut_1);  delete(tmpIn_1, tmpOut_1);
            [peaks,~,~,~] = R_1.out{:};

            [st_2, out_2] = system(cmd_2);
            if st_2 ~= 0, error('findpeaks exec failed:\n%s', out_2); end
            R_2 = load(tmpOut_2);  delete(tmpIn_2, tmpOut_2);
            [peaks2,~,~,~] = R_2.out{:};
        end

        peaks = [peaks peaks2]; % Concatenate both Peaks and throughts
        warn = warning('query','last');
        if ~isempty(warn)
            warn_id = warn.identifier;
            warning('off',warn_id)
        end
        num_peaks_in_window(windows) = length(peaks); % Gtet peaks in windoiw
    end

    % addpath('/opt/MATbox/emegs3.3/emegs2dLib') % Add path back on

end