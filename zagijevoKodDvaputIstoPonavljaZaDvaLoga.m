function varargout = zagijevoKodDvaputIstoPonavljaZaDvaLoga(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @zagijevoKodDvaputIstoPonavljaZaDvaLoga_OpeningFcn, ...
                   'gui_OutputFcn',  @zagijevoKodDvaputIstoPonavljaZaDvaLoga_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before zagijevoKodDvaputIstoPonavljaZaDvaLoga is made visible.
function zagijevoKodDvaputIstoPonavljaZaDvaLoga_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for zagijevoKodDvaputIstoPonavljaZaDvaLoga
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = zagijevoKodDvaputIstoPonavljaZaDvaLoga_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;
%################################################################################################################
% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)

[File_Name, Path_Name] = uigetfile('*.PNG');
J = imread(fullfile(Path_Name, File_Name));
guidata(hObject,handles); 
imshow(J);

Igray = rgb2gray(J); 
[rows cols] = size(Igray);
Idilate = Igray; %% Dilate and Erode Image in order to remove noise
for i = 1:rows
for j = 2:cols-1
temp = max(Igray(i,j-1), Igray(i,j));
 Idilate(i,j) = max(temp, Igray(i,j+1));
end
end
I = Idilate;





difference = 0;
sum = 0;
total_sum = 0;
difference = uint32(difference);
%% PROCESS EDGES IN HORIZONTAL DIRECTION
max_horz = 0;
maximum = 0;
for i = 2:cols
sum = 0;
for j = 2:rows
if(I(j, i) > I(j-1, i))
difference = uint32(I(j, i) - I(j-1, i));
else
difference = uint32(I(j-1, i) - I(j, i));
end
if(difference > 20)
sum = sum + difference;
end
end
horz1(i) = sum;
% Find Peak Value
if(sum > maximum)
max_horz = i;
maximum = sum;
end
total_sum = total_sum + sum;
end
average = total_sum / cols;

%% Smoothen the Horizontal Histogram by applying Low Pass Filter
sum = 0;
horz = horz1;
for i = 21:(cols-21)
sum = 0;
for j = (i-20):(i+20)
sum = sum + horz1(j);
end
horz(i) = sum / 41;
end

%% Filter out Horizontal Histogram Values by applying Dynamic Threshold
disp('Filter out Horizontal Histogram...');
for i = 1:cols
if(horz(i) < average)
horz(i) = 0;
for j = 1:rows
I(j, i) = 0;
end
end
end

%% PROCESS EDGES IN VERTICAL DIRECTION
difference = 0;
total_sum = 0;
difference = uint32(difference);
disp('Processing Edges Vertically...');
maximum = 0;
max_vert = 0;
for i = 2:rows
sum = 0;
for j = 2:cols %cols
if(I(i, j) > I(i, j-1))
difference = uint32(I(i, j) - I(i, j-1));
end
if(I(i, j) <= I(i, j-1))
difference = uint32(I(i, j-1) - I(i, j));
end
if(difference > 20)
sum = sum + difference;
end
end
vert1(i) = sum;
%% Find Peak in Vertical Histogram
if(sum > maximum)
max_vert = i;
maximum = sum;
end
total_sum = total_sum + sum;
end
average = total_sum / rows;

%% Smoothen the Vertical Histogram by applying Low Pass Filter
disp('Passing Vertical Histogram through Low Pass Filter...');
sum = 0;
vert = vert1;
for i = 21:(rows-21)
sum = 0;
for j = (i-20):(i+20)
sum = sum + vert1(j);
end
vert(i) = sum / 41;
end

%% Filter out Vertical Histogram Values by applying Dynamic Threshold
disp('Filter out Vertical Histogram...');
for i = 1:rows
if(vert(i) < average)
vert(i) = 0;
for j = 1:cols
I(i, j) = 0;
end
end
end


%% Find Probable candidates for Number Plate
j = 1;
for i = 2:cols-2
if(horz(i) ~= 0 && horz(i-1) == 0 && horz(i+1) == 0)
column(j) = i;
column(j+1) = i;
j = j + 2;
elseif((horz(i) ~= 0 && horz(i-1) == 0) || (horz(i) ~= 0 && horz(i+1) == 0))
column(j) = i;
j = j+1;
end
end
j = 1;
for i = 2:rows-2
if(vert(i) ~= 0 && vert(i-1) == 0 && vert(i+1) == 0)
row(j) = i;
row(j+1) = i;
j = j + 2;
elseif((vert(i) ~= 0 && vert(i-1) == 0) || (vert(i) ~= 0 && vert(i+1) == 0))
row(j) = i;
j = j+1;
end
end
[temp column_size] = size (column);
if(mod(column_size, 2))
column(column_size+1) = cols;
end
[temp row_size] = size (row);
if(mod(row_size, 2))
row(row_size+1) = rows;
end
%% Region of Interest Extraction
%Check each probable candidate
for i = 1:2:row_size
for j = 1:2:column_size
% If it is not the most probable region remove it from image
if(~((max_horz >= column(j) && max_horz <= column(j+1)) && (max_vert >=row(i) && max_vert <= row(i+1))))
%This loop is only for displaying proper output to User
positionsRow(i)=row(i);
 positionsCols(j)=column(j);


for m = row(i):row(i+1)
   
for n = column(j):column(j+1)
 
I(m, n) = 0;
end
end
end
end
end
  imshow(I);
x=1;
y=1;
for x=1:rows
   for y=1:cols
       
       if(I(x,y)~=0)
           
           pikselix(x)=x;
           pikseliy(y)=y;
           
       end
    
   end
end
pikselix(pikselix==0)=NaN;
pikseliy(pikseliy==0)=NaN;
minx=min(pikselix);
miny=min(pikseliy);

maxx=max(pikselix);
maxy=max(pikseliy);

width=maxy-miny;
widthDivide=width;
height=maxx-minx;

znakx=minx-(2.9*height);
height=height*2.5;
width=width/2;
widthDivide=widthDivide/3.5;

znaky=miny+widthDivide;
rect=[znaky, znakx, width,height];





F=imcrop(J,rect);
carImage=F;
  figure(8),imshow(carImage);

  [rows, columns, numberOfColorChannels1] = size(carImage);
if numberOfColorChannels1 > 1
        carImage = rgb2gray(carImage);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%MARIN KOD%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%######################################################################
originalLogo = imread('opelLogo.jpg') ;
 logoImage = rgb2gray(originalLogo);
% figure;
% imshow(F);

% title('Image of a Pads box');

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end
    


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);



[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_OPEL(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 
averageDistance=0.86355/3.5;
p=2;
s=1;

boxPairsOpel(1,1)=0;
boxPairsOpel(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_OPEL(i,k)<averageDistance)
           
          boxPairsOpel(s,p)=i;
          boxPairsOpel(s,p+1)=k;
          s=s+1;
           
       
      
        end
       
        
    end
end



 
    
    pairedDotOPEL=size(boxPairsOpel,1);
   
   
%#############################################################
originalLogo = imread('audiRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);


[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
       logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_AUDI(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;


p=2;
s=1;

boxPairsAudi(1,1)=0;
boxPairsAudi(1,2)=0;
for i=1:m
    for k=1:g
        
        if(EUD_AUDI(i,k)<averageDistance)
           
          boxPairsAudi(s,p)=i;
          boxPairsAudi(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end







    
    pairedDotAUDI=size(boxPairsAudi,1);
%################################################################
originalLogo = imread('skodaRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end



logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_SKODA(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;

p=2;
s=1;

boxPairsSkoda(1,1)=0;
boxPairsSkoda(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_SKODA(i,k)<averageDistance)
           
          boxPairsSkoda(s,p)=i;
          boxPairsSkoda(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotSKODA=size(boxPairsSkoda,1);
%#######################################################################
originalLogo = imread('vwLogo.jpg') ;
logoImage = rgb2gray(originalLogo);
% figure;
% imshow(logoImage);

% title('Image of a Pads box');

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end
% figure;
% imshow(carImage);
% title('Image of a Cluttered desk scene');


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_VW(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;

p=2;
s=1;

boxPairsVW(1,1)=0;
boxPairsVW(1,2)=0;
for i=1:m
    for k=1:g
        
        if(EUD_VW(i,k)<averageDistance)
           
          boxPairsVW(s,p)=i;
          boxPairsVW(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotVW=size(boxPairsVW,1);
%#######################################################################

%##############################################CITROEN#########################
originalLogo = imread('citroenRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_CITROEN(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;
p=2;
s=1;

boxPairsCitroen(1,1)=0;
boxPairsCitroen(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_CITROEN(i,k)<averageDistance)
           
          boxPairsCitroen(s,p)=i;
          boxPairsCitroen(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotCitroen=size(boxPairsCitroen,1);

%###############################################################FiAT########
originalLogo = imread('fiatRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_Fiat(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;
p=2;
s=1;

boxPairsFiat(1,1)=0;
boxPairsFiat(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_Fiat(i,k)<averageDistance)
           
          boxPairsFiat(s,p)=i;
          boxPairsFiat(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotFiat=size(boxPairsFiat,1);
%#######################################################################
originalLogo = imread('mazdaRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);


[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
   logoImage = originalLogo;
end



logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_Mazda(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;
p=2;
s=1;

boxPairsMazda(1,1)=0;
boxPairsMazda(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_Mazda(i,k)<averageDistance)
           
          boxPairsMazda(s,p)=i;
          boxPairsMazda(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotMazda=size(boxPairsMazda,1);
    
    
    %#######################################################################
originalLogo = imread('nissanRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
       logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end



logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_Nissan(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;
p=2;
s=1;

boxPairsNissan(1,1)=0;
boxPairsNissan(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_Nissan(i,k)<averageDistance)
           
          boxPairsNissan(s,p)=i;
          boxPairsNissan(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotNissan=size(boxPairsNissan,1);
    
    %#######################################################################
originalLogo = imread('renaultRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);

[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end



logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);




[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_Renault(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;

p=2;
s=1;

boxPairsRenault(1,1)=0;
boxPairsRenault(1,2)=0;

for i=1:m
    for k=1:g
        
        if(EUD_Renault(i,k)<averageDistance)
           
          boxPairsRenault(s,p)=i;
          boxPairsRenault(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotRenault=size(boxPairsRenault,1);
    
    %#######################################################################
originalLogo = imread('toyotaRealLogo.jpg') ;
logoImage = rgb2gray(originalLogo);


[rows, columns, numberOfColorChannels] = size(originalLogo);
if numberOfColorChannels > 1
        logoImage = rgb2gray(originalLogo);
else
    % It's already gray scale.  No need to convert.
    logoImage = originalLogo;
end


logoBoxPoints = detectSURFFeatures(logoImage);
carBoxPoints = detectSURFFeatures(carImage);



[carboxFeatures, carboxPoints] = extractFeatures(logoImage, logoBoxPoints); %caboxFeatures su Feature vektori tj. deskriptori a carboxPoints su njihove lokacije
                                                                            %logoImage je slika a logoBoxPoints njezini SURFPoints
[carFeatures, carBoxPoints] = extractFeatures(carImage, carBoxPoints);

[m n]=size(carboxFeatures);
[g h]=size(carFeatures);

for i=1:m
    for k=1:g
        euclid=0;
         for j=1:n
       
        
             
           
           euclid=euclid+(carboxFeatures(i,j)-carFeatures(k,j))^2;
             EUD_Toyota(i,k)=sqrt(euclid);
         end
             
           
     end
        
       
        
        
 end
  

 

averageDistance=0.86355/3.5;

p=2;
s=1;

boxPairsToyota(1,1)=0;
boxPairsToyota(1,2)=0;
for i=1:m
    for k=1:g
        
        if(EUD_Toyota(i,k)<averageDistance)
           
          boxPairsToyota(s,p)=i;
          boxPairsToyota(s,p+1)=k;
          s=s+1;
           
        end
       
        
    end
end






    
    pairedDotToyota=size(boxPairsToyota,1);
    




maxNumberOfPairedDots1 = max(pairedDotOPEL, pairedDotAUDI);
maxNumberOfPairedDots2 = max(pairedDotSKODA, pairedDotVW);
maxNumberOfPairedDots3 = max(pairedDotCitroen, pairedDotFiat);
maxNumberOfPairedDots4 = max(pairedDotMazda, pairedDotNissan);
maxNumberOfPairedDots5 = max(pairedDotRenault, pairedDotToyota);

handles.maxMax1 = max(maxNumberOfPairedDots1, maxNumberOfPairedDots2);
handles.maxMax2 = max(maxNumberOfPairedDots3, maxNumberOfPairedDots4);
handles.maxMax3 = max(handles.maxMax1, handles.maxMax2);
handles.maxMax4 = max(maxNumberOfPairedDots5, handles.maxMax3);


if handles.maxMax4 == pairedDotOPEL
    f = msgbox('Opel');
else end
if handles.maxMax4 == pairedDotAUDI
    f = msgbox('Audi');
else end
if handles.maxMax4 == pairedDotSKODA
    f = msgbox('�koda');
else end
 if handles.maxMax4 == pairedDotVW
    f = msgbox('Volkswagen');
 else end
 if handles.maxMax4 == pairedDotCitroen
    f = msgbox('Citroen');
else end
if handles.maxMax4 == pairedDotFiat
    f = msgbox('Fiat');
else end
if handles.maxMax4 == pairedDotMazda
    f = msgbox('Mazda');
else end
if handles.maxMax4 == pairedDotNissan
    f = msgbox('Nissan');
else end
if handles.maxMax4 == pairedDotRenault
    f = msgbox('Renault');
else end
if handles.maxMax4 == pairedDotToyota
    f = msgbox('Toyota');
else end

