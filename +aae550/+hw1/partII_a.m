% Thomas Satterly
% AAE 550
% HW 1, Part II (a)
clear;
close all;
clc;

% Setup problem
aae550.hw1.partII_setup;


cs = ones(1, numel(gs));
% Set constraint coefficients

for i = 1:numel(gs)
    gs{i} = @(x) cs(i) * gs{i}(x);
end

% Define penalty coefficient
rp = 1e3;
maxErr = 1e-1;
err = inf;
fLast = inf;
x0 = [0.4; 0.385];
isValid = 0;
minCount = 0;
iterationCount = 0;
j  = 0;
while err > maxErr || ~isValid
    j = j + 1;
    % Create pseudo-objective function
    objFunc = @(x) aae550.hw1.extPenalty(f, x, rp, gs);
    
    options = optimoptions(@fminunc, 'Display', 'iter', 'PlotFcn', @optimplotfval);
    
    [x_opt, f_opt, exitFlag, output, grad] = fminunc(objFunc, [0.4; 0.35], options);
    
    % Record values for table
    data(j).minimization = j;
    data(j).rp = rp;
    data(j).x0 = x0;
    data(j).xOpt = x_opt;
    data(j).fOpt = f(x_opt);
    [isValid, data(j).gx] = aae550.hw1.checkConstraints(gsOrig, x_opt);
    data(j).iterations = output.iterations;
    data(j).exitFlag = exitFlag;
    
    err = abs(f_opt - fLast);
    fLast = f_opt;
    x0 = x_opt;
    rp = rp * 1.1;
    
    % Update counters
    minCount = minCount + 1;
    iterationCount = iterationCount + output.iterations + 1; % Oh, so now Matlab decides to start indecies at 0
end

% Make sure final solution is valid
[isValid, gx] = aae550.hw1.checkConstraints(gs, x_opt);
assert(isValid, 'Solution is invalid!');

% Post data to excel table

% File name
fName = [mfilename('fullpath'), '.xlsx'];

% Create table column titles
gCell = {};
for i = 1:numel(gs)
    gCell{i} = sprintf('g%d(x_star)', i);
end
xlswrite(fName, {'Minimization', 'r_p', 'x_0', 'x_star', 'f(x_star)', gCell{:}, '# of Iterations', 'Exit Flag'}, 'sheet1');

for i = 1:numel(data)
    dataCell = {};
    dataCell{1} = data(i).minimization;
    dataCell{2} = data(i).rp;
    dataCell{3} = num2str(data(i).x0');
    dataCell{4} = num2str(data(i).xOpt');
    dataCell{5} = data(i).fOpt;
    for j = 1:numel(data(i).gx)
        dataCell{end + 1} = data(i).gx(j);
    end
    dataCell{end + 1} = data(i).iterations;
    dataCell{end + 1} = data(i).exitFlag;
    xlswrite(fName, dataCell, 'sheet1', sprintf('A%d', i + 1));
end
