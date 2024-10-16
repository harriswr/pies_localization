clear; clc; close all;

addpath("../subroutines\")
load("pies.mat")

% PIES ID for use in estimating surfaced position
piesID = "C3";

% copy file to see settings used
copyfile("template_calculate_drift.m", piesID+"_calculate_drift.m")

% User selection of methodology. If UHDAS, will attempt to use inputs of
% UHDAS subsection below. If HDSS will attempt to use HDSS data detailed
% below. If Manual, will perform integration of manual inputs of velocity
% components.
src = "UHDAS";      % Set UHDAS or Manual (for HDSS reach out to Will)

% Extrapolation option for estimating full water column currents
extrap = "taper";   % taper: will taper from last good value to zero at pies depth
                    % const: will keep last good value to pies depth
                    % zero: assume zero velocity between last good value

% file path should be set to either the cruise directory or the science
% share dependent on the ADCP src being used. If performing manual caculations, 
% you may leave this blank. May need to talk to the Instrumentation Tech to 
% determine where this is. For RR2412, this was in:
% /cruise/adcp_uhdas/RR2412/proc/os150nb/contour/
%
% Note that os150nb refers to the frequency of the ADCP. For better
% results, should use lower frequencies (e.g., os38nb)

%e.g. UHDAS
file_path = "..\..\adcp_uhdas\RR2412\RR2412\proc\os150nb\contour";

% time to pull ADCP from. Assume small spatial variability during recovery
% operations. os150nb synced data every 3 minutes, so will find the closest
% one to the input time.
calc_time = datetime(2024,10,7,18,38,00);

% Override depth (in m) if unsatisfied with automated quality detection
depthoverride = nan;

% Inputs if manually setting the velocities.
z_u = [50 250];   % depths where reading u values
u = [0.9 0.9];     % u values at depths z_u
z_v = [25 50 250];   % depths where reading v values
v = [-0.2 0 0.1];     % v values at depths z_v

%% Doing the actual calculations

%find structure index for this pies
pind = find({pies(:).name} == piesID);

switch src
    case "UHDAS"
        % Load the adcp data
        try
            adcp = sub_read_uhdas(file_path);
        catch
            load("adcp.mat") % only for illustration purposes
        end
        
        [pies, fig] = sub_calculate_pies_drift_uhdas(pies, pind, calc_time,...
            adcp, depthoverride, extrap, 1);

    case "Manual"
        [pies, fig] = sub_calculate_pies_drift_manual(pies, pind, z_u, u, z_v, v, extrap, 1);
end

save("pies.mat","pies")

%% Show drifted position on original plot (if possible)
try
    localization_fname = "figures/"+piesID+"_localization.fig";
    fig = open(localization_fname);
    hold on
    plot(pies(pind).drift.final_lon, pies(pind).drift.final_lat, 'ro','markerfacecolor','r')
    savefig(fig,localization_fname)
catch
    fprintf("\nUnsuccesful in opening or saving localization figure.")
end



