
clear; clc; close all;

%% Multi-RPM Dataset Generation Setup
rpm_start = 100;
rpm_end = 700;
rpm_step = 100;
rpm_values = rpm_start:rpm_step:rpm_end;
total_rpms = length(rpm_values);

% Create main output directory
main_output_dir = 'drone_radar_dataset';
if ~exist(main_output_dir, 'dir')
    mkdir(main_output_dir);
end

fprintf('Starting Multi-RPM Drone Radar Dataset Generation\n');
fprintf('RPM Range: %d to %d (step: %d)\n', rpm_start, rpm_end, rpm_step);
fprintf('Total RPM values: %d\n', total_rpms);
fprintf('Estimated total time: %.1f minutes\n\n', total_rpms * 0.5); % Rough estimate

%% Initialize Radar System (Once for all RPMs)
disp('Initializing radar system...');

% Radar parameters
fc = 5e9;                    % Operating frequency (5 GHz)
c = physconst('lightspeed'); % Speed of light
lambda = c/fc;               % Wavelength
fs = 1e6;                    % Sample rate
prf = 2e4;                   % Pulse repetition frequency (20 kHz)

% Create radar waveform
waveform = phased.RectangularWaveform('SampleRate', fs, ...
                                      'PulseWidth', 2e-6, ...
                                      'PRF', prf);

% Create radar antenna
antenna = phased.IsotropicAntennaElement('FrequencyRange', [1e9 10e9]);
array = phased.URA('Size', [4 4], 'ElementSpacing', lambda/2, 'Element', antenna);

% Create transmitter and receiver
transmitter = phased.Transmitter('PeakPower', 1e3, 'Gain', 20);
receiver = phased.ReceiverPreamp('Gain', 20, 'NoiseFigure', 5);

% Create radiator and collector
radiator = phased.Radiator('Sensor', array, ...
                          'PropagationSpeed', c, ...
                          'OperatingFrequency', fc);
collector = phased.Collector('Sensor', array, ...
                            'PropagationSpeed', c, ...
                            'OperatingFrequency', fc);

% Create free space propagation environment
channel = phased.FreeSpace('PropagationSpeed', c, ...
                          'OperatingFrequency', fc, ...
                          'TwoWayPropagation', true, ...
                          'SampleRate', fs);

% Fixed simulation parameters
animation_time = 2;          % Reduced for radar processing
dt = 1/prf;                  % Sync with radar PRF
radar_position = [0; 0; 0];  % Radar at origin
drone_position = [100; 50; 30]; % Drone position in meters

%% Load 3D Models (Once for all RPMs)
disp('Loading drone frame and 4 propeller STL models...');

try
    % Load drone frame
    drone_frame_stl = 'data/main/drone_frame.stl';
    drone_frame_mesh = stlread(drone_frame_stl);
    drone_frame_vertices = drone_frame_mesh.Points;
    
    % Initialize storage for propellers
    hub_meshes = cell(4, 1);
    blade_meshes = cell(4, 1);
    hub_vertices_original = cell(4, 1);
    blade_vertices_original = cell(4, 1);
    
    % Load each propeller
    for i = 1:4
        hub_stl = sprintf('data/main/propeller%d_hub.stl', i);
        hub_meshes{i} = stlread(hub_stl);
        hub_vertices_original{i} = hub_meshes{i}.Points;
        
        blade_stl = sprintf('data/main/propeller%d_blade.stl', i);
        blade_meshes{i} = stlread(blade_stl);
        blade_vertices_original{i} = blade_meshes{i}.Points;
    end
    
    model_loaded = true;
    disp('STL models loaded successfully');
    
    % Pre-process model centering (once for all RPMs)
    all_vertices = drone_frame_vertices;
    for i = 1:4
        all_vertices = [all_vertices; hub_vertices_original{i}; blade_vertices_original{i}];
    end
    overall_center = mean(all_vertices, 1);
    
    % Center all components
    drone_frame_vertices = drone_frame_vertices - overall_center;
    hub_vertices_centered = cell(4, 1);
    blade_vertices_centered = cell(4, 1);
    hub_centers = zeros(4, 3);
    
    for i = 1:4
        hub_vertices_centered{i} = hub_vertices_original{i} - overall_center;
        blade_vertices_centered{i} = blade_vertices_original{i} - overall_center;
        hub_centers(i, :) = mean(hub_vertices_original{i}, 1) - overall_center;
    end
    
catch ME
    warning('Could not load STL files: %s', ME.message);
    model_loaded = false;
    disp('Proceeding with radar simulation without 3D visualization');
    hub_centers = zeros(4, 3); % Default hub positions
end

%% Create Radar Target Model for Drone (Once for all RPMs)
num_scatterers = 5; % 1 body + 4 blade tips
drone_rcs = [5, 0.1, 0.1, 0.1, 0.1]; % RCS values in m²

drone_target = phased.RadarTarget('MeanRCS', drone_rcs, ...
                                 'PropagationSpeed', c, ...
                                 'OperatingFrequency', fc);

%% Main Multi-RPM Loop
for rpm_idx = 1:total_rpms
    current_rpm = rpm_values(rpm_idx);
    
    fprintf('\n=== Processing RPM %d/%d: %d RPM ===\n', rpm_idx, total_rpms, current_rpm);
    
    % Update RPM-specific parameters
    prop_rpm = current_rpm;
    prop_speed = prop_rpm * 2 * pi / 60;
    
    % Create folder structure for current RPM
    rpm_folder = fullfile(main_output_dir, sprintf('RPM_%d', current_rpm));
    if ~exist(rpm_folder, 'dir'), mkdir(rpm_folder); end
    
    subfolders = {'drone_signal', 'spectrogram', 'time_series', 'psd', 'range_doppler', 'doppler_profile'};
    for k = 1:length(subfolders)
        subfolder_path = fullfile(rpm_folder, subfolders{k});
        if ~exist(subfolder_path, 'dir'), mkdir(subfolder_path); end
    end
    
    %% Initialize Data Storage for Current RPM
    time_steps = round(animation_time / dt);
    samples_per_pulse = round(fs / prf);
    received_signal = complex(zeros(samples_per_pulse, time_steps));
    
    %% Setup Visualization for Current RPM
    if model_loaded
        % Create figure for animation
        fig = figure('Name', sprintf('Drone Radar Simulation - %d RPM', current_rpm), ...
                    'Position', [100 100 1200 800], 'Visible', 'off'); % Hidden for speed
        
        % Animation subplot
        subplot(2, 2, [1, 3]);
        ax_anim = gca;
        axis equal; grid on;
        xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
        view(35, 25);
        max_range = max(max(all_vertices) - min(all_vertices)) * 0.6;
        xlim([-max_range max_range]);
        ylim([-max_range max_range]);
        zlim([-max_range max_range]);
        title(sprintf('Drone Animation - %d RPM', current_rpm));
        hold on;
        
        % Draw drone components
        drone_frame_handle = patch(ax_anim, 'Faces', drone_frame_mesh.ConnectivityList, ...
                                  'Vertices', drone_frame_vertices, ...
                                  'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'none');
        
        blade_colors = [0, 0.5, 1; 1, 0.5, 0; 0, 0.8, 0.2; 0.8, 0, 0.8];
        hub_handles = gobjects(4, 1);
        blade_handles = gobjects(4, 1);
        
        for i = 1:4
            hub_handles(i) = patch(ax_anim, 'Faces', hub_meshes{i}.ConnectivityList, ...
                                  'Vertices', hub_vertices_centered{i}, ...
                                  'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
            
            blade_handles(i) = patch(ax_anim, 'Faces', blade_meshes{i}.ConnectivityList, ...
                                    'Vertices', blade_vertices_centered{i}, ...
                                    'FaceColor', blade_colors(i, :), 'EdgeColor', 'none');
        end
        
        light; camlight; material shiny; lighting gouraud;
    end
    
    %% Main Radar and Animation Loop for Current RPM
    fprintf('Starting radar simulation for %d RPM...\n', current_rpm);
    
    rotation_directions = [1, -1, 1, -1]; % CW-CCW-CW-CCW pattern
    angle_increment = rad2deg(prop_speed * dt);
    
    for step = 1:time_steps
        current_time = (step - 1) * dt;
        
        % Calculate scatterer positions for current time
        scatterer_positions = calculateDroneScatterers(current_time, drone_position, ...
                                                      hub_centers, prop_speed, 0.5);
        
        % Calculate scatterer velocities
        scatterer_velocities = calculateDroneVelocities(current_time, prop_speed, 0.5);
        
        % Generate and transmit radar signal
        transmitted_signal = waveform();
        transmitted_signal = transmitter(transmitted_signal);
        
        % Calculate angles to scatterers
        [~, scatterer_angles] = rangeangle(scatterer_positions, radar_position);
        
        % Radiate signal towards drone
        radiated_signal = radiator(transmitted_signal, scatterer_angles);
        
        % Propagate signal to drone and back
        propagated_signal = channel(radiated_signal, radar_position, scatterer_positions, ...
                                   zeros(3, 1), scatterer_velocities);
        
        % Apply target reflections
        reflected_signal = drone_target(propagated_signal);
        
        % Collect and receive the signal
        collected_signal = collector(reflected_signal, scatterer_angles);
        received_signal(:, step) = receiver(sum(collected_signal, 2));
        
        % Update animation if models loaded (minimal updates for speed)
        if model_loaded && ishghandle(fig) && mod(step, 10) == 0 % Update every 10 steps
            for prop_idx = 1:4
                actual_angle = angle_increment * rotation_directions(prop_idx) * 10;
                if ishghandle(blade_handles(prop_idx))
                    rotate(blade_handles(prop_idx), [0 0 1], actual_angle, hub_centers(prop_idx, :));
                end
            end
            drawnow limitrate;
        end
    end
    
    %% Signal Processing and Micro-Doppler Analysis for Current RPM
    fprintf('Processing radar signals for %d RPM...\n', current_rpm);
    
    % Apply matched filtering
    matched_filter = phased.MatchedFilter('Coefficients', getMatchedFilter(waveform));
    filtered_signal = matched_filter(received_signal);
    
    % Find the range bin with maximum energy
    [~, range_idx] = max(sum(abs(filtered_signal), 2));
    drone_signal = filtered_signal(range_idx, :);
    
    % Save drone signal data
    drone_signal_file = fullfile(rpm_folder, 'drone_signal', 'drone_signal.mat');
    save(drone_signal_file, 'drone_signal', 'time_steps', 'dt', 'prop_rpm', 'fc', 'prf', 'fs');
    
    % Generate analysis plots
    time_vector = (0:time_steps-1) * dt;
    window_length = 64;
    overlap = 60;
    nfft = 128;
    blade_length = 0.5;
    max_blade_tip_velocity = blade_length * prop_speed;
    theoretical_doppler = 2 * max_blade_tip_velocity * fc / c;
    
    %% Plot 1: Time Series
    figure('Visible', 'off', 'Position', [100 100 800 600]);
    plot(time_vector, real(drone_signal), 'LineWidth', 1.5);
    xlabel('Time (s)'); ylabel('Amplitude');
    title(sprintf('Received Signal from Drone (RPM: %d)', current_rpm));
    grid on;
    time_series_file = fullfile(rpm_folder, 'time_series', 'time_series.png');
    saveas(gcf, time_series_file);
    close;
    
    %% Plot 2: Power Spectral Density
    figure('Visible', 'off', 'Position', [100 100 800 600]);
    [psd, freq] = periodogram(drone_signal, [], [], prf, 'centered');
    plot(freq, 10*log10(psd), 'LineWidth', 1.5);
    xlabel('Frequency (Hz)'); ylabel('PSD (dB)');
    title(sprintf('Power Spectral Density (RPM: %d)', current_rpm));
    grid on;
    psd_file = fullfile(rpm_folder, 'psd', 'psd.png');
    saveas(gcf, psd_file);
    close;
    
    %% Plot 3: Micro-Doppler Spectrogram
    figure('Visible', 'off', 'Position', [100 100 1000 700]);
    [s, f, t] = spectrogram(drone_signal, hamming(window_length), overlap, nfft, prf, 'centered');
    spectrogram_db = 20*log10(abs(s));
    
    imagesc(t, f, spectrogram_db);
    axis xy; colorbar;
    xlabel('Time (s)'); ylabel('Doppler Frequency (Hz)');
    title(sprintf('Micro-Doppler Spectrogram (RPM: %d)', current_rpm));
    colormap jet;
    clim([max(spectrogram_db(:))-60, max(spectrogram_db(:))]);
    
    spectrogram_file = fullfile(rpm_folder, 'spectrogram', 'spectrogram.png');
    saveas(gcf, spectrogram_file);
    close;
    
    %% Plot 4: Range-Doppler Response
    figure('Visible', 'off', 'Position', [100 100 800 600]);
    rd_processor = phased.RangeDopplerResponse('PropagationSpeed', c, ...
                                              'SampleRate', fs, ...
                                              'DopplerFFTLengthSource', 'Property', ...
                                              'DopplerFFTLength', min(128, time_steps), ...
                                              'DopplerOutput', 'Speed', ...
                                              'OperatingFrequency', fc);
    mf_coeff = getMatchedFilter(waveform);
    plotResponse(rd_processor, received_signal(:, 1:min(128, time_steps)), mf_coeff);
    title(sprintf('Range-Doppler Response (RPM: %d)', current_rpm));
    
    range_doppler_file = fullfile(rpm_folder, 'range_doppler', 'range_doppler.png');
    saveas(gcf, range_doppler_file);
    close;
    
    %% Plot 5: Doppler Profile Analysis
    figure('Visible', 'off', 'Position', [100 100 800 600]);
    doppler_profile = mean(abs(s), 2);
    plot(f, doppler_profile, 'LineWidth', 1.5);
    xlabel('Doppler Frequency (Hz)'); ylabel('Magnitude');
    title(sprintf('Average Doppler Profile (RPM: %d)', current_rpm));
    grid on;
    hold on;
    xline(theoretical_doppler, 'r--', 'LineWidth', 2);
    xline(-theoretical_doppler, 'r--', 'LineWidth', 2);
    legend('Measured', 'Theoretical ±Max Doppler', 'Location', 'best');
    
    doppler_profile_file = fullfile(rpm_folder, 'doppler_profile', 'doppler_profile.png');
    saveas(gcf, doppler_profile_file);
    close;
    
    % Close animation figure if it exists
    if model_loaded && ishghandle(fig)
        close(fig);
    end
    
    % Progress update
    elapsed_time = toc;
    estimated_remaining = (elapsed_time / rpm_idx) * (total_rpms - rpm_idx);
    fprintf('Completed RPM %d (%d/%d) - Estimated remaining: %.1f minutes\n', ...
            current_rpm, rpm_idx, total_rpms, estimated_remaining/60);
end

%% Generate Dataset Summary
fprintf('\n=== DATASET GENERATION COMPLETE ===\n');
fprintf('Output directory: %s\n', main_output_dir);
fprintf('RPM range: %d to %d (step: %d)\n', rpm_start, rpm_end, rpm_step);
fprintf('Total RPM folders created: %d\n', total_rpms);
fprintf('Files per RPM folder: 6 (1 .mat + 5 .png)\n');
fprintf('Total files generated: %d\n', total_rpms * 6);

% Create dataset summary file
summary_file = fullfile(main_output_dir, 'dataset_summary.txt');
fid = fopen(summary_file, 'w');
fprintf(fid, 'Drone Radar Micro-Doppler Dataset Summary\n');
fprintf(fid, 'Generated on: %s\n\n', datestr(now));
fprintf(fid, 'Dataset Parameters:\n');
fprintf(fid, '  RPM Range: %d to %d (step: %d)\n', rpm_start, rpm_end, rpm_step);
fprintf(fid, '  Total RPM values: %d\n', total_rpms);
fprintf(fid, '  Radar Frequency: %.1f GHz\n', fc/1e9);
fprintf(fid, '  Animation Time: %.1f seconds\n', animation_time);
fprintf(fid, '  Blade Length: %.1f meters\n', blade_length);
fprintf(fid, '\nFolder Structure:\n');
fprintf(fid, '  RPM_XXXX/\n');
fprintf(fid, '    ├── drone_signal/drone_signal.mat\n');
fprintf(fid, '    ├── spectrogram/spectrogram.png\n');
fprintf(fid, '    ├── time_series/time_series.png\n');
fprintf(fid, '    ├── psd/psd.png\n');
fprintf(fid, '    ├── range_doppler/range_doppler.png\n');
fprintf(fid, '    └── doppler_profile/doppler_profile.png\n');
fclose(fid);

fprintf('\nDataset ready for machine learning training!\n');
fprintf('Summary file created: %s\n', summary_file);

%% Utility Functions (Same as original)
function scatterer_pos = calculateDroneScatterers(t, drone_pos, hub_centers, blade_rate, blade_length)
    % Calculate positions of drone scatterers (body + blade tips)
    
    % Drone body (stationary relative to drone frame)
    body_pos = drone_pos;
    
    % Calculate blade tip positions (rotating)
    num_blades = 4;
    blade_angles = (0:num_blades-1) * 2*pi/num_blades; % Initial angles
    rotation_angle = blade_rate * t;
    
    blade_positions = zeros(3, num_blades);
    for i = 1:num_blades
        current_angle = blade_angles(i) + rotation_angle;
        % Add hub center offset and blade tip offset
        blade_positions(:, i) = drone_pos + hub_centers(i, :)' + ...
                               blade_length * [cos(current_angle); sin(current_angle); 0];
    end
    
    scatterer_pos = [body_pos, blade_positions];
end

function scatterer_vel = calculateDroneVelocities(t, blade_rate, blade_length)
    % Calculate velocities of drone scatterers
    
    % Body velocity (stationary)
    body_vel = [0; 0; 0];
    
    % Blade tip velocities (tangential to rotation)
    num_blades = 4;
    blade_angles = (0:num_blades-1) * 2*pi/num_blades;
    rotation_angle = blade_rate * t;
    
    blade_velocities = zeros(3, num_blades);
    for i = 1:num_blades
        current_angle = blade_angles(i) + rotation_angle;
        % Tangential velocity
        blade_velocities(:, i) = blade_length * blade_rate * ...
                                [-sin(current_angle); cos(current_angle); 0];
    end
    
    scatterer_vel = [body_vel, blade_velocities];
end
