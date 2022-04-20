# Gait Detection

For detailed description of the methods and corresponding reference works, see:
https://bit.ly/3JOMVDN

## Data

### Folder structure

```
.
├── BraViva/
│   ├── rawdata/
│   │   ├── sub-COKI70030/
│   │   │   └── ses-T2/
│   │   │       └── motion/
│   │   │           ├── sub-COKI70030_ses-T2_run-20200228.mat
│   │   │           ├── sub-COKI70030_ses-T2_run-20200229.mat
│   │   │           ├── ...
│   │   │           └── sub-COKI70030_ses-T2_run-20200306.mat
│   ├── derivatives/
│   │   ├── sub-COKI70030/
│   │   │   └── ses-T2/
│   │   │       ├── motion/
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200228_channels.tsv
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200228_motion.mat
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200228_channels.tsv
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200229_motion.mat
│   │   │       │   ├── ...
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200306_channels.tsv
│   │   │       │   └── sub-COKI70030_ses-T2_run-20200306_motion.mat
│   │   │       ├── press/
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200228_press.mat
│   │   │       │   ├── sub-COKI70030_ses-T2_run-20200229_press.mat
│   │   │       │   ├── ...
│   │   │       │   └── sub-COKI70030_ses-T2_run-20200306_press.mat
│   │   │       └── temp/
│   │   │           ├── sub-COKI70030_ses-T2_run-20200228_temp.mat
│   │   │           ├── sub-COKI70030_ses-T2_run-20200229_temp.mat
│   │   │           ├── ...
│   │   │           └── sub-COKI70030_ses-T2_run-20200306_temp.mat
└── ...
```

The `.mat` files in the `rawdata/` folder contain a single variable, `data`, namely a MATLAB struct that contains relevant data and corresponding meta-data:
```matlab
>>> load('./BraViva/rawdata/sub-COKI70030/sess-T2/motion/sub-COKI70030_sess-T2_run-2020028.mat', 'data')
>>> data
```
| tracked point | data       | acq_time_start
| ------------- | ---------- | --------------
| ankle         | 1x4 struct | 1x1 datetime
| lowBack       | 1x4 struct | 1x1 datetime
| wrist         | 1x4 struct | 1x1 datetime

For each of the tracked points, the data collected with the corresponding IMU is saved in a struct itself:
```matlab
>>> data(1).data
```
| type          | unit         | sampling_frequency | data
| ------------- | ------------ | ------------------ | ----
| angularRate   | dps          | 64                 | Nx3 double
| acc           | g            | 64                 | Nx1 double
| press         | Pa           |  8                 | Nx1 double
| temp          | Grad Celsius |  1                 | Nx3 double

with $N$ number of timesteps. 

```matlab
>>> ts_init = data(1).acq_time_start; % initial timestamp
>>> ts = ts_init + seconds((0:size(data(1).data(1).data,1)-1)'/data(1).data(1).sampling_frequency); % timestamps
>>> figure; plot(ts, data(1).data(1).data); % Plots the angular rate data of the ankle sensor
```

![alt text](fig_example_plot.png)

### Channels file
| filename | tracked_point | type | component | unit | sampling_frequency
| -------- | ------------- | ---- | --------- | ---- | ------------------
| sess-T2/motion/sub-COKI70030_sess-T2_run-20200228.mat | ankle | ACC | x | g | 64
| sess-T2/motion/sub-COKI70030_sess-T2_run-20200228.mat | ankle | ACC | y | g | 64
| ... | ... | ... | ... | ... | ...
| sess-T2/temp/sub-COKI70030_sess-T2_run-20200306.mat | ankle | TEMP | n/a | Grad Celsius | 1
