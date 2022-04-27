# Gait Detection

For detailed description of the methods and corresponding reference works, see: https://bit.ly/3JOMVDN

## Code


## Data
### Source Data
The [Movisens Move 4](https://docs.movisens.com/Sensors/Move4/) source data consist of 24/7 time series data for each of the devices (i.e., low back, wrist, ankle sensor). The data are in binary format and contain sensing modalities for linear acceleration (`acc.bin`), angular velocity (`angularrate.bin`), barometric pressure (`press.bin`) and ambient temperature (`temp.bin`). Relevant meta-data, such as sampling frequency and units, are available from a accompanying `unisens.xml` file. In order to get from source data to a raw data format that can be further processed, the sensor data are accummulated on a per-day basis, and both data and meta-data are saved in a MATLAB struct.

### Raw Data
The resulting raw data are organized in a BIDS-like format, i.e.:
```
.
├── BraViva/
│   ├── rawdata/
│   │   ├── sub-COKI10147/
│   │   │   └── ses-T2/
│   │   │       └── motion/
│   │   │           ├── sub-COKI10147_ses-T2_tracksys-imu_date-20191126.mat
│   │   │           ├── sub-COKI10147_ses-T2_tracksys-imu_date-20191127.mat
│   │   │           ├── ...
│   │   │           └── sub-COKI10147_ses-T2_tracksys-imu_date-20191203.mat
```

The `.mat` files in the `rawdata/` folder contain a single variable, `data`, namely a MATLAB struct that contains relevant data and corresponding meta-data:
```matlab
>>> load('./BraViva/rawdata/sub-COKI70030/sess-T2/motion/sub-COKI70030_sess-T2_run-2020028.mat', 'data')
>>> data
```
| tracked point | data       | acq time start
| ------------- | ---------- | --------------
| ankle         | 1x4 struct | 1x1 datetime
| lowBack       | 1x4 struct | 1x1 datetime
| wrist         | 1x4 struct | 1x1 datetime

For each of the tracked points, the data collected with the corresponding device is saved in a struct itself:
```matlab
>>> data(1).data
```
| type          | unit         | sampling_frequency | data
| ------------- | ------------ | ------------------ | ----
| angularRate   | dps          | 64                 | Nx3 double
| acc           | g            | 64                 | Nx1 double
| press         | Pa           |  8                 | Nx1 double
| temp          | Grad Celsius |  1                 | Nx3 double

with $N$ number of timesteps, that is $f_{\mathrm{s}}*60*60*24$ for a full day of measurement (e.g., 5,529,600 time steps at 64 Hz). 

```matlab
>>> ts_init = data(1).acq_time_start; % initial timestamp
>>> ts = ts_init + seconds((0:size(data(1).data(1).data,1)-1)'/data(1).data(1).sampling_frequency); % timestamps
>>> figure; plot(ts, data(1).data(1).data); % Plots the angular rate data of the ankle sensor
```

### Derived Data
Currently, analysis of the IMU data consists of two main applictions:
1. objective quantification of physical  activity in a general sense, and
2. detection of walking bouts, and subsequent quantitative and qualitative clinical gait analysis

The derived data are saved in a folder structure according to the following proposed structure:
```
.
├── BraViva/
│   ├── deriveddata/
│   │   ├── sub-COKI10147/
│   │   │   └── ses-T2/
│   │   │       └── sma/
│   │   │           ├── sub-COKI10147_ses-T2_tracksys-imu_trackedpoint-ankle_date-20191126.tsv
│   │   │           ├── sub-COKI10147_ses-T2_tracksys-imu_trackedpoint-ankle_date-20191127.tsv
│   │   │           ├── ...
│   │   │           └── sub-COKI10147_ses-T2_tracksys-imu_trackedpoint-wrist-date_20191203.tsv
```
