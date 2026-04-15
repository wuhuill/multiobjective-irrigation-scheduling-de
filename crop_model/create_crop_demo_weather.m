function create_crop_demo_weather()

GPL = 120;
t = (1:GPL)';

weather.Temp = 15 + 10*sin(linspace(-pi/2, pi/2, GPL))' + 1.5*randn(GPL,1);
weather.RN   = 12 + 5*sin(linspace(-pi/2, pi/2, GPL))' + 1.0*randn(GPL,1);
weather.EP   = zeros(GPL,1);
weather.ET0  = 3 + 0.1*weather.Temp + 0.2*weather.RN + 0.5*randn(GPL,1);

rain_days = [10 30 50 80 100];
rain_amt  = [5 8 3 10 4];
weather.EP(rain_days) = rain_amt;

weather.Temp = max(weather.Temp, 0);
weather.RN   = max(weather.RN, 0);
weather.ET0  = max(weather.ET0, 0.5);

save('demo_crop_weather.mat', 'weather');
disp('demo_crop_weather.mat created.');

end