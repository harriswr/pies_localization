clear; clc;

%This code will need to be rerun for each site. If want to autosave script
%using a new name for troubleshooting purposes. Set copy_file to 1.
copy_file = 0;

addpath("..\subroutines\")
load("pies.mat")

% User inputs
piesID = "C4";

if copy_file
    copyfile("template_survey_position.m", piesID+"_survey_position.m")
end

survey_lats = [38+39.534/60 38+39.4991/60 38+39.471/60 38+39.4411/60 38+39.101/60 38+39.7317/60]; %decimal degrees
survey_lons = [-63-31.152/60 -63-30.7892/60 -63-30.446/60 -63-30.1018/60 -63-30.253/60 -63-29.4156/60]; %decimal degrees
survey_hrange = [1500 1131 790 660 1423 828];

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