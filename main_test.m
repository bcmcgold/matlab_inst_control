%% measure RH
clear all;
instrreset;

multi.obj = gpib('ni',0,4); fopen(multi.obj);
multi.name = 2400;

sweep_range = linspace(0,1,3);
output.current = sweep_range;

output.start_time = datetime();

for index=1:length(sweep_range)
    tic;
    set_inst(multi,'mA',sweep_range(index));
    pause(1);
    output.data(index) = read_inst(multi,'XV');
    figure(1);
    plot(sweep_range(1:index),output.data(1:index),'-x');
    output.time_sep(index) = toc;
end

output.end_time = datetime();

save('test.m',"output");

