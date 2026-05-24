function TWD_RAE_UI
% TWD_RAE_UI  Interactive TWD-RAE multicriteria sorting demo.
%
% Data format:
%   Alternative (optional), g1, g2, ..., Class
%
% Workflow:
%   1. Load a CSV/XLSX dataset.
%   2. Mark a few alternatives as reference examples and assign DMClass.
%   3. Train MM-UTADIS and classify all remaining alternatives.
%   4. Let TWD-RAE recommend a high-risk alternative to query.
%   5. Submit the decision maker's class feedback and update the model.

    state = emptyState();

    theme.bg = [1.000 1.000 1.000];
    theme.panel = [1.000 1.000 1.000];
    theme.line = [0.875 0.890 0.910];
    theme.text = [0.122 0.161 0.200];
    theme.muted = [0.420 0.447 0.502];
    theme.tableText = [0.200 0.200 0.200];
    theme.tableHeaderBg = [0.949 0.953 0.961];
    theme.tableHeaderText = [0.067 0.067 0.067];
    theme.mutedBlue = [0.180 0.300 0.430];
    theme.tableFontSize = 18;
    theme.tableHeaderFontSize = 18;

    % Clear product-style palette: blue actions, teal training, amber query.
    theme.paperBlue = [0.145 0.388 0.922];
    theme.paperTeal = [0.000 0.585 0.620];
    theme.paperGold = [0.965 0.700 0.000];
    theme.paperPurple = [0.520 0.160 0.760];
    theme.paperDark = [0.180 0.200 0.225];
    theme.font = 'Times New Roman';

    theme.primary = theme.paperBlue;
    theme.primarySoft = [0.900 0.945 1.000];
    theme.valueRed = [0.920 0.000 0.000];
    theme.posColor = [137 183 75] / 255;
    theme.bndColor = [237 177 32] / 255;
    theme.negColor = [217 83 25] / 255;
    theme.posSoft = [231 241 219] / 255;
    theme.bndSoft = [253 247 233] / 255;
    theme.negSoft = [247 221 209] / 255;
    theme.neutralSoft = [1.000 1.000 1.000];
    theme.querySoft = [239 248 255] / 255;
    theme.posBar = [137 183 75] / 255;
    theme.bndBar = [237 177 32] / 255;
    theme.negBar = [217 83 25] / 255;
    theme.buttonGray = [0.925 0.930 0.938];
    theme.buttonGrayText = [0.120 0.140 0.165];
    theme.greenSoft = theme.posSoft;
    theme.yellowSoft = theme.bndSoft;
    theme.redSoft = theme.negSoft;
    theme.purpleSoft = [0.930 0.880 0.985];
    lang = "en";

    fig = uifigure('Name', 'TWD-RAE Interactive Multicriteria Sorting System', ...
        'Position', [100 100 1500 850], 'Color', theme.bg);

    root = uigridlayout(fig, [3 1]);
    setBackgroundIfAvailable(root, theme.bg);
    root.RowHeight = {66, '1x', 76};
    root.ColumnWidth = {'1x'};
    root.Padding = [16 12 16 12];
    root.RowSpacing = 10;

    headerPanel = uipanel(root, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    header = uigridlayout(headerPanel, [2 16]);
    setBackgroundIfAvailable(header, theme.panel);
    header.RowHeight = {42, 1};
    header.ColumnWidth = {'1x', '1x', '1x', '1x', 60, 46, 24, 70, 44, 72, 32, 72, 24, 64, 44, 82};
    header.Padding = [14 18 14 0];
    header.RowSpacing = 4;
    header.ColumnSpacing = 8;

    lblTitle = uilabel(header, 'Text', '', ...
        'FontSize', 22, 'FontWeight', 'bold', 'FontColor', theme.text);
    lblTitle.Layout.Row = 1;
    lblTitle.Layout.Column = [1 4];

    lblSubtitle = uilabel(header, ...
        'Text', '', ...
        'FontSize', 11.5, 'FontColor', theme.muted);
    lblSubtitle.Layout.Row = 2;
    lblSubtitle.Layout.Column = [1 4];
    lblSubtitle.Visible = 'off';

    lblStatus = uilabel(header, 'Text', '', ...
        'FontSize', 14, 'FontWeight', 'bold', 'FontColor', [0.000 0.235 0.620], ...
        'BackgroundColor', theme.primarySoft, 'HorizontalAlignment', 'center');
    lblStatus.Layout.Row = 1;
    lblStatus.Layout.Column = [8 11];
    lblStatus.Visible = 'off';

    btnLoad = uibutton(header, 'Text', '', 'ButtonPushedFcn', @onLoadData, ...
        'BackgroundColor', theme.buttonGray, 'FontColor', theme.buttonGrayText, ...
        'FontWeight', 'bold', 'FontSize', 16);
    btnLoad.Layout.Row = 1;
    btnLoad.Layout.Column = [8 9];
    setButtonIcon(btnLoad, 'load', theme.buttonGrayText, theme.buttonGray);

    btnTrain = uibutton(header, 'Text', '', 'ButtonPushedFcn', @onTrain, ...
        'BackgroundColor', theme.buttonGray, 'FontColor', theme.buttonGrayText, ...
        'FontWeight', 'bold', 'FontSize', 16);
    btnTrain.Layout.Row = 1;
    btnTrain.Layout.Column = [10 11];
    setButtonIcon(btnTrain, 'train', theme.buttonGrayText, theme.buttonGray);

    btnRandomRef = uibutton(header, 'Text', '', 'ButtonPushedFcn', @onRandomReferences, ...
        'BackgroundColor', theme.buttonGray, 'FontColor', theme.buttonGrayText, ...
        'FontWeight', 'bold', 'FontSize', 16);
    btnRandomRef.Layout.Row = 1;
    btnRandomRef.Layout.Column = [5 7];
    setButtonIcon(btnRandomRef, 'sample', theme.buttonGrayText, theme.buttonGray);

    btnSuggest = uibutton(header, 'Text', '', 'ButtonPushedFcn', @onSuggest, ...
        'BackgroundColor', theme.primary, 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'FontSize', 16);
    btnSuggest.Layout.Row = 1;
    btnSuggest.Layout.Column = [12 14];
    setButtonIcon(btnSuggest, 'suggest', [1 1 1], theme.primary);

    ddLang = uidropdown(header, 'Items', {'English / 中文','中文','English'}, 'Value', 'English / 中文', ...
        'ValueChangedFcn', @onLanguageChanged, 'FontSize', 16);
    ddLang.Layout.Row = 1;
    ddLang.Layout.Column = [15 16];

    lblModelParams = uilabel(header, 'Text', 'Model Parameters', ...
        'FontSize', 14, 'FontWeight', 'bold', 'FontColor', theme.muted, ...
        'HorizontalAlignment', 'right', 'FontName', theme.font);
    lblModelParams.Layout.Row = 2;
    lblModelParams.Layout.Column = [5 6];

    lblLParam = addParamLabel(header, 'L', 11, theme);
    edtL = uieditfield(header, 'numeric', 'Value', 3, 'Limits', [1 inf], ...
        'RoundFractionalValues', 'on', 'HorizontalAlignment', 'center', ...
        'FontSize', 14, 'FontColor', [0 0 0], 'ValueChangedFcn', @onSettingsChanged);
    edtL.Layout.Row = 2;
    edtL.Layout.Column = 12;

    lblXiParam = addParamLabel(header, 'λ', 13, theme);
    edtXi = uieditfield(header, 'numeric', 'Value', 0.40, 'Limits', [eps 0.499], ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontColor', [0 0 0], ...
        'ValueChangedFcn', @onSettingsChanged);
    edtXi.Layout.Row = 2;
    edtXi.Layout.Column = 14;
    lblXiParam.Text = '\xi';
    setInterpreterIfAvailable(lblXiParam, 'tex');

    lblMACParam = addParamLabel(header, 'MAC', 15, theme);
    edtMAC = uieditfield(header, 'numeric', 'Value', 0.60, 'Limits', [eps 1-eps], ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontColor', [0 0 0], ...
        'ValueChangedFcn', @onSettingsChanged);
    edtMAC.Layout.Row = 2;
    edtMAC.Layout.Column = 16;

    lblNsParam = addParamLabel(header, 'N', 7, theme);
    edtNs = uieditfield(header, 'numeric', 'Value', 100, 'Limits', [1 inf], ...
        'RoundFractionalValues', 'on', 'HorizontalAlignment', 'center', ...
        'FontSize', 14, 'FontColor', [0 0 0], 'ValueChangedFcn', @onSettingsChanged);
    edtNs.Layout.Row = 2;
    edtNs.Layout.Column = 8;

    lblKmaxParam = addParamLabel(header, 'Kmax', 9, theme);
    edtKmax = uieditfield(header, 'numeric', 'Value', 10, 'Limits', [1 inf], ...
        'RoundFractionalValues', 'on', 'HorizontalAlignment', 'center', ...
        'FontSize', 14, 'FontColor', [0 0 0], 'ValueChangedFcn', @onSettingsChanged);
    edtKmax.Layout.Row = 2;
    edtKmax.Layout.Column = 10;

    advancedOpen = false;
    advancedControls = {lblModelParams, lblNsParam, edtNs, lblKmaxParam, edtKmax, lblLParam, edtL, lblXiParam, edtXi, lblMACParam, edtMAC};
    fig.UserData = state;

    main = uigridlayout(root, [1 2]);
    setBackgroundIfAvailable(main, theme.bg);
    main.ColumnWidth = {'7x', '3x'};
    main.RowHeight = {'1x'};
    main.Padding = [0 0 0 0];
    main.ColumnSpacing = 16;

    leftPane = uigridlayout(main, [2 1]);
    setBackgroundIfAvailable(leftPane, theme.panel);
    leftPane.Layout.Row = 1;
    leftPane.Layout.Column = 1;
    leftPane.RowHeight = {42, '1x'};
    leftPane.ColumnWidth = {'1x'};
    leftPane.Padding = [0 0 0 0];
    leftPane.RowSpacing = 0;

    tabBar = uigridlayout(leftPane, [1 4]);
    setBackgroundIfAvailable(tabBar, theme.panel);
    tabBar.Layout.Row = 1;
    tabBar.Layout.Column = 1;
    tabBar.ColumnWidth = {170, 150, 120, '1x'};
    tabBar.RowHeight = {'1x'};
    tabBar.Padding = [0 0 0 0];
    tabBar.ColumnSpacing = 0;
    btnTabData = uibutton(tabBar, 'Text', '', 'ButtonPushedFcn', @(~,~) switchMainTab("data"), ...
        'FontName', theme.font, 'FontSize', 18, 'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left');
    btnTabData.Layout.Row = 1;
    btnTabData.Layout.Column = 1;
    btnTabReference = uibutton(tabBar, 'Text', '', 'ButtonPushedFcn', @(~,~) switchMainTab("reference"), ...
        'FontName', theme.font, 'FontSize', 18, 'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left');
    btnTabReference.Layout.Row = 1;
    btnTabReference.Layout.Column = 2;
    btnTabMetrics = uibutton(tabBar, 'Text', '', 'ButtonPushedFcn', @(~,~) switchMainTab("metrics"), ...
        'FontName', theme.font, 'FontSize', 18, 'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left');
    btnTabMetrics.Layout.Row = 1;
    btnTabMetrics.Layout.Column = 3;

    tabContent = uigridlayout(leftPane, [1 1]);
    setBackgroundIfAvailable(tabContent, theme.panel);
    tabContent.Layout.Row = 2;
    tabContent.Layout.Column = 1;
    tabContent.Padding = [0 0 0 0];
    tabContent.RowSpacing = 0;
    tabContent.ColumnSpacing = 0;
    tabData = uipanel(tabContent, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    tabReference = uipanel(tabContent, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    tabMetrics = uipanel(tabContent, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    tabData.Layout.Row = 1; tabData.Layout.Column = 1;
    tabReference.Layout.Row = 1; tabReference.Layout.Column = 1;
    tabMetrics.Layout.Row = 1; tabMetrics.Layout.Column = 1;
    currentMainTab = "data";

    dataGrid = uigridlayout(tabData, [3 1]);
    setBackgroundIfAvailable(dataGrid, theme.panel);
    dataGrid.RowHeight = {1, 50, '1x'};
    dataGrid.Padding = [8 0 8 8];
    dataGrid.RowSpacing = 0;
    legendBar = uigridlayout(dataGrid, [1 10]);
    setBackgroundIfAvailable(legendBar, theme.panel);
    legendBar.ColumnWidth = {1, 1, 1, 1, 1, 1, '1x', 56, 82, 142};
    legendBar.Padding = [0 0 0 0];
    legendBar.ColumnSpacing = 8;
    lblLegendIntro = uilabel(legendBar, 'Text', '', ...
        'FontColor', theme.muted, 'FontWeight', 'bold');
    lblLegendIntro.Layout.Column = 7;
    lblLegendPOS = makeLegendPill(legendBar, 'POS', theme.greenSoft, theme.text, 1);
    lblLegendBND = makeLegendPill(legendBar, 'BND', theme.yellowSoft, theme.text, 2);
    lblLegendNEG = makeLegendPill(legendBar, 'NEG', theme.redSoft, theme.text, 3);
    lblLegendCurrent = makeLegendPill(legendBar, '', mixColor(theme.paperBlue, [1 1 1], 0.35), theme.text, 4);
    lblLegendRef = makeLegendPill(legendBar, '', theme.panel, theme.text, 5);
    lblLegendQueried = makeLegendPill(legendBar, '', theme.panel, theme.text, 6);
    lblLegendPOS.Visible = 'off';
    lblLegendBND.Visible = 'off';
    lblLegendNEG.Visible = 'off';
    lblLegendCurrent.Visible = 'off';
    lblLegendRef.Visible = 'off';
    lblLegendQueried.Visible = 'off';
    dataHeaderPanel = uipanel(dataGrid, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    dataHeaderPanel.Layout.Row = 2;
    dataHeaderPanel.Layout.Column = 1;
    tblData = uitable(dataGrid);
    tblData.Layout.Row = 3;
    tblData.Layout.Column = 1;
    tblData.ColumnEditable = [];
    tblData.CellEditCallback = @onDataEdited;
    tblData.FontName = theme.font;
    tblData.FontSize = theme.tableFontSize;
    if isprop(tblData, 'FontColor')
        tblData.FontColor = theme.tableText;
    end
    tblData.RowStriping = 'off';
    tblData.BackgroundColor = [1 1 1; 1 1 1];

    referenceGrid = uigridlayout(tabReference, [2 1]);
    setBackgroundIfAvailable(referenceGrid, theme.panel);
    referenceGrid.RowHeight = {42, '1x'};
    referenceGrid.ColumnWidth = {'1x'};
    referenceGrid.Padding = [8 8 8 8];

    referenceToolbar = uigridlayout(referenceGrid, [1 3]);
    setBackgroundIfAvailable(referenceToolbar, theme.panel);
    referenceToolbar.Layout.Row = 1;
    referenceToolbar.Layout.Column = 1;
    referenceToolbar.ColumnWidth = {150, '1x', 250};
    referenceToolbar.Padding = [0 0 0 0];
    referenceToolbar.ColumnSpacing = 8;
    btnImportRef = uibutton(referenceToolbar, 'Text', '', 'ButtonPushedFcn', @onImportReferenceSet, ...
        'BackgroundColor', theme.buttonGray, 'FontColor', theme.buttonGrayText, ...
        'FontWeight', 'bold', 'FontSize', 14, 'FontName', theme.font);
    btnImportRef.Layout.Row = 1;
    btnImportRef.Layout.Column = 1;

    tblReference = uitable(referenceGrid, 'FontName', theme.font, 'FontSize', theme.tableFontSize);
    tblReference.Layout.Row = 2;
    tblReference.Layout.Column = 1;
    tblReference.CellEditCallback = @onReferenceEdited;
    if isprop(tblReference, 'FontColor')
        tblReference.FontColor = theme.tableText;
    end
    tblReference.RowStriping = 'off';
    tblReference.BackgroundColor = [1 1 1; 1 1 1];
    if isprop(tblReference, 'RowHeight')
        tblReference.RowHeight = 44;
    end

    metricsGrid = uigridlayout(tabMetrics, [1 1]);
    setBackgroundIfAvailable(metricsGrid, theme.panel);
    metricsGrid.RowHeight = {'1x'};
    metricsGrid.ColumnWidth = {'1x'};
    metricsGrid.Padding = [8 8 8 8];
    metricsGrid.ColumnSpacing = 0;

    tblLog = uitable(metricsGrid, 'FontName', theme.font, 'FontSize', theme.tableFontSize);
    tblLog.Layout.Row = 1;
    tblLog.Layout.Column = 1;
    if isprop(tblLog, 'FontColor')
        tblLog.FontColor = theme.tableText;
    end
    tblLog.RowStriping = 'off';
    tblLog.BackgroundColor = [1 1 1; 1 1 1];
    if isprop(tblLog, 'RowHeight')
        tblLog.RowHeight = 44;
    end

    rightPane = uigridlayout(main, [2 1]);
    setBackgroundIfAvailable(rightPane, theme.bg);
    rightPane.Layout.Row = 1;
    rightPane.Layout.Column = 2;
    rightPane.RowHeight = {42, '1x'};
    rightPane.ColumnWidth = {'1x'};
    rightPane.Padding = [0 0 0 0];
    rightPane.RowSpacing = 8;

    summarySettingsPanel = uipanel(rightPane, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    summarySettingsPanel.Layout.Row = 1;
    summarySettingsPanel.Layout.Column = 1;
    summarySettingsGrid = uigridlayout(summarySettingsPanel, [1 2]);
    setBackgroundIfAvailable(summarySettingsGrid, theme.panel);
    summarySettingsGrid.ColumnWidth = {160, '1x'};
    summarySettingsGrid.RowHeight = {'1x'};
    summarySettingsGrid.Padding = [0 0 0 0];
    summarySettingsGrid.ColumnSpacing = 8;
    btnAdvanced = uibutton(summarySettingsGrid, 'Text', '', 'ButtonPushedFcn', @toggleAdvancedSettings, ...
        'BackgroundColor', theme.panel, 'FontColor', theme.buttonGrayText, ...
        'FontWeight', 'bold', 'FontSize', 16);
    btnAdvanced.Layout.Row = 1;
    btnAdvanced.Layout.Column = 1;
    lblSettingsSummary = uilabel(summarySettingsGrid, 'Text', '', ...
        'FontSize', 16, 'FontWeight', 'bold', 'FontColor', theme.muted, ...
        'HorizontalAlignment', 'left');
    lblSettingsSummary.Layout.Row = 1;
    lblSettingsSummary.Layout.Column = 2;
    setInterpreterIfAvailable(lblSettingsSummary, 'latex');
    refreshSettingsSummary();

    summaryPanel = uipanel(rightPane, 'BorderType', 'line', ...
        'ForegroundColor', theme.line, 'BackgroundColor', theme.panel);
    summaryPanel.Layout.Row = 2;
    summaryPanel.Layout.Column = 1;
    summaryGrid = uigridlayout(summaryPanel, [5 1]);
    setBackgroundIfAvailable(summaryGrid, theme.panel);
    summaryGrid.RowHeight = {42, 42, 42, 24, '1x'};
    summaryGrid.Padding = [12 8 12 10];
    summaryGrid.RowSpacing = 2;

    setAdvancedSettingsVisible(false);

    [cardKnown, lblKnown, lblKnownTitle] = makeMetricCard(summaryGrid, 'Known / Total', '-', theme.paperPurple, theme);
    cardKnown.Layout.Row = 1;
    [cardQuery, lblQueryBudget, lblQueryBudgetTitle] = makeMetricCard(summaryGrid, 'Query / Kmax', '-', theme.primary, theme);
    cardQuery.Layout.Row = 2;
    [cardMaxRRA, lblMaxRRA, lblMaxRRATitle] = makeMetricCard(summaryGrid, 'Max RRA', '-', theme.negColor, theme);
    cardMaxRRA.Layout.Row = 3;

    lblChartTitle = uilabel(summaryGrid, 'Text', '', ...
        'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold', 'FontColor', theme.text);
    lblChartTitle.Layout.Row = 4;

    axRegions = uiaxes(summaryGrid);
    axRegions.Layout.Row = 5;
    axRegions.FontName = theme.font;
    axRegions.FontSize = 13;
    axRegions.Box = 'off';
    axRegions.XGrid = 'off';
    axRegions.YGrid = 'on';
    axRegions.Color = [1 1 1];

    feedbackSlot = uipanel(root, 'BorderType', 'none', 'BackgroundColor', theme.bg);
    feedbackSlot.Layout.Row = 3;
    feedbackSlot.Layout.Column = 1;
    feedbackSlotGrid = uigridlayout(feedbackSlot, [1 1]);
    setBackgroundIfAvailable(feedbackSlotGrid, theme.bg);
    feedbackSlotGrid.RowHeight = {'1x'};
    feedbackSlotGrid.ColumnWidth = {'1x'};
    feedbackSlotGrid.Padding = [0 0 0 6];
    feedbackSlotGrid.RowSpacing = 0;
    feedbackSlotGrid.ColumnSpacing = 0;

    feedbackFrame = uipanel(feedbackSlotGrid, 'BorderType', 'line', ...
        'ForegroundColor', theme.line, 'BackgroundColor', theme.panel);
    feedbackFrame.Layout.Row = 1;
    feedbackFrame.Layout.Column = 1;
    bottom = uigridlayout(feedbackFrame, [1 12]);
    setBackgroundIfAvailable(bottom, theme.panel);
    bottom.RowHeight = {'1x'};
    bottom.ColumnWidth = {185, 72, 185, 55, 52, 340, 118, 112, 65, 1, 1, 140};
    bottom.Padding = [14 0 14 0];
    bottom.RowSpacing = 0;
    bottom.ColumnSpacing = 6;

    lblQueryHeading = uilabel(bottom, 'Text', '', ...
        'FontWeight', 'bold', 'FontSize', 15, 'FontColor', theme.text);
    lblQueryHeading.Visible = 'off';

    lblCapAlt = uilabel(bottom, 'Text', '', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', [0 0 0], ...
        'HorizontalAlignment', 'right');
    lblCapAlt.Layout.Row = 1; lblCapAlt.Layout.Column = 1;
    lblAlt = uilabel(bottom, 'Text', '-', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', theme.valueRed, ...
        'HorizontalAlignment', 'left');
    lblAlt.Layout.Row = 1; lblAlt.Layout.Column = 2;
    setInterpreterIfAvailable(lblAlt, 'latex');

    lblCapPred = uilabel(bottom, 'Text', '', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', [0 0 0], ...
        'HorizontalAlignment', 'right');
    lblCapPred.Layout.Row = 1; lblCapPred.Layout.Column = 3;
    lblPred = uilabel(bottom, 'Text', '-', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', theme.valueRed, ...
        'HorizontalAlignment', 'left');
    lblPred.Layout.Row = 1; lblPred.Layout.Column = 4;

    lblCapRisk = uilabel(bottom, 'Text', '', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', [0 0 0], ...
        'HorizontalAlignment', 'right');
    lblCapRisk.Layout.Row = 1; lblCapRisk.Layout.Column = 5;
    riskPanel = uipanel(bottom, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    riskPanel.Layout.Row = 1; riskPanel.Layout.Column = 6;
    riskGrid = uigridlayout(riskPanel, [1 1]);
    setBackgroundIfAvailable(riskGrid, theme.neutralSoft);
    riskGrid.Padding = [0 0 0 0];
    lblRisk = uilabel(riskGrid, 'Text', '-', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', theme.valueRed, ...
        'HorizontalAlignment', 'left');
    lblRisk.Layout.Row = 1; lblRisk.Layout.Column = 1;

    lblFeedbackCaption = uilabel(bottom, 'Text', '', ...
        'FontWeight', 'normal', 'FontSize', 22, 'FontColor', [0 0 0], ...
        'HorizontalAlignment', 'right');
    lblFeedbackCaption.Layout.Row = 1;
    lblFeedbackCaption.Layout.Column = 7;
    feedbackControlPanel = uipanel(bottom, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    feedbackControlPanel.Layout.Row = 1;
    feedbackControlPanel.Layout.Column = 8;
    feedbackControlGrid = uigridlayout(feedbackControlPanel, [3 1]);
    setBackgroundIfAvailable(feedbackControlGrid, theme.panel);
    feedbackControlGrid.RowHeight = {'1x', 34, '1x'};
    feedbackControlGrid.ColumnWidth = {'1x'};
    feedbackControlGrid.Padding = [0 0 0 0];
    feedbackControlGrid.RowSpacing = 0;
    ddFeedback = uidropdown(feedbackControlGrid, 'Items', {'-'}, ...
        'FontSize', 22, 'FontColor', theme.valueRed);
    ddFeedback.Layout.Row = 2;
    ddFeedback.Layout.Column = 1;
    lblFeedbackOptions = uilabel(bottom, 'Text', '', ...
        'FontSize', 22, 'FontColor', [0 0 0]);
    lblFeedbackOptions.Layout.Row = 1;
    lblFeedbackOptions.Layout.Column = [9 11];
    lblFeedbackOptions.Visible = 'off';

    submitControlPanel = uipanel(bottom, 'BorderType', 'none', 'BackgroundColor', theme.panel);
    submitControlPanel.Layout.Row = 1;
    submitControlPanel.Layout.Column = 12;
    submitControlGrid = uigridlayout(submitControlPanel, [3 1]);
    setBackgroundIfAvailable(submitControlGrid, theme.panel);
    submitControlGrid.RowHeight = {'1x', 34, '1x'};
    submitControlGrid.ColumnWidth = {'1x'};
    submitControlGrid.Padding = [0 0 0 0];
    submitControlGrid.RowSpacing = 0;
    btnSubmit = uibutton(submitControlGrid, 'Text', '', 'ButtonPushedFcn', @onSubmitFeedback, ...
        'BackgroundColor', theme.primary, 'FontColor', [1 1 1], ...
        'FontWeight', 'normal', 'FontSize', 22);
    btnSubmit.Layout.Row = 2;
    btnSubmit.Layout.Column = 1;

    setFontTree(fig, theme.font);
    fig.UserData = state;
    updateLanguage();

    function toggleAdvancedSettings(~, ~)
        advancedOpen = ~advancedOpen;
        setAdvancedSettingsVisible(advancedOpen);
    end

    function onSettingsChanged(~, ~)
        refreshSettingsSummary();
    end

    function setAdvancedSettingsVisible(isOpen)
        if isOpen
            btnAdvanced.Text = 'Advanced settings';
            lblSettingsSummary.Visible = 'off';
            header.RowHeight = {42, 56};
            header.Padding = [14 6 14 6];
            root.RowHeight = {124, '1x', 76};
            dataGrid.RowHeight = {50, 50, '1x'};
        else
            btnAdvanced.Text = 'Advanced settings';
            lblSettingsSummary.Visible = 'on';
            header.RowHeight = {42, 1};
            header.Padding = [14 18 14 0];
            root.RowHeight = {66, '1x', 76};
            dataGrid.RowHeight = {1, 50, '1x'};
        end
        if isOpen
            visibility = 'on';
        else
            visibility = 'off';
        end
        for kk = 1:numel(advancedControls)
            advancedControls{kk}.Visible = visibility;
        end
        refreshSettingsSummary();
    end

    function refreshSettingsSummary()
        lblSettingsSummary.Text = sprintf('Ns = %d | $\\xi$ = %.3g | MAC = %.3g', ...
            round(edtNs.Value), edtXi.Value, edtMAC.Value);
    end

    function switchMainTab(tabName)
        currentMainTab = string(tabName);
        refreshTabButtons();
    end

    function refreshTabButtons()
        tabData.Visible = matlab.lang.OnOffSwitchState(currentMainTab == "data");
        tabReference.Visible = matlab.lang.OnOffSwitchState(currentMainTab == "reference");
        tabMetrics.Visible = matlab.lang.OnOffSwitchState(currentMainTab == "metrics");
        styleTabButton(btnTabData, currentMainTab == "data");
        styleTabButton(btnTabReference, currentMainTab == "reference");
        styleTabButton(btnTabMetrics, currentMainTab == "metrics");
    end

    function styleTabButton(btn, isActive)
        btn.FontSize = 18;
        btn.FontName = theme.font;
        btn.FontWeight = 'normal';
        btn.FontColor = theme.text;
        if isActive
            btn.BackgroundColor = [1 1 1];
        else
            btn.BackgroundColor = [0.780 0.780 0.780];
        end
    end

    function updateReferenceStatus()
    end

    function updateFeedbackOptions()
        state = fig.UserData;
        if isempty(state.X) || state.q < 1
            lblFeedbackOptions.Text = 'Options: -';
            return;
        end
        lblFeedbackOptions.Text = ['Options: ', strjoin(classItems(state.q), ', ')];
    end

    function updateControlState()
        state = fig.UserData;
        hasData = ~isempty(state.X);
        hasModel = hasData && ~isempty(state.model);
        hasPendingQuery = hasData && ~isnan(state.currentQueryGlobal);
        withinBudget = hasData && state.queryCount < state.cfg.Kmax;

        setEnabled(btnTrain, hasData);
        setEnabled(btnRandomRef, hasData);
        setEnabled(btnImportRef, hasData);
        setEnabled(btnSuggest, hasModel && withinBudget);
        setEnabled(ddFeedback, hasPendingQuery);
        setEnabled(btnSubmit, hasPendingQuery);

        if hasData && ~withinBudget
            lblStatus.Text = tr('queryLimitReached');
        end
    end

    function setRiskDisplay(region, pValue, rraValue)
        region = string(region);
        riskPanel.BackgroundColor = theme.panel;
        setBackgroundIfAvailable(riskGrid, theme.panel);
        lblRisk.FontColor = theme.valueRed;
        if region == "POS"
            lblRisk.Text = sprintf('%s / P(S)=%.3f / RRA=%.3f', region, pValue, rraValue);
        elseif region == "BND"
            lblRisk.Text = sprintf('%s / P(S)=%.3f / RRA=%.3f', region, pValue, rraValue);
        elseif region == "NEG"
            lblRisk.Text = sprintf('%s / P(S)=%.3f / RRA=%.3f', region, pValue, rraValue);
        else
            lblRisk.Text = '-';
            return;
        end
    end

    function onLoadData(~, ~)
        [file, path] = uigetfile({'*.csv;*.xlsx;*.xls', 'Data files (*.csv, *.xlsx, *.xls)'}, ...
            tr('chooseData'));
        if isequal(file, 0)
            return;
        end

        try
            filePath = fullfile(path, file);
            [X, yTrue, altNames, critNames] = loadMCSDataUI(filePath);

            state = emptyState();
            state.filePath = string(filePath);
            state.X = X;
            state.yTrue = yTrue;
            state.altNames = altNames(:);
            state.critNames = critNames(:)';
            state.q = max(yTrue);
            if state.q < 2
                error('%s', sprintf(tr('qTooSmall'), state.q));
            end
            state.n = size(X, 1);
            state.knownMask = false(state.n, 1);
            state.queriedMask = false(state.n, 1);
            state.yKnown = nan(state.n, 1);
            state.pred = nan(state.n, 1);
            state.pS = nan(state.n, 1);
            state.AIW = nan(state.n, 1);
            state.RRA = nan(state.n, 1);
            state.region = strings(state.n, 1);
            state.queryCount = 0;
            state.correctionCount = 0;
            state.queryLog = emptyQueryLog();
            state.metricsHistory = emptyMetricLog();
            state.refMode = "manual";
            state.refPct = nan;

            fig.UserData = state;
            ddFeedback.Items = classItems(state.q);
            updateFeedbackOptions();
            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            clearSuggestion();
            updateReferenceStatus();

            lblStatus.Text = sprintf('%s | n=%d, m=%d, q=%d | Round %d', ...
                file, state.n, size(X,2), state.q, state.queryCount);
            updateControlState();
        catch ME
            uialert(fig, ME.message, tr('loadFailed'));
        end
    end

    function onLanguageChanged(~, ~)
        if strcmp(ddLang.Value, '中文')
            lang = "zh";
        else
            lang = "en";
        end
        updateLanguage();
        refreshDataTable();
        refreshReferenceTable();
        refreshMetricsTables();
    end

    function onDataEdited(~, ~)
        state = fig.UserData;
        if isempty(state.X)
            return;
        end
        try
            syncReferenceEditsFromTable();
        catch ME
            uialert(fig, ME.message, tr('tableError'));
        end
    end

    function onReferenceEdited(~, ~)
        state = fig.UserData;
        if isempty(state.X)
            return;
        end
        try
            syncReferenceEditsFromTable("manual");
            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            clearSuggestion();
            state = fig.UserData;
            lblStatus.Text = sprintf('%s | %d / %d', tr('manualRefReady'), sum(state.knownMask), state.n);
        catch ME
            uialert(fig, ME.message, tr('tableError'));
        end
    end

    function onRandomReferences(~, ~)
        try
            state = fig.UserData;
            assertDataLoaded(state);

            defaultPct = 70;
            if isfield(state, 'refPct') && isfinite(state.refPct)
                defaultPct = state.refPct;
            end
            pct = promptReferencePercent(defaultPct);
            if isnan(pct)
                return;
            end
            selected = selectRandomReferenceMask(state.yTrue, state.q, pct);

            state.knownMask = selected;
            state.queriedMask = false(state.n, 1);
            state.yKnown = nan(state.n, 1);
            state.yKnown(selected) = state.yTrue(selected);
            state.model = [];
            state.pred = nan(state.n, 1);
            state.pS = nan(state.n, 1);
            state.AIW = nan(state.n, 1);
            state.RRA = nan(state.n, 1);
            state.region = strings(state.n, 1);
            state.queryCount = 0;
            state.correctionCount = 0;
            state.queryLog = emptyQueryLog();
            state.metricsHistory = emptyMetricLog();
            state.currentQueryGlobal = nan;
            state.currentQueryLocal = nan;
            state.refMode = "random";
            state.refPct = pct;

            fig.UserData = state;
            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            clearSuggestion();
            lblStatus.Text = sprintf('%s %.0f%% | %d / %d', tr('randomRefReady'), pct, sum(selected), state.n);
            updateControlState();
        catch ME
            uialert(fig, ME.message, tr('randomRefFailed'));
        end
    end

    function onImportReferenceSet(~, ~)
        try
            state = fig.UserData;
            assertDataLoaded(state);
            [file, path] = uigetfile({'*.csv;*.xlsx;*.xls', 'Reference files (*.csv, *.xlsx, *.xls)'}, ...
                tr('chooseReferenceSet'));
            if isequal(file, 0)
                return;
            end

            T = readtable(fullfile(path, file), 'VariableNamingRule', 'preserve');
            [knownMask, yKnown] = importReferenceSelection(T, state);
            state.knownMask = knownMask;
            state.yKnown = yKnown;
            state.refMode = "manual";
            state.refPct = nan;
            state = resetAfterReferenceChange(state);

            fig.UserData = state;
            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            clearSuggestion();
            lblStatus.Text = sprintf('%s | %d / %d', tr('manualRefReady'), sum(state.knownMask), state.n);
            updateControlState();
        catch ME
            uialert(fig, ME.message, tr('importRefFailed'));
        end
    end

    function onTrain(~, ~)
        try
            state = fig.UserData;
            assertDataLoaded(state);
            syncReferenceEditsFromTable();
            state = updateCfgFromUI(state);
            validateReferences(state);
            state = trainAndClassifyState(state);
            fig.UserData = state;
            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            lblStatus.Text = makeMetricStatus(state, lang);
            if state.queryCount < state.cfg.Kmax && any(~state.knownMask)
                clearSuggestion();
                onSuggest([], []);
            else
                clearSuggestion();
                updateControlState();
            end
            updateControlState();
        catch ME
            uialert(fig, ME.message, tr('trainFailed'));
        end
    end

    function onSuggest(~, ~)
        try
            state = fig.UserData;
            assertDataLoaded(state);
            if isempty(state.model)
                syncReferenceEditsFromTable();
                state = updateCfgFromUI(state);
                validateReferences(state);
                state = trainAndClassifyState(state);
            end

            if state.queryCount >= state.cfg.Kmax
                uialert(fig, sprintf(tr('reachKmax'), state.cfg.Kmax), tr('queryStop'));
                return;
            end

            if isempty(find(~state.knownMask, 1))
                uialert(fig, tr('noCandidateMsg'), tr('noCandidateTitle'));
                return;
            end

            [selGlobal, selLocal] = selectNextTWDQuery(state);
            state.currentQueryGlobal = selGlobal;
            state.currentQueryLocal = selLocal;
            fig.UserData = state;
            refreshDataTable();

            lblAlt.Text = latexAlternativeName(state.altNames(selGlobal));
            lblPred.Text = displayClassName(state.pred(selGlobal));
            setRiskDisplay(state.region(selGlobal), state.pS(selGlobal), state.RRA(selGlobal));

            ddFeedback.Items = classItems(state.q);
            ddFeedback.Value = displayClassName(state.yTrue(selGlobal));
            updateFeedbackOptions();

            lblStatus.Text = makeMetricStatus(state, lang);
            updateControlState();
        catch ME
            uialert(fig, ME.message, tr('suggestFailed'));
        end
    end

    function onSubmitFeedback(~, ~)
        try
            state = fig.UserData;
            assertDataLoaded(state);
            if isnan(state.currentQueryGlobal)
                uialert(fig, tr('needSuggestMsg'), tr('needSuggestTitle'));
                return;
            end

            feedback = parseClassItem(ddFeedback.Value);
            idx = state.currentQueryGlobal;
            predBefore = state.pred(idx);
            corrected = predBefore ~= feedback;

            state.knownMask(idx) = true;
            state.queriedMask(idx) = true;
            state.yKnown(idx) = feedback;
            state.queryCount = state.queryCount + 1;
            state.correctionCount = state.correctionCount + double(corrected);

            newLog = table( ...
                state.queryCount, ...
                string(state.altNames(idx)), ...
                predBefore, ...
                feedback, ...
                state.yTrue(idx), ...
                corrected, ...
                string(state.region(idx)), ...
                state.pS(idx), ...
                state.RRA(idx), ...
                'VariableNames', {'Round','Alternative','PredBefore','FeedbackClass','TrueClass','Corrected','Region','pS','RRA'});
            state.queryLog = [state.queryLog; newLog];

            state.currentQueryGlobal = nan;
            state.currentQueryLocal = nan;
            state = trainAndClassifyState(state);
            fig.UserData = state;

            refreshDataTable();
            refreshReferenceTable();
            refreshMetricsTables();
            clearSuggestion();
            updateReferenceStatus();
            lblStatus.Text = makeMetricStatus(state, lang);
        catch ME
            uialert(fig, ME.message, tr('feedbackFailed'));
        end
    end

    function syncReferenceEditsFromTable(selectionMode)
        if nargin < 1
            selectionMode = "preserve";
        end
        selectionMode = string(selectionMode);
        state = fig.UserData;
        if isempty(state.X)
            return;
        end
        if ~isempty(tblReference.Data) && any(strcmp(tblReference.Data.Properties.VariableNames, 'UseRef'))
            D = tblReference.Data;
            useRef = logical(D.UseRef);
            rawClass = D.DMClass;
            if isnumeric(rawClass)
                dmClass = double(rawClass);
            else
                dmClass = arrayfun(@(v) parseClassItem(v), string(rawClass));
            end
            bad = useRef & (isnan(dmClass) | dmClass < 1 | ...
                dmClass > state.q | fix(dmClass) ~= dmClass);
            if any(bad)
                error('%s', sprintf(tr('badDMClass'), state.q));
            end

            state.knownMask = useRef(:);
            state.queriedMask(~state.knownMask) = false;
            state.yKnown = nan(state.n, 1);
            state.yKnown(state.knownMask) = dmClass(state.knownMask);
            if selectionMode == "manual"
                state = resetAfterReferenceChange(state);
                state.refMode = "manual";
                state.refPct = nan;
            end
            fig.UserData = state;
            updateReferenceStatus();
            return;
        end
        bad = state.knownMask & (isnan(state.yKnown) | state.yKnown < 1 | ...
            state.yKnown > state.q | fix(state.yKnown) ~= state.yKnown);
        if any(bad)
            error('%s', sprintf(tr('badDMClass'), state.q));
        end
        fig.UserData = state;
    end

    function refreshDataTable()
        state = fig.UserData;
        if isempty(state.X)
            tblData.Data = table();
            refreshDataHeader({}, {});
            return;
        end

        poolIdx = find(~state.knownMask);
        D = table();
        D.Alternative = cellstr(displayAlternativeNames(state.altNames(poolIdx)));
        for j = 1:numel(state.critNames)
            D.(matlab.lang.makeValidName(state.critNames(j))) = state.X(poolIdx,j);
        end
        D.Class = cellstr(displayClassNames(state.pred(poolIdx)));
        D.pS = state.pS(poolIdx);
        D.Region = state.region(poolIdx);
        D.RRA = state.RRA(poolIdx);

        tblData.Data = D;
        tblData.ColumnEditable = false(1, width(D));
        tblData.ColumnName = {};
        setResultsTableLook();
    end

    function refreshDataHeader(names, widths)
        delete(dataHeaderPanel.Children);
        if isempty(names)
            return;
        end
        headerGrid = uigridlayout(dataHeaderPanel, [1, numel(names)]);
        setBackgroundIfAvailable(headerGrid, theme.panel);
        headerGrid.Padding = [0 0 0 0];
        headerGrid.RowSpacing = 0;
        headerGrid.ColumnSpacing = 0;
        headerGrid.RowHeight = {'1x'};
        headerGrid.ColumnWidth = widths;
        for cc = 1:numel(names)
            cellPanel = uipanel(headerGrid, 'BorderType', 'line', ...
                'ForegroundColor', theme.line, 'BackgroundColor', theme.tableHeaderBg);
            cellPanel.Layout.Row = 1;
            cellPanel.Layout.Column = cc;
            cellGrid = uigridlayout(cellPanel, [1 1]);
            setBackgroundIfAvailable(cellGrid, theme.tableHeaderBg);
            cellGrid.Padding = [2 0 2 0];
            lbl = uilabel(cellGrid, 'Text', names{cc}, ...
                'FontName', theme.font, 'FontSize', theme.tableHeaderFontSize, ...
                'FontWeight', 'bold', 'FontColor', theme.tableHeaderText, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', theme.tableHeaderBg);
            lbl.Layout.Row = 1;
            lbl.Layout.Column = 1;
        end
    end

    function refreshReferenceTable()
        state = fig.UserData;
        if isempty(state.X)
            tblReference.Data = table();
            return;
        end

        D = table();
        D.UseRef = state.knownMask(:);
        D.Alternative = cellstr(displayAlternativeNames(state.altNames));
        for j = 1:numel(state.critNames)
            D.(matlab.lang.makeValidName(state.critNames(j))) = state.X(:,j);
        end
        dmClass = state.yKnown(:);
        dmClass(isnan(dmClass)) = state.yTrue(isnan(dmClass));
        D.DMClass = dmClass;
        D.Source = strings(state.n, 1);
        D.Source(state.knownMask & ~state.queriedMask) = referenceSourceLabel(state, lang);
        D.Source(state.queriedMask) = tr("srcQueried");

        tblReference.Data = D;
        editable = false(1, width(D));
        editable(1) = true;
        editable(end-1) = true;
        tblReference.ColumnEditable = editable;
        tblReference.ColumnName = referenceColumnNames(state);
        critWidths = repmat({120}, 1, numel(state.critNames));
        tblReference.ColumnWidth = [{70, 118}, critWidths, {88, 136}];
        try
            removeStyle(tblReference);
            applyBaseTableStyle(tblReference);
            centerTableColumns(tblReference);
            addStyle(tblReference, uistyle('FontWeight', 'bold', 'FontColor', theme.tableText, ...
                'HorizontalAlignment', 'center'), 'column', 2);
            knownRows = find(state.knownMask);
            if ~isempty(knownRows)
                addStyle(tblReference, uistyle('FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center'), 'row', knownRows);
            end
            queriedRows = find(state.queriedMask);
            if ~isempty(queriedRows)
                addStyle(tblReference, uistyle('BackgroundColor', theme.purpleSoft, ...
                    'FontWeight', 'bold', 'HorizontalAlignment', 'center'), ...
                    'row', queriedRows);
            end
        catch
        end
    end

    function refreshMetricsTables()
        state = fig.UserData;
        logDisplay = state.queryLog;
        if ~isempty(logDisplay)
            logDisplay.Alternative = cellstr(displayAlternativeNames(logDisplay.Alternative));
            logDisplay.PredBefore = cellstr(displayClassNames(logDisplay.PredBefore));
            logDisplay.FeedbackClass = cellstr(displayClassNames(logDisplay.FeedbackClass));
            logDisplay.TrueClass = cellstr(displayClassNames(logDisplay.TrueClass));
        end
        tblLog.Data = logDisplay;
        tblLog.ColumnName = logColumnNames();
        if ~isempty(state.queryLog)
            tblLog.ColumnWidth = {70, 120, 112, 112, 88, 90, 80, 80, 80};
        end
        try
            removeStyle(tblLog);
            applyBaseTableStyle(tblLog);
        catch
        end
        centerTableColumns(tblLog);
        refreshSummaryCards();
        refreshRegionChart();
    end

    function applyBaseTableStyle(tbl)
        if isprop(tbl, 'FontName')
            tbl.FontName = theme.font;
        end
        if isprop(tbl, 'FontSize')
            tbl.FontSize = theme.tableFontSize;
        end
        if isprop(tbl, 'FontColor')
            tbl.FontColor = theme.tableText;
        end
        addStyle(tbl, uistyle('FontColor', theme.tableText, ...
            'HorizontalAlignment', 'center'));
    end

    function clearSuggestion()
        lblAlt.Text = '-';
        lblPred.Text = '-';
        setRiskDisplay("", nan, nan);
        ddFeedback.Items = {'-'};
        ddFeedback.Value = '-';
        updateFeedbackOptions();
        state = fig.UserData;
        state.currentQueryGlobal = nan;
        state.currentQueryLocal = nan;
        fig.UserData = state;
        updateControlState();
        updateReferenceStatus();
    end

    function refreshSummaryCards()
        state = fig.UserData;
        if isempty(state.X)
            lblKnown.Text = '-';
            lblQueryBudget.Text = '-';
            lblMaxRRA.Text = '-';
            return;
        end

        rraPool = state.RRA(~state.knownMask & isfinite(state.RRA));
        if isempty(rraPool)
            maxRRAText = '-';
            maxRRAColor = theme.muted;
        else
            maxRRA = max(rraPool);
            maxRRAText = sprintf('%.3f', maxRRA);
            if maxRRA <= 0
                maxRRAColor = theme.posColor;
            elseif maxRRA <= edtXi.Value
                maxRRAColor = theme.bndColor;
            else
                maxRRAColor = theme.negColor;
            end
        end

        lblKnown.FontColor = [0.520 0.160 0.760];
        lblQueryBudget.FontColor = theme.primary;
        lblMaxRRA.FontColor = maxRRAColor;
        lblKnown.Text = sprintf('%d / %d', sum(state.knownMask), state.n);
        lblQueryBudget.Text = sprintf('%d / %d', state.queryCount, state.cfg.Kmax);
        lblMaxRRA.Text = maxRRAText;
    end

    function refreshRegionChart()
        cla(axRegions);
        [posN, bndN, negN] = regionCounts(fig.UserData);
        values = [posN, bndN, negN];
        b = barh(axRegions, values, 0.58, 'FaceColor', 'flat', 'EdgeColor', 'none');
        b.CData = [theme.posBar; theme.bndBar; theme.negBar];
        labelColors = [theme.posColor; theme.bndColor; theme.negColor];
        axRegions.YTick = 1:3;
        axRegions.YTickLabel = {'POS','BND','NEG'};
        xlabel(axRegions, tr('count'));
        ylabel(axRegions, '');
        xlim(axRegions, [0, max(1, max(values) * 1.22)]);
        axRegions.XGrid = 'on';
        axRegions.YGrid = 'on';
        axRegions.GridAlpha = 0.15;
        grid(axRegions, 'on');
        for ii = 1:numel(values)
            text(axRegions, values(ii), ii, sprintf(' %d', values(ii)), ...
                'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
                'FontName', theme.font, 'FontWeight', 'bold', 'FontSize', 13, ...
                'Color', labelColors(ii,:));
        end
    end

    function setResultsTableLook()
        state = fig.UserData;
        if isempty(tblData.Data)
            return;
        end

        % 列宽设置
        widthScale = 0.78;
        critWidths = repmat({round(112 * widthScale)}, 1, numel(state.critNames));
        dataWidths = [{round(128 * widthScale)}, critWidths, ...
            {round(104 * widthScale), round(110 * widthScale), ...
            round(120 * widthScale), round(110 * widthScale)}];
        tblData.ColumnWidth = dataWidths;
        refreshDataHeader(dataColumnNames(state), dataWidths);
        tblData.BackgroundColor = [1 1 1; 1 1 1];
        if isprop(tblData, 'RowHeight')
            tblData.RowHeight = 46;
        end

        % 清除旧样式，避免每次刷新后样式叠加
        try
            removeStyle(tblData);
        catch
        end

        try
            % 1. 所有单元格内容居中
            applyBaseTableStyle(tblData);

            % 2. 根据当前候选池行的 Region 判断行背景色
            poolIdx = find(~state.knownMask);
            localRegion = state.region(poolIdx);

            posRows = find(localRegion == "POS");
            bndRows = find(localRegion == "BND");
            negRows = find(localRegion == "NEG");

            % Region 列的位置：
            % Alternative = 1
            % g1...gm = 2 到 m+1
            % Class = m+2
            % pS = m+3
            % Region = m+4
            % RRA = m+5
            regionCol = numel(state.critNames) + 4;

            if ~isempty(posRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', theme.posSoft, ...
                    'HorizontalAlignment', 'center'), ...
                    'row', posRows);
            end

            if ~isempty(bndRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', theme.bndSoft, ...
                    'HorizontalAlignment', 'center'), ...
                    'row', bndRows);
            end

            if ~isempty(negRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', theme.negSoft, ...
                    'HorizontalAlignment', 'center'), ...
                    'row', negRows);
            end

            % 3. POS 行：浅绿色背景
            if ~isempty(posRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', mixColor(theme.posSoft, theme.posColor, 0.12), ...
                    'FontColor', theme.posColor, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center'), ...
                    'cell', [posRows, repmat(regionCol, numel(posRows), 1)]);
            end

            % 4. BND 行：浅黄色背景
            if ~isempty(bndRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', mixColor(theme.bndSoft, theme.bndColor, 0.13), ...
                    'FontColor', theme.bndColor, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center'), ...
                    'cell', [bndRows, repmat(regionCol, numel(bndRows), 1)]);
            end

            % 5. NEG 行：浅红色背景
            if ~isempty(negRows)
                addStyle(tblData, uistyle( ...
                    'BackgroundColor', mixColor(theme.negSoft, theme.negColor, 0.11), ...
                    'FontColor', theme.negColor, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center'), ...
                    'cell', [negRows, repmat(regionCol, numel(negRows), 1)]);
            end

            % 6. 当前推荐询问方案：蓝色高亮
            if ~isnan(state.currentQueryGlobal)
                currentLocal = find(poolIdx == state.currentQueryGlobal, 1);
                if ~isempty(currentLocal)
                    addStyle(tblData, uistyle( ...
                        'BackgroundColor', theme.querySoft, ...
                        'HorizontalAlignment', 'center'), ...
                        'row', currentLocal);
                end
            end

            % 7. Alternative 列加粗蓝色
            addStyle(tblData, uistyle( ...
                'FontWeight', 'bold', ...
                'FontColor', theme.tableText, ...
                'HorizontalAlignment', 'center'), ...
                'column', 1);

        catch ME
            warning('表格样式设置失败：%s', ME.message);
        end
    end

    function state = updateCfgFromUI(state)
        cfg = defaultCfg();
        cfg.L = max(1, round(edtL.Value));
        cfg.xi = edtXi.Value;
        cfg.MAC = edtMAC.Value;
        cfg.Ns = max(1, round(edtNs.Value));
        cfg.Kmax = max(1, round(edtKmax.Value));
        state.cfg = cfg;
    end

    function updateLanguage()
        fig.Name = tr('appName');
        lblTitle.Text = tr('title');
        lblSubtitle.Text = tr('subtitle');
        btnLoad.Text = tr('load');
        btnTrain.Text = tr('train');
        btnSuggest.Text = tr('suggest');
        btnRandomRef.Text = tr('randomRef');
        btnImportRef.Text = tr('importRef');
        btnSubmit.Text = tr('submit');
        btnTabData.Text = tr('tabData');
        btnTabReference.Text = tr('tabReference');
        btnTabMetrics.Text = tr('tabMetrics');
        refreshTabButtons();
        lblChartTitle.Text = tr('chartTitle');
        lblQueryHeading.Text = tr('queryHeading');
        lblLegendIntro.Text = tr('legendIntro');
        lblLegendRef.Text = tr('legendRef');
        lblLegendQueried.Text = tr('legendQueried');
        lblLegendCurrent.Text = tr('legendCurrent');
        lblCapAlt.Text = tr('capAlt');
        lblCapPred.Text = tr('capPred');
        lblCapRisk.Text = tr('capRisk');
        lblFeedbackCaption.Text = tr('feedbackCaption');
        updateFeedbackOptions();
        lblKnownTitle.Text = tr('knownTotal');
        lblQueryBudgetTitle.Text = tr('queryBudget');
        lblMaxRRATitle.Text = 'Max RRA';
        updateControlState();
        if isempty(fig.UserData.X)
            lblStatus.Text = tr('statusStart');
        else
            lblStatus.Text = makeMetricStatus(fig.UserData, lang);
        end
        refreshRegionChart();
    end

    function out = tr(key)
        key = string(key);
        if lang == "en"
            out = translateEN(key);
        else
            out = translateZH(key);
        end
    end

    function names = dataColumnNames(state)
        critHeaders = cellstr(displayCriterionNames(state.critNames));
        if lang == "en"
            names = [{'Alternative'}, critHeaders, ...
                {'Class','P(S)','Region','RRA'}];
        else
            names = [{'方案'}, critHeaders, ...
                {'类别','条件概率','区域','RRA'}];
        end
    end

    function names = referenceColumnNames(state)
        critHeaders = cellstr(displayCriterionNames(state.critNames));
        if lang == "en"
            names = [{'UseRef','Alternative'}, critHeaders, {'DMClass','Source'}];
        else
            names = [{'方案'}, critHeaders, {'类别','来源'}];
        end
    end
    
    function names = logColumnNames()
        if lang == "en"
            names = {'Round','Alternative','Pred. before','Feedback','True','Corrected','Region','P(S)','RRA'};
        else
            names = {'轮次','方案','询问前预测','反馈类','真实类','是否纠错','区域','P(S)','RRA'};
        end
    end

end

%% Visual helpers
function setFontTree(rootObj, fontName)
    objs = findall(rootObj);
    for k = 1:numel(objs)
        if isprop(objs(k), 'FontName')
            try
                objs(k).FontName = fontName;
            catch
            end
        end
    end
end

function setFontSizeIfAvailable(obj, fontSize)
    if isprop(obj, 'FontSize')
        try
            obj.FontSize = fontSize;
        catch
        end
    end
end

function setFontNameIfAvailable(obj, fontName)
    if isprop(obj, 'FontName')
        try
            obj.FontName = fontName;
        catch
        end
    end
end

function setInterpreterIfAvailable(obj, interpreterName)
    if isprop(obj, 'Interpreter')
        try
            obj.Interpreter = interpreterName;
        catch
        end
    end
end

function centerTableColumns(tbl)
    if isempty(tbl.Data)
        return;
    end

    try
        nCols = width(tbl.Data);
    catch
        nCols = size(tbl.Data, 2);
    end

    for c = 1:nCols
        try
            addStyle(tbl, uistyle('HorizontalAlignment', 'center'), 'column', c);
        catch
        end
    end
end

function setButtonIcon(btn, kind, fgColor, bgColor)
    if ~isprop(btn, 'Icon')
        return;
    end

    try
        btn.Icon = makeButtonIcon(kind, fgColor, bgColor);
        if isprop(btn, 'IconAlignment')
            btn.IconAlignment = 'left';
        end
    catch
    end
end

function icon = makeButtonIcon(kind, fgColor, bgColor)
    n = 22;
    [x, y] = meshgrid(1:n, 1:n);
    mask = false(n, n);

    switch string(kind)
        case "load"
            mask(7, 4:12) = true;
            mask(8, 4:18) = true;
            mask(9:17, 4) = true;
            mask(17, 4:19) = true;
            mask(10:16, 19) = true;
            mask(10, 5:19) = true;
            mask(6:8, 5) = true;
            mask(6, 5:10) = true;
        case "train"
            r2 = (x - 11.5).^2 + (y - 11.5).^2;
            mask = (r2 >= 18 & r2 <= 30);
            mask(5:18, 11:12) = true;
            mask(11:12, 5:18) = true;
            mask(abs((x - y)) <= 1 & x > 5 & x < 18) = true;
            mask(abs((x + y) - 23) <= 1 & x > 5 & x < 18) = true;
            mask(r2 < 8) = false;
        case "suggest"
            r2 = (x - 11.5).^2 + (y - 9.5).^2;
            mask = (r2 >= 18 & r2 <= 30);
            mask(10:14, 11:12) = true;
            mask(15, 8:15) = true;
            mask(17, 8:15) = true;
            mask(19, 9:14) = true;
        case "submit"
            mask(abs((x + y) - 23) <= 1 & x >= 4 & x <= 19) = true;
            mask(abs((y - x) + 7) <= 1 & x >= 8 & x <= 18) = true;
            mask(abs((y - x) - 5) <= 1 & x >= 4 & x <= 13) = true;
            mask(10:12, 8:17) = true;
        case "sample"
            mask(6:9, 6:9) = true;
            mask(6:9, 14:17) = true;
            mask(14:17, 6:9) = true;
            mask(14:17, 14:17) = true;
            mask(4:5, 10:13) = true;
            mask(10:13, 4:5) = true;
            mask(10:13, 18:19) = true;
            mask(18:19, 10:13) = true;
        otherwise
            mask(7:16, 7:16) = true;
    end

    icon = repmat(reshape(bgColor, 1, 1, 3), n, n);
    for channel = 1:3
        layer = icon(:, :, channel);
        layer(mask) = fgColor(channel);
        icon(:, :, channel) = layer;
    end
end

function lbl = addParamLabel(parent, textValue, col, theme)
    lbl = uilabel(parent, 'Text', textValue, ...
        'HorizontalAlignment', 'right', 'FontWeight', 'bold', ...
        'FontColor', theme.muted, 'FontName', theme.font, 'FontSize', 14);
    if strcmp(textValue, 'ξ')
        setInterpreterIfAvailable(lbl, 'tex');
        lbl.Text = '\xi';
    end
    lbl.Layout.Row = 2;
    lbl.Layout.Column = col;
end

function setBackgroundIfAvailable(obj, colorValue)
    if isprop(obj, 'BackgroundColor')
        obj.BackgroundColor = colorValue;
    end
end

function lbl = makeLegendPill(parent, textValue, bgColor, fontColor, col)
    lbl = uilabel(parent, 'Text', textValue, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'FontSize', 13, 'BackgroundColor', bgColor, 'FontColor', fontColor, ...
        'FontName', themeFont(parent));
    lbl.Layout.Row = 1;
    lbl.Layout.Column = col;
end

function [panel, valueLabel, titleLabel] = makeMetricCard(parent, titleText, valueText, accentColor, theme)
    panel = uipanel(parent, 'BorderType', 'none', ...
        'BackgroundColor', theme.panel);
    grid = uigridlayout(panel, [1 2]);
    setBackgroundIfAvailable(grid, theme.panel);
    grid.ColumnWidth = {'1x', 130};
    grid.Padding = [4 0 4 0];
    grid.ColumnSpacing = 6;

    titleLabel = uilabel(grid, 'Text', titleText, ...
        'FontColor', theme.text, 'FontSize', 16, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', 'FontName', theme.font);
    titleLabel.Layout.Column = 1;

    valueLabel = uilabel(grid, 'Text', valueText, ...
        'FontColor', accentColor, 'FontWeight', 'bold', ...
        'FontSize', 20, 'HorizontalAlignment', 'right', 'FontName', theme.font);
    valueLabel.Layout.Column = 2;
end

function out = metricIcon(titleText)
    t = string(titleText);
    if t == "Known / Total"
        out = 'K';
    elseif t == "Query / Kmax"
        out = 'Q';
    elseif t == "Max RRA"
        out = '!';
    else
        out = '#';
    end
    return;
%{
    switch string(titleText)
        case "Known / Total"
            out = '☷';
        case "Query / Kmax"
            out = '?';
        case "Max RRA"
            out = '!';
        otherwise
            out = '▦';
    end
%}
end

function out = queryIcon(titleText)
    t = string(titleText);
    if contains(t, "Alternative") || contains(t, "方案")
        out = 'a';
    elseif contains(t, "recommendation") || contains(t, "推荐")
        out = 'C';
    elseif contains(t, "Risk") || contains(t, "风险")
        out = '!';
    else
        out = '?';
    end
end

function fontName = themeFont(~)
    fontName = 'Segoe UI';
end

function setEnabled(obj, tf)
    if tf
        obj.Enable = 'on';
    else
        obj.Enable = 'off';
    end
end

function out = displayAlternativeNames(names)
    names = string(names);
    out = strings(size(names));
    for k = 1:numel(names)
        [~, sub] = splitSymbolToken(names(k), "a");
        out(k) = "a" + sub;
    end
end

function out = displayCriterionNames(names)
    names = string(names);
    out = strings(size(names));
    for k = 1:numel(names)
        [base, sub] = splitSymbolToken(names(k), "g");
        out(k) = base + unicodeSubscript(sub);
    end
end

function out = latexAlternativeName(name)
    [base, sub] = splitSymbolToken(name, "a");
    out = sprintf('$%s_{%s}$', char(base), char(sub));
end

function out = plainAlternativeName(name)
    [~, sub] = splitSymbolToken(name, "a");
    out = char("a" + sub);
end

function out = displayClassNames(values)
    values = double(values);
    out = strings(size(values));
    for k = 1:numel(values)
        out(k) = displayClassName(values(k));
    end
end

function out = displayClassName(value)
    if isnan(value)
        out = "-";
    else
        out = "C" + unicodeSubscript(string(round(value)));
    end
end

function [base, sub] = splitSymbolToken(token, defaultBase)
    token = string(token);
    token = regexprep(token, '<[^>]*>', '');
    parts = regexp(token, '^([A-Za-z]+)[_\s-]*(\d+)$', 'tokens', 'once');
    if isempty(parts)
        digits = regexp(token, '\d+', 'match', 'once');
        if isempty(digits)
            base = defaultBase;
            sub = token;
        else
            base = defaultBase;
            sub = string(digits);
        end
    else
        base = string(parts{1});
        sub = string(parts{2});
    end
end

function out = unicodeSubscript(value)
    chars = char(string(value));
    out = "";
    for k = 1:numel(chars)
        switch chars(k)
            case '0'
                out = out + "₀";
            case '1'
                out = out + "₁";
            case '2'
                out = out + "₂";
            case '3'
                out = out + "₃";
            case '4'
                out = out + "₄";
            case '5'
                out = out + "₅";
            case '6'
                out = out + "₆";
            case '7'
                out = out + "₇";
            case '8'
                out = out + "₈";
            case '9'
                out = out + "₉";
            case 'k'
                out = out + "ₖ";
            otherwise
                out = out + string(chars(k));
        end
    end
end

function c = mixColor(c1, c2, amount)
    c = c1 .* (1 - amount) + c2 .* amount;
end

function c = darkerColor(baseColor)
    c = max(0, baseColor .* 0.58);
end

function [posN, bndN, negN] = regionCounts(state)
    if isempty(state.X)
        posN = 0;
        bndN = 0;
        negN = 0;
        return;
    end

    pool = ~state.knownMask;
    posN = sum(state.region(pool) == "POS");
    bndN = sum(state.region(pool) == "BND");
    negN = sum(state.region(pool) == "NEG");
end

function out = translateZH(key)
    switch key
        case "appName"
            out = 'TWD-RAE 交互式多准则分类决策系统';
        case "title"
            out = 'Interactive Multiple Criteria Sorting System';
        case "subtitle"
            out = '';
        case "statusStart"
            out = '请先导入数据集。';
        case "load"
            out = '导入数据';
        case "train"
            out = '训练/更新';
        case "suggest"
            out = '推荐询问';
        case "randomRef"
            out = '随机参考集';
        case "refPct"
            out = 'Reference set';
        case "submit"
            out = '提交反馈';
        case "tabData"
            out = '数据与风险区域';
        case "tabReference"
            out = '参考集';
        case "tabMetrics"
            out = '询问日志';
        case "summaryPanel"
            out = ' ';
        case "summaryTitle"
            out = '风险与交互摘要';
        case "chartTitle"
            out = '当前轮三支区域划分';
        case "queryPanel"
            out = ' ';
        case "queryHeading"
            out = '主动询问与偏好反馈';
        case "legendIntro"
            out = '';
        case "legendRef"
            out = 'Reference';
        case "legendQueried"
            out = 'Queried';
        case "legendCurrent"
            out = '当前推荐';
        case "capAlt"
            out = '询问方案';
        case "capPred"
            out = '当前推荐';
        case "capRisk"
            out = '风险状态';
        case "feedbackCaption"
            out = '决策者反馈';
        case "feedbackOptions"
            out = '选项：C₁, C₂, C₃, ...';
        case "knownTotal"
            out = 'Known / Total';
        case "queryBudget"
            out = 'Query / Kmax';
        case "count"
            out = '数量';
        case "region"
            out = '区域';
        case "round"
            out = '轮次';
        case "initialInfo"
            out = '导入数据后，选择或导入参考集，训练后查看风险区域并提交反馈。';
        case "chooseData"
            out = '选择多准则分类数据集';
        case "afterLoad"
            out = '已导入。请使用 Random 或手动选择参考集后训练模型。';
        case "randomRefReady"
            out = '已随机生成参考集';
        case "randomRefInfo"
            out = '已随机选择 %d / %d 个已知参考样本（%.1f%%）；每个类别至少保留一个样本。';
        case "afterTrain"
            out = '已训练并完成分类。点击“推荐询问”选择下一条高风险方案。';
        case "suggestLine"
            out = '建议询问';
        case "predLine"
            out = '推荐';
        case "feedbackHint"
            out = '下拉框已按真实 Class 预填；实际应用时由决策者选择反馈类别。';
        case "suggestReady"
            out = '已生成主动询问建议';
        case "afterFeedback"
            out = '反馈已提交。模型已更新，分类结果已刷新。';
        case "srcModel"
            out = '模型';
        case "srcReference"
            out = '参考';
        case "srcQueried"
            out = '询问';
        case "loadFailed"
            out = '导入失败';
        case "tableError"
            out = '表格数据错误';
        case "trainFailed"
            out = '训练失败';
        case "queryStop"
            out = '询问停止';
        case "suggestFailed"
            out = '推荐失败';
        case "randomRefFailed"
            out = '随机参考集失败';
        case "feedbackFailed"
            out = '反馈失败';
        case "noCandidateTitle"
            out = '无候选方案';
        case "noCandidateMsg"
            out = '所有方案都已经由决策者标注或确认。';
        case "needSuggestTitle"
            out = '没有待反馈方案';
        case "needSuggestMsg"
            out = '请先点击“推荐询问”。';
        case "reachKmax"
            out = '已达到最大询问次数 Kmax=%d。';
        case "qTooSmall"
            out = '自动识别到的类别数 q=%d，至少需要 2 个类别。';
        case "badDMClass"
            out = '被勾选为 UseRef 的方案必须填写 1 到 %d 之间的整数 DMClass。';
        otherwise
            out = char(key);
    end
end

function out = translateEN(key)
    switch key
        case "appName"
            out = 'TWD-RAE Interactive Multiple Criteria Sorting System';
        case "title"
            out = 'TWD-RAE Interactive Multiple Criteria Sorting System';
        case "subtitle"
            out = '';
        case "statusStart"
            out = 'Load a dataset first.';
        case "load"
            out = 'Load Data';
        case "train"
            out = 'Train Model';
        case "suggest"
            out = 'Suggest Query';
        case "randomRef"
            out = 'Random';
        case "importRef"
            out = 'Import Ref Set';
        case "refPct"
            out = 'Reference set';
        case "submit"
            out = 'Submit';
        case "tabData"
            out = 'Non-reference set';
        case "tabReference"
            out = 'Reference set';
        case "tabMetrics"
            out = 'Query log';
        case "summaryPanel"
            out = ' ';
        case "summaryTitle"
            out = 'Risk Summary';
        case "chartTitle"
            out = 'Region Distribution';
        case "queryPanel"
            out = ' ';
        case "queryHeading"
            out = 'Active query and preference feedback';
        case "legendIntro"
            out = '';
        case "legendRef"
            out = 'Reference';
        case "legendQueried"
            out = 'Queried';
        case "legendCurrent"
            out = 'Suggested';
        case "capAlt"
            out = 'Active Query:';
        case "capPred"
            out = 'Recommendation:';
        case "capRisk"
            out = 'Risk:';
        case "feedbackCaption"
            out = 'Feedback:';
        case "feedbackOptions"
            out = 'Options: C₁, C₂, C₃, ...';
        case "knownTotal"
            out = 'Known / Total';
        case "queryBudget"
            out = 'Query / Kmax';
        case "count"
            out = 'Count';
        case "region"
            out = 'Region';
        case "round"
            out = 'Round';
        case "initialInfo"
            out = 'Load data, choose or import a reference set, train the model, then review risk regions and submit feedback.';
        case "chooseData"
            out = 'Choose a multicriteria sorting dataset';
        case "afterLoad"
            out = 'Loaded. Use Random or manually choose references, then train the model.';
        case "randomRefReady"
            out = 'Random reference set selected:';
        case "manualRefReady"
            out = 'Reference set manually selected';
        case "chooseReferenceSet"
            out = 'Choose a reference set file';
        case "importRefFailed"
            out = 'Reference set import failed';
        case "randomRefInfo"
            out = 'Selected %d / %d known reference samples at %.1f%%; at least one sample is kept in each class.';
        case "afterTrain"
            out = 'Model trained and alternatives sorted. Click "Suggest query" for the next high-risk alternative.';
        case "suggestLine"
            out = 'Suggested query';
        case "predLine"
            out = 'Predicted';
        case "feedbackHint"
            out = 'The dropdown is prefilled from the true Class; in real use, the decision maker should choose the feedback class.';
        case "suggestReady"
            out = 'Query suggestion ready';
        case "afterFeedback"
            out = 'Feedback submitted. Model and sorting results were updated.';
        case "srcModel"
            out = 'Model';
        case "srcReference"
            out = 'Reference';
        case "srcQueried"
            out = 'Queried';
        case "loadFailed"
            out = 'Load failed';
        case "tableError"
            out = 'Table data error';
        case "trainFailed"
            out = 'Training failed';
        case "queryStop"
            out = 'Query stopped';
        case "suggestFailed"
            out = 'Suggestion failed';
        case "randomRefFailed"
            out = 'Random reference selection failed';
        case "feedbackFailed"
            out = 'Feedback failed';
        case "noCandidateTitle"
            out = 'No candidate';
        case "noCandidateMsg"
            out = 'All alternatives have been labeled or confirmed.';
        case "needSuggestTitle"
            out = 'No pending feedback';
        case "needSuggestMsg"
            out = 'Click "Suggest query" first.';
        case "reachKmax"
            out = 'Maximum query budget Kmax=%d reached.';
        case "qTooSmall"
            out = 'The detected number of classes is q=%d; at least 2 classes are required.';
        case "badDMClass"
            out = 'Every selected UseRef row must have an integer DMClass from 1 to %d.';
        otherwise
            out = char(key);
    end
end

%% UI state and data helpers
function state = emptyState()
    state = struct();
    state.filePath = "";
    state.X = [];
    state.yTrue = [];
    state.altNames = strings(0,1);
    state.critNames = strings(0,1);
    state.q = [];
    state.n = 0;
    state.knownMask = [];
    state.queriedMask = [];
    state.yKnown = [];
    state.model = [];
    state.pred = [];
    state.pS = [];
    state.AIW = [];
    state.RRA = [];
    state.region = strings(0,1);
    state.queryCount = 0;
    state.correctionCount = 0;
    state.queryLog = emptyQueryLog();
    state.metricsHistory = emptyMetricLog();
    state.currentQueryGlobal = nan;
    state.currentQueryLocal = nan;
    state.cfg = defaultCfg();
    state.refMode = "manual";
    state.refPct = nan;
end

function cfg = defaultCfg()
    cfg.L = 3;
    cfg.xi = 0.40;
    cfg.MAC = 0.60;
    cfg.Ns = 100;
    cfg.Kmax = 10;
    cfg.thresholdMinGap = 1e-6;
    cfg.kappa = cfg.thresholdMinGap;
    cfg.compatTol = 1e-8;
    cfg.solverDisplay = 'none';
    cfg.caiPositiveTol = 1e-12;
    cfg.regretEps = 1e-6;
end

function T = emptyQueryLog()
    T = table('Size', [0 9], ...
        'VariableTypes', {'double','string','double','double','double','logical','string','double','double'}, ...
        'VariableNames', {'Round','Alternative','PredBefore','FeedbackClass','TrueClass','Corrected','Region','pS','RRA'});
end

function T = emptyMetricLog()
    T = table('Size', [0 8], ...
        'VariableTypes', {'double','double','double','double','double','double','double','double'}, ...
        'VariableNames', {'Round','Accuracy','Precision','Recall','Fmeasure','MAE','CR','KnownCount'});
end

function state = resetAfterReferenceChange(state)
    state.queriedMask = false(state.n, 1);
    state.model = [];
    state.pred = nan(state.n, 1);
    state.pS = nan(state.n, 1);
    state.AIW = nan(state.n, 1);
    state.RRA = nan(state.n, 1);
    state.region = strings(state.n, 1);
    state.queryCount = 0;
    state.correctionCount = 0;
    state.queryLog = emptyQueryLog();
    state.metricsHistory = emptyMetricLog();
    state.currentQueryGlobal = nan;
    state.currentQueryLocal = nan;
end

function label = referenceSourceLabel(state, lang)
    if nargin < 2
        lang = "en";
    end
    if isfield(state, 'refMode') && string(state.refMode) == "random"
        pct = 70;
        if isfield(state, 'refPct') && isfinite(state.refPct)
            pct = state.refPct;
        end
        label = sprintf('Random %.0f%%', pct);
    else
        label = 'Manual';
    end
    if nargin >= 2 && string(lang) ~= "en"
        label = char(label);
    end
end

function pct = promptReferencePercent(defaultPct)
    pct = nan;
    answer = inputdlg({'Reference set percentage (%):'}, ...
        'Random Reference Set', [1 36], {sprintf('%.0f', defaultPct)});
    if isempty(answer)
        return;
    end
    value = str2double(strtrim(answer{1}));
    if ~isfinite(value) || value <= 0 || value > 100
        error('Reference percentage must be a number in (0, 100].');
    end
    pct = value;
end

function [knownMask, yKnown] = importReferenceSelection(T, state)
    vars = string(T.Properties.VariableNames);
    n = state.n;
    knownMask = false(n, 1);
    yKnown = nan(n, 1);

    altCol = find(strcmpi(vars, 'Alternative') | strcmpi(vars, 'Alt') | strcmpi(vars, 'Name'), 1);
    useCol = find(strcmpi(vars, 'UseRef') | strcmpi(vars, 'Reference') | strcmpi(vars, 'Selected'), 1);
    classCol = find(strcmpi(vars, 'DMClass') | strcmpi(vars, 'Class') | strcmpi(vars, 'Feedback'), 1);

    if ~isempty(altCol)
        importedNames = string(T{:, altCol});
        [isMatched, rowIdx] = ismember(importedNames, string(state.altNames));
        if ~all(isMatched)
            displayNames = string(displayAlternativeNames(state.altNames));
            [isMatched2, rowIdx2] = ismember(importedNames(~isMatched), displayNames);
            rowIdx(~isMatched) = rowIdx2;
            isMatched(~isMatched) = isMatched2;
        end
        rows = rowIdx(isMatched);
        tableRows = find(isMatched);
    elseif height(T) == n
        rows = (1:n)';
        tableRows = rows;
    else
        error('Reference import must include an Alternative column or have the same row count as the dataset.');
    end

    if isempty(useCol)
        selected = true(numel(rows), 1);
    else
        selected = parseUseRefColumn(T{tableRows, useCol});
    end
    rows = rows(selected);
    tableRows = tableRows(selected);
    knownMask(rows) = true;

    if isempty(classCol)
        yKnown(rows) = state.yTrue(rows);
    else
        rawClass = T{tableRows, classCol};
        if isnumeric(rawClass)
            importedClass = double(rawClass);
        else
            importedClass = arrayfun(@(v) parseClassItem(v), string(rawClass));
        end
        yKnown(rows) = importedClass;
    end
end

function selected = parseUseRefColumn(values)
    if islogical(values)
        selected = values(:);
    elseif isnumeric(values)
        selected = values(:) ~= 0;
    else
        textValues = lower(strtrim(string(values(:))));
        selected = textValues == "true" | textValues == "yes" | textValues == "y" | ...
            textValues == "1" | textValues == "ref" | textValues == "reference";
    end
end

function mask = selectRandomReferenceMask(y, q, pct)
    n = numel(y);
    mask = false(n, 1);
    target = min(n, max(q, round(n * pct / 100)));

    for cls = 1:q
        clsIdx = find(y == cls);
        if isempty(clsIdx)
            error('类别 %d 中没有可选样本，无法生成分层随机参考集。', cls);
        end
        pick = clsIdx(randi(numel(clsIdx)));
        mask(pick) = true;
    end

    remainingCount = target - nnz(mask);
    if remainingCount > 0
        pool = find(~mask);
        pool = pool(randperm(numel(pool)));
        mask(pool(1:min(remainingCount, numel(pool)))) = true;
    end
end

function items = classItems(q)
    items = cellstr(displayClassNames(1:q));
end

function c = parseClassItem(item)
    normalized = normalizeSubscriptDigits(string(item));
    token = regexp(normalized, '\d+', 'match');
    if isempty(token)
        error('请选择有效类别。');
    end
    c = str2double(token{1});
end

function out = normalizeSubscriptDigits(value)
    out = string(value);
    subs = ["₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"];
    nums = ["0","1","2","3","4","5","6","7","8","9"];
    for k = 1:numel(subs)
        out = replace(out, subs(k), nums(k));
    end
end

function assertDataLoaded(state)
    if isempty(state.X)
        error('请先导入包含 Alternative、g1,g2,...、Class 的数据集。');
    end
end

function validateReferences(state)
    yref = state.yKnown(state.knownMask);
    if numel(yref) < state.q
        error('参考样本过少。建议每个类别至少选择一个参考方案。');
    end
    missing = setdiff(1:state.q, unique(yref(:))');
    if ~isempty(missing)
        error('参考集中缺少类别：%s。请为每个类别至少选择一个参考方案。', mat2str(missing));
    end
end

function s = makeMetricStatus(state, lang)
    if isempty(state.metricsHistory)
        if nargin >= 2 && string(lang) == "en"
            s = sprintf('Round %d | Known %d / %d', state.queryCount, sum(state.knownMask), state.n);
        else
            s = sprintf('第 %d 轮 | 已知 %d / %d', state.queryCount, sum(state.knownMask), state.n);
        end
        return;
    end
    r = state.metricsHistory(end,:);
    if nargin >= 2 && string(lang) == "en"
        s = sprintf('Round %d | Known %d / %d | Query %d / %d', ...
            r.Round, r.KnownCount, state.n, state.queryCount, state.cfg.Kmax);
    else
        s = sprintf('第 %d 轮 | 已知 %d / %d | 询问 %d / %d', ...
            r.Round, r.KnownCount, state.n, state.queryCount, state.cfg.Kmax);
    end
end

function [X, y, altNames, critNames] = loadMCSDataUI(filePath)
    T = readtable(filePath, 'VariableNamingRule', 'preserve');

    varNames = string(T.Properties.VariableNames);
    classCol = find(strcmpi(varNames, 'Class'), 1);
    if isempty(classCol)
        error('数据文件必须包含 Class 列，用于自动识别类别数并测试准确率。');
    end

    gCols = find(startsWith(varNames, 'g', 'IgnoreCase', true));
    if isempty(gCols)
        error('数据文件必须包含 g1, g2, ... 形式的准则列。');
    end

    X = double(table2array(T(:, gCols)));
    if any(~isfinite(X(:)))
        error('准则列中存在非数值或缺失值，请先清理数据。');
    end

    for j = 1:size(X,2)
        xmin = min(X(:,j));
        xmax = max(X(:,j));
        if xmin < -1e-10 || xmax > 1 + 1e-10
            if xmax > xmin
                X(:,j) = (X(:,j) - xmin) ./ (xmax - xmin);
            else
                X(:,j) = 0;
            end
        end
    end

    rawClass = string(T{:, classCol});
    y = parseClassVector(rawClass);
    if any(y < 1) || any(fix(y) ~= y)
        error('Class 必须是 Cl1, Cl2, ... 或正整数。');
    end

    altNames = "a_" + string((1:size(X,1))');
    critNames = varNames(gCols);
end

function y = parseClassVector(rawClass)
    y = zeros(numel(rawClass), 1);
    for i = 1:numel(rawClass)
        token = regexp(rawClass(i), '\d+', 'match');
        if ~isempty(token)
            y(i) = str2double(token{1});
        else
            val = str2double(rawClass(i));
            if ~isnan(val)
                y(i) = val;
            else
                error('类别标签必须类似 Cl1, Cl2, ... 或数字。');
            end
        end
    end
end

%% Session update
function state = trainAndClassifyState(state)
    Xref = state.X(state.knownMask,:);
    yref = state.yKnown(state.knownMask);
    q = state.q;
    cfg = state.cfg;

    model = trainMMUTADIS(Xref, yref, q, cfg);
    state.model = model;

    state.pred = nan(state.n, 1);
    state.pred(state.knownMask) = state.yKnown(state.knownMask);
    state.pS = nan(state.n, 1);
    state.AIW = nan(state.n, 1);
    state.RRA = nan(state.n, 1);
    state.region = strings(state.n, 1);
    state.region(state.knownMask) = "Known";

    poolIdx = find(~state.knownMask);
    if ~isempty(poolIdx)
        Xpool = state.X(poolIdx,:);
        [predPool, ~] = predictModel(model, Xpool);
        rob = computeRobustInfo(model, Xref, yref, Xpool, cfg);
        state.pred(poolIdx) = predPool;
        state.pS(poolIdx) = rob.pS;
        state.AIW(poolIdx) = rob.AIW;
        state.RRA(poolIdx) = rob.RRA;
        state.region(poolIdx) = regionNames(rob.Region);
    end

    metrics = computeClassificationMetrics(state.yTrue, state.pred, q);
    if state.queryCount > 0
        cr = state.correctionCount / state.queryCount;
    else
        cr = 0;
    end

    row = table(state.queryCount, metrics.Accuracy, metrics.Precision, metrics.Recall, ...
        metrics.Fmeasure, metrics.MAE, cr, sum(state.knownMask), ...
        'VariableNames', {'Round','Accuracy','Precision','Recall','Fmeasure','MAE','CR','KnownCount'});

    if isempty(state.metricsHistory)
        state.metricsHistory = row;
    elseif state.metricsHistory.Round(end) == state.queryCount
        state.metricsHistory(end,:) = row;
    else
        state.metricsHistory = [state.metricsHistory; row];
    end
end

function names = regionNames(regionCode)
    names = strings(numel(regionCode), 1);
    names(regionCode == 1) = "POS";
    names(regionCode == 2) = "BND";
    names(regionCode == 3) = "NEG";
end

function [selGlobal, selLocal] = selectNextTWDQuery(state)
    poolIdx = find(~state.knownMask);
    if isempty(poolIdx)
        selGlobal = [];
        selLocal = [];
        return;
    end

    negLocal = find(state.region(poolIdx) == "NEG");
    if isempty(negLocal)
        cand = (1:numel(poolIdx))';
    else
        cand = negLocal(:);
    end

    score = state.RRA(poolIdx);
    sub = score(cand);
    sub(~isfinite(sub)) = -inf;
    best = max(sub);
    tied = cand(abs(sub - best) <= 1e-12);
    selLocal = tied(1);
    selGlobal = poolIdx(selLocal);
end

%% MM-UTADIS and robust information
function model = trainMMUTADIS(X, y, q, cfg)
    [~, ~, phiStar] = solveUTADISStage1Paper(X, y, q, cfg);
    [theta, b, delta] = solveUTADISStage2Paper(X, y, q, phiStar, cfg);
    model.type = "MM-UTADIS";
    model.q = q;
    model.L = cfg.L;
    model.theta = theta;
    model.b = b(:);
    model.delta = delta;
    model.phiStar = phiStar;
end

function [theta, b, phiStar] = solveUTADISStage1Paper(X, y, q, cfg)
    lp = buildStage1LP(X, y, q, cfg);
    f = zeros(lp.nVar, 1);
    f(lp.idxE) = 1;
    [sol, fval] = runLinprog(f, lp.A, lp.rhs, lp.Aeq, lp.beq, lp.lb, lp.ub, cfg);
    theta = sol(lp.idxTheta);
    b = sol(lp.idxB);
    phiStar = fval;
end

function [theta, b, delta] = solveUTADISStage2Paper(X, y, q, phiStar, cfg)
    n = size(X,1);
    L = cfg.L;
    Phi = computePhiBasis(X, L);
    p = size(Phi, 2);
    nB = q - 1;

    idxTheta = 1:p;
    idxB = p + (1:nB);
    idxE = p + nB + (1:n);
    idxDelta = p + nB + n + 1;
    nVar = idxDelta;

    A = sparse(0, nVar);
    rhs = [];

    row = zeros(1, nVar);
    row(idxE) = 1;
    A = [A; sparse(row)];
    rhs = [rhs; phiStar + cfg.compatTol];

    for i = 1:n
        h = y(i);
        if h > 1
            row = zeros(1, nVar);
            row(idxTheta) = -Phi(i,:);
            row(idxB(h-1)) = 1;
            row(idxDelta) = 1;
            row(idxE(i)) = -1;
            A = [A; sparse(row)];
            rhs = [rhs; 0];
        end
        if h < q
            row = zeros(1, nVar);
            row(idxTheta) = Phi(i,:);
            row(idxB(h)) = -1;
            row(idxDelta) = 1;
            row(idxE(i)) = -1;
            A = [A; sparse(row)];
            rhs = [rhs; 0];
        end
    end

    row = zeros(1, nVar);
    row(idxB(1)) = -1;
    row(idxDelta) = 1;
    A = [A; sparse(row)];
    rhs = [rhs; 0];

    row = zeros(1, nVar);
    row(idxB(q-1)) = 1;
    row(idxDelta) = 1;
    A = [A; sparse(row)];
    rhs = [rhs; 1];

    for h = 2:q-1
        row = zeros(1, nVar);
        row(idxB(h-1)) = 1;
        row(idxB(h)) = -1;
        row(idxDelta) = 2;
        A = [A; sparse(row)];
        rhs = [rhs; 0];
    end

    f = zeros(nVar,1);
    f(idxDelta) = -1;
    Aeq = sparse(1, idxTheta, ones(1,p), 1, nVar);
    beq = 1;

    lb = zeros(nVar,1);
    ub = inf(nVar,1);
    ub(idxB) = 1;
    ub(idxDelta) = 1 / (2*(q-1));

    [sol, ~] = runLinprog(f, A, rhs, Aeq, beq, lb, ub, cfg);
    theta = sol(idxTheta);
    b = sol(idxB);
    delta = sol(idxDelta);
end

function lp = buildStage1LP(X, y, q, cfg)
    n = size(X,1);
    L = cfg.L;
    Phi = computePhiBasis(X, L);
    p = size(Phi, 2);
    nB = q - 1;

    idxTheta = 1:p;
    idxB = p + (1:nB);
    idxE = p + nB + (1:n);
    nVar = p + nB + n;

    A = sparse(0, nVar);
    rhs = [];

    for i = 1:n
        h = y(i);
        if h > 1
            row = zeros(1, nVar);
            row(idxTheta) = -Phi(i,:);
            row(idxB(h-1)) = 1;
            row(idxE(i)) = -1;
            A = [A; sparse(row)];
            rhs = [rhs; 0];
        end
        if h < q
            row = zeros(1, nVar);
            row(idxTheta) = Phi(i,:);
            row(idxB(h)) = -1;
            row(idxE(i)) = -1;
            A = [A; sparse(row)];
            rhs = [rhs; 0];
        end
    end

    [A, rhs] = addThresholdOrderRows(A, rhs, idxB, q, cfg.thresholdMinGap, nVar);

    Aeq = sparse(1, idxTheta, ones(1,p), 1, nVar);
    beq = 1;
    lb = zeros(nVar,1);
    ub = inf(nVar,1);
    ub(idxB) = 1;

    lp.A = A;
    lp.rhs = rhs;
    lp.Aeq = Aeq;
    lp.beq = beq;
    lp.lb = lb;
    lp.ub = ub;
    lp.idxTheta = idxTheta;
    lp.idxB = idxB;
    lp.idxE = idxE;
    lp.nVar = nVar;
end

function [A, rhs] = addThresholdOrderRows(A, rhs, idxB, q, minGap, nVar)
    if q <= 1
        return;
    end

    row = zeros(1, nVar);
    row(idxB(1)) = -1;
    A = [A; sparse(row)];
    rhs = [rhs; -minGap];

    for h = 2:q-1
        row = zeros(1, nVar);
        row(idxB(h-1)) = 1;
        row(idxB(h)) = -1;
        A = [A; sparse(row)];
        rhs = [rhs; -minGap];
    end

    row = zeros(1, nVar);
    row(idxB(q-1)) = 1;
    A = [A; sparse(row)];
    rhs = [rhs; 1 - minGap];
end

function rob = computeRobustInfo(model, Xref, yref, Xpool, cfg)
    q = model.q;
    [pred, Ucentral] = predictModel(model, Xpool);
    samples = sampleCompatibleAdditiveModels(Xref, yref, Xpool, q, model.phiStar, cfg);

    CAI = samples.CAI;
    P = CAI;
    P(P <= 0) = 1;
    ECAI = -sum(CAI .* log2(P), 2);
    AIW = sum(CAI > cfg.caiPositiveTol, 2);
    AIW(AIW == 0) = 1;

    pS = zeros(size(Xpool,1),1);
    for i = 1:size(Xpool,1)
        pS(i) = CAI(i, pred(i));
    end
    pN = 1 - pS;

    xi = cfg.xi;
    MAC = cfg.MAC;
    RA = MAC .* pN;
    RD = xi .* (1 - MAC) .* pS + xi .* MAC .* pN;
    RR = (1 - MAC) .* pS;

    alpha = ((1 - xi) * MAC) / (((1 - xi) * MAC) + xi * (1 - MAC));
    beta  = (xi * MAC) / ((xi * MAC) + ((1 - xi) * (1 - MAC)));

    Region = 2 * ones(size(pS));
    Region(pS >= alpha) = 1;
    Region(pS <= beta) = 3;

    RRA = min(RA, RD) - RR;

    rob.pred = pred;
    rob.Ucentral = Ucentral;
    rob.CAI = CAI;
    rob.ECAI = ECAI;
    rob.AIW = AIW;
    rob.pS = pS;
    rob.RA = RA;
    rob.RD = RD;
    rob.RR = RR;
    rob.alpha = alpha;
    rob.beta = beta;
    rob.Region = Region;
    rob.RRA = RRA;
    rob.samples = samples;
end

function samples = sampleCompatibleAdditiveModels(Xref, yref, Xpool, q, phiStar, cfg)
    lp = buildStage1LP(Xref, yref, q, cfg);

    row = zeros(1, lp.nVar);
    row(lp.idxE) = 1;
    Acomp = [lp.A; sparse(row)];
    rhsComp = [lp.rhs; phiStar + cfg.compatTol];

    nPool = size(Xpool,1);
    predSamples = zeros(nPool, cfg.Ns);
    USamples = zeros(nPool, cfg.Ns);
    bSamples = zeros(q-1, cfg.Ns);
    counts = zeros(nPool, q);
    nAccepted = 0;
    maxAttempts = max(cfg.Ns * 4, cfg.Ns + 20);

    for s = 1:maxAttempts
        if nAccepted >= cfg.Ns
            break;
        end

        f = randn(lp.nVar,1);
        f(lp.idxE) = 0.05 * f(lp.idxE);
        try
            sol = runLinprog(f, Acomp, rhsComp, lp.Aeq, lp.beq, lp.lb, lp.ub, cfg);
            thetaS = sol(lp.idxTheta);
            bS = sol(lp.idxB);
            [predS, US] = predictAdditive(thetaS, bS, Xpool, cfg.L, q);

            nAccepted = nAccepted + 1;
            predSamples(:, nAccepted) = predS;
            USamples(:, nAccepted) = US;
            bSamples(:, nAccepted) = bS(:);

            for i = 1:nPool
                counts(i, predS(i)) = counts(i, predS(i)) + 1;
            end
        catch
        end
    end

    if nAccepted == 0
        error('相容模型采样失败：没有得到可行模型。可尝试增大 compatTol、减少 Ns 或增加参考样本。');
    end

    samples.predSamples = predSamples(:, 1:nAccepted);
    samples.USamples = USamples(:, 1:nAccepted);
    samples.bSamples = bSamples(:, 1:nAccepted);
    samples.CAI = counts ./ nAccepted;
    samples.nAccepted = nAccepted;
end

%% Prediction, metrics, solver
function Phi = computePhiBasis(X, L)
    [n, m] = size(X);
    tau = linspace(0, 1, L+1);
    Phi = zeros(n, m*L);
    col = 0;
    for j = 1:m
        x = X(:,j);
        for ell = 1:L
            col = col + 1;
            denom = tau(ell+1) - tau(ell);
            Phi(:,col) = max(0, min(1, (x - tau(ell)) ./ denom));
        end
    end
end

function [pred, U] = predictModel(model, X)
    switch string(model.type)
        case "MM-UTADIS"
            [pred, U] = predictAdditive(model.theta, model.b, X, model.L, model.q);
        otherwise
            error('未知模型类型：%s', model.type);
    end
end

function [pred, U] = predictAdditive(theta, b, X, L, q)
    Phi = computePhiBasis(X, L);
    U = Phi * theta;
    pred = assignByThresholds(U, b, q);
end

function pred = assignByThresholds(U, b, q)
    pred = ones(size(U));
    tol = 1e-10;
    for h = 1:q-1
        pred = pred + (U > b(h) + tol);
    end
    pred = max(1, min(q, pred));
end

function cls = computeClassificationMetrics(ytrue, ypred, q)
    confMat = zeros(q, q);
    valid = ~isnan(ypred);
    ytrue = ytrue(valid);
    ypred = ypred(valid);
    for i = 1:numel(ytrue)
        if ytrue(i) >= 1 && ytrue(i) <= q && ypred(i) >= 1 && ypred(i) <= q
            confMat(ytrue(i), ypred(i)) = confMat(ytrue(i), ypred(i)) + 1;
        end
    end

    precision = zeros(q,1);
    recall = zeros(q,1);
    f1 = zeros(q,1);

    for h = 1:q
        TP = confMat(h,h);
        FP = sum(confMat(:,h)) - TP;
        FN = sum(confMat(h,:)) - TP;
        if TP + FP > 0
            precision(h) = TP / (TP + FP);
        end
        if TP + FN > 0
            recall(h) = TP / (TP + FN);
        end
        if precision(h) + recall(h) > 0
            f1(h) = 2 * precision(h) * recall(h) / (precision(h) + recall(h));
        end
    end

    cls.Accuracy = mean(ypred == ytrue);
    cls.Precision = mean(precision);
    cls.Recall = mean(recall);
    cls.Fmeasure = mean(f1);
    cls.MAE = mean(abs(ypred - ytrue));
end

function [x, fval] = runLinprog(f, A, b, Aeq, beq, lb, ub, cfg)
    try
        opts = optimoptions('linprog', 'Display', cfg.solverDisplay, 'Algorithm', 'dual-simplex');
    catch
        opts = optimoptions('linprog', 'Display', cfg.solverDisplay);
    end

    [x, fval, exitflag, output] = linprog(f, A, b, Aeq, beq, lb, ub, opts);
    if exitflag <= 0
        msg = '';
        if exist('output', 'var') && isfield(output, 'message')
            msg = output.message;
        end
        error('线性规划求解失败：exitflag=%d, message=%s', exitflag, msg);
    end
end
