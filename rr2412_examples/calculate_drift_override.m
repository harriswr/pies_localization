clear; clc; close all;

addpath("subroutines\")

% PIES ID for use in estimating surfaced position
piesID = "C3";

%load PIES data
load("pies.mat")

%find structure index for this pies
pind = find({pies(:).name} == piesID);

%distance override
dist = 1500;

%heading override; leave as nan to use heading from drift calculations
heading = nan;

% use initial position as either surveyed or original position
try
    p_lat = pies(pind).survey.localized_lat;
    p_lon = pies(pind).survey.localized_lon;
catch
    fprintf("No surveyed position available in PIES.\nIf this is in error, rerun the survey_position script.\nContinuing with non-surveyed PIES location.")
    p_lat = pies(pind).lat;
    p_lon = pies(pind).lon;
end

if exist("reckon","file")
    wgs84 = wgs84Ellipsoid("meter");
    if ~isnan(heading)
        [final_lat, final_lon] = reckon(p_lat, p_lon, dist, heading, wgs84);
    else
        [final_lat, final_lon] = reckon(p_lat, p_lon, dist, pies(pind).drift.heading, wgs84);
    end
else
    fprintf("Mapping toolbox not installed. Using flat earth approximation.")
    if ~isnan(heading)
        dx = dist * sind(heading);
        dy = dist * cosd(heading);
    else
        dx = dist * sind(pies(pind).drift.heading);
        dy = dist * cosd(pies(pind).drift.heading);
    end
    [final_lat, final_lon] = sub_transfer_XY_to_LL(dx,dy, p_lon,p_lat);
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

final_lat_str
final_lon_str