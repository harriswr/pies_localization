clear; clc;

%This code will need to be rerun for each site. If want to autosave script
%using a new name for troubleshooting purposes. Set copy_file to 1.
copy_file = 1;

addpath("subroutines\")
load("pies.mat")

% User inputs
piesID = "C4";

if copy_file
    copyfile("template_survey_position.m", piesID+"_survey_position.m")
end

% Lat and Longitude for success hrange survey points (center of circle)
% with associated hrange value
survey_lats = []; %decimal degrees
survey_lons = []; %decimal degrees
survey_hrange = [];

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

% draws the circles and if 3 or more points will try to localize the PIES
% using least-squares error methodology
[pies, fig] = sub_localize_pies(pies, pind);

savefig(fig, "./figures/"+piesID+"_localization.fig")
save("pies.mat","pies")