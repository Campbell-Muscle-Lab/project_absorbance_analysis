function calculate_time_constant_and_area_average

utilities = '../../../../../utku/github/MATLAB_Utilities';

addpath(genpath(utilities))


no_of_panels_wide = 1;
no_of_panels_high = 3;



data_folder = 'Data';

xls_files = findfiles('xlsx',data_folder);


trace_width = 1.8;
marker_size = 10;


deriv_threshold = -0.0005;


for i = 1 : numel(xls_files)

data = [];

sheets = sheetnames(xls_files{i})
for sh = 1

figure(1)
sp = initialise_publication_quality_figure('no_of_panels_wide',no_of_panels_wide, ...
                                      'no_of_panels_high',no_of_panels_high, ...
                                      'x_to_y_axes_ratio',2,'right_margin',2, ...
                                      'top_margin',0.75,'axes_padding_left',1.2, ...
                                      'panel_label_font_size',0, ...
                                      'relative_row_heights',[1 0.75 0.75]);

data = readtable(xls_files{i},'Sheet',sheets{sh});

[~,output_figure_file,~] = fileparts(xls_files{i});

conditions = data.Properties.VariableNames'

conditions(strcmp(conditions,'Time')) = [];
conditions(1) = [];

col = parula(numel(conditions));

control = (data.Control);

min_control = min(control);
max_control = max(control);


for j = 1 : numel(conditions)
    
    cond = [];
    time = [];

    cond = data.(conditions{j});
    cond = (cond-min_control)/(max_control - min_control);
    time = data.Time;
    
    [max_od,max_ix] = max(cond);
    diff_cond = diff(cond);
    
    figure(1)
    subplot(sp(1));
    hold on
        c = col(j,:);
    c(4) = 0.75;
    h(j) = plot(time,cond,'color',c,'LineWidth',trace_width);
    plot(time(max_ix),max_od,'^','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')

    deriv_ix = find(diff_cond<deriv_threshold,1,'first')-1;


    ix_1 = find(cond>max_od*0.9,1,'last');
    ix_2 = find(cond>max_od*0.2,1,'last');
    ix_reach_bottom = max_ix + find(cond(max_ix+1:end)<=0,1,'first')

    ix_3 = find(cond>max_od*0.9,1,'first');
    ix_4 = find(cond>max_od*0.3,1,'first');

    if deriv_ix == 0
        deriv_ix = 1;
        ix_2 = numel(cond);
    end

    if isempty(deriv_ix)
        deriv_ix = 1;
        ix_1 = max_ix;
        ix_2 = numel(cond);
    end

    if isempty(ix_1)
        ix_1 = 1;
    end

    if ix_1 == ix_2 || isempty(ix_2)
        ix_2 = numel(cond);
        if ix_1 == numel(cond)
            ix_1 = max_ix 
        end
    end
        
    ix_1 
    ix_2
    if isempty(ix_reach_bottom)
        ix_reach_bottom = numel(cond);
    end

    fitted_line_down = fit_linear_model(time(ix_1:ix_reach_bottom)',cond(ix_1:ix_reach_bottom));
    fitted_line_up = fit_linear_model(time(ix_4:ix_3)',cond(ix_4:ix_3));

    



    area_under_the_curve = simps(time(1:ix_reach_bottom),cond(1:ix_reach_bottom))
    trapz(time(1:ix_reach_bottom),cond(1:ix_reach_bottom))


    
    plot(time(ix_3),cond(ix_3),'p','color',col(j,:),'LineStyle','none', ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')
    plot(time(ix_4),cond(ix_4),'o','color',col(j,:),'LineStyle','none', ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')
    plot(time(ix_1),cond(ix_1),'o','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')
    % plot(time(ix_2),cond(ix_2),'s','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
    %     'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')
    plot(fitted_line_down.x_fit,fitted_line_down.y_fit,':','color',col(j,:),'LineWidth',trace_width)
    plot(time(ix_reach_bottom),cond(ix_reach_bottom),'v','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')

    
    subplot(sp(2))
    hold on
    plot(j,fitted_line_down.slope,'o','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')

    subplot(sp(3))
    hold on
    plot(j,area_under_the_curve,'o','color',col(j,:),'LineStyle','none','MarkerSize',marker_size, ...
        'MarkerSize',marker_size,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','k')



    out(i).condition(j,1) = conditions(j);
    % out(i).lysine_onset(j,1) = time(deriv_ix);
    out(i).ninety_percent_max_OD(j,1) = cond(ix_1);
    out(i).ninety_percent_max_OD_time(j,1) = time(ix_1);
    out(i).upward_slope_start_time(j,1) = time(ix_4);
    out(i).upward_slope_end_time(j,1) = time(ix_3);
    out(i).upward_slope(j,1) = fitted_line_up.slope;
    out(i).downward_slope_start_time(j,1) = time(ix_1);
    out(i).downward_slope_end_time(j,1) = time(ix_reach_bottom);
    out(i).downward_slope(j,1) = fitted_line_down.slope;
    out(i).reach_bottom_time(j,1) = time(ix_reach_bottom);
    out(i).bottom_OD(j,1) = cond(ix_reach_bottom);
    out(i).area_under_the_curve(j,1) = area_under_the_curve;



end

conditions = strrep(conditions,'_',' ');



% legendflex(h, conditions, 'ref', gcf, ...
%                        'anchor', {'n','n'}, ...
%                        'buffer',[40 -10], ...
%                        'fontsize',8,'nrow',4);


improve_axes('axis_handle',sp(1),'y_axis_label',{'Norm.','OD'}, ...
    'y_label_offset',-0.1,'x_axis_label','Time(min)','x_label_offset',-0.1, ...
    'x_tick_decimal_places',0);


improve_axes('axis_handle',sp(2),'y_axis_label',{'Downward','slope','(min^-^1)'}, ...
    'y_label_offset',-0.15,'x_axis_label','','x_label_offset',-0.2, ...
    'x_tick_decimal_places',0,'x_tick_label_positions',[1:numel(conditions)],...
    'x_tick_labels',conditions,'x_tick_label_rotation',45,'x_tick_length',0,'x_axis_off',1);

improve_axes('axis_handle',sp(3),'y_axis_label',{'Area under','the','curve','(A.U.)'}, ...
    'y_label_offset',-0.15,'x_axis_label','','x_label_offset',-0.2, ...
    'x_tick_decimal_places',0,'x_tick_label_positions',[1:numel(conditions)],...
    'x_tick_labels',conditions,'x_tick_label_rotation',45,'x_tick_length',0);


figure_export('output_file_string',sheets{sh},'output_type','png')

writetable(struct2table(out),sprintf('%s_summary.xlsx',sheets{sh}))


end

end




















end