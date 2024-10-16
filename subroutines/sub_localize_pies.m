function [pies, fig] = sub_localize_pies(pies, piesID, varargin)
% This function uses the provided latitudes, longitudes, and horizontal
% ranges to determine the most likely location of the deployed PIES. If
% isplot is turned on, this function will also save a figure showing the
% various ranging circles and the estimated position of the PIES.
%
% Input Variables:
%   pies: Structure containing latitude and longitude, as well as ranging
%   meaasurements
%   piesID: Index in the pies structure to perform localization on
%   isplot: On-off switch for generating figure. By default, will save into
%   the "images" directory

% check if mapping tool is installed

if nargin < 3
    isplot = 1;
else
    isplot = varargin{1};
end

if exist("reckon","file")
    map_check = true;
else
    fprintf("Mapping toolbox not installed. Using flat earth approximation.")
    map_check = false;
end

lats = pies(piesID).survey.lats;
lons = pies(piesID).survey.lons;
hrange = pies(piesID).survey.hrange;

% initialize pts for plotting
ths = 0:0.1:359.9;
pts = nan([length(lats), length(ths), 2]);

for ilat = 1:length(lats)
    if map_check
        wgs84 = wgs84Ellipsoid("meter"); %reference ellipsoid for mapping toolbox
        [pts(ilat,:,1), pts(ilat,:,2)]=reckon(lats(ilat), lons(ilat), hrange(ilat), 0:0.1:359.9, wgs84);
    else
        [x, y] = sub_transfer_LL_to_XY(lats(ilat),lons(ilat), pies(piesID).lon, pies(piesID).lat);
        [xc, yc] = sub_circle(x, y, hrange(ilat));
        [pts(ilat,:,1), pts(ilat,:,2)] = sub_transfer_XY_to_LL(xc, yc, pies(piesID).lon, pies(piesID).lat);
    end
end

% least squares using guess point
if length(lats) >= 3
    
    lat_range = min(pts(:,:,1),[],'all'):5e-4:max(pts(:,:,1),[],'all');
    lon_range = min(pts(:,:,2),[],'all'):5e-4:max(pts(:,:,2),[],'all');
    [xs, ys] = sub_transfer_LL_to_XY(lon_range, lat_range, pies(piesID).lon, pies(piesID).lat);
    [xpts, ypts] = sub_transfer_LL_to_XY(lons, lats, pies(piesID).lon, pies(piesID).lat);

    % initialize variables to store minimum
    min_d = inf;

    for i = 1:length(xs)
        for j = 1:length(ys)

            % current point
            x_try = xs(i);
            y_try = ys(j);

            % Compute the distance from the current point to all waypoints
            if exist("reckon","file")
                x_try_ranges = distance(lat_range(j),lon_range(i),lats,lons,wgs84);
            else
                fprintf("Performing Euclidian distance")
                x_try_ranges = sqrt((xpts - x_try).^2 + (ypts - y_try).^2);
            end

            % Compute sum squared error
            d = sum((x_try_ranges - hrange).^2);

            % Check if smallest so far and store if yes
            if d < min_d
                min_d = d; %store for further comparison
                best_est = [x_try, y_try]; %store position with minimum error
            end
        end
    end

    % move back into lat lon coordinates for plotting and reporting
    [final_lon, final_lat] = sub_transfer_XY_to_LL(best_est(1),best_est(2),...
        pies(piesID).lon, pies(piesID).lat);

    pies(piesID).survey.localized_lat = final_lat;
    pies(piesID).survey.localized_lon = final_lon;

    % format into decimal minutes for reporting
    final_lat_deg = floor(final_lat);
    final_lat_min = (final_lat-final_lat_deg)*60;

    if final_lon < 0
        final_lon_deg = floor(abs(final_lon));
        final_lon_min = (abs(final_lon)-final_lon_deg)*60;
        fprintf("Pies successfully located to:\n%0.0f %0.4f N\n%0.0f %0.4f W",...
            final_lat_deg, final_lat_min, final_lon_deg, final_lon_min)
    else
        final_lon_deg = floor(final_lon);
        final_lon_min = (final_lon-final_lon_deg)*60;
        fprintf("Pies successfully located to:\n%0.0f %0.4f N\n%0.0f %0.4f E",...
            final_lat_deg, final_lat_min, final_lon_deg, final_lon_min)
    end

    pies(piesID).survey.localized_lat_string = sprintf("%0.0f %0.4f N",final_lat_deg, final_lat_min);
    if final_lon < 0
        pies(piesID).survey.localized_lon_string = sprintf("%0.0f %0.4f W",final_lon_deg, final_lon_min);
    else
        pies(piesID).survey.localized_lon_string = sprintf("%0.0f %0.4f E",final_lon_deg, final_lon_min);
    end

    %% Make plot
    if isplot
        fig = figure;
        colors = lines(length(lats));
        hold on;
        for ilat = 1:length(lats)
            plot(lons(ilat), lats(ilat), 'Color',colors(ilat,:),'marker','x', 'MarkerSize',10)
            plot(pts(ilat,:,2), pts(ilat,:,1), 'Color',colors(ilat,:))
        end

        plot(final_lon, final_lat, 'ko','markerfacecolor',[0 0 0], 'LineStyle','none')
    end

end

end