function xhat = LinearRecipo(Q, R, inp, show_plot, point)
% inp = inp';
inp = detrend(inp);
%
%   Continuous-time system
% C0 = 100000;
% C1 = 100;
% C2 = 100;
% C3 = 10;
% C0 = 100000;
% C1 = 1000;
% C2 = 10;
% C3 = 10;
% C0 = 10;
% C1 = 10;
% C2 = 10;
% C3 = 100;

C0 = 3.222697860962567e+08;
C1 = 2.596267602495544e+07;
C2 = 3.992825089126559e+05;
C3 = 1.586100713012478e+03;

A = [0 1 0 0;0 0 1 0; 0 0 0 1; -C0 -C1 -C2 -C3] ;
B = [0 0 0 1]'; Bw = [1 0 0 0]';
C = [1 0 0 0];
D = 0;
sys = ss(A,[B Bw],C,D);

%tlab

%   Discretization
%
T = 0.004; % sampling time
sysd = c2d(sys,T);
Ad = sysd.a; 
Bd = sysd.b(:,1); Bwd = sysd.b(:,2);
Cd = sysd.c; Dd = sysd.d;

%
%   Covariances
%
% Q = 0.1; % disturbance input
% Rv = 0.07; % measurement noise
% Q = 0.5; % disturbance input
% Rv = 0.07; % measurement noise
% Q = 0.001; % disturbance input
% R = 0.7; % measurement noise

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Linear Recipo model %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%   Design of time-varying Kalman filter
%
kfinal = length(inp);  % number of iteration
% kfinal = length(w0);
M(:,:,1) = eye(4); % Error covariance initial value
for k = 1:kfinal
    %
    %   (TASK) WRITE CODE FOR COMPUTING TIME-VARYING 
    %   KALMAN GAIN HERE!!!
    %
    P(:,:,k) = M(:,:,k) ...
    -M(:,:,k)*Cd'/(Cd*M(:,:,k)*Cd'+R)*Cd*M(:,:,k);

    M(:,:,k+1) = Ad*P(:,:,k)*Ad'+Bwd*Q*Bwd';
    %
    %   Kalman gain
    %
    K(:,:,k)=P(:,:,k)*C'/R;
    
end

%
%   Input-output data for the state estimator design
%
% u = [ones(1,10) zeros(1,10) ...
%     ones(1,10) zeros(1,10)]; % square-wave input

% SacInt = 20;
% u = [zeros(1,SacInt) (30000000000/3.1)*ones(1,length(inp)-SacInt)];  % step-input

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%inputEdit
% SacInt = 21;
% SacStop = 134; 
% 
% %val for testInput
% SacInt = 66;
% SacStop = 142; 

cutoffs = findchangepts(inp, "MaxNumChanges", 2); 
if length(cutoffs) < 2 || cutoffs(2) - cutoffs(1) < 3 % If insufficient cutoffs
    cutoffs = [1 length(inp)]; % Start of saccade
end
SacInt = cutoffs(1);
SacEnd = cutoffs(2);
SacDur = SacEnd-SacInt; % Duration of saccade

offset = mean(inp(1:cutoffs(1)));
inp = inp - offset; % Offset

peaks = findpeaks(abs(inp(cutoffs(1): cutoffs(2))));

% If there are no peaks in isolated region, then take entire length
if(isempty(peaks)) % Take peaks of entire saccade
    peaks = findpeaks(abs(inp));
end
if(isempty(peaks)) % If still empty, just take raw values
    peaks = abs(inp);
end
if strcmp(point, 'A') || strcmp(point, 'B')
    peaks = -peaks;
end

SacMag = mean(peaks); % Average of peaks
alpha_r = 1E10/3.1; % Magnification coefficent

u = [zeros(1,SacInt) SacMag*alpha_r*ones(1,SacDur) zeros(1,length(inp)-(SacDur+SacInt))];  % step-input

%w = sqrt(Rw)*randn(size(u)); % disturbance input
%[y0,Ttmp,X] = lsim(sysd,[u;w]); % output without measurement noise
%v = sqrt(Rv)*randn(size(y0)); % measurement noise
%y = y0+v; % measurement with noise
%real1 = X(:,1);
%real2 = X(:,2);
%
%   State estimate with time-varying Kalman filter
%
% xhat(0|-1) (time update)
xhat_t(:,:,1) = [0 0 0 0]'; % initial estimate
y_a = inp(1,1:kfinal)';

for k = 1:kfinal
    xhat_m(:,:,k) = xhat_t(:,:,k)+K(:,:,k)*...
        (y_a(k)-Cd*xhat_t(:,:,k)); % xhat(k|k) (measurement update)
    xhat_t(:,:,k+1) = Ad*xhat_m(:,:,k)+Bd*u(k); % xhat(k+1|k)
end


% theta after correction
xhatm1sub = xhat_m(1,1,:); xhatm1 = xhatm1sub(:); 
% d(theta)/dt after correction
xhatm2sub = xhat_m(2,1,:); xhatm2 = xhatm2sub(:); 
% theta after prediction
xhatt1sub = xhat_t(1,1,:); xhatt1 = xhatt1sub(:); 
% d(theta)/dt after prediction
xhatt2sub = xhat_t(2,1,:); xhatt2 = xhatt2sub(:); 

% xhat = xhatt1' + offset;
xhat = xhatt1';
xhat(:,1) = [];
%xhat = sgolayfilt(xhat,5,111);

if show_plot
    figure()
    K1sub = K(1,1,:); K1 = K1sub(:);
    K2sub = K(2,1,:); K2 = K2sub(:);
    subplot(2,1,1), plot(K1) 
    title('Time Varying Kalman gain','fontsize',12,'fontweight','bold')
    ylabel('K1','fontsize',12,'fontweight','bold')
    set(gca,'fontsize',12,'fontweight','bold') % Fontsize
    subplot(2,1,2), plot(K2) 
    ylabel('K2','fontsize',12,'fontweight','bold')
    set(gca,'fontsize',12,'fontweight','bold') % Fontsize
    xlabel('k','fontsize',12,'fontweight','bold')

    figure()
    kgrid = 1:kfinal;
    subplot(2,1,1), plot(kgrid,y_a+1,kgrid,xhatm1,'r',kgrid,xhatt1(1:end-1),'g-.')
    title('Trajectories with time varying kamlan gain','fontsize',12,'fontweight','bold')
    legend('meassurement','correction','prediction')
    set(gca,'fontsize',12,'fontweight','bold') % Fontsize
    subplot(2,1,2), plot(kgrid,y_a,kgrid,xhatm2,'r',kgrid,xhatt2(1:end-1),'g-.')
    legend('true x_2','correction','prediction')
    set(gca,'fontsize',12,'fontweight','bold') % Fontsize

    %use saccade sac30S17
    figure();
    plot(inp,'b');
    hold on; 
    plot(xhat, 'r'); 
    xlabel('Sample No.');
    ylabel('Signal Magnitude'); 
    title('EOG 30 Degree Saccadic Eye Motion : KF with Linear Reciprocal'); 
    legend('raw EOG','KF-Linear Reciprocal EOG')
end
end

