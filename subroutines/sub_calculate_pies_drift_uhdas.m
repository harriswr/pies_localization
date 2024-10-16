function [pies, fig] = sub_calculate_pies_drift_uhdas(pies, piesID, date0, adcp, depthoverride, extrapMethod, isplot)
% Read in ADCP data from shipboard server at timestamp nearest date0 then
% calculates the PIES drift and expected surfacing location/time using the
% surveyed position. If surveyed position is unavailable, will use the
% recorded position. Will try first to read 38 kHz ADCP from UHDAS but may
% need to be changed by editing the adcp_path input variable.
%
% Inputs:
% - pies: structure used to store deployed and localized positions
% - piesID: pies index within the structure
% - date0: datetime (in UTC) from datetime(YY,MM,DD,HH,MM,SS) format
% - adcp: uhdas read-in
% - depthoverride: depth to cut the ADCP reading at (if different from quality)
% - isplot: true or false for plotting the expected surfacing position
%
% Outputs:
% - pies: updated structure with drift calcs added to appropriate entry
% - fig: If isplot is on and localization has been completed, will update
% the localization figure with a red dot signifying the surfaced position.

% reading starting position for drift calculations
try
    p_lat = pies(piesID).survey.localized_lat;
    p_lon = pies(piesID).survey.localized_lon;
catch
    fprintf("No surveyed position available in PIES.\nIf this is in error, rerun the survey_position script.\nContinuing with non-surveyed PIES location.")
    p_lat = pies(piesID).lat;
    p_lon = pies(piesID).lon;
end

% find time index for pulling the data
tind=find(min(abs(date0-adcp.time)) == abs(date0-adcp.time));
fprintf("Found UHDAS data on %s\nInput date was %s\n", adcp.time(tind), date0)

% find the last value where the percent good of the ADCP data is above 80%
if isnan(depthoverride)
    maxind = find(adcp.qual(:,tind)>=80,1,'last');
else
    maxind = find(min(abs(adcp.depths(:,tind)-depthoverride))==abs(adcp.depths(:,tind)-depthoverride));
end

if adcp.depths(maxind,tind) <= 200
    testVar = 1;
else
    testVar = 0;
end

count = 0;
while adcp.depths(maxind,tind) <= 200
    fprintf("Minimum UHDAS good data was below 200 m.\nSearching for new point...\n")
    tind = tind -1;
    maxind = find(adcp.qual(:,tind)>=80,1,'last');
    count = count + 1;
    if count > 10
        break
    end
end

if testVar == 1
    fprintf("Using UHDAS data from %s\n", adcp.time(tind))
end

if isplot
    % start plotting figure
    fig = figure;
    subplot(2,2,[1 3])
    plot(adcp.u(:,tind), adcp.depths(:,tind), 'r', 'LineWidth',1.5)
    hold on
    plot(adcp.v(:,tind), adcp.depths(:,tind), 'b', 'LineWidth',1.5)
    plot([-2 2], adcp.depths(maxind,tind)*ones([1 2]), 'k:','LineWidth',1)
    grid on
    ylabel("Depth (m)")
    xlabel("Component Velocity (m/s)")
    legend({"U","V","Cutoff Depth"},'location','southoutside')
    axis ij

    subplot(2,2,2)
    plot(adcp.qual(:,tind), adcp.depths(:,tind), 'b', 'LineWidth',1.5)
    hold on
    plot([0 100], adcp.depths(maxind,tind)*ones([1 2]), 'k:','LineWidth',1)
    grid on
    xlim([0 100])
    ylabel("Depth (m)")
    xlabel("Percent Good")
    axis ij
end
% calculate the drift now

% convert to m/min to keep same units as ascent rate
U = adcp.u(1:maxind,tind) * 60;
V = adcp.v(1:maxind,tind) * 60;
depths = adcp.depths(1:maxind, tind);

% get the good regions 
U_int = trapz(depths(~isnan(U)), U(~isnan(U)));
V_int = trapz(depths(~isnan(V)), V(~isnan(V)));

% add back first U value to depth for near surface
iumin = find(~isnan(U),1,'first');
ivmin = find(~isnan(V),1,'first');

U_int = U_int + adcp.depths(iumin)*U(iumin);
V_int = V_int + adcp.depths(ivmin)*V(iumin);

% extrapolate to pies depth
switch extrapMethod
    case "taper" % triangle to PIES depth
        U_int = U_int + 0.5 * U(end) * (pies(piesID).depth - depths(end));
        V_int = V_int + 0.5 * V(end) * (pies(piesID).depth - depths(end));
    case "const"
        U_int = U_int + U(end) * (pies(piesID).depth - depths(end));
        V_int = V_int + V(end) * (pies(piesID).depth - depths(end));
    case "zero"
        U_int = U_int;
        V_int = V_int;
end

% calculate drift now
U_drift = U_int / pies(piesID).ascent_rate;
V_drift = V_int / pies(piesID).ascent_rate;
max_drift = max(abs(U_drift), abs(V_drift));

if isplot
    subplot(2,2,4)
    plot([0 0],[-2 2], 'k','LineWidth',1)
    hold on
    plot([-2 2],[0 0], 'k','LineWidth',1)
    plot([0 U_drift]./max_drift, [0 V_drift]./max_drift, 'r','Marker','x','LineWidth',2)
    xlabel("W/E (m)")
    ylabel("N/S (m)")
    xlim([-2 2])
    ylim([-2 2])

    sgtitle(pies(piesID).name+" UHDAS Readout")
end

tot_dist = sqrt(U_drift^2 + V_drift^2); %m
heading = mod(90 - rad2deg(atan2(V_drift, U_drift)), 360);

if exist("reckon","file")
    wgs84 = wgs84Ellipsoid("meter");
    [final_lat, final_lon] = reckon(p_lat, p_lon, tot_dist, heading, wgs84);

   
else
    fprintf("Mapping toolbox not installed. Using flat earth approximation.")
    [final_lat, final_lon] = sub_transfer_XY_to_LL(U_drift,V_drift, p_lon,p_lat);
end

% Format to decimal minutes for bridge
final_lat_deg = floor(final_lat);
final_lat_min = (final_lat-floor(final_lat))*60;

if final_lon < 0
    final_lon_deg = floor(abs(final_lon));
    final_lon_min = (abs(final_lon)-floor(abs(final_lon)))*60;
else
    final_lon_deg = floor(final_lon);
    final_lon_min = (final_lon-floor(final_lon))*60;
end

final_lat_str = sprintf("%0.0f %0.4f N", final_lat_deg, final_lat_min);
if final_lon < 0
    final_lon_str = sprintf("%0.0f %0.4f W", final_lon_deg, final_lon_min);
else
    final_lon_str = sprintf("%0.0f %0.4f E", final_lon_deg, final_lon_min);
end

%store outputs in the pies structure
pies(piesID).drift = struct;
pies(piesID).drift.method = "UHDAS";
pies(piesID).drift.extrap = extrapMethod;
pies(piesID).drift.check_time = date0;
pies(piesID).drift.uhdas_time = adcp.time(tind);
pies(piesID).drift.distance = tot_dist;
pies(piesID).drift.heading = heading;
pies(piesID).drift.final_lat = final_lat;
pies(piesID).drift.final_lon = final_lon;
pies(piesID).drift.final_lat_decmin = final_lat_str;
pies(piesID).drift.final_lon_decmin = final_lon_str;

if isplot
    savefig(fig,"./figures/"+pies(piesID).name+"_adcp.fig")
end

end