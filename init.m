% add necessary scripts to path for full running
addpath("subroutines\")

% Check if Mapping toolbox is installed
check = exist("reckon","file");
if check == 0
    fprintf("Mapping toolbox is either not in the current path or is uninstalled.\nIf not installed, localization will be done using the flat earth approximation.")
end

% Set up PIES instrument look up table
% Input the latitude, longitude, waypoint names, and depths of each PIES

lats = [];          
        %e.g. [39.0867, 39.1982, 38.2455]
lons = -1*[];         
        %e.g. -1*[64.1432, 62.9676, 62.8109]

depths = [];        
        %e.g. [5004, 5102, 4983]
% names = {};         
        %e.g. {"C1","P2","C3"}; else assumes "C"+order of 1:length(lats)
% cpies_or_pies = {}; 
        %e.g. {"C","P","C"}; used for ascent rate calcs. Else assumes "C"

if exist('names','var') && exist('cpies_or_pies','var')
    % if providing station names and cpies_or_pies use the following
    pies = sub_make_pies_struct(lats, lons, depths, cpies_or_pies, names);
else
    % else assumes all cpies and numbered from 1 to max entry
    pies = sub_make_pies_struct(lats, lons, depths);
end


