# MATLAB interactive system

This folder contains the MATLAB interactive system for the TWD-RAPL
multicriteria sorting experiments.

## Files

| File | Description |
| --- | --- |
| `MCS_RAPL_UI.m` | Main MATLAB user interface. |

## How to run

Open MATLAB, set the current folder to this `app/` directory or add it to the
MATLAB path, and run:

```matlab
MCS_RAPL_UI
```

After the interface opens, use the data-loading button to select a CSV file from:

```text
data/raw/
```

## Data format

The system accepts CSV, XLSX, or XLS files with the following columns:

```text
Alternative, g1, g2, ..., Class
```

`Alternative` is optional. Criterion columns are named `g1`, `g2`, and so on.
`Class` is the ordered assignment class.
