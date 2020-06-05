clc;
close all;
clear;

Ke = 123456789;
Kw = 123456;
M = 'This is the message to be embedded.';

img = imread('./images/airplane.pgm');

%% Image Standardisation %%

% I = rgb2gray(img);
I = img;
I = imresize(I,[512 512]);
I = double(I);
figure('Name','Original Image','NumberTitle','off');
imshow(uint8(I));

%% Preprocess Prediction Error %%

% Iinv = mod((I + 128),256);
Iinv = bitset(I,8,~bitget(I,8));

% figure('Name','I inverse');
% imshow(Iinv);
pred = zeros(512);
pred(1,:) = I(1,:);
pred(:,1) = I(:,1);
for ii = 2:512
    for jj  = 2:512
        pred(ii,jj) = ceil((I(ii-1,jj) + I(ii,jj-1))/2);
    end
end

delta = abs(pred - I);
figure('Name','Delta')
imshow(uint8(delta));
deltainv = abs(pred - Iinv);
figure('Name','Delta inv')
imshow(uint8(deltainv));
for ii = 1:512
    for jj = 1:512
        if(delta(ii,jj) >= deltainv(ii,jj))
            display([ii jj]);
            if(I(ii,jj)<128)
                I(ii,jj) = pred(ii,jj) - 63;
            else
                I(ii,jj) = pred(ii,jj) + 63;
            end
        end
    end
end
figure('Name','Prediction Corrected');
imshow(uint8(I))

%% Encryption %%

seed = Ke;
rng(seed,'twister');
S = randi(255,512);
% % % % % pe(i, j) = XOR(s(i, j), p(i, j))
Ie = bitxor(S,I);
% figure('Name','Encrypted Image','NumberTitle','off');
% imshow(uint8(Ie));

% % % % % Id = bitxor(S,Ie);
% % % % % figure('Name','Decoded Image','NumberTitle','off');
% % % % % imshow(uint8(Id));

%% Data Embedding %%

M = [M zeros(1,floor(511*511/8) - numel(M))];
seed = Kw;
rng(seed,'twister');

S = randi(255,[1,numel(M)]);
M = double(M);
Me = bitxor(M,S);
Me = dec2bin(Me);
Me = reshape(Me,[1,numel(Me)]);
Me = [Me zeros(1,511*511 - numel(Me))];
Me = reshape(Me,[511,511]);
Me = Me - 48;



% % % % % Me = Me + 48;
% % % % % Me = char(Me);
% % % % % Me = reshape(Me,32768,8);
% % % % % Me = bin2dec(Me);
% % % % % Me = uint8(Me');
% % % % % Md = bitxor(uint8(Me),S);
% % % % % Md = char(Md)

% % % pew(i, j) = bk * 128 + (pe(i, j) mod 128).
% % % Iew = uint8((uint16(Me) .* 128) + mod(Ie,128));

Iew = zeros(512);
Iew(1,:) = Ie(1,:);
Iew(:,1) = Ie(:,1);
Iew(2:512,2:512) = bitset(Ie(2:512,2:512),8,Me);
% Iew = bitset(Ie,8,Me);
% Iew = Ie;
% figure('Name','Encrypted Image with hidden word','NumberTitle','off');
% imshow(uint8(Iew));

% seed = Ke;
% rng(seed,'twister');
% S = randi(255,512);
% Id = bitxor(S,Ie);
% figure('Name','Decoded Image','NumberTitle','off');
% imshow(uint8(Id));


%% Data Extraction %%
%% Message Extraction %%

% % % Me = Iew./128;
Me = bitget(Iew(2:512,2:512),8);

seed = Kw;
rng(seed,'twister');
S = randi(255,[1,numel(M)]);

Me = Me + 48;
Me = reshape(Me,[1,numel(Me)]);
Me = Me(1:floor(511*511/8)*8);
Me = char(Me);
Me = reshape(Me,floor(511*511/8),8);
Me = bin2dec(Me);
Me = (Me');
Md = bitxor(Me,S);
Md = char(Md);
display(Md);

%% Image Extraction %%

seed = Ke;
rng(seed,'twister');
S = randi(255,512);
Id = bitxor(S,Iew);
figure('Name','Decoded Image','NumberTitle','off');
imshow(uint8(Id));

pred = zeros(512);
pred(1,:) = Id(1,:);
pred(:,1) = Id(:,1);
for ii = 2:512
    for jj  = 2:512
        pred(ii,jj) = ceil((Id(ii-1,jj) + Id(ii,jj-1))/2);
    end
end

Id0m = bitset(Id,8,0);
Id1m = bitset(Id,8,1);

delta0 = abs(pred - Id0m);
delta1 = abs(pred - Id1m);

errorloc = (delta0 < delta1);

Id = bitset(Id,8,~errorloc);
% Id = bitset(Id,8,bitget(I,8));
figure('Name','Corrected Decoded Image','NumberTitle','off');
imshow(uint8(Id));
