# irrigation-model

A MATLAB demo for multi-objective DE-based irrigation optimization with a preserved crop growth model.

## Project Structure
- `main.m` : entry point for the optimization demo
- `params_demo.m` : demo parameters
- `create_demo_weather.m` : script to generate `demo_weather.mat`
- `demo_weather.mat` : demo weather data used by the demos
- `optimizer/` : DE mutation, crossover, and selection
- `model/` : objective wrapper and penalty handling
- `crop_model/` : preserved crop simulation model and standalone crop demo
- `utils/` : Pareto sorting and dominance utilities

## How to Run

### 1. Generate demo weather data
Run this in MATLAB:

    create_demo_weather

### 2. Run the standalone crop model demo
Run this in MATLAB:

    crop_model/crop_demo

### 3. Run the optimization demo
Run this in MATLAB:

    main

## Notes
- `run_crop_model.m` is preserved.
- The crop model demo can be run independently from the optimization demo.
- The optimization part uses penalty-based constraint handling and Pareto-based selection.
- The public demo is intended to support reproducibility while keeping the release compact.