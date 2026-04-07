# Data Analysis

This `./analysis` folder serves as the directory where the R code data analysis and Firebase exporter (to CSV)  is stored. 

## Code Descriptions

### `main.r`

The `main.r` script runs data analysis and visualization for generating box-and-whisker plots, bar charts (for means of variables), and a linear regression model to analyze the various effects of response time and accuracy versus feedback types and the time-accuracy tradeoff, respectively. 

### `QQ.r`

The `QQ.r` script runs data analysis and visualization for generating QQ plots, analyzing normality of response time and accuracy distributions across both feedback types.

### `T_test.r`

The `T_test.r` runs Welch's two-sample t-tests to compare response time and accuracy across both feedback types and outputs means, degrees of freedom, t-statistics, p-values, and confidence intervals for each group. 

### `covariates.r`

The `covariates.r` script runs data analysis and visualization for generating QQ plots and multi-linear regression to analyze the effects of covariates on dependent variables versus feedback type. 

## Installation and Setup

### R Setup
1. Install R from the [CRAN Website](https://mirror.csclub.uwaterloo.ca/CRAN/). This link specifically navigates to the Waterloo domain. 
2. Install all necessary R packages required using:
```sh
Rscript -e 'install.packages(c("tidyverse","checkmate"), repos="https://cloud.r-project.org")'
```
3. From the base directory, the R code can be run using:
```sh
Rscript analysis/<r_file_name>.r
```

### Node.js and Firebase Export Setup

1. Install Node.js from the [Node.js Website](https://nodejs.org/).

2. Install project dependencies using:
```sh
npm install
```
3. Export Firebase data to CSV using:
```sh
npx tsx analysis/export.ts
```

NOTE: When running the `main.r` script, it will automatically run the `npx tsx` terminal command for exporting the Firebase data to ensure the most up-to-date version when running data analysis.