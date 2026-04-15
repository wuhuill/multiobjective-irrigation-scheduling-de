# Irrigation_DE_Project

A MATLAB demo for multi-objective DE-based irrigation optimization with a preserved crop growth model.

## Files
- `main.m` : entry point
- `params_demo.m` : demo parameters
- `create_demo_weather.m` : generates `demo_weather.mat`
- `optimizer/` : DE mutation, crossover, selection
- `model/` : objective wrapper and penalty handling
- `crop_model/` : preserved crop simulation model
- `utils/` : Pareto sorting and dominance utilities

## How to run
1. Open MATLAB in the project folder.
2. Run:
   ```matlab
   create_demo_weather
   main