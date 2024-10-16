function adcp = sub_read_uhdas(root_path)
% read uhdas from cruise directory

adcp = struct;

load(root_path+"\allbins_other.mat", "TIME","LON","LAT");
load(root_path+"\allbins_u.mat","U");
load(root_path+"\allbins_v.mat","V");
load(root_path+"\allbins_depth.mat","DEPTH");
load(root_path+"\allbins_pg.mat","PGOOD");


adcp.time = datetime(TIME);
adcp.lat = LAT;
adcp.lon = LON;
adcp.depths = DEPTH;
adcp.qual = PGOOD;
adcp.u = U;
adcp.v = V;

end