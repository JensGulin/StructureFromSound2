clear
close all
path = 'processed_data/music4/';
load([path, 'data_struct.mat']);
m1 = 4; % first microphone index
m2 = 7; % second microphone index
win_len = 2048; %gcc-phat window size

[s1, fs] = audioread([path, 'Track ', mat2str(m1), '.wav']);
s2 = audioread([path, 'Track ', mat2str(m2), '.wav']);

k = 6; % decimation factor. I use 6 to get 16kHz
s1 = decimate(s1, k);
s2 = decimate(s2, k);

t = sfs.time(1:k:end);
mic1 = sfs.mics{m1} * 0.001;
mic2 = sfs.mics{m2} * 0.001;
speaker = sfs.speaker * 0.001;
tdoa = (sqrt(sum((speaker - mic1).^2, 2)) - sqrt(sum((speaker - mic2).^2, 2))) * fs / 343;
tdoa = tdoa(1:k:end) / k;

%% Estimate tdoa using gcc-phat

t_samp = t * fs / k;

tau_hat = zeros(length(t), 1);
for i = 1:length(t_samp)

   this_t = round(t_samp(i));
   y1 = s1(this_t:this_t+win_len-1);
   y2 = s2(this_t:this_t+win_len-1);

   % compute gcc-phat
   Y1 = fft(y1);
   Y2 = fft(y2);
   C = Y1 .* conj(Y2);
   C = C ./ (abs(C)+0.0001);
   c = fftshift(ifft(C));
   [m, max_i] = max(c);

   tau_hat(i) = max_i - win_len/2;

end

figure
plot(tdoa)
hold on
plot(tau_hat, '*')
legend('ground truth', 'estimate')

acc = mean(abs(tau_hat - tdoa) < 5, 'omitnan')