%% MILP MICROGRID SCHEDULING - 1 week
% Uses GUROBI + YALMIP
% Components: load + PV + battery + PV curtailment + load shedding
% Duration: 1 week
% Time step: 1 hour

clear all
clc



%% DATA

% Solar radiation [W/m2]
load pv_1week;
solarRad = pv_1week';
etaPv = 0.2;
Spv = 1500; % [m2] - from sizing
Ppv = etaPv*Spv*solarRad;

% Load [W]
load load_1week
loadProfile = load_1week'*1e3;
Pload = loadProfile;


%% PARAMETERS

Horizon = length(solarRad);

% Battery
battSocMin = 0.3;
battSocMax = 0.9;
battPmin = 0;
battPmax = 500e3; % [W] - from sizing
battCapa = 5e6; % [Wh] - from sizing
battEff = 0.9;


%% VARIABLES

% Battery state (lines: 1 for charge, 2 for discharge)
battChargeOrNot = binvar(2,Horizon,'full'); % binary variable for charge or discharge
Pbatt = sdpvar(2,Horizon,'full'); % 

% Battery SOC and initialization
SOC = sdpvar(1,Horizon,'full'); 
SOC(1,1) = 0.8;

% Load shedding and PV curtailment
Pshed = sdpvar(1,Horizon,'full');
Pcurt = sdpvar(1,Horizon,'full');


%% CONSTRAINTS

% Constraints array initialization
Constraints = [];

% Battery power bounds constraint
for k=2:Horizon
	Constraints = [Constraints, battChargeOrNot(:,k)*battPmin <= Pbatt(:,k) <= battChargeOrNot(:,k)*battPmax];
end

% Battery state constraint
% No charge and discharge at the same time
for k=2:Horizon
	Constraints = [Constraints, battChargeOrNot(1,k) + battChargeOrNot(2,k)<=1];
end

% Battery SOC constraints
% Value update and min./max. bounds
dt = 1;
for k=2:Horizon % SOC
	SOC(1,k) = SOC(1,k-1) + battEff*Pbatt(1,k)*dt/(battCapa) - Pbatt(2,k)*dt/(battCapa);
	Constraints = [Constraints, battSocMin <= SOC(:,k) <= battSocMax];
end

% Power balance constraint
% PV + storage discharge = demand + storage charge
for k=2:Horizon 
    Constraints = [Constraints, Ppv(1,k) + Pshed(1,k) + Pbatt(2,k) == Pload(1,k) + Pcurt(1,k) + Pbatt(1,k)];
end

% Load shedding constraint
% Min. at 0, max. at load value
for k=2:Horizon  
	Constraints = [Constraints, 0 <= Pshed(1,k) <= Pload(1,k)];
end

% PV curtailment constraint
% Min. at 0, max. at PV output
for k=2:Horizon  
	Constraints = [Constraints, 0 <= Pcurt(1,k) <= Ppv(1,k)];
end


%% OBJECTIVE FUNCTION

Objective = 0;
penalty = 1e3;

for k=2:Horizon
	Objective = Objective + penalty*abs(Pshed(1,k)) + penalty*abs(Pcurt(1,k));
end


%% OPTIMIZATION

diagnostics = optimize(Constraints,Objective)
fitness = value(Objective)


%% PLOTS

figure
subplot(3,1,1:2)
plot(value(Ppv(1,2:Horizon)));
hold on
plot(-Pload(1,2:Horizon));
hold on
plot(-value(Pbatt(1,2:Horizon)));
hold on
plot(value(Pbatt(2,2:Horizon)));
hold on
plot(-value(Pshed(1,2:Horizon)),'-*');
hold on
plot(-value(Pcurt(1,2:Horizon)),'-*');
legend('PV','Load','Batt. charge','Batt. discharge','Load shedding','Curtailed PV');
xlabel('Time [h]')
ylabel('Power [W]')
xlim([0 Horizon])
grid

subplot(3,1,3)
plot(value(SOC(1,1:Horizon)));
legend('SOC');
xlabel('Time [h]')
ylabel('SOC')
xlim([0 Horizon])
ylim([0 1])
grid
