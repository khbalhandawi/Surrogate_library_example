clearvars
close all
clc
addpath SGTE_matlab_server
addpath Support_functions
addpath ./Support_functions/hatchfill2_r8
addpath ./Support_functions/export_fig

%% Problem definition
load('DOE_results.mat','X','Err','lb','ub');

lhs_data_normalize = X; % X_data
obj_data = Err; % Y_data

%% Design space sampling
lhs_data = scaling(lhs_data_normalize, lb, ub, 2); % unscale data from ( [0 , 1] --> [lb, ub] )
%% Construct surrogate models <---------------------------------------------------- CHOOSE DIFFERENT SURROGATE MODELS
%-------------------------------------------------------------------------%
% For default hyperparameters
% model = 'TYPE LOWESS DEGREE 2 KERNEL_TYPE D1 KERNEL_SHAPE 1.12073 DISTANCE_TYPE NORM2 RIDGE 0.0125395';
% model = 'TYPE KRIGING RIDGE 1.01723e-16 DISTANCE_TYPE NORM2 METRIC OECV BUDGET 200';
% For Hyperparameter Optimization
budget = 200; out_file = 'surrogate_model.sgt';
% model = ['TYPE LOWESS ', 'DEGREE OPTIM ', 'RIDGE OPTIM ', 'KERNEL_TYPE OPTIM ', 'KERNEL_COEF OPTIM ', 'DISTANCE_TYPE OPTIM ', 'METRIC OECV ', 'BUDGET ', num2str(budget), ' OUTPUT ', out_file];
% model = ['TYPE KS ', 'KERNEL_TYPE OPTIM ', 'KERNEL_COEF OPTIM ', 'DISTANCE_TYPE OPTIM ', 'METRIC OECV ','BUDGET ', num2str(budget), ' OUTPUT ', out_file];
% model = ['TYPE RBF ', 'KERNEL_TYPE OPTIM ', 'KERNEL_COEF OPTIM ', 'DISTANCE_TYPE OPTIM ', 'RIDGE OPTIM ', 'METRIC OECV ', 'BUDGET ', num2str(budget), ' OUTPUT ', out_file];
% model = ['TYPE KRIGING ', 'RIDGE OPTIM ', 'DISTANCE_TYPE OPTIM ', 'METRIC OECV ', 'BUDGET ', num2str(budget), ' OUTPUT ', out_file];
model = ['TYPE ENSEMBLE ', 'WEIGHT OPTIM ', 'METRIC OECV ', 'DISTANCE_TYPE OPTIM ','BUDGET ', num2str(budget),' OUTPUT ', out_file];
%-------------------------------------------------------------------------%

sgtelib_server_start(model,true,true)
% Test if server is ok and ready
sgtelib_server_ping;
% Feed server
sgtelib_server_newdata(lhs_data,obj_data');

% metric_str = 'OECV';
% metric = sgtelib_server_metric(metric_str);
% fprintf('===============================\n')
% fprintf('The OECV is : %f\n',metric)
% metric_str = 'RMSECV';
% metric = sgtelib_server_metric(metric_str);
% fprintf('The RMSECV is : %f\n',metric)
% fprintf('===============================\n')

%Prediction

lb_plot = lb;
ub_plot = ub;

res = 70;
X = gridsamp([lb_plot; ub_plot], res);
[YX,std,ei,cdf] = sgtelib_server_predict(X);
% sgtelib_server_stop; %stop the server 

X1 = reshape(X(:,1),res,res); X2 = reshape(X(:,2),res,res);
YX = reshape(YX, size(X1));

%% Plot design space

fig1 = figure(1);
h = axes(fig1);
axis(h,[lb(1),ub(1),lb(2),ub(2)]) % fix the axis limits

[cc, hh] = contourf(h,X1, X2, YX,20); % plot contour of response surface
hold on
plot(lhs_data(:,1),lhs_data(:,2),'.k','markersize',10) % plot training data
colorbar(h)
xlabel('$x_1$','interpreter','latex','fontsize',16)
ylabel('$x_2$','interpreter','latex','fontsize',16)
set(fig1,'color','w');
export_fig('surrogate_function.pdf','-p0.002',fig1); 
export_fig('surrogate_function.png','-p0.002','-r600',fig1); 