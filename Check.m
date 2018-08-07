function varargout = Check(varargin)
% A GUI control for Sandbox Proside motor calibration check.
%
% The motors run for steps of equal time and (if calibrated properly)
% distance steps. Measured distances are used to compute the quality of
% instrument calibration.
%
% INPUTS: 
%   varargin{1} = string defining motor to use: 'ProIn', 'ProOut', 'RetIn', 'RetOut'
%   varargin{2} = Parameter A for the above motor
%   varargin{3} = "       " B "                  "
% 
% v1.2  Updated to work with new VB Yalebox control program, namely changed inputs
%
%       NOTE: Direction of motor movement is not tested for each motor and
%       may need to be reset - find SETMOTORDIR to go to the corresponding code
%
% v1.1  Updated to match Calibrate.m v1.1
%       Updated to run new 4-motor apparatus on PC. Updated arguments and log outputs
%       Saves x,N data before and after fitting in case fitting fails
%       Adds HHMM time to saved filenames to avoid overwriting
%
% v1.0  New common code for calibration, variable passing simplified,
%       function  number reduced. Variable names are made generic.
%       Two arguments: 1) either 'Pro' or 'Retro'
%                      2) Pro or Retro structs from Control.m
%       (May 2009) NOT TESTED
%
% v0.4  Wedge velocity control is recoded in terms of two fit parameters (A,B) rather than 
%       The physically real parameters used before which proved too
%       difficult to measure.  Fits are now r==1, and imporvement is
%       expected.
%
% v0.3 Configured for lab computer running linux Redhat Enterprise 5 (working)
%
% v0.2: Full version (pro and retro) with minor simplification to the code.  
%
% v0.1: Proside only
%
%       all variables are stored in MKS for simplicity, but may be
%       displayed in different units in the GUI
%
% Keith Laskowski, Yale University Jan 2009 
%
% GUI produced using MATLAB 'GUIDE' software.  
% Last Modified by GUIDE v2.5 22-May-2009 15:16:25




% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI is opened and variables defined

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Check_OpeningFcn, ...
                   'gui_OutputFcn',  @Check_OutputFcn, ...
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


% ... Opening Function ... %
function Check_OpeningFcn(hObject, eventdata, handles, varargin)
motor=varargin{1}; % string determining Pro/Retro In/Out
% A=varargin{2}; % Calibration parameter A
A=varargin{2}*0.99; % Calibration parameter A
B=varargin{3}; % Calibration parameter B
handles.output = hObject;

% Initialize variables  
current_step=[handles.d1,handles.d2,handles.d3,handles.d4,handles.d5,...
              handles.d6,handles.d7,handles.d8,handles.d9,handles.d10,handles.d11];
step=0;
n=nan(1,10); n(1)=0;
x=[];
t=[];
S=400; %run settings are locally defined only
M=90;
movetime=5; % length of move in s
v=A*(M*10)/S; % compute velocity 
w=@(N) (S*v)/(A^2+4*B*((B/S^2)*N^2+(A/S)*N))^0.5; % derived equations giving w (angular velocity in rev/s) in terms of N
% N=@(t) floor((-A+sqrt(A^2+4*B*v*t))/(2*B/S)); % and N in terms of t
N=@(t) round((-A+sqrt(A^2+4*B*v*t))/(2*B/S)); % and N in terms of t

% initialize indexer
switch motor(1:3)
    case 'Pro' 
        indexer_port='COM1';                    
    case 'Ret' 
        indexer_port='COM2';
    otherwise
        disp('improper arguments to Calibrate.m, exiting...')
        return
end
dir='R'; % 'LAR' is forward for all motors

indexer=serial(indexer_port);
fopen(indexer);
set(indexer,'Terminator','CR')
fprintf(indexer,'%s\n','CPASTEP') % Now the ADR2100 card is configured to step indexer mode
setspeed=sprintf('%s%i','MS',M);
fprintf(indexer,'%s\n',setspeed)

% Update handles structure
All=CompStruct(A,B,M,N,S,current_step,dir,indexer,motor,movetime,n,step,t,v,w,x);
handles.All=All;
guidata(hObject, handles);




% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actions to take following button press: includes the mian fucntion loop
% "Step", as well as funcitons to rewind and exit.

% --- Executes on button press in Step.
function Step_Callback(hObject, eventdata, handles)
[A,B,M,N,S,current_step,dir,indexer,motor,movetime,n,step,t,v,w,x]=DecompStruct(handles.All); % load variables
cm2m=.01;

step=step+1;

% AFTER LAST MOVE: compute results, display and save, return from "step" fuction when competed to ignore "move" code 
if step==length(current_step)
    set(handles.Instructions,'String','Checking Calibration: Please check the figure to ensure the fit is accetable.  If not, please run "Calibrate" to create a new fit')

    % Read in measurements
    x(1)=str2double(get(handles.d1,'String'))*cm2m;
    x(2)=str2double(get(handles.d2,'String'))*cm2m;
    x(3)=str2double(get(handles.d3,'String'))*cm2m;
    x(4)=str2double(get(handles.d4,'String'))*cm2m;
    x(5)=str2double(get(handles.d5,'String'))*cm2m;
    x(6)=str2double(get(handles.d6,'String'))*cm2m;
    x(7)=str2double(get(handles.d7,'String'))*cm2m;
    x(8)=str2double(get(handles.d8,'String'))*cm2m;
    x(9)=str2double(get(handles.d9,'String'))*cm2m;
    x(10)=str2double(get(handles.d10,'String'))*cm2m;
    
    %Adjusting Variables
    nold=n;
    n=[];
    for i=1:length(nold)-1; n(i)=nold(i+1); end % removing the zero from the first cell in n
    for i=2:length(x); 
        x(i)=x(i)+x(i-1); % making x cumulative 
        t(i)=t(i)+t(i-1); % making t cumulative 
    end 
    
    % Producing a "perfect fit"
    perfectx=v*t; % in m
    
    % Plotting
    h=figure; 
    hp=plot(t,x,t,perfectx); title('Distance vs. Time'); xlabel('time (s)'); ylabel('Distance (m)'); legend('Measured','Perfect','Location','SouthEast');
    set(hp(1),'LineStyle','none','Marker','*','MarkerSize',10) % set line style of first data set
    
    % Approximating velocity over each time step
    v_obs=diff(x)./diff(t);
    v_set=ones(size(v_obs))*v;
    
    %Plotting
    h2=figure;
    hp2=plot(t(2:end),v_set,'--',t(2:end),v_obs); title('Velocity vs Time'); xlabel('time (s)'); ylabel('velocity (m/s)'); legend('Set velocity','Measured Velocity')
    set(hp2(2),'LineStyle','none','Marker','*','MarkerSize',10) % set line style of second data set
    
    % Compute, display, and print average and max error in distance and in velocity
    dist_errors=abs(perfectx-x);
    fprintf(1,'%s%g\n','Mean error (distance, m): ',mean(dist_errors))
    fprintf(1,'%s%g\n','Max error (distance, m): ',max(dist_errors))
    
    v_errors=abs(v_set-v_obs);
    fprintf(1,'%s%g\n','Mean error (velocity, m/s): ',mean(v_errors))
    fprintf(1,'%s%g\n','Max error (velocity, m/s): ',max(v_errors))
    fprintf(1,'%s%g\n','Mean error (velocity, %): ',mean(v_errors)*100/v)
    fprintf(1,'%s%g\n','Max error (velocity, %): ',max(v_errors)*100/v)
    
    %save results
    time=datestr(now,'mmm-dd-yyyy_HHMM');
    saveas(h,['C:\Yalebox\Log\',motor,'_Check_Distance_',time,'.fig']) % Save results
    saveas(h2,['C:\Yalebox\Log\',motor,'_Check_Velocity_',time,'.fig'])
    save(['C:\Yalebox\Log\',motor,'_Check_Data_',time,'.mat'], 'n','x','t','v_obs','dist_errors','v_errors','movetime','S','v');
    LOG=fopen('C:\Yalebox\Log\Calibration_Log.txt','at');
    time2=datestr(now,'mm-dd-yy');
    fprintf(LOG,'\n%s%s%s%s',motor,', ','Check, ', time2);
    fclose(LOG);
    ERR=fopen(['C:\Yalebox\Log\',motor,'_Check_Err_',time,'.txt'],'wt');
    fprintf(ERR,'%s%g\n','Mean error (distance, m): ',mean(dist_errors));
    fprintf(ERR,'%s%g\n','Max error (distance, m): ',max(dist_errors));
    fprintf(ERR,'%s%g\n','Mean error (velocity, m/s): ',mean(v_errors));
    fprintf(ERR,'%s%g\n','Max error (velocity, m/s): ',max(v_errors));
    fprintf(ERR,'%s%g\n','Mean error (velocity, %): ',mean(v_errors)*100/v);
    fprintf(ERR,'%s%g\n','Max error (velocity, %): ',max(v_errors)*100/v);
    fclose(ERR);
    
    % reset instructions and exit "step"
    set(handles.Instructions,'String','Check Complete! Hit rewind to reset mylar positions to x=0.')
    return
end

% MAKING EACH MOVE:
time=movetime*step;
move=N(time)-n(step);
loadmove=sprintf('%s%s%05i','LA',dir,move); % Set move length
fprintf(indexer,'%s\n',loadmove); % Load move
fprintf(indexer,'%s\n','QA')
RemStep=str2double(fgetl(indexer));
fprintf(indexer,'%s\n','G') % Begin move
tic % Begin timing

% measure progress and adjust speed
while RemStep>0
    fprintf(indexer,'%s\n','QA')
    RemStep=str2double(fgetl(indexer));
    n(step+1)=move-RemStep+n(step); % n is defined so that n(1)=0, and n(step+1) records the values at the current step.  This is adjusted later in the code.  COnfusing, but it makes the code neater becasue teh first step can be treated the same.
    
    %calculating the angular velocity w as a function of N required to maintain constant v;
    wofN=w(n(step+1));
    
    % rounding wofN properly (to the tens) and reducing by an order of magnitude
    if wofN>1000; disp('M is too high! exiting'); return;
%     elseif wofN>100; wofN=round(wofN/10);
    elseif wofN>100; wofN=ceil(wofN/10);
    elseif wofN<10; disp('M is too low! exiting'); return 
    end
    
    % change motor speed if necessary
    if wofN~=M
        M=wofN;
        fprintf(1,'%s%i\n','Motor speed: ',M)
        setspeed=sprintf('%s%i','MS',M);
        fprintf(indexer,'%s\n',setspeed)
    end
    
    
end

% Move completed, save current data
t(step)=toc;
    
% GUI adjustment
set(current_step(step),'ForegroundColor',[0 0 0])
drawnow

% Update handles structure
All=CompStruct(A,B,M,N,S,current_step,dir,indexer,motor,movetime,n,step,t,v,w,x);
handles.All=All;
guidata(hObject, handles);


% ... Rewind Function ... %
function Rewind_Callback(hObject, eventdata, handles)
n=handles.All.n;
cleanup
N=max(n(isnan(n)==0));
WedgeMove(1,2,N);


% ... Exit Function ... %
function Exit_Callback(hObject, eventdata, handles)
cleanup
clear t
close(gcf)


% Unused Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = Check_OutputFcn(hObject, eventdata, handles) 
%varargout{1} = handles.output;

