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

Iinv = bitset(I,8,~bitget(I,8));
% figure('Name','I inverse');
% imshow(uint8(Iinv));

pred = zeros(512);
pred(1,:) = I(1,:);
pred(:,1) = I(:,1);
for ii = 2:512
    for jj  = 2:512
        pred(ii,jj) = floor((I(ii-1,jj) + I(ii,jj-1))/2);
    end
end

delta = abs(pred - I);
figure('Name','Delta')
imshow(uint8(delta));
deltainv = abs(pred - Iinv);
figure('Name','Delta inv')
imshow(uint8(deltainv));
In=zeros(512);
for ii = 1:512
    for jj = 1:512
        if(delta(ii,jj) >= deltainv(ii,jj))
            fprintf('[ %d %d ]\n',ii,jj);
            if(I(ii,jj)<128)
                In(ii,jj) = pred(ii,jj) - 63;
            else
                In(ii,jj) = pred(ii,jj) + 63;
            end
        else
            In(ii,jj) = I(ii,jj);
        end
    end
end
figure('Name','Prediction Corrected');
imshow(uint8(In))

%% Encryption %%

seed = Ke;
rng(seed,'twister');
S = randi(255,512);

Ie = bitxor(S,In);
% figure('Name','Encrypted Image','NumberTitle','off');
% imshow(uint8(Ie));

%% Data Embedding %%

M = [M zeros(1,floor(512*512/8) - numel(M))];
seed = Kw;
rng(seed,'twister');

S = randi(255,[1,numel(M)]);
M = double(M);
Me = bitxor(M,S);
Me = dec2bin(Me);
Me = reshape(Me,[512,512]);
Me = Me - 48;

Iew = bitset(Ie,8,Me);
% Iew = Ie;
% figure('Name','Encrypted Image with hidden word','NumberTitle','off');
% imshow(uint8(Iew));

%% Data Extraction %%
%% Message Extraction %%

Me = bitget(Iew,8);

seed = Kw;
rng(seed,'twister');
S = randi(255,[1,numel(Me)/8]);

Me = Me + 48;
Me = char(Me);
%     Me = Me(1:find(Me, 1, 'last')); 
Me = reshape(Me,numel(Me)/8,8);
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
        pred(ii,jj) = floor((Id(ii-1,jj) + Id(ii,jj-1))/2);
    end
end

Id0m = bitset(Id,8,0);
Id1m = bitset(Id,8,1);

delta0 = abs(pred - Id0m);
delta1 = abs(pred - Id1m);

errorloc = (delta0 >= delta1);

Id = bitset(Id,8,errorloc);
% Id = bitset(Id,8,bitget(I,8));
figure('Name','Corrected Decoded Image','NumberTitle','off');
imshow(uint8(Id));

figure('Name','Uncorrected')
imshow(bitxor(errorloc,bitget(I,8)),[])