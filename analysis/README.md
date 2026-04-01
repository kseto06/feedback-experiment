# Data Analysis

This `./analysis` folder serves as the directory where the Firebase database exporter (to CSV) and R code data analysis is stored. 

## Installation and Setup

### R Setup
1. Install R from the [CRAN Website](https://mirror.csclub.uwaterloo.ca/CRAN/). This link specifically navigates to the Waterloo domain. 
2. Install all necessary R packages required using:
```sh
Rscript -e 'install.packages(c("tidyverse","checkmate"), repos="https://cloud.r-project.org")'
```
3. From the base directory, the R code can be run using:
```sh
Rscript analysis/main.r
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

NOTE: When running the script, `main.r` will automatically run the `npx tsx` terminal command for exporting the Firebase data to ensure the most up-to-date version when running data analysis.