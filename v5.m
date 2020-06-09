clc;
close all;
clear;

% Ke = 123456789;
% Kw = 123456;
% data = ['This is the message to be embedded. '...
%     'This is the continuation of the same message.\n'...
%     'This is a really long message to check the amount of problems in the word hiding. \n'...
%     'The size of the message is limited to around 512*512/8 characters in the string.\n'...
%     'This string should be fully decipherable and should be shown in the command Window.\n\n'];

% img = imread('./images/hands1.jpg');
% img = imread('./images/satellite.png');
% img = imread('./images/airplane.pgm');

[file,path]=uigetfile('*.pgm','Select image file');
ss=strcat(path,file);
img=imread(ss);

%% Image Standardisation %%
if size(img,3) == 3
    I = rgb2gray(img);
end
I = img;
I = imresize(I,[512 512]);
I = double(I);
figure('Name','Original Image','NumberTitle','off');
imshow(uint8(I));

%% Preprocess Prediction Error %%

Iinv = bitset(I,8,~bitget(I,8));
% figure('Name','I inverse','NumberTitle','off');
% imshow(uint8(Iinv));

pred = zeros(512);
In=zeros(512);
% error = zeros(512);
for ii = 1:512
    for jj = 1:512
        if ii == 1 || jj == 1
            pred(ii,jj) = I(ii,jj);
        else
            pred(ii,jj) = floor((pred(ii-1,jj) + pred(ii,jj-1))/2);
        end
        delta = abs(pred(ii,jj) - I(ii,jj));
        deltainv = abs(pred(ii,jj) - Iinv(ii,jj));
        if(delta >= deltainv)
            if(I(ii,jj)<128)
                In(ii,jj) = pred(ii,jj) - 63;
            else
                In(ii,jj) = pred(ii,jj) + 63;
            end
        else
            In(ii,jj) = I(ii,jj);
        end
        pred(ii,jj) = In(ii,jj);
    end
end
% figure('Name','Prediction Corrected vs Original','NumberTitle','off');
% imshow(In~=I,[]);

%% Encryption %%

Ke = inputdlg({'Enter the Key for Encrypting Image'},'Image Encryption Key',[1,35],{'123456789'});
Ke = str2double((cell2mat(Ke)));
seed = Ke;
rng(seed,'twister');
S = randi(255,512);

Ie = bitxor(S,In);
figure('Name','Encrypted Image','NumberTitle','off');
imshow(uint8(Ie));

%% Data Embedding %%

data = inputdlg({'Enter the Data to be Embedded'},'Embedding Data',[5,35],{'This is the data to be embedded'});
data = (cell2mat(data));

M = [data, (zeros(1,floor(512*512/8) - numel(data)))];

Kw = inputdlg({'Enter the Key for Encrypting Word'},'Word Encryption Key',[1,35],{'123456'});
Kw = str2double((cell2mat(Kw)));
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

Iew = Ie;
m=0;
for ii = 2:512
    for jj = 2:512
        Iew(ii,jj) = bitset(Iew(ii,jj),8,Me(m+1));
        m = m + 1;
    end
end

figure('Name','Encrypted Image with hidden word','NumberTitle','off');
imshow(uint8(Iew));

%% Extraction %%
%% Message Extraction %%

m = 0;
Me = zeros([1 512*512]);
for ii = 2:512
    for jj = 2:512
        Me(m+1) = bitget(Iew(ii,jj),8);
        m = m + 1;
    end
end

Me = Me(1:261120); %% floor((512*512-512-511)/8)*8

Kw = inputdlg({'Enter the Key for Decrypting Word'},'Word Decryption Key',[1,35],{'123456'});
Kw = str2double((cell2mat(Kw)));
seed = Kw;
rng(seed,'twister');
S = randi(255,[1,numel(Me)/8]);

Me = Me + 48;
Me = char(Me);
Me = reshape(Me,[8,numel(Me)/8]);
Me = Me';
Me = bin2dec(Me);
Me = (Me');
Md = bitxor(Me,S);
Md = char(Md);

fprintf(Md);
fprintf('\n');
msgbox(Md,'Decoded Message');

%% Image Extraction %%

Ke = inputdlg({'Enter the Key for Decrypting Image'},'Image Decryption Key',[1,35],{'123456789'});
Ke = str2double((cell2mat(Ke)));
seed = Ke;
rng(seed,'twister');
S = randi(255,512);
Id = bitxor(S,Iew);
% figure('Name','Decoded Image','NumberTitle','off');
% imshow(uint8(Id));

%figure('Name','Correcting the Decoded Image','NumberTitle','off');
for ii = 2:512
    for jj  = 2:512
        predictor = floor((Id(ii-1,jj) + Id(ii,jj-1))/2);
        Id0m = bitset(Id(ii,jj),8,0);
        Id1m = bitset(Id(ii,jj),8,1);
        delta0 = abs(predictor - Id0m);
        delta1 = abs(predictor - Id1m);
        if delta0 < delta1
            Id(ii,jj) = bitset(Id(ii,jj),8,0);
        else
            Id(ii,jj) = bitset(Id(ii,jj),8,1);
        end
    end
%     imshow(uint8(Id));
end


% figure('Name','Predicted','NumberTitle','off');
% imshow(uint8(pred));

figure('Name','Corrected Decoded Image','NumberTitle','off');
imshow(uint8(Id));

figure('Name','Id vs I Uncorrected','NumberTitle','off')
imshow(((Id~=I)),[]);

%% PSNR and SSIM

img_processed = Id;
img_original = I;
psnrval = psnr(img_processed,img_original,255);
ssimval = ssim(img_processed,img_original);
fprintf('psnr = %2.2f dB \nssim = %1.5f \n',psnrval,ssimval);
msgbox({['PSNR =  ',num2str(psnrval),' dB'],['SSIM =  ',num2str(ssimval)]},'PSNR and SSIM');
