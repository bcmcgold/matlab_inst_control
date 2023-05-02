clear test;

for index=1:1000
tic;
load('test_data');
read_time(index) = toc

test = test+1;

tic
save("test_data.txt","test");
write_time(index) = toc
end
