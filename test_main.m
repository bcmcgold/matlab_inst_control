clear all;
close all;
instrreset;

sourcemeter.obj = gpib('ni',0,24); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

% use SR810 as voltmeter and field
% voltmeter.obj = gpib('ni',0,8); fopen(voltmeter.obj);
% voltmeter.name = 'SR810';

field.obj = gpib('ni',0,8); fopen(field.obj);
field.name = 'SR810';
field.field_factor = 582;

for index=1:1000
tic;
load('test_data');
read_time(index) = toc

test = test+1;

tic
save("test_data.txt","test");
write_time(index) = toc
end
