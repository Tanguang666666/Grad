% Thomas Satterly
% AAE 537
% Homework 5, part iv (optimization)
clear;
close all;


dmdot_dt = @(x) 1.3 * ((x <= 0.5) * sin(pi * x) + ...
    (x > 0.5) * (x <= 2.5) * 1 + ...
    (x > 2.5) * sin(pi * (x - 2)));

burner = aae550.final.Burner();
burner.setMaxStep(5e-3);

% Set up the geometry
w = 1.067724; % need to calculate this
h = w / 5;

numSegments = 50;
startAngle = 1;
endAngle = 12;
totalLength = 3;
aa = linspace(-pi / 2, 3 * pi / 2, numSegments);
angles = (sin(aa) + 1) * 6;
width = w;
height = h;
lengths = ones(1, numSegments) * totalLength / numSegments;


% Setup the initial flow
M0 = 6; % Freestream mach
M3 = 2.5; % Mach at isolator exit
pr = 0.7; % Inlet/compression system total pressure recovery factor
mdot = 100; % [kg/s] Mass flow of air at isolator exit
h = 120908000;  % J/kg
startFlow = aeroBox.flowFields.FlowElement();
startFlow.setCp(1216); % J/kg*K
startFlow.setR(287.058); % J/kg*K

startFlow.setGamma(1.4);
startFlow.setMach(M3);
startFlow.setStagnationTemperature(aeroBox.isoBox.calcStagTemp('mach', M0, 'gamma', 1.4, 'Ts', 227));
startFlow.setStagnationPressure(aeroBox.isoBox.calcStagPressure('mach', M0, 'gamma', 1.4, 'Ps', 1117) * pr);
startFlow.setMassFlow(mdot);

cea = nasa.CEARunner();
params = cea.run('prob', 'tp', 'p(bar)', startFlow.P()/1e5, 't,k', startFlow.T(), 'reac', 'name', 'Air', 'wt%', 100, 'end');

startFlow.setGamma(params.output.gamma);
startFlow.setCp(params.output.cp * 1e3);

burner.setGeometry(width, height, lengths, angles);
burner.setHeatingValue(h);
burner.setInjectionFunc(dmdot_dt);
burner.setStartFlow(startFlow);


% Setup solver


burner.solve();

states = burner.states;
M = zeros(1, numel(states));
u = zeros(1, numel(states));
for l = 1:numel(states)
    x(l) = states{l}.x;
    flow = states{l}.flow;
    M(l) = flow.M();
    mdot(l) = flow.mdot();
    u(l) = flow.u();
    Pt(l) = flow.Pt();
    Tt(l) = flow.Tt();
    R(l) =flow.R();
    cp(l) = flow.cp();
    T(l) = flow.T();
    gamma(l) = flow.gamma();
end
if any(M < 1)
    thrust = -1;
else
    thrust = u(end) * mdot(end);
end

plot(x, M);
burner.plotGeometry();



