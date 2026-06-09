# MATLAB Interactive System

This folder contains the MATLAB interactive system for the TWD-BAL batch-feedback multicriteria sorting experiments.

The system provides an interactive workflow for constructing a reference set, training a sorting model, partitioning non-reference alternatives into TWD risk regions, recommending a batch of alternatives for decision-maker feedback, and updating the model after each feedback round.

## Files

| File           | Description                                                                          |
| -------------- | ------------------------------------------------------------------------------------ |
| `TWD_BAL_UI.m` | Main MATLAB user interface for the TWD-BAL interactive multicriteria sorting system. |

## How to run

Open MATLAB, set the current folder to this `app/` directory or add the folder to the MATLAB path, and run:

```matlab
TWD_BAL_UI
```

If MATLAB saved the file under a duplicate name such as `TWD_BAL_UI(1).m`, rename it to `TWD_BAL_UI.m` before running it.

## Workflow

1. Click **Load Data** to import a multicriteria sorting dataset.
2. Build the reference set in one of the following ways:

   * click **Random** to generate a random reference set by percentage;
   * use the **Reference set** tab to manually select reference alternatives and edit `DMClass`;
   * click **Import Ref Set** to import an external reference-set file.
3. Click **Train Model** to train the MM-UTADIS-based sorting model and classify the remaining alternatives.
4. Review the non-reference alternatives in the **Non-reference set** tab. The table shows predicted class, conditional probability `P(S)`, and TWD region.
5. Click **Suggest Batch** to let TWD-BAL recommend the next batch of alternatives for decision-maker feedback.
6. Use the feedback selectors at the bottom of the interface to assign decision-maker classes to the suggested alternatives.
7. Click **Submit** to update the reference information, retrain the model, refresh the sorting results, and append the interaction to the query log.
8. Review the feedback history in the **Query log** tab.

## Interface overview

The interface contains three main tabs:

| Tab                   | Purpose                                                                                                                                                                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Non-reference set** | Displays alternatives that are not yet in the reference set, together with predicted class, `P(S)`, and TWD region.                                                               |
| **Reference set**     | Allows users to select reference alternatives, edit decision-maker classes, and inspect whether a reference item was manually selected, randomly selected, or queried.            |
| **Query log**         | Records each queried alternative, the prediction before feedback, the submitted feedback class, the true class, whether the feedback corrected the model, the region, and `P(S)`. |

The right panel summarizes the number of known alternatives and the current distribution of non-reference alternatives across the three TWD regions:

```text
POS, BND, NEG
```

## Model parameters

The **Advanced settings** panel exposes the main interactive parameters:

| Parameter | Meaning                                   |
| --------- | ----------------------------------------- |
| `Kmax`    | Maximum query budget.                     |
| `xi`      | TWD-BAL risk/threshold-related parameter. |
| `MAC`     | Minimum assignment confidence parameter.  |

Some internal parameters are fixed in the current UI implementation, including `L = 3` and `Ns = 100`.

## Data format

The system accepts `.csv`, `.xlsx`, or `.xls` files.

The main dataset should contain the following columns:

```text
Alternative, g1, g2, ..., Class
```

where:

* `Alternative` is optional. If omitted, the system generates alternative names automatically.
* `g1, g2, ...` are criterion columns.
* `Class` is required and represents the ordered assignment class.
* Class labels should be positive integer values such as `1, 2, ..., q`.
* At least two classes are required.

Example:

| Alternative |   g1 |   g2 |   g3 | Class |
| ----------- | ---: | ---: | ---: | ----: |
| a1          | 0.72 | 0.41 | 0.88 |     2 |
| a2          | 0.35 | 0.76 | 0.52 |     1 |
| a3          | 0.91 | 0.63 | 0.79 |     3 |

## Reference-set format

Reference sets can be created directly in the UI or imported from a `.csv`, `.xlsx`, or `.xls` file.

An imported reference-set file may contain columns such as:

```text
Alternative, UseRef, DMClass
```

or equivalent names supported by the interface:

* alternative identifier: `Alternative`, `Alt`, or `Name`;
* reference indicator: `UseRef`, `Reference`, or `Selected`;
* decision-maker class: `DMClass`, `Class`, or `Feedback`.

If no alternative identifier column is provided, the reference-set file must have the same number of rows as the loaded dataset.

## Notes

* The feedback dropdowns are prefilled with the true `Class` values for offline experiment and demonstration purposes.
* In a real decision-support setting, the decision maker should manually choose the feedback class for each suggested alternative.
* After each submitted batch, the model is retrained and the non-reference set, region distribution, and query log are refreshed.
