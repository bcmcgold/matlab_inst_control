instrreset;
clear all;

multi.obj = gpib('ni',0,5); fopen(multi.obj);
multi.name = 2400;
lockin.obj = daq("mcc");
lockin.name = 'daq';
lockin.field_factor = 300;

n_avg = 5;
t_betw_avg = 50e-3;

%sweep_current = [ linspace(-12,12,31) linspace(12,-12,31)  linspace(-12,12,31) linspace(12,-12,31)   linspace(-12,12,31) linspace(12,-12,31) ];
% sweep_field = [linspace(500,-500,25) linspace(-500,500,25)];
sweep_field = -500:10:500;
sweep_field = [sweep_field fliplr(sweep_field)];
%set_inst(multi,'mA',1);
ramp_inst(lockin,'field IP',sweep_field(1),5);
figure;
h = animatedline('Marker','o');
for index=1:length(sweep_field)
    set_inst(lockin,'field IP',sweep_field(index));
    pause(0.5);
    data(index) = read_inst_avg(multi,'XI',n_avg,t_betw_avg);
%     plot(sweep_field(1:index),data(1:index),'-x');
    addpoints(h,sweep_field(index),data(index));
    drawnow
end

%set_inst(multi,'mA',0);
ramp_inst(lockin,'field IP',0,5);

out.data=data;
out.Vx = 20;
out.note = 'Vx unit in mV, data in A';
out.field = sweep_field;
out.angle = 90;

save("out");
% save(['C:\Users\floor2\Documents\MATLAB\Zhiping\CMG_MTJ' '\2-7-0deg'],'out');
fieldcal = [-2000 2000; 520 590];