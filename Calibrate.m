function varargout = Calibrate(varargin)
% A GUI control for Sandbox Proside motor calibration.
%
% The motors run for moves of equal #steps. Measured distances are used to
% compute the "thickness" value required to drive the mylar at constant
% velocity.
%
% ARGUMENT: motor to calibrate, possible values are 'ProIn', 'ProOut','RetIn','RetOut'
%
% OUTPUTS: -writes a line to C:\Yalebox\Log\Calibration_Log.txt
%          -saves X, N and fit data to a .mat file
%          -saves fitting figure to a .fig file
%
% v1.1  Updated to run new 4-motor apparatus on PC. Updated arguments and log outputs
%       Saves x,N data before and after fitting in case fitting fails
%
% v1.0  New common code for calibration, variable passing simplified,
%       function  number reduced.
%       Single argument: either 'Pro' or 'Retro'
%
% v0.4  Wedge velocity control is recoded in terms of two fit parameters (A,B) rather than 
%       The physically real parameters used before which proved too
%       difficult to measure.  Fits are now r==1, and imporvement is
%       expected.
%
% v0.3  Configured for lab computer running linux Redhat Enterprise 5
%
% v0.2  Full version (pro and retro included). Minor coding
%       simplifications
%
% v0.1  Proside only
%
% Requires: 
%       -Sandbox indexer (ADR2100) on COM1 serial port
%       -'ezyfit' curve fitting toolbox
%
% NOTES: 
%       all variables are stored in MKS for simplicity, but may be
%       displayed in different units in the GUI
%
% Keith Laskowski, Yale University Jan 2009 
% 
% GUI produced using MATLAB 'GUIDE' software.  
% Last Modified by GUIDE v2.5 10-Jul-2009 14:39:40


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Calibrate_OpeningFcn, ...
                   'gui_OutputFcn',  @Calibrate_OutputFcn, ...
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
function Calibrate_OpeningFcn(hObject, eventdata, handles, varargin)

% determine which side to run, and initialize accordingly
side=varargin{1};
switch side(1:3)
    case 'Pro' 
        indexer_port='COM1';
    case 'Ret' 
        indexer_port='COM2';
    otherwise
        disp('improper arguments to Calibrate.m, exiting...')
        return
end

S=400; % fixed motor settings
M=100;

Rstep=20; % fixed step settings: number of revolution per measurement
Nstep=floor(Rstep*S); % Number of steps per measurement
loadmove=['LAR',num2str(Nstep)]; %'LAR' command gives forward movement

indexer=serial(indexer_port); % initialize indexer (ADR2100)
fopen(indexer);
set(indexer,'Terminator','CR')
fprintf(indexer,'%s\n','CPASTEP') % Now the ADR2100 card is configured to step indexer mode
setspeed=sprintf('%s%i','MS',M);
fprintf(indexer,'%s\n',setspeed)

fit=sprintf('%s%e%s%e%s','x(N)=',1/S,'*A*N+',1/S^2,'*B*N^2'); % fully parameterized fit equation

LOG=fopen('C:\Yalebox\Log\Calibration_Log.txt','at');

step=0; % count current step number
N=[];  % calibration data: number of steps taken
x=[];  % calibration data: distance traveled (cm)
step_handles=[handles.d1,handles.d2,handles.d3,handles.d4,handles.d5,...
         handles.d6,handles.d7,handles.d8,handles.d9,handles.d10,...
         handles.d11,handles.d12,handles.d13,handles.d14,handles.d15,...
         handles.d16,handles.d17,handles.d18,handles.d19,handles.d20,...
         handles.d21];

% Set instructions
set(handles.Instructions,'String','Set indexer to 400 steps/rev.  Mark mylar in current position, measure distance, input, Click "Start / Step"');  

% compile "All" struct
All=CompStruct(LOG,N,Nstep,fit,indexer,loadmove,side,step,step_handles,x);

% Choose default command line output for Calibrate
handles.All=All;
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);



% ... Step Function ... %
function Step_Callback(hObject, eventdata, handles)
% Advances mylar for steps 1-20, computes fit on step 21
[LOG,N,Nstep,fit,indexer,loadmove,side,step,step_handles,x]=DecompStruct(handles.All); % load "All" struct
m2cm=100; % unit conversion constants
cm2m=.01;

% move Rstep revolutions and keep track of number of steps taken
step=step+1;
fprintf(indexer,'%s\n',loadmove); % run
fprintf(indexer,'%s\n','G');
N(step)=Nstep*step; % record
set(step_handles(step),'ForegroundColor',[0 0 0]); % GUI adjustment

% After last step...
if step==length(step_handles)
    set(handles.Instructions,'String','Computing fit: Please check the figure to ensure the fit is acceptable.  If not, please use the command line to adjust and store the fit to "fit_result." When finished, press "Start / Step"')
   
    % trim N data
    N=N(1:end-1); 
    
    % read in x data
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
    x(11)=str2double(get(handles.d11,'String'))*cm2m;
    x(12)=str2double(get(handles.d12,'String'))*cm2m;
    x(13)=str2double(get(handles.d13,'String'))*cm2m;
    x(14)=str2double(get(handles.d14,'String'))*cm2m;
    x(15)=str2double(get(handles.d15,'String'))*cm2m;
    x(16)=str2double(get(handles.d16,'String'))*cm2m;
    x(17)=str2double(get(handles.d17,'String'))*cm2m;
    x(18)=str2double(get(handles.d18,'String'))*cm2m;
    x(19)=str2double(get(handles.d19,'String'))*cm2m;
    x(20)=str2double(get(handles.d20,'String'))*cm2m;
    
    % Save data (backup if fitting fails)
    time=datestr(now,'mmm-dd-yyyy_HHMM');
    save(['C:\Yalebox\Log\', side, 'Calib_Data_', time, '.mat'],'N','x');
    
    %     %OPTIONAL: substituting old data to compute the fit again and save properly
    %     load('CalibrationData.mat')
    %     x=calib1'.*.01;
    %     %OPTIONAL
    
    for i=2:length(x); x(i)=x(i)+x(i-1); end % making x cumulative
    h=figure(2); % plot and fit
    plot(N,x,'*'); title('Steps vs. Distance, with Calibration fit'); xlabel('Steps (N)'); ylabel('Distance (cm)');
    fit_result=showfit(fit);
    
    
    saveas(h,['C:\Yalebox\Log\', side, 'Calib_Fit_', time, '.fig']); % Save results
    save(['C:\Yalebox\Log\', side, 'Calib_Data_', time, '.mat'],'N','x','fit_result');
    time2=datestr(now,'mm-dd-yy');
    fprintf(LOG,'\n%s%s%s%s%s%e%s%e',side,', ','Calibrate, ',time2,', ',fit_result.m(1),', ',fit_result.m(2));
    fclose(LOG);
    
    % instructions
    set(handles.Instructions,'String','Calibration Complete! Hit rewind to reset mylar positions to x=0.')
end
    % compile "All" struct
    All=CompStruct(LOG,N,Nstep,fit,indexer,loadmove,side,step,step_handles,x);
    
    % Update handles structure
    handles.All=All;
    guidata(hObject, handles);

       
% ... Rewind Function ... %
function Rewind_Callback(hObject, eventdata, handles)
cleanup
N=handles.All.N;
WedgeMove(1,2,N(end))


% ... Exit Function ... %
function Exit_Callback(hObject, eventdata, handles)
cleanup % close serial object(s)
close(gcf);



% Unused Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Outputs from this function are retuned to the command line.
function varargout = Calibrate_OutputFcn(hObject, eventdata, handles) 
%varargout{1} = handles.output;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);
