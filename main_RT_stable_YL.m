clear all;
instrreset;


lockin.obj = gpib('ni',0,12); fopen(lockin.obj);
lockin.name = 7260;

multi.obj = gpib('ni',0,4); fopen(multi.obj);
multi.name = 2400;

heater.obj = gpib('ni',0,10); fopen(heater.obj);
heater.name = 336;

sweep_range = [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255 260 265 270 275 280 285 290 295 300];
margin = 0.5;

set_inst(heater,'RangB',3);
set_inst(heater,'RangA',2);
set_inst(multi,'RangI',100E-6);
set_inst(multi,'CompI',100E-6);
set_inst(multi,'OUTRangV',0.2);
output.field = 0;

for index=1:length(sweep_range)
    set_inst(heater,'T',sweep_range(index));
    stab_time=0;
    track_A = [];
    track_B = [];
    while stab_time < 60
        pause(1);
        stab_time = stab_time+1;
        temp_TA = read_inst(heater,'A');
        temp_TB = read_inst(heater,'B');
        track_A = [track_A temp_TA];
        track_B = [track_B temp_TB];
        errorA = abs(temp_TA - sweep_range(index));
        errorB = abs(temp_TB - sweep_range(index));
        if ( errorA > margin ) | ( errorB > margin )
            stab_time = 0;
        end
        figure(4);
        pause(0);
        hold off;
        plot(track_A);
        hold on;
        plot(track_B);
        hold off;
    end
    pause(0);
       
    set_inst(multi,'V',0.001);
    output.I1(index) = read_inst(multi,'XI');
    output.V1(index) = read_inst(multi,'XV');
    output.TA1(index) = read_inst(heater,'A');
    output.TB1(index) = read_inst(heater,'B');
    set_inst(multi,'V',-0.001);
    output.I2(index) = read_inst(multi,'XI');
    output.V2(index) = read_inst(multi,'XV');
    output.TA2(index) = read_inst(heater,'A');
    output.TB2(index) = read_inst(heater,'B');
    set_inst(multi,'V',0.01);
    output.I3(index) = read_inst(multi,'XI');
    output.V3(index) = read_inst(multi,'XV');
    output.TA3(index) = read_inst(heater,'A');
    output.TB3(index) = read_inst(heater,'B');
    set_inst(multi,'V',-0.01);
    output.I4(index) = read_inst(multi,'XI');
    output.V4(index) = read_inst(multi,'XV');
    output.TA4(index) = read_inst(heater,'A');
    output.TB4(index) = read_inst(heater,'B');
    set_inst(multi,'V',0.05);
    output.I5(index) = read_inst(multi,'XI');
    output.V5(index) = read_inst(multi,'XV');
    output.TA5(index) = read_inst(heater,'A');
    output.TB5(index) = read_inst(heater,'B');
    set_inst(multi,'V',-0.05);
    output.I6(index) = read_inst(multi,'XI');
    output.V6(index) = read_inst(multi,'XV');
    output.TA6(index) = read_inst(heater,'A');
    output.TB6(index) = read_inst(heater,'B');
    set_inst(multi,'V',0.1);
    output.I7(index) = read_inst(multi,'XI');
    output.V7(index) = read_inst(multi,'XV');
    output.TA7(index) = read_inst(heater,'A');
    output.TB7(index) = read_inst(heater,'B');
    set_inst(multi,'V',-0.1);
    output.I8(index) = read_inst(multi,'XI');
    output.V8(index) = read_inst(multi,'XV');
    output.TA8(index) = read_inst(heater,'A');
    output.TB8(index) = read_inst(heater,'B');
    set_inst(multi,'V',0);

       figure(1);
       pause(0);
       %hold off;
       plot(output.TA1(1:index),output.V1(1:index)./output.I1(1:index));
       hold on;
       plot(output.TA2(1:index),output.V2(1:index)./output.I2(1:index));
       hold on;
       plot(output.TA3(1:index),output.V3(1:index)./output.I3(1:index));
      hold on;
       plot(output.TA4(1:index),output.V4(1:index)./output.I4(1:index)); 
      hold on;
       plot(output.TA5(1:index),output.V5(1:index)./output.I5(1:index));
      hold on;
       plot(output.TA6(1:index),output.V6(1:index)./output.I6(1:index));
       hold on;
       plot(output.TA7(1:index),output.V7(1:index)./output.I7(1:index));
      hold on;
       plot(output.TA8(1:index),output.V8(1:index)./output.I8(1:index));
       %hold off;
   
end

save output;
