%% measure RH
clear all;
instrreset;

lockin.obj = gpib('ni',0,12); fopen(lockin.obj);
lockin.name = 7260;

multi.obj = gpib('ni',0,4); fopen(multi.obj);
multi.name = 2400;

heater.obj = gpib('ni',0,10); fopen(heater.obj);
heater.name = 336;

num_repeat = 10;% <- repeat times
sweep_range_temp = [ linspace(-10000,10000,51) linspace(10000,-10000,51)];
sweep_range = repmat(sweep_range_temp,1,num_repeat); 
output.field = sweep_range;

set_inst(multi,'RangI',100E-6);
set_inst(multi,'CompI',100E-6);
set_inst(multi,'OUTRangV',0.2);
set_inst(multi,'V',-0.2);

ramp_inst(lockin,'DAC1',sweep_range(1),5000);
for index = 1:length(sweep_range)
    set_inst(lockin,'DAC1',sweep_range(index));
    pause(0.5);
    output.I(index) = read_inst(multi,'XI');
    output.V(index) = read_inst(multi,'XV');
    output.TA(index) = read_inst(heater,'A');
    output.TB(index) = read_inst(heater,'B');
    pause(0);
    figure(1);
    plot(output.field(1:index),output.V(1:index)./output.I(1:index));
    pause(0);
    figure(2);
    plot(output.field(1:index),output.I(1:index));
end
ramp_inst(lockin,'DAC1',0,5000);

save output;

%% average
dim = 51;

x1=output.field(1:51);
x2=output.field(52:102);
y=output.I;


for index=1:10
    range1 = (1:dim) + (index*2-2)*dim;
    range2 = (1:dim) + (index*2-1)*dim;
    R1(:,index) = y(range1);
    R2(:,index) = y(range2);
end


range = 1:10;
R1_avg = mean(R1(:,range)');
R2_avg = mean(R2(:,range)');


figure(3);
hold on;
plot(x1,R1_avg,'r-x');
plot(x2,R2_avg,'k-x');
