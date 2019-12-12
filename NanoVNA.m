% NanoVNA control program for Octave and MatLAB
% Author: Paul Fredette, K1YBE
% Copyright 2019 All rigths reserved
% Features
% 1. setup serial link
% 2. Sweep bands and collect Frequency snd S11  srrays
% Bands might include .9-900Khz, 900Khz - 9MHz, 9MhZ-90MHz, 90MHz-900MHz
% Log mag = 20*log(abs(D))
% SWR = (1+abs(D))./(1-abs(D))
% Phase in degrees = angle(D)*180/pi 
% 50 ohm Zo Impedance 
% R+jX: Z = 50*(1+D)./(1-D)  

pkg load instrument-control

if (exist("serial") != 3)
    disp("No Serial Support");
endif 
 
            
% info at https://www.edn.com/design/analog/4440674/Read-serial-data-directly-into-Octave
% Instantiate the Serial Port
% Naturally, set the COM port # to match your device
% Use this crazy notation for any COM port number: 1 - 255
s1 = serial("\\\\.\\COM3");   % Open the port of the NanoVNA
pause(1);                    % Optional wait for device to wake up
%  The open above will fail if the port is already open - K1YBE
% Set the port parameters

set(s1, 'baudrate', 9600);     % See List Below
set(s1, 'bytesize', 8);        % 5, 6, 7 or 8
set(s1, 'parity', 'n');        % 'n' or 'y'
set(s1, 'stopbits', 1);        % 1 or 2
set(s1, 'timeout' , 50 );       %  5.0 sec timeout
get(s1, 'baudrate');

%function reference
% https://octave.sourceforge.io/instrument-control/overview.html
% Optional Flush input and output buffers
srl_flush(s1);


function [char_array] = ReadToTermination(srl_handle, term_char)
 % parameter term_char is optional, if not specified
 % then CR = '\r' = 13dec is the default.
if(nargin == 1)
 term_char = 13;
end
not_terminated = true;
i = 1;
int_array = uint8(1);
while not_terminated
 val = srl_read(srl_handle, 1);
 if(val == term_char)
 not_terminated = false;
 end

 % Add char received to array
 int_array(i) = val;
 i = i + 1;
end

 % Change int array to a char array and return a string array
 char_array = char(int_array);
endfunction

%Write example
% n = srl_write (s1, "sweep 1000000 100000000 101\r\n");
%Read
% [data, count] = srl_read (s1, n); %reads echo of command line as an n integer array
% datastring = char(data); % command line as string
% datastring = ReadToTermination(s1,13);  % replace datatring with result is any
% may require line by line and could be added to to the ReadToTermination func.

function npts = band(s1,f1, f2, points)
   % parameter "points" is optional, set to 101 if not specified
   % Plan is to return an array of numbers [F, S11, SWR, Z]
   % for now--- n= number of points; S11 and Z are complex
npts=-1  
if(nargin == 3)
  npts = 101; %default
  else n=points;
end
if(npts == 0)   
   npts = -1; 
   return; 
end
if(npts > 101)
    npts = -1; 
    return; 
end

srl_flush(s1);
F=[];
%Set a specific band - HF 3Mhz to 900 Mhz
n = srl_write (s1, ["sweep " num2str(f1) " " num2str(f2) " " num2str(npts) "\r\n"]  );
  datastring=ReadToTermination(s1,10) % read echo from command line

n = srl_write (s1, "frequencies\r\n"); % get frequency array
  datastring=ReadToTermination(s1,10) % read echo from command line
  %[data, count] = srl_read (s1, n+1); % reads back command line as integer array
point = 1;
while point != (npts+1)

  % Read lines and convert to a Frequency array
  datastring=ReadToTermination(s1);
  F(point) = str2num(datastring);
  point = point + 1;
endwhile
F(1)
F(point-1)
% LOOP:  Repeat from here to refresh the data

 srl_flush(s1);
 
 D=[];
%Read a set of measurement vectors   x y

n = srl_write (s1, "data\r\n");
  datastring=ReadToTermination(s1,10)
  %[data, count] = srl_read (s1, n+1); % reads back command line as integer array
point = 1;
while point != npts+1

  % Read lines and convert to a complex array
    datastring=ReadToTermination(s1,32); % Read to a space
    Dr = str2num(datastring);
    datastring=ReadToTermination(s1,10); %Read remainder of line
    Di = str2num(datastring);
  D(point) = Dr + i*Di;
  point = point + 1;
endwhile
D(1)
D(point-1)
   subplot (3,1,1, "align");
   semilogx(F,20*log(abs(D))); % log mag S11 (Ch0)
    ylabel (sprintf ("LOG MAG S11"));
    xlabel (sprintf ("Frequency(Hz)"));
    title (sprintf ("NanoVNA ( %d points)", point-1));
    grid on
    
    subplot (3,1,2, "align");
    semilogx(F,angle(D)*180/pi) % phase S11
    ylabel (sprintf ("Phase S11"));
    xlabel (sprintf ("Frequency(Hz)"));
    title (sprintf ("NanoVNA ( %d points)", point-1));
    grid on;
    
    subplot (3,1,3, "align");
    semilogx(F,(1+abs(D))./(1-abs(D)))  % SWR
    ylabel (sprintf ("SWR"));
    xlabel (sprintf ("Frequency(Hz)"));
    title (sprintf ("NanoVNA ( %d points)", point-1));
    grid on;
 endfunction
 
 posnum = band(s1,3000000,300000000); 
 print ("HFandVHF.pdf", "-dpdf");
  
 %  HF Ham band edges follow...
  posnum = band(s1,1800000, 2000000);   % 160m
  print ("160M.pdf", "-dpdf");
 posnum = band(s1,3500000, 4000000);   % 80m
  print ("80M.pdf", "-dpdf");
 posnum = band(s1,5330000, 5403000);   % 60m
   print ("60M.pdf", "-dpdf");
 posnum = band(s1,7000000, 7300000);   % 40m  
  print ("40M.pdf", "-dpdf"); 
 posnum = band(s1,10100000, 10150000); % 30m
   print ("30M.pdf", "-dpdf");
 posnum = band(s1,14000000, 14350000); % 20m
   print ("20M.pdf", "-dpdf");
 posnum = band(s1,18068000, 18158000); % 17m
   print ("17M.pdf", "-dpdf");
 posnum = band(s1,21000000, 21450000); % 15m
   print ("15M.pdf", "-dpdf");
 posnum = band(s1,24890000, 24990000);  % 12m
   print ("12M.pdf", "-dpdf");
 posnum = band(s1,28000000, 29700000); % 10m
  print ("10M.pdf", "-dpdf");
 fclose(s1),  % Close the serial port to the program can be run again
 
 %  single plot code  
 %  plot(F,20*log(abs(D))), % log mag S11 (Ch0)   
 %  plot(F,angle(D)*180/pi) % phase S11
 %  plot(F,(1+abs(D))./(1-abs(D)))  % SWR
% Menus
%menuLevel1  = {" Analysis ", " Options  ", " View Mins"};
%menuBands   = {"All", "160M", "80M", "60M", "40M", "30M", "20M", "17M", "15M", "12M", "10M"};
%menuResults = {"Table"};
%menuLevel2  = {"New Scan", "Repeat", "Frequency"};
%menuFile    = {"Save Scan", "View Plot", "View Table", "Overlay", "Serial", "Delete File"};

%    >> strcmp("60M",menuBands)
%      0  0  0  1  0  0  0  0  0  0  0

 
 
 fclose(s1);  % Close the serial port to the program can be run again


 
 %   
 %  plot(F,20*log(abs(D))); % log mag S11 (Ch0)   
 %  plot(F,angle(D)*180/pi) % phase S11
 %  plot(F,(1+abs(D))./(1-abs(D)))  % SWR


 %srl_flush(s1);

