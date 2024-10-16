function [xunit, yunit] = sub_circle(x,y,r)

th = linspace(0,2*pi,3600);
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;