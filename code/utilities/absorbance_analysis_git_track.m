classdef absorbance_analysis_git_track < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AbsorbanceAnalysisUIFigure  matlab.ui.Figure
        Menu                        matlab.ui.container.Menu
        LoadFileMenu                matlab.ui.container.Menu
        ExportAnalysisMenu          matlab.ui.container.Menu
        AnalysisPanel               matlab.ui.container.Panel
        ControlsPanel               matlab.ui.container.Panel
        RelativeClotFormationOnsetThresholdEditField  matlab.ui.control.NumericEditField
        RelativeClotFormationOnsetThresholdEditFieldLabel  matlab.ui.control.Label
        RelativeLysisOnsetThresholdEditField  matlab.ui.control.NumericEditField
        RelativeLysisOnsetThresholdEditFieldLabel  matlab.ui.control.Label
        AnalysisAxes                matlab.ui.control.UIAxes
        RawDataPanel                matlab.ui.container.Panel
        NormalizedRawDataAxes       matlab.ui.control.UIAxes
        RawDataAxes                 matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        analysis % Description
    end
    
    methods (Access = public)
        
        function PlotRawData(app,sheet_no)
            
            data_table = app.analysis.data{sheet_no};
            conditions = data_table.Properties.VariableNames';
            conditions(strcmp(conditions,'Time')) = [];
            conditions(1) = [];
            sz = numel(conditions);
            col_map = lines(sz);
            col_map(:,4) = 0.5;
            app.analysis.normalized_data{sheet_no}.Time = data_table.Time;

            control = (data_table.Control);
            min_control = min(control);
            max_control = max(control);

            for i = 1 : numel(conditions)
                cond = [];
                hold(app.RawDataAxes,"on")
                plot(app.RawDataAxes,data_table.Time,data_table.(conditions{i}),'color',col_map(i,:),'LineWidth',1.7);
                cond = data_table.(conditions{i});
                cond = (cond-min_control)/(max_control - min_control);
                app.analysis.normalized_data{sheet_no}.(conditions{i}) = cond;
                hold(app.NormalizedRawDataAxes,"on")
                plot(app.NormalizedRawDataAxes,data_table.Time,cond,'color',col_map(i,:),'LineWidth',1.7);
            end
            
            app.AnalyzeNormalizedData(sheet_no)

            
        end
        
        function AnalyzeNormalizedData(app,sheet_no)

            normalized_data = app.analysis.normalized_data{sheet_no};

            conditions = fieldnames(normalized_data);
            conditions(strcmp(conditions,'Time')) = [];
            sz = numel(conditions);
            col_map = lines(sz);
            marker_col_map = col_map;
            col_map(:,4) = 0.25;
            clot_formation_threshold = app.RelativeClotFormationOnsetThresholdEditField.Value;
            lysine_onset_threshold = app.RelativeLysisOnsetThresholdEditField.Value;
            deriv_threshold = -0.0005;
            marker_size = 6;
            


            for i = 1 : numel(conditions)

                cond = [];
                time = [];
                lysine_onset = [];
                lysine_cess = [];
                clot_onset = [];
                clot_cess = [];
               
                time = normalized_data.Time;
                cond = normalized_data.(conditions{i});

                [max_od,max_ix] = max(cond);
                diff_cond = diff(cond);

                deriv_ix = find(diff_cond<deriv_threshold,1,'first')-1;

                lysine_onset = find(cond>max_od*lysine_onset_threshold,1,'last');
                lysine_cess = max_ix + find(cond(max_ix+1:end)<=0,1,'first');
                if isempty(lysine_cess) 
                    lysine_cess = numel(cond);
                end

                if lysine_cess == lysine_onset
                    lysine_onset = max_ix;
                end

                clot_onset = find(cond>max_od*clot_formation_threshold,1,'first');
                clot_cess = find(cond>max_od*lysine_onset_threshold,1,'first');

                lysine_trajectory = fit_linear_model(time(lysine_onset:lysine_cess)',cond(lysine_onset:lysine_cess));

                clot_trajectory = fit_linear_model(time(clot_onset:clot_cess)',cond(clot_onset:clot_cess));

                area_under_the_curve = simps(time(1:lysine_cess),cond(1:lysine_cess));
                
                
                hold(app.AnalysisAxes,'on')
                p(i) = plot(app.AnalysisAxes,time,cond,'color',col_map(i,:),'LineWidth',1.7);
                plot(app.AnalysisAxes,time(max_ix),cond(max_ix),'^', ...
                    'LineStyle','none', ...
                    'MarkerFaceColor',marker_col_map(i,:), ...
                    'MarkerEdgeColor','k', ...
                    'MarkerSize',marker_size)
                plot(app.AnalysisAxes,time(clot_onset),cond(clot_onset),'o', ...
                    'LineStyle','none', ...
                    'MarkerFaceColor',marker_col_map(i,:), ...
                    'MarkerEdgeColor','k', ...
                    'MarkerSize',marker_size)
                plot(app.AnalysisAxes,time(clot_cess),cond(clot_cess),'o', ...
                    'LineStyle','none', ...
                    'MarkerFaceColor',marker_col_map(i,:), ...
                    'MarkerEdgeColor','k', ...
                    'MarkerSize',marker_size)
                plot(app.AnalysisAxes,time(lysine_onset),cond(lysine_onset),'s', ...
                    'LineStyle','none', ...
                    'MarkerFaceColor',marker_col_map(i,:), ...
                    'MarkerEdgeColor','k', ...
                    'MarkerSize',marker_size)
                plot(app.AnalysisAxes,time(lysine_cess),cond(lysine_cess),'s', ...
                    'LineStyle','none', ...
                    'MarkerFaceColor',marker_col_map(i,:), ...
                    'MarkerEdgeColor','k', ...
                    'MarkerSize',marker_size)
                plot(app.AnalysisAxes,lysine_trajectory.x_fit,lysine_trajectory.y_fit, ...
                    ':','color',marker_col_map(i,:), ...
                    'LineWidth',1.7)
                plot(app.AnalysisAxes,clot_trajectory.x_fit,clot_trajectory.y_fit, ...
                    ':','color',marker_col_map(i,:), ...
                    'LineWidth',1.7)


                app.analysis.out(sheet_no).condition(i,1) = conditions(i);
                app.analysis.out(sheet_no).ninety_percent_max_OD(i,1) = cond(lysine_onset);
                app.analysis.out(sheet_no).ninety_percent_max_OD_time(i,1) = time(lysine_onset);
                app.analysis.out(sheet_no).upward_slope_start_time(i,1) = time(clot_onset);
                app.analysis.out(sheet_no).upward_slope_end_time(i,1) = time(clot_cess);
                app.analysis.out(sheet_no).upward_slope(i,1) = clot_trajectory.slope;
                app.analysis.out(sheet_no).downward_slope_start_time(i,1) = time(lysine_onset);
                app.analysis.out(sheet_no).downward_slope_end_time(i,1) = time(lysine_cess);
                app.analysis.out(sheet_no).downward_slope(i,1) = lysine_trajectory.slope;
                app.analysis.out(sheet_no).reach_bottom_time(i,1) = time(lysine_cess);
                app.analysis.out(sheet_no).bottom_OD(i,1) = cond(lysine_cess);
                app.analysis.out(sheet_no).area_under_the_curve(i,1) = area_under_the_curve;

            end
            leg_conditions = strrep(conditions,'_',' ');
            legend(p,leg_conditions, ...
                'Location','northoutside', ...
                'Orientation','horizontal', ...
                'NumColumns',3)

          
            
        end
        
        function ClearDisplays(app)

            ax = {'RawDataAxes','NormalizedRawDataAxes','AnalysisAxes'};

            for i = 1:numel(ax)
                cla(app.(ax{i}))
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath('utilities'))
            movegui(app.AbsorbanceAnalysisUIFigure,'center')
        end

        % Menu selected function: LoadFileMenu
        function LoadFileMenuSelected(app, event)
            f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
            [file_string,path_string]=uigetfile2( ...
                {'*.xlsx','XLSX'}, ...
                'Select the Excel File');
            delete(f)
            if (path_string~=0)
                app.ClearDisplays
                app.analysis = [];
                app.analysis.data_file_string = fullfile(path_string,file_string);
                sheets = sheetnames(app.analysis.data_file_string);
                for i = 1 : numel(sheets)
                    app.analysis.data{i} = readtable(app.analysis.data_file_string,'Sheet',sheets{i});
                    app.PlotRawData(i)
                end

            end
        end

        % Menu selected function: ExportAnalysisMenu
        function ExportAnalysisMenuSelected(app, event)
            f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file_string,path_string] = uiputfile2( ...
                {'*.xlsx','Excel file'},'Enter Excel File Name For Analysis Results');
            delete(f)

            if (path_string~=0)
                out = [];
                output_file_string = fullfile(path_string,file_string);

                try
                    delete(output_file_string);
                end
                for i = 1 : size(app.analysis.out,2)
                out = app.analysis.out(i);
                writetable(struct2table(out),output_file_string,'Sheet',i);
                end
            end

        end

        % Value changed function: 
        % RelativeClotFormationOnsetThresholdEditField
        function RelativeClotFormationOnsetThresholdEditFieldValueChanged(app, event)
            cla(app.AnalysisAxes);
            app.analysis.out = [];


            for i = 1 : size(app.analysis.data,2)
                app.AnalyzeNormalizedData(i)
            end

        end

        % Value changed function: RelativeLysisOnsetThresholdEditField
        function RelativeLysisOnsetThresholdEditFieldValueChanged(app, event)
            cla(app.AnalysisAxes);
            app.analysis.out = [];

            for i = 1 : size(app.analysis.data,2)
                app.AnalyzeNormalizedData(i)
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create AbsorbanceAnalysisUIFigure and hide until all components are created
            app.AbsorbanceAnalysisUIFigure = uifigure('Visible', 'off');
            app.AbsorbanceAnalysisUIFigure.Position = [100 100 956 471];
            app.AbsorbanceAnalysisUIFigure.Name = 'Absorbance Analysis';

            % Create Menu
            app.Menu = uimenu(app.AbsorbanceAnalysisUIFigure);
            app.Menu.Text = 'Menu';

            % Create LoadFileMenu
            app.LoadFileMenu = uimenu(app.Menu);
            app.LoadFileMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadFileMenuSelected, true);
            app.LoadFileMenu.Text = 'Load File';

            % Create ExportAnalysisMenu
            app.ExportAnalysisMenu = uimenu(app.Menu);
            app.ExportAnalysisMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportAnalysisMenuSelected, true);
            app.ExportAnalysisMenu.Text = 'Export Analysis';

            % Create RawDataPanel
            app.RawDataPanel = uipanel(app.AbsorbanceAnalysisUIFigure);
            app.RawDataPanel.Title = 'Raw Data';
            app.RawDataPanel.Position = [9 9 488 455];

            % Create RawDataAxes
            app.RawDataAxes = uiaxes(app.RawDataPanel);
            xlabel(app.RawDataAxes, 'Time (min)')
            ylabel(app.RawDataAxes, 'Optical Density (AU)')
            app.RawDataAxes.Box = 'on';
            app.RawDataAxes.Position = [9 217 471 201];

            % Create NormalizedRawDataAxes
            app.NormalizedRawDataAxes = uiaxes(app.RawDataPanel);
            xlabel(app.NormalizedRawDataAxes, 'Time (min)')
            ylabel(app.NormalizedRawDataAxes, 'Normalized Optical Deensity')
            app.NormalizedRawDataAxes.Box = 'on';
            app.NormalizedRawDataAxes.Position = [9 1 471 201];

            % Create AnalysisPanel
            app.AnalysisPanel = uipanel(app.AbsorbanceAnalysisUIFigure);
            app.AnalysisPanel.Title = 'Analysis';
            app.AnalysisPanel.Position = [506 9 444 455];

            % Create AnalysisAxes
            app.AnalysisAxes = uiaxes(app.AnalysisPanel);
            xlabel(app.AnalysisAxes, 'Time (min)')
            ylabel(app.AnalysisAxes, 'Normalized Optical Deensity')
            zlabel(app.AnalysisAxes, 'Z')
            app.AnalysisAxes.Box = 'on';
            app.AnalysisAxes.Position = [12 12 420 307];

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.AnalysisPanel);
            app.ControlsPanel.Title = 'Controls';
            app.ControlsPanel.Position = [8 338 424 89];

            % Create RelativeLysisOnsetThresholdEditFieldLabel
            app.RelativeLysisOnsetThresholdEditFieldLabel = uilabel(app.ControlsPanel);
            app.RelativeLysisOnsetThresholdEditFieldLabel.WordWrap = 'on';
            app.RelativeLysisOnsetThresholdEditFieldLabel.Position = [239 18 129 34];
            app.RelativeLysisOnsetThresholdEditFieldLabel.Text = 'Relative Lysis Onset Threshold';

            % Create RelativeLysisOnsetThresholdEditField
            app.RelativeLysisOnsetThresholdEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.RelativeLysisOnsetThresholdEditField.Limits = [0 1];
            app.RelativeLysisOnsetThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @RelativeLysisOnsetThresholdEditFieldValueChanged, true);
            app.RelativeLysisOnsetThresholdEditField.Position = [367 24 43 22];
            app.RelativeLysisOnsetThresholdEditField.Value = 0.9;

            % Create RelativeClotFormationOnsetThresholdEditFieldLabel
            app.RelativeClotFormationOnsetThresholdEditFieldLabel = uilabel(app.ControlsPanel);
            app.RelativeClotFormationOnsetThresholdEditFieldLabel.VerticalAlignment = 'top';
            app.RelativeClotFormationOnsetThresholdEditFieldLabel.WordWrap = 'on';
            app.RelativeClotFormationOnsetThresholdEditFieldLabel.Position = [9 22 160 28];
            app.RelativeClotFormationOnsetThresholdEditFieldLabel.Text = 'Relative Clot Formation Onset Threshold';

            % Create RelativeClotFormationOnsetThresholdEditField
            app.RelativeClotFormationOnsetThresholdEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.RelativeClotFormationOnsetThresholdEditField.Limits = [0 1];
            app.RelativeClotFormationOnsetThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @RelativeClotFormationOnsetThresholdEditFieldValueChanged, true);
            app.RelativeClotFormationOnsetThresholdEditField.Position = [145 25 43 22];
            app.RelativeClotFormationOnsetThresholdEditField.Value = 0.3;

            % Show the figure after all components are created
            app.AbsorbanceAnalysisUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = absorbance_analysis_git_track

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AbsorbanceAnalysisUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AbsorbanceAnalysisUIFigure)
        end
    end
end