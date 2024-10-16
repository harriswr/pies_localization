function pies = sub_make_pies_struct(lat, lon, depths, varargin)
% Takes inputs of latitude, longitudes, waypoint names, and depths for
% deployed PIES instruments to store for use in later codes. Output is
% a Matlab structure which is saved in the "outputs/" directory. All input
% variables should be of size Nx1, where N is the number of instruments in
% the region.
%
%    Input Variables:
%    lat: Nx1 array of latitude in decimal degrees
%    lon: Nx1 array of longitude in decimal degrees
%    depths: Nx1 array of deployment depths in meters
%    model: Nx1 array of either "C" for CPIES or "P" for PIES. Used for
%    ascent rate calculations.
%    names: Nx1 cell array of latitude in decimal degrees
%
%    Output Variables:
%    pies: Nx1 structure where PIES M can be accessed as pies(M)

if nargin <= 3
    L_str = arrayfun(@num2str, 1:length(lat), 'UniformOutput', false);
    L_str = L_str';
    model = repmat({'C'},length(lat),1);
    names = strcat(model, L_str);
elseif nargin <= 4
    L = 1:length(lat);
    model = varargin{1};

    % Pre-allocate result
    result = cell(1, length(model));

    % Loop to concatenate elements
    for i = 1:length(model)
        result{i} = strcat(model{i}, num2str(L(i)));
    end
    names = result;
elseif nargin <= 5
    model = varargin{1};
    names = varargin{2};
end

pies = struct;

for i = 1:length(lat)
    pies(i).name = names{i};
    pies(i).model = model{i};
    pies(i).lat = lat(i);
    pies(i).lon = lon(i);
    pies(i).depth = depths(i);

    if strcmpi(model{i}, "C")
        pies(i).ascent_rate = 94;
    else
        pies(i).ascent_rate = 60;
    end
end

save("pies.mat", "pies")

end