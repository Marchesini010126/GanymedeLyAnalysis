close all;
clear all;
addpath("./src")

panel_figure = figure("Units","inches","Position",[1,1,7.1,8]);
counter = 1

for observation_ID= [4010,3010];

    if  observation_ID == 3010
        observation.file = "./oe9z03011_flt.fits";
        observation.name = "oe9z03010";
        observation.x_pcenter = 166;
        observation.y_pcenter = 349;
        observation.best_n0  = 820;
        observation.poly_order = 3;
        observation.north_pole_angle_direction = 27.0; %deg defined clockwise from horizonatal axis

    elseif  observation_ID == 4010
        observation.file = "./oe9z04011_flt.fits";
        observation.name = "oe9z04010";
        observation.x_pcenter = 158;
        observation.y_pcenter = 361;
        observation.best_n0  = 1020;
        observation.poly_order = 3;
        observation.north_pole_angle_direction = 24.4;
    else
        error("uknown obseravton")
    end

    observations_dir   = "/Users/gregorio/Desktop/ganymede_adventure/ganymede_observations";

    % extract fits data
    GanymedeImage = FitsImageObject;
    GanymedeImage.read_image(fullfile(observations_dir,observation.file));

    %%  PLOT IMAGE
    [rows,cols]              = size(GanymedeImage.image);     % find image size
    x_pixel_range_full_image = 1:cols;                        % full image axis range  x
    y_pixel_range_full_image = 1:rows;                        % full images axis range y
    max_intensity            = max(max(GanymedeImage.image)); % define max intensity
    cscale                   = [0,max_intensity];

    % dark counts should remain for the analysis, but you don't want
    % to see them in the picture


    ax   = formal_axes(subplot(2,2,counter));
    hold on
    imagesc(ax,GanymedeImage.image,cscale);
    ax.XLim = [1,cols];
    ax.YLim = [1,rows];
    ax.XLabel.String = "pixel"
    ax.YLabel.String = "pixel"
    ax.Title.String  = upper(observation.name)
    color_bar_instance = formal_colorbar(colorbar(ax));
    color_bar_instance.Label.String = "counts"


    % define subimage outer edge

    x_pmin = 70 ; % pixel
    x_pmax = 260; % pixel
    y_pmin = 260; % pixel
    y_pmax = 450; % pixel

    % plot borders
    x_square = [x_pmin,x_pmin,x_pmax,x_pmax];
    y_square = [y_pmin,y_pmax,y_pmin,y_pmax];
%     scatter(ax,x_square,y_square,'green','filled',LineWidth=10)

    %% RESIZE IMAGE
    [ganymede_centred_subimage,sigma_matrix_ganymede_centred_subimage] = GanymedeImage.resize_image(x_pmin,x_pmax,y_pmin,y_pmax);
    x_pixel_range_ganymede_centred_subimage     = x_pixel_range_full_image(x_pixel_range_full_image<=x_pmax & x_pixel_range_full_image>= x_pmin);
    y_pixel_range_ganymede_centred_subimage     = y_pixel_range_full_image(y_pixel_range_full_image<=y_pmax & y_pixel_range_full_image>= y_pmin);


    %% CENTER DEFINITION

    % floor(diameter/2) and center by eye (referenced to the full image)
    diameter_ganymede    = 70.373;   % define floor(diameter_ganymede/2) so that diameter_ganymede is an odd number (makes easy to have a center than)
    x_pixel_center       = observation.x_pcenter ;      % define center of the image by eye on the big image
    y_pixel_center       = observation.y_pcenter ;    % define center of the image by eye on the big image
    box_radial_extension = 1.5;      % box around the ganymede to be eliminated
    % from the fit expressed is ganymedes radii

    x_index_center_ganymede_centred_subimage = find(x_pixel_range_ganymede_centred_subimage == x_pixel_center); % index of the center in the x_range_sub
    y_index_center_ganymede_centred_subimage = find(y_pixel_range_ganymede_centred_subimage == y_pixel_center); % index of the center in the y_range_sub

    %% CONVERSION FROM COUNTS TO REYLIGHTS

    exposition_time =  GanymedeImage.find_key("TEXPTIME"); %s
    mx              =  0.0246;     % field of view x dierction [arsec]
    my              =  0.0246;     % field of view y dierction [arsec]
    A_mirror        =  45238.9342; % cm2

    filter_data   = dlmread("HST_STIS_FUV.25MAMA_G140L.dat");
    wavelength    = filter_data(:,1);
    throughput    = filter_data(:,2);
    throughput_Ly = interp1(wavelength,throughput,1216);
    A_eff         = A_mirror*throughput_Ly;
    Omega         = mx*my*(2*pi/3600/360)^2;

    count2KRayleight = 4*pi/10^6/(exposition_time*Omega*A_eff)*10^-3;
    ganymede_centred_subimage_reyleights = ganymede_centred_subimage*count2KRayleight;
    sigma_matrix_ganymede_centred_subimage_reyleights = sigma_matrix_ganymede_centred_subimage*count2KRayleight;

    
    xcorner = [x_pixel_range_ganymede_centred_subimage(1),x_pixel_range_ganymede_centred_subimage(end)];
    ycorner  = [y_pixel_range_ganymede_centred_subimage(1),y_pixel_range_ganymede_centred_subimage(end)];

    max_intensity            = max(max(ganymede_centred_subimage_reyleights)); % define max intensity
    cscale                   = [0,max_intensity];

    ax   = formal_axes(subplot(2,2,counter+2));
    hold on
    imagesc(ax,xcorner,ycorner,ganymede_centred_subimage_reyleights,cscale);
    ax.XLim = [x_pixel_range_ganymede_centred_subimage(1),x_pixel_range_ganymede_centred_subimage(end)];
    ax.YLim = [y_pixel_range_ganymede_centred_subimage(1),y_pixel_range_ganymede_centred_subimage(end)];
    ax.XLabel.String = "pixel"
    ax.YLabel.String = "pixel"
    color_bar_instance = formal_colorbar(colorbar());
    color_bar_instance.Label.String = "Brightness [kR]"

    counter = counter+1;
end