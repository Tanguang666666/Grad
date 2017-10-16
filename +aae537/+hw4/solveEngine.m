function [engineData, mixError] = solveEngine(varargin)
%SOLVEENGINE Solves the engine (Part II)
% engineData contains all relevant solved engine data
% mixError is the percent error between bypass and core pressures before
% mixing (if relevant)

mixError = [];

np = aeroBox.inputParser();

% Required inputs
np.addParameter('eta_c', []); % Compressor efficiency
np.addParameter('eta_b', []); % Combustor efficiency
np.addParameter('eta_t', []); % Turbine efficiency
np.addParameter('eta_n', []); % Nozzle efficiency
np.addParameter('h', []); % Fuel heating value
np.addParameter('Tt4', []); % Turbine entrace total temperature
np.addParameter('M0', []); % Free stream mach
np.addParameter('q', []); % Free stream dynamic pressure
np.addParameter('T0', []); % Free stream static temperature
np.addParameter('CPR', []); % Compression ratio
np.addParameter('gamma', []); % Ratio of specific heats
np.addParameter('cp', []); % Specific heat at constant pressure
np.addParameter('m_dot', []) % Total engine mass flow
np.addParameter('beta', []); % Bypass ratio
np.addParameter('R', []); % Gas constant

% Possible inputs
np.addParameter('Tt7', []); % Nozzle entrace total temperature (assumes afterburner in use)
np.addParameter('eta_ab', []); % Afterburner efficiency


% Can only define M5_c or M5_b, not both
np.addParameter('M5_c', []); % Core mach number exit after turbine/before mixing
np.addParameter('M5_b', []); % Bypass mach number before mixing
np.addParameter('A5_c', []);

np.parse(varargin{:});

gamma = np.results.gamma;
cp = np.results.cp;
R = np.results.R;


% Import useful functions
import aeroBox.isoBox.*;

% Split up mass flows
m_c = np.results.m_dot / (1 + np.results.beta);
m_b = np.results.m_dot - m_c;

% Inlet: 0 -> 2
P0 = 2 * np.results.q / (gamma * np.results.M0^2);
Pt0 = calcStagPressure('Ps', P0, 'gamma', gamma, 'mach', np.results.M0);
Tt0 = calcStagTemp('Ts', np.results.T0, 'gamma', gamma, 'mach', np.results.M0);
Pt2 = Pt0 * aae537.hw4.MilStd5008B(np.results.M0);
Tt2 = Tt0;

% Compressor: 2 -> 3
Tt3 = Tt2 * (1 + (1 / np.results.eta_c) * (np.results.CPR^((gamma - 1) / gamma) - 1));
Pt3 = np.results.CPR * Pt2;

% Combustor: 3 -> 4
Tt4 = np.results.Tt4;
f = ((Tt4 / Tt3) - 1) / (((np.results.eta_b * np.results.h) / (cp * Tt3)) - (Tt4 / Tt3));
Pt4 = Pt3;

% Turbine: 4 -> 5
Pt5 = Pt4 * ( ...
    1 - (((Pt3 / Pt2)^((gamma - 1) / gamma) - 1) / (np.results.eta_t * np.results.eta_c * (Tt4 / Tt2))))^(gamma / (gamma - 1));
Tt5 = Tt4 * (1 - np.results.eta_t * (1 - ((Pt5 / Pt4)^((gamma - 1) / gamma))));

if isempty(np.results.A5_c) && ~isempty(np.results.M5_c)
    % Calculate static conditions at station 5 of the core
    P5_c = calcStaticPressure('Pt', Pt5, 'gamma', gamma, 'mach', np.results.M5_c); 
    T5_c = calcStaticTemp('Tt', Tt5, 'gamma', gamma, 'mach', np.results.M5_c);
    rho5_c = P5_c / (R * T5_c);
    
    u5_c = np.results.M5_c * sqrt(gamma * R * T5_c); % Velocity
    A5_c = (m_c * (1 + f)) / (rho5_c * u5_c); % Area at the end of the turbine
end

% Mixing: 5 -> 6
if np.results.beta == 0
    % No bypass air, same properties as station 5
    Pt6 = Pt5;
    Tt6 = Tt5;
    m6 = (1 + f) * m_c;
else
    % Mix assuming constant pressure mixing
    if ~isempty(np.results.M5_b) && ~isempty(np.results.A5_c)
        % Bypass stream defined, find static pressure
        P5 = calcStaticPressure('Pt', Pt5, 'gamma', gamma, 'mach', np.results.M5_b);
        P5_c = P5;
        % Find out what the core needs to look like in order to match pressures
        M5_c = machFromPressureRatio('Prat', P5 / Pt5, 'gamma', gamma);
        T5_c = calcStaticTemp('Tt', Tt5, 'gamma', gamma, 'mach', M5_c);
        rho5_c = P5_c / (R * T5_c);
        
        u5_c = M5_c * sqrt(gamma * R * T5_c);
        A5_c = m_c / (rho5_c * u5_c);
        
        % Record the error in required core exit area
        mixError = (A5_c - np.results.A5_c) / np.results.A5_c;
        
        % Solve bypass static properties
        T5_b = calcStaticTemp('Tt', Tt2, 'gamma', gamma, 'mach', np.results.M5_b);
        u5_b = np.results.M5_b * sqrt(gamma * R * T5_b);
        
        % Continue with mixing calculation
        m6 = m_b + m_c * (1 + f);
        u_6 = (m_c * (1 + f) * u5_c + m_b * u5_b) / m6;
        % Can analytically solve for T6 assuming cp's are all the same
        % (thank you!)
        T6 = (((m_b * (cp * T5_b + u5_b^2 / 2) + m_c * (1 + f) * (cp * T5_c + u5_c^2 / 2)) / m6) - (u_6^2 / 2)) / cp;
        M6 = u_6 / sqrt(gamma * R * T6);
        Tt6 = calcStagTemp('Ts', T6, 'gamma', gamma, 'mach', M6);
        Pt6 = calcStagPressure('Ps', P5, 'gamma', gamma, 'mach', M6);
    else
        error('Cannot solve flow!');
    end
end

% Afterburner: 6 -> 7
if ~isempty(np.results.Tt7)
    f_ab = ((np.results.Tt7 / Tt6) - 1) / (((np.results.eta_ab * np.results.h) / (Tt6 * cp)) - (np.results.Tt7 / Tt6));
    Tt7 = np.results.Tt7;
    Pt7 = Pt6;
    m7 = m6 * (1 + f_ab);
else
    % No afterburning
    Tt7 = Tt6;
    Pt7 = Pt6;
    m7 = m6;
end

% Nozzle: 7 -> 9
P9 = P0;
u9 = sqrt(2 * cp * Tt7 * np.results.eta_n * (1 - (P9 / Pt7)^((gamma - 1) / gamma)));
T9 = Tt7 * (1 - np.results.eta_n * (1 - (P9 / Pt5)^((gamma - 1) / gamma)));
M9 = u9 / sqrt(gamma * R * T9);
Tt9 = calcStagTemp('Ts', T9, 'gamma', gamma, 'mach', M9);
Pt9 = calcStagPressure('Ps', 'P9', 'gamma', gamma, 'mach', M9);

% Calculate thrust
thrust = m6 * u9 - np.results.m_dot * np.results.M0 * sqrt(gamma * R * np.results.T0); % lbf
if exist('f_ab')
    SFC = (f * m_c + f_ab * (m6)) / thrust;
else
    SFC = f * m_c / thrust;
end

engineData.SFC = SFC;
engineData.thrust = thrust;
if exist('A5_c')
    engineData.A5_c = A5_c;
end

end



