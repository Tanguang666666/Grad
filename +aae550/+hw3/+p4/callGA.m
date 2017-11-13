close all;
clear;

options = aae550.hw3.p3.goptions([]);

% Gene encoding:
%   
%     |   Beam 1     |    Beam 2     |    Beam 3     |
% x = [Material, Area, Material, Area, Material, Area]
% Area in [m^2]
vlb = [1 1e-4 1 1e-4 1 1e-4];	%Lower bound of each gene
vub = [4 1e-3 4 1e-3 4 1e-3];	%Upper bound of each gene
bits =[2 30 2 30 2 30];	% Number of bits describing each gene

l = sum(bits); % Chromosome length

% Basic guidlines for population and mutation rate
nPop = 4 * l;
pMutation = (l + 1) / (2 * nPop * l);

% Set options
options(11) = nPop; % Set the population size
options(13) = pMutation; % Set the mutation probability
options(14) = 1e6; % Maximum number of generations

% Evaluate
pMult = 5e2; % Penalty multiplier
[x,fbest,stats,nfit,fgen,lgen,lfit]= aae550.hw3.p3.GA550(@(x) aae550.hw3.p4.evalTruss(x, pMult),[ ],options,vlb,vub,bits);

% Print results
resolution = (vub(2) - vlb(2)) / (2^bits(2));
fprintf('Cross sectional area resolution: %0.9f %sm^2 \n', resolution * 1e12, char(956));

disp(x)
[phi, g] = aae550.hw3.p4.evalTruss(x)
assert(all(g <= 0), 'Constraints violated!');