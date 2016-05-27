function [x,X,freq,ex,cf] = multisine(harm, Hampl, options)
%MULTISINE - Multisine Excitation Signal generation.
%   [x,Xs,freqs,Xt,freqt] = multisine(harmonics, Hamp, options)
%
% HARMONICS = parameter set concerning the excited harmonics
%   <>.fs     : Sampling frequency in Hz
%   <>.fl/.fh : Lowest/Highest frequency lines
%   <>.df     : Spectral lines density
%   <>.fr     : Quasi-logarithmic freq ration
% AMPLITUDE = vectors of transfer functions with input ampl spectrum
% OPTIONS = parameter set containing multisine design options
%   <>.itp    : Initial phase type - 's' schroeder / 'r' random
%   <>.ctp    : Compression type   - 'c' compressed / 'n' non-compressed
%   <>.gtp    : Grid spacing type  - 'l' linear / 'q' quasi-logarithmic
%   <>.dtp    : Density type       - 'f' full / 'o' odd / 'O' odd-odd
% OUTPUT = time/frequency information of designed multisine signal
%   <>.x/X    : time and frequency data of multisine
%   <>.freq   : measured frequency lines of multisine
%   <>.ex     : index of excited frequency lines
%   <>.cf     : Crest factor of the different signals
% Author      : Thomas Beauduin, KULeuven, PMA division, 2014
%%%%%
nrofi = size(Hampl,2);              % Number of inputs
nl = ceil(harm.fl/harm.df)+1;       % Lowest frequency number
nh = round(harm.fh/harm.df)+1;      % Highest frequency number
nrofs = ceil(harm.fs/harm.df);      % Number of time domain samples
df = harm.fs/nrofs;                 % Spectral density of signal
if mod(nrofi,2)~=0, options.otp = 'o'; itp = 'r';
else                options.otp = 'e'; itp = options.itp;
end

% Calculation of Excited Harmonics
switch options.dtp
    case {'f','full'},    ex = (1:1:nh);
    case {'o','odd'},     ex = (1:2:nh);
    case {'O','odd-odd'}, ex = (1:4:nh);
end
idx = find(ex <= nl);
switch options.gtp
    case {'l','lin'},     ex = ex(max(idx):end);
    case {'q','qlog'},    ex = lin2qlog(ex(max(idx):end),harm.fr);
end

% Calculation of Optimized Spectrum
R = zeros(nrofi,nrofi,nh);
E = zeros(nrofi,nh);
for i=1:nrofi
    w = 1i*2*pi*df*(0:1:nrofs/2-1)';
    X = zeros(nh,1); w = w(1:nh);
    [Bn,An] = tfdata(Hampl(i),'v');
    Mag = abs(polyval(Bn,w)./polyval(An,w));
    X(ex) = Mag(ex);
    for j=1:nrofi
        if i == 1
            E(j,:) = msinl2p(X,nrofs,itp);
        end
        R(i,j,:) = abs(X).*exp(1i*angle(E(j,:)'));
    end
end

% Calculation of Orthogonal Transform
T = zeros(nrofi,nrofi,nh);
switch options.otp
    case {'e','even'}, T = hadamard(nrofi);
    case {'o','odd'},  T = orthogonal(nrofi);
end
T = repmat(T,[1,1,nh]);

% Calculation of Multisine Signal
S = zeros(nrofi,nrofi,nrofs);
S(:,:,(1:nh)) = R.*T;
s = 2*real(ifft(S,[],3));
rms = mean(abs(s.^2),3).^0.5;
x = s ./ repmat(rms, [1,1,nrofs]);
X = fft(x,[],3)/sqrt(nrofs);
X = X(:,:,1:nrofs/2);
freq = harm.fs*(0:1:nrofs/2-1)'/nrofs;

% Calculation of Crest Factors
cf = zeros(nrofi,nrofi);
for i=1:nrofi
    for j=1:nrofi
        C = squeeze(S(i,j,:)); c = f2t(C,nrofs);
        cf(i,j) = lpnorm(c,inf)./effval(C,ex);
    end
end

end