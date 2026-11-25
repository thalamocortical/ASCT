function [Pxx, F] = sc_welchPSD(x, win, Fs)
% Base-MATLAB replacement for:
%   psd(spectrum.welch('Hamming',win,0), x, 'NFFT',win, 'Fs',Fs)
% Welch: Hamming window, 0 overlap, NFFT = win, one-sided PSD.

    x = x(:);
    n = (0:win-1)';
    w = 0.54 - 0.46*cos(2*pi*n/(win-1));          % Hamming window (= hamming(win))

    nSeg = floor(numel(x)/win);                   % number of non-overlapping segments
    idx  = (1:win)' + (0:nSeg-1)*win;             % win x nSeg segment indices
    X    = fft(x(idx) .* w, win);                 % windowed FFT of each segment

    P    = mean(abs(X).^2, 2) / (Fs * sum(w.^2)); % averaged, scaled periodogram

    nHalf = floor(win/2) + 1;                     % one-sided spectrum
    Pxx  = P(1:nHalf);
    k    = 2:nHalf - (mod(win,2)==0);             % double all except DC (and Nyquist)
    Pxx(k) = 2*Pxx(k);

    F    = (0:nHalf-1)' * Fs/win;                 % frequency axis
end