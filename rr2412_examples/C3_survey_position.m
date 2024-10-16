clear; clc; close all;

%This code will need to be rerun for each site. If want to autosave script
%using a new name for troubleshooting purposes. Set copy_file to 1.
copy_file = 0;

addpath("..\subroutines\")
load("pies.mat")

% User inputs
piesID = "C3";

if copy_file
    copyfile("template_survey_position.m", piesID+"_survey_position.m")
end

survey_lats = [38+14.1085/60 38.2369 38+14.670/60]; %decimal degrees
survey_lons = [-62-47.1040/60 -62.7897 -62-47.503/60]; %decimal degrees
survey_hrange = [2244 1908 1106];

%find structure index for this pies
pind = find({pies(:).name} == piesID);

if length(survey_hrange) ~= length(survey_lons) || length(survey_lats) ~= length(survey_lons) || ...
    length(survey_lats) ~= length(survey_hrange)
    fprintf("Size mismatch in inputs. Please confirm localization data.\n")
else
    % will store lat, lon, and hrange for future reference
    pies(pind).survey = struct;
    pies(pind).survey.lats = survey_lats;
    pies(pind).survey.lons = survey_lons;
    pies(pind).survey.hrange = survey_hrange;
end

[pies, fig] = sub_localize_pies(pies, pind);


savefig(fig, "./figures/"+piesID+"_localization.fig")
save("pies.mat","pies")