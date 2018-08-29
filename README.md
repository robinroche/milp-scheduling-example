# milp-scheduling-example

Mixed integer linear programming (MILP) scheduling example for an islanded microgrid with PV panels and a battery.
- Takes load and solar radiation forecasts as inputs.
- Returns the schedule for each component over the planed horizon (e.g., one week).
- Tries to minimize load shedding and generation curtailment.
- Requires YALMIP and GUROBI, both properly installed and interfaced with MATLAB.
- Based on a simplified version of Bei Li's work in: https://doi.org/10.1016/j.apenergy.2016.12.038

If you are using this code, please cite the above publication.
