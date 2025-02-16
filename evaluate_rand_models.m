% evaluate_rand-system_models
% 
%   Trains linear/bilinear/nonlinear models of random systems
%   Validates sytems models against data
%   Quantifies average error in validation trials
%   Plots the average normalized error for each model type/degree

%% Set training parameters and choose data

% save models?
save_models = false;

% Maximum degree for each type of model
max_degree_linear = 13;     %13;     % 20
max_degree_bilinear = 6;   %6;    % 10
max_degree_nonlinear = 4;   %4;   % 5

% load in data file(s)
[ datafile_name , datafile_path ] = uigetfile( 'datafiles/*.mat' , 'Choose data file for sysid...' );
load( [datafile_path , datafile_name] );    % should be called 'data4sysid_all'

%% Train models for each random system

% make directories for saving models
if save_models
    folder_all_models = [ 'systems' , filesep , data4sysid_all{1}.folder_name ];
    folder_linear_models = [ folder_all_models , filesep , 'linear' ];
    folder_bilinear_models = [ folder_all_models , filesep , 'bilinear' ];
    folder_nonlinear_models = [ folder_all_models , filesep , 'nonlinear' ];
    
    % create directories for storing models
    mkdir( folder_all_models );
    mkdir( folder_linear_models );
    mkdir( folder_bilinear_models );
    mkdir( folder_nonlinear_models );
end

err_linear_models = zeros( max_degree_linear , size( data4sysid_all , 1 ) );  % preallocate
err_bilinear_models = zeros( max_degree_bilinear , size( data4sysid_all , 1 ) );  % preallocate
err_nonlinear_models = zeros( max_degree_nonlinear , size( data4sysid_all , 1 ) );  % preallocate
dim_linear_models = zeros( max_degree_linear , size( data4sysid_all , 1 ) );  % preallocate
dim_bilinear_models = zeros( max_degree_bilinear , size( data4sysid_all , 1 ) );  % preallocate
dim_nonlinear_models = zeros( max_degree_nonlinear , size( data4sysid_all , 1 ) );  % preallocate

for i = 1 : size( data4sysid_all , 1 )
    % train linear models
    for j = 1 : max_degree_linear
        clear Ksysid;
        Ksysid = Ksysid( data4sysid_all{i} ,...
            'model_type' , 'linear' ,...    % model type (linear, bilinear, or nonlinear)
            'time_type' , 'discrete' , ...  % 'discrete' or 'continuous'
            'obs_type' , { 'poly' } ,...    % type of basis functions
            'obs_degree' , [ j ] ,...       % "degree" of basis functions
            'snapshots' , Inf ,...          % Number of snapshot pairs
            'lasso' , [ Inf ] ,...            % L1 regularization term (Inf for least-squares sol.)   1
            'delays' , 0 ,...               % Numer of state/input delays
            'loaded' , false ,...           % Does system include external loads?
            'dim_red' , false);             % Should dimensional reduction be performed?
        Ksysid = Ksysid.train_models;
        
        % save the model
        if save_models
            model = Ksysid.model;
            file_name = [ Ksysid.model_type , '_' , Ksysid.obs_type{1} , '-' , num2str(Ksysid.obs_degree) ,'_n-' , num2str( Ksysid.params.n ) , '_m-' , num2str( Ksysid.params.m ) , '_del-' , num2str( Ksysid.params.nd ) ];
            save( [ folder_linear_models , filesep , file_name ] , '-struct' , 'model' );
        end
        
        % validate model
        results = Ksysid.valNplot_model([],false,false);
        mean_error = results{1}.error.mean;  % mean error over all time steps
        mean_error_zeros = sum( abs( results{1}.real.y ) ) / size(results{1}.real.y,1); % mean error over all time steps, zero response
        normed_mean_error = results{1}.error.mean / mean_error_zeros;   % mean error normed by zero response
        
        % put all the normed mean error for linear models in single matrix
        err_linear_models( j , i ) = normed_mean_error;
        dim_linear_models( j , i ) = size( Ksysid.basis.full , 1 );
    end
    
    % train bilinear models
    for j = 1 : max_degree_bilinear
        clear Ksysid;
        Ksysid = Ksysid( data4sysid_all{i} ,...
            'model_type' , 'bilinear' ,...    % model type (linear, bilinear, or nonlinear)
            'time_type' , 'discrete' , ...  % 'discrete' or 'continuous'
            'obs_type' , { 'poly' } ,...    % type of basis functions
            'obs_degree' , [ j ] ,...       % "degree" of basis functions
            'snapshots' , Inf ,...          % Number of snapshot pairs
            'lasso' , [ Inf ] ,...            % L1 regularization term (Inf for least-squares sol.)     4-8
            'delays' , 0 ,...               % Numer of state/input delays
            'loaded' , false ,...           % Does system include external loads?
            'dim_red' , false);             % Should dimensional reduction be performed?
        Ksysid = Ksysid.train_models;
        
        % save the model
        if save_models
            model = Ksysid.model;
            file_name = [ Ksysid.model_type , '_' , Ksysid.obs_type{1} , '-' , num2str(Ksysid.obs_degree) ,'_n-' , num2str( Ksysid.params.n ) , '_m-' , num2str( Ksysid.params.m ) , '_del-' , num2str( Ksysid.params.nd ) ];
            save( [ folder_bilinear_models , filesep , file_name ] , '-struct' , 'model' );
        end
        
        % validate model
        results = Ksysid.valNplot_model([],false,false);
        mean_error = results{1}.error.mean;  % mean error over all time steps
        mean_error_zeros = sum( abs( results{1}.real.y ) ) / size(results{1}.real.y,1); % mean error over all time steps, zero response
        normed_mean_error = results{1}.error.mean / mean_error_zeros;   % mean error normed by zero response
        
        % put all the normed mean error for linear models in single matrix
        err_bilinear_models( j , i ) = normed_mean_error;
        dim_bilinear_models( j , i ) = size( Ksysid.basis.full_input , 1 );
    end
    
    % train nonlinear models
    for j = 1 : max_degree_nonlinear
        clear Ksysid;
        Ksysid = Ksysid( data4sysid_all{i} ,...
            'model_type' , 'nonlinear' ,...    % model type (linear, bilinear, or nonlinear)
            'time_type' , 'discrete' , ...  % 'discrete' or 'continuous'
            'obs_type' , { 'poly' } ,...    % type of basis functions
            'obs_degree' , [ j ] ,...       % "degree" of basis functions
            'snapshots' , Inf ,...          % Number of snapshot pairs
            'lasso' , [ 4 ] ,...            % L1 regularization term (Inf for least-squares sol.)
            'delays' , 0 ,...               % Numer of state/input delays
            'loaded' , false ,...           % Does system include external loads?
            'dim_red' , false);             % Should dimensional reduction be performed?
        Ksysid = Ksysid.train_models;
        
        % save the model
        if save_models
            model = Ksysid.model;
            file_name = [ Ksysid.model_type , '_' , Ksysid.obs_type{1} , '-' , num2str(Ksysid.obs_degree) ,'_n-' , num2str( Ksysid.params.n ) , '_m-' , num2str( Ksysid.params.m ) , '_del-' , num2str( Ksysid.params.nd ) ];
            save( [ folder_nonlinear_models , filesep , file_name ] , '-struct' , 'model' );
        end
        
        % validate model
        results = Ksysid.valNplot_model([],false,false);
        mean_error = results{1}.error.mean;  % mean error over all time steps
        mean_error_zeros = sum( abs( results{1}.real.y ) ) / size(results{1}.real.y,1); % mean error over all time steps, zero response
        normed_mean_error = results{1}.error.mean / mean_error_zeros;   % mean error normed by zero response
        
        % put all the normed mean error for linear models in single matrix
        err_nonlinear_models( j , i ) = normed_mean_error;
        dim_nonlinear_models( j , i ) = size( Ksysid.basis.full , 1 );
    end
end

%% Plot the error

% throw out any trials with NaNs
err_linear_nonan = err_linear_models( : , all(~isnan(err_linear_models)) );
err_bilinear_nonan = err_bilinear_models( : , all(~isnan(err_bilinear_models)) );
err_nonlinear_nonan = err_nonlinear_models( : , all(~isnan(err_nonlinear_models)) );

% % remove outliers
err_linear_nonan = err_linear_models( : , all( err_linear_models < 10 ) );
err_bilinear_nonan = err_bilinear_models( : , all( err_bilinear_models < 10 ) );
err_nonlinear_nonan = err_nonlinear_models( : , all( err_nonlinear_models < 10 ) );
% err_linear_nonan = rmoutliers(err_linear_nonan,2);
% err_bilinear_nonan = rmoutliers( err_bilinear_nonan , 2 );
% err_nonlinear_nonan = rmoutliers(err_nonlinear_nonan,2);

% linear
mean_linear = mean( err_linear_nonan , 2 );
std_linear = std( err_linear_nonan' )';

% bilinear
mean_bilinear = mean( err_bilinear_nonan , 2 );
std_bilinear = std( err_bilinear_nonan' )';

% nonlinear
mean_nonlinear = mean( err_nonlinear_nonan , 2 );
std_nonlinear = std( err_nonlinear_nonan' )';

% plot the comparison (need to edit figure to make it look nice
std_scale = 1; % reduce scale of standard devation for better viewing
figure;
hold on;
errorbar( dim_linear_models(:,1) , mean_linear , std_scale * std_linear , 'b' );
errorbar( dim_bilinear_models(:,1) , mean_bilinear , std_scale * std_bilinear , 'g' );
errorbar( dim_nonlinear_models(:,1) , mean_nonlinear , std_scale * std_nonlinear , 'r' );
% plot( dim_linear_models(:,1) , mean_linear , 'b' );
% plot( dim_bilinear_models(:,1) , mean_bilinear , 'g' );
% plot( dim_nonlinear_models(:,1) , mean_nonlinear , 'r' );
hold off;
xlabel('Numer of basis functions')
ylabel('Normalized error')
legend( 'linear' , 'bilinear' , 'nonlinear' )
ylim([0,1]);




% % box and whisker plots
% figure;
% subplot(1,3,1)
% boxplot( err_linear_nonan' , dim_linear_models(:,1) , 'Colors' , [0 0 1] , 'PlotStyle','compact' );
% ylim([0,0.6]);
% xlim([0,23]);
% subplot(1,3,2)
% boxplot( err_bilinear_nonan' , dim_bilinear_models(:,1) , 'Colors' , [0 1 0] , 'PlotStyle','compact' );
% ylim([0,0.6]);
% xlim([0,23]);
% subplot(1,3,3)
% boxplot( err_nonlinear_nonan' , dim_nonlinear_models(:,1) , 'Colors' , [1 0 0] , 'PlotStyle','compact' );
% ylim([0,0.6]);
% xlim([0,23]);


%% custom box and whisker plots (move this to a separate function)
linear_bars = prctile( err_linear_nonan , [0 25 50 75 100] , 2 ); 
bilinear_bars = prctile( err_bilinear_nonan , [0 25 50 75 100] , 2 ); 
nonlinear_bars = prctile( err_nonlinear_nonan , [0 25 50 75 100] , 2 ); 

cmap = colormap('lines');   % store colormap

% % attempt #1
% figure;
% hold on;
% % linear models [0 100] and [25 75]
% for i = 1 : length( dim_linear_models(:,1) )
%     line( [ dim_linear_models(i,1) , dim_linear_models(i,1) ] , [ linear_bars(i,1) , linear_bars(i,5) ] , 'Marker' , '.' , 'MarkerSize' , 12 , 'LineWidth' , 2 , 'Color' , cmap(1,:) );
%     line( [ dim_linear_models(i,1) , dim_linear_models(i,1) ] , [ linear_bars(i,2) , linear_bars(i,4) ] , 'LineWidth' , 12 , 'Color' , cmap(1,:) );
% end
% % bilinear models [25 75]
% for i = 1 : length( dim_bilinear_models(:,1) )
%     line( [ dim_bilinear_models(i,1) , dim_bilinear_models(i,1) ] , [ bilinear_bars(i,1) , bilinear_bars(i,5) ] , 'Marker' , '.' , 'MarkerSize' , 12 , 'LineWidth' , 1.5 , 'Color' , cmap(2,:) );
%     line( [ dim_bilinear_models(i,1) , dim_bilinear_models(i,1) ] , [ bilinear_bars(i,2) , bilinear_bars(i,4) ] , 'LineWidth' , 10 , 'Color' , cmap(2,:) );
% end
% % nonlinear models [25 75]
% for i = 1 : length( dim_nonlinear_models(:,1) )
%     line( [ dim_nonlinear_models(i,1) , dim_nonlinear_models(i,1) ] , [ nonlinear_bars(i,1) , nonlinear_bars(i,5) ] , 'Marker' , '.' , 'MarkerSize' , 12 , 'LineWidth' , 1 , 'Color' , cmap(3,:) );
%     line( [ dim_nonlinear_models(i,1) , dim_nonlinear_models(i,1) ] , [ nonlinear_bars(i,2) , nonlinear_bars(i,4) ] , 'LineWidth' , 8 , 'Color' , cmap(3,:) );
% end
% patch( [0,25,25,0] , [0,0,1,1] , [1 1 1] , 'FaceAlpha' , 0.6 , 'EdgeColor' , 'none');
% % Plot median
% p_linear = plot( dim_linear_models(:,1) , linear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 18 , 'Color' , cmap(1,:) );
% p_bilinear = plot( dim_bilinear_models(:,1) , bilinear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 18 , 'Color' , cmap(2,:) );
% p_nonlinear = plot( dim_nonlinear_models(:,1) , nonlinear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 18 , 'Color' , cmap(3,:) );
% hold off;
% ylim([0,0.8]);
% xlim([0,25]);
% grid on; box on;
% legend( [ p_linear , p_bilinear , p_nonlinear ] , {'Linear' , 'Bilinear' , 'Nonlinear' } );
% xlabel('Number of Basis Functions');
% ylabel('Average Error (Normalized)');


% attempt #2
cmap(1,:) = [27,158,119]/255;
cmap(2,:) = [217,95,2]/255;
cmap(3,:) = [117,112,179]/255;

figure;
hold on;
% Plot dividing lines
for i = 0 : 25
    line( [ i+0.5 , i+0.5 ] , [ 0 1 ] , 'LineStyle' , '-.' , 'Color' , 'k' );
    if mod(i,2) == 0
        patch( [ i-0.5 , i+0.5 , i+0.5 , i-0.5 ] , [ 0 , 0 , 1 , 1 ] , [1 1 1]*0.85 , 'EdgeColor' , 'none' );
    end
end
% linear models [0 100] and [25 75]
for i = 1 : length( dim_linear_models(:,1) )
%     line( [ dim_linear_models(i,1) , dim_linear_models(i,1) ] - 0.25 , [ linear_bars(i,1) , linear_bars(i,5) ] , 'Marker' , '+' , 'MarkerSize' , 5 , 'LineWidth' , 1 , 'Color' , cmap(1,:) );
    line( [ dim_linear_models(i,1) , dim_linear_models(i,1) ] - 0.25 , [ linear_bars(i,2) , linear_bars(i,4) ] , 'LineWidth' , 2 , 'Color' , cmap(1,:) );
end
patch( [ dim_linear_models(:,1) - 0.25 ; flipud(dim_linear_models(:,1)) - 0.25 ] , [ linear_bars(:,2) ; flipud( linear_bars(:,4) ) ] , cmap(1,:) , 'EdgeColor' , cmap(1,:) , 'FaceAlpha' , 0.5);
% bilinear models [0 100] and [25 75]
for i = 1 : length( dim_bilinear_models(:,1) )
%     line( [ dim_bilinear_models(i,1) , dim_bilinear_models(i,1) ] , [ bilinear_bars(i,1) , bilinear_bars(i,5) ] , 'Marker' , '+' , 'MarkerSize' , 5 , 'LineWidth' , 1 , 'Color' , cmap(2,:) );
    line( [ dim_bilinear_models(i,1) , dim_bilinear_models(i,1) ] , [ bilinear_bars(i,2) , bilinear_bars(i,4) ] , 'LineWidth' , 2 , 'Color' , cmap(2,:) );
end
patch( [ dim_bilinear_models(:,1) ; flipud(dim_bilinear_models(:,1)) ] , [ bilinear_bars(:,2) ; flipud( bilinear_bars(:,4) ) ] , cmap(2,:) , 'EdgeColor' , cmap(2,:) , 'FaceAlpha' , 0.5 );
% nonlinear models [0 100] and [25 75]
for i = 1 : length( dim_nonlinear_models(:,1) )
%     line( [ dim_nonlinear_models(i,1) , dim_nonlinear_models(i,1) ] + 0.25 , [ nonlinear_bars(i,1) , nonlinear_bars(i,5) ] , 'Marker' , '+' , 'MarkerSize' , 5 , 'LineWidth' , 1 , 'Color' , cmap(3,:) );
    line( [ dim_nonlinear_models(i,1) , dim_nonlinear_models(i,1) ] + 0.25 , [ nonlinear_bars(i,2) , nonlinear_bars(i,4) ] , 'LineWidth' , 2 , 'Color' , cmap(3,:) );
end
patch( [ dim_nonlinear_models(:,1) + 0.25 ; flipud(dim_nonlinear_models(:,1)) + 0.25 ] , [ nonlinear_bars(:,2) ; flipud( nonlinear_bars(:,4) ) ] , cmap(3,:) , 'EdgeColor' , cmap(3,:) , 'FaceAlpha' , 0.5);
% White patch to lighten background layers
patch( [0,22.5,22.5,0] , [0,0,0.4,0.4] , [1 1 1] , 'FaceAlpha' , 0.4 , 'EdgeColor' , 'k');
% Plot median
p_linear = plot( dim_linear_models(:,1) - 0.25 , linear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 20 , 'Color' , cmap(1,:) );
p_bilinear = plot( dim_bilinear_models(:,1) , bilinear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 20 , 'Color' , cmap(2,:) );
p_nonlinear = plot( dim_nonlinear_models(:,1) + 0.25 , nonlinear_bars(:,3) , '.-' , 'LineWidth' , 2 , 'MarkerSize' , 20 , 'Color' , cmap(3,:) );
hold off;
ylim([0,0.4]);
xlim([1.5,22.5]);
box on;
legend( [ p_linear , p_bilinear , p_nonlinear ] , {'Linear' , 'Bilinear' , 'Nonlinear' } , 'Location' , 'northwest' );
xlabel('Number of Basis Functions');
ylabel('Average Error (Normalized)');
xticks(2:2:22);



