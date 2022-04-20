close all; clearvars; clc;

fs = 64;
T  = 10;
N  = T*fs;

t = (0:N-1)/fs;
x = 3.0 * cos(2*pi*0.9*t) + ...
    1.5 * cos(2*pi*1.8*t) + ...
    0.7 * cos(2*pi*2.7*t) + ...
    0.4 * cos(2*pi*3.6*t);
xn = x + 1.2*randn(size(x));

xn = xn - mean(xn);

X = fft(xn);
P2 = abs(X)/N;
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs * (0:(N/2))/N;
fq = fs * (0:0.1:(N/2))/N;
P1q = interp1(f, P1, fq, 'linear');

% Cadence likelihood estimation
f_res = 0.01;
f_test = (0.4:0.01:4.0);
CL = zeros(1,length(f_test));
indx_10Hz = round(10/0.01)+1;
for i = 1:length(f_test)
    indx_ff = round(f_test(i)/f_res)+1; % index of fundamental frequency
    indx_hf = (1:4)*(indx_ff-1) + 1;    % index of harmonics
    indx_hhf= round((1.5:3.5)*(indx_ff-1)) + 1; % index of half-harmonics
    
    % Create comb filter
    h = zeros(size(fq));
    h(indx_hf)  = 1;
    h(indx_hhf) = -1;

    % Element-wise multiplication
    CL_ = P1q .* h;
    CL(i) = sum(CL_(1:indx_10Hz));
end

figure;
plot(f_test, CL, 'b');


figure;
ax1 = subplot(2, 2, [1, 2]);
hold on; grid minor;
plot(ax1, t, x, 'Color', [0, 0, 1, 0.2], 'LineWidth', 2);
plot(ax1, t, xn, 'Color', [0, 0, 1], 'LineWidth', 0.8)
xlabel('time / s'); ylabel('amplitude / V');

ax3 = subplot(2, 2, 3);
hold on; grid minor;
stem(f, P1, 'Color', [0, 0, 1, 0.2]);
plot(fq, P1q, 'Color', [1, 0, 0]);
xlim([0, max(f)]);
xlabel('frequency / Hz');
ylabel('amplitude / V');