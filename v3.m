clc;
close all;
clear;

Ke = 123456789;
Kw = 123456;
M = ['This is the message to be embedded. '...
    'This is the continuation of the same message.\n'...
    'This is a really long message to check the amount of problems in the image. \n'...
    'The size of the message is limited to 512*512/8 characters in the string.\n'...
    'This string has only half that many characters when we create 30 copies of this string.\n'...
    'So only half of the image will be distorted because of the problems in the word embeding.\n'...
    'This string should be fully decipherable and will be shown in the command Window.\n\n'];
M = [M M M M M M M M M M M M M M M];

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

% M = [M zeros(1,floor(512*512/8) - numel(M))];
seed = Kw;
rng(seed,'twister');
S = randi(255,[1,numel(M)]);

M = double(M);
Me = bitxor(M,S);
Me = Me';
Me = dec2bin(Me);
Me = Me';
Me = reshape(Me,[1,numel(Me)]);
Me = double(Me);
Me = Me - 48;

% % % % % Me = [Me zeros(1,512*512-numel(Me))]; 
Me = [Me bitget(Ie(numel(Me)+1:512*512),8)]; 
Me = reshape(Me,512,512);
Iew = bitset(Ie,8,Me);

% % 
% % Iew = Ie;
% % m=0;
% % for ii = 1:512
% %     for jj = 1:512
% %         Iew(ii,jj) = bitset(Iew(ii,jj),8,Me(m+1));
% %         m = m + 1;
% %         if(m >= numel(Me))
% %             break;
% %         end
% %     end
% %     if(m >= numel(Me))
% %         break;
% %     end
% % end
% % % % Me = reshape(Me,[512,512]);
% % 
% % % % Iew = bitset(Ie,8,Me);
% % % Iew = Ie;
% % % figure('Name','Encrypted Image with hidden word','NumberTitle','off');
% % % imshow(uint8(Iew));

%% Data Extraction %%
%% Message Extraction %%

% % % Me = bitget(Iew,8);
% % 
% % m = 0;
% % for ii = 1:512
% %     for jj = 1:512
% %         Me(m+1) = bitget(Iew(ii,jj),8);
% %         m = m + 1;
% %         if(m >= numel(Me))
% %             break;
% %         end
% %     end
% %     if(m >= numel(Me))
% %         break;
% %     end
% % end

Me = bitget(Iew,8);
Me = reshape(Me,1,512*512);
% Me = Me(1:find(Me,1,'last'));
Me = Me(1:(numel(M)*8));

seed = Kw;
rng(seed,'twister');
S = randi(255,[1,numel(M)]);

Me = Me + 48;
Me = char(Me);
Me = reshape(Me,[8,numel(Me)/8]);
Me = Me';
Me = bin2dec(Me);
%     Me = Me(1:numel(S));
Me = (Me');
Md = bitxor(Me,S);
Md = char(Md);

fprintf(Md);

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
% figure('Name','Decoded with 0 MSB','NumberTitle','off');
% imshow(uint8(Id0m));
Id1m = bitset(Id,8,1);
% figure('Name','Decoded with 1 MSB','NumberTitle','off');
% imshow(uint8(Id1m));

delta0 = abs(pred - Id0m);
delta1 = abs(pred - Id1m);

errorloc = (delta0 >= delta1);

Id = bitset(Id,8,errorloc);
% Id = bitset(Id,8,bitget(I,8));
figure('Name','Corrected Decoded Image','NumberTitle','off');
imshow(uint8(Id));

figure('Name','Uncorrected')
imshow(bitxor(errorloc,bitget(I,8)),[])