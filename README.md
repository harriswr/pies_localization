# PIES Localization Toolbox

The enclosed package contains scripts and subroutines for surveying location of deployed PIES and estimating drift during recovery operations.

## Author Information
Author: Will Harris \
Email: harriswr@mit.edu \
Date: 10/16/24 \

## Brief Overview 
The files here can be used to automate the localization and drift calculation for PIES recoveries. 

Many of the functions here have been adapted to work without the Mapping toolbox; however, accuracy is improved when this toolbox is installed. When not installed, distance calculations are performed assuming a flat earth approximation and a message will be shown indicating that this approximation was used.

The drift calculations in particular rely on access to the ADCP data from shipboard systems (primarily written for UHDAS). The file path to the processed data must be pointed out in the template_calculate_drift.m file. I believe the path is: /cruise/adcp_uhdas/CRUISEID/proc/os38nb/contour/, though you may need to ask the Instrumentation Tech to point you to the correct directory.

The various codes will generate .fig files under the "figures" directory. These are:
- PIESID_localization.fig: Shows the circles, the surveyed position, and (if drift calcs run) the expected surfaced position
- PIESID_adcp.fig: Shows the UHDAS output, as well as the depth to which the calculation kept the UHDAS data before extrapolation. Also, shows drift heading.
- PIESID_manual.fig: Only build when manually inputting UHDAS currents. Shows the piecewise linear current profile and heading.

Files with the subscript "template" will create copies when run based on the piesID field. This allows you to change values between sites without losing those data points from prior sites.


## Workflow
The envisioned workflow for using this project is as follows:

1. Fill out station names, lat-lon coordinates, and depths in init.m 
	-This will create a "pies" object referenced and edited by all other codes. 
	-After running this once at the start of the cruise, you should not need to change it. Rerunning this file will erase all localization and drift data from the structure and will require you to rerun the relevant scripts.
2. When at a station and performing localization, use template_survey_position and follow instructions in comments.
	- Changes piesID to the name specified in the init file, as this will inform which sub-struct to edit.
	- This file will draw the circles used for triangulating the deployment position of the instrument
	- If more than three circles are provided, a least-squares optimization will be performed to estimate the position.
	- Final surveyed positions can be found in pies(IDNo).survey
		- This structure will also record the centers and radii of the ranging circles
3. When estimating drift, use the template_calculate_drift.m and follow instructions
	- Changes piesID to the name specified in the init file, as this will inform which sub-struct to edit.
	- CPIES are assumed to rise at 94 m/min. PIES are assumed to rise at 60 m/min.
	- src denotes the data from which to estimate the drift.
		- If able to set the program to read from the UHDAS directory (described above), this will automatically account for their quality metrics in calculating the total drift range and heading.
		- If you change to manual, you must specify depths and velocity components separately for each component. This allows varying resolution in the case of, for instance, shear in N/S but not E/W velocity.
	- extrap denotes how the code will extrapolate velocity profiles to the instrument depth
		- taper draws a triangle from last good value to the final depth
		- const draws a rectangle from the last good value to the final depth
		- zero neglects all velocities below the last good value
	- calc_time tells the code which ADCP reading to read. 
		- In the case that the last good depth reading is less than 200 m, it will search into the past for a deeper depth profile
	- depth_override allows you to manually truncate the profiles, in case you don't agree with the UHDAS quality metrics
	- Final drift values will be under pies(IDNo).drift
		- Values to report to bridge are in final_lat/lon_decmin under this struct.

## Explanation of files
File Included with this package:

├── README.txt: this file\
├── calculate_drift_override.m: Use this if you want to estimate the surfaced position manually (takes in a heading and distance)\
├── figures: .fig files when codes are run\
├── init.m: Builds PIES struct\
├── rr2412_examples\
│   ├── C3_calculate_drift.m: Sample for C3 site on RR2412 showing output of drift calculations.\
│   ├── C3_survey_position.m: Sample for C3 site on RR2412 showing output of surveying calculations.\
│   ├── C4_survey_position.m: Sample for C4 site on RR2412 showing output of surveying calculations.\
│   ├── adcp.mat: UHDAS output from RR2412 so that the sample scripts can be run\
│   ├── calculate_drift_override.m: Sample for running a manual drift estimation (for telling ship where to be)\
│   ├── figures\
│   │   ├── C3_adcp.fig: UHDAS output for C3\
│   │   ├── C3_localization.fig: Localization output for C3\
│   │   ├── C3_manual.fig: Piecewise approximation of UHDAS for C3\
│   │   └── C4_localization.fig: Localization output for C4\
│   ├── pies.mat: PIES struct for RR2412 including lat, lon, and depth\
│   ├── rr2412_init.m: Code used to build the pies.mat file\
│   └── template_calculate_drift.m: template for calculating the drift (used to make C3_calculate_drift.m)\
├── subroutines\
│   ├── sub_calculate_pies_drift_manual.m: subroutine for calculating drift from manual speed inputs\
│   ├── sub_calculate_pies_drift_uhdas.m: subroutine for calculating drift from UHDAS inputs\
│   ├── sub_circle.m: subroutine for flat-earth ranging circles\
│   ├── sub_localize_pies.m: subroutine for drawing ranging circles and performing least-squares estimate of position\
│   ├── sub_make_pies_struct.m: subroutine to make pies structure\
│   ├── sub_read_uhdas.m: subroutine to read UHDAS files into one adcp struct\
│   ├── sub_transfer_LL_to_XY.m: subroutine to transfer lat-lon coordinates into x-y coordinates relative to a reference lat-lon\
│   └── sub_transfer_XY_to_LL.m: subroutine to transfer x-y coordinates into lat-lon coordinates relative to a reference lat-lon\
├── template_calculate_drift.m: blank copy to be edited in calculating drift for new cruises\
└── template_survey_position.m: blank copy to be edited in localizing PIES for new cruises\