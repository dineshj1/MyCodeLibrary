classdef ShadedCorrelationTable < handle
% ShadedCorrelationTable produces a correlation table for a set of
% variables, enhanced graphically with shading according to correlation 
% values.
%
% Upper or lower ranges of correlation values may be highlighted through 
% the interface controls.  Two methods are provided to do this: a decay 
% function that softens shading of values of less interest, or, shading 
% according to a discrete threshold.
% 
% Pearson's linear correlation coefficient is used.
% 
% Usage:
%
%     ShadedCorrelationTable(x,xLabels);
%
% x: an m column matrix, where m >= 2.  Each column corresponds to a
% variable.
%
% xLabels: column labels as a cell array of strings. e.g. {'var 1' 'var 2'}
%
% Example:
%
% load('demo data.mat');
% ShadedCorrelationTable(data.x,data.labels);
%
% Acknowledgements:
%
% The source file rotateXLabels2.m is from the Matlab File Exchange. It can 
% be found at:
% http://www.mathworks.co.kr/matlabcentral/fileexchange/27812-rotate-x-axis-tick-labels
%
% The source file usercolormap.m, also from the Matlab File Exchange, is 
% included with kind permission of its author, Yo Fukushima. It can be 
% found at:
% http://www.mathworks.com/matlabcentral/fileexchange/7144-usercolormap
%
% Author: 
%
% Jaspar Cahill, jjcahill@gmail.com. 24 Jan 2011.
 

    properties
        % user data
        x = [];
        labels = {};
        
        % ui
        fig;
        topPanel;
        bottomPanel;        
        ax;        
        slider;
        sliderLength = 300;
        sliderMin = 0;
        sliderMax = 1;
        sliderStep = [0.05 0.1];
        sliderValue = 0;
        textbox;
        fadeCheck;
        fadeCheckStateInit = true;
        reverseCheck;
        reverseCheckStateInit = false;

        panelMargin = 7;
        uiControlHeight = 21;
        
        % column count
        ncols;
        
        % plot data
        corrData;  % correlation matrix
        colourMap;  % of the figure, containing uniform shade gradation
        gridColourFractions;  % grid colours as fractions into colour map
        gridColours;  % grid colours as RGB values
        hGridLabels;  % correlation value labels
        
        % decay/fade
        decaySteepness = 1;
        minSteep = 1;
        maxSteep = 5;
        
        % plot display preferences
        whiteTextThreshold = 0.5; % white text if clr fraction above this value
        baseColour = [0 0 1];
        gridLabelSize = 8;
    end
    
    methods
       
        function obj=ShadedCorrelationTable(x, labels)
            % Create an instance of the application with parameters as
            % described in the opening comments.
            
            obj.x =x;
            obj.labels = labels;
            obj.fig = figure('name', 'Shaded Correlation Table', 'resizefcn', @obj.resize);
            obj.topPanel=uipanel('parent', obj.fig, 'units', 'pixels', 'BorderType', 'none');
            obj.ax = axes('parent', obj.topPanel);
            obj.bottomPanel=uipanel('parent', obj.fig, 'units', 'pixels', 'BorderType', 'beveledout');
            obj.initControls();
            obj.ncols = size(obj.x,2);
            obj.corrData = abs(corr(obj.x, 'type', 'pearson'));
            obj.colourMap = usercolormap([1 1 1], obj.baseColour);                        
            obj.updateColourData();           
            obj.initPlot();
            obj.updatePlotColours();
        end
    end
    
    methods(Access='private')
        
        function updatePlotColours(obj)
            % Apply colour data to the plot.
            
            % update grid colours
            colorSeq = zeros(obj.ncols * obj.ncols, 3);
            i=1;
            for r=1:obj.ncols
                for c = 1:obj.ncols
                    colorSeq(i,:)=obj.gridColours(r, c, :);
                    i = i + 1;
                end
            end
            colormap(obj.ax,colorSeq);
            
            % update grid label colours
            for r = 1:obj.ncols
                for c=1:obj.ncols
                    if (c < r)
                        htext = obj.hGridLabels(r, c);       
                        rev = get(obj.reverseCheck, 'value');
                        if (~rev && (obj.gridColourFractions(r,c) > obj.whiteTextThreshold)) ||...
                            (rev && obj.gridColourFractions(r,c) < obj.whiteTextThreshold)
                            set(htext, 'color', [1 1 1]);
                        else
                            set(htext, 'color', [0 0 0]);
                        end
                    end
                end
            end
        end
        
        function initPlot(obj)
            % Sets up flat surface on which to display grid.
            
            % grid         
            [x,y]=meshgrid(1:obj.ncols+1, 1:obj.ncols+1);
            z = ones(obj.ncols+1,obj.ncols+1);
            
            i = 1; 
            colourMatrix = ones(obj.ncols,obj.ncols); 
            for r=1:obj.ncols
                for c=1:obj.ncols
                    colourMatrix(r,c)=i;
                    i=i+1;
                end
            end
 
            for r=1:obj.ncols+1     % white out half the grid
                for c=1:obj.ncols+1                    
                    if c < r        
                        x(r,c)=NaN;
                        y(r,c)=NaN;
                        colourMatrix(r,c)=NaN;  
                    end
                end
            end            
            
            hold(obj.ax, 'on');
            surf(obj.ax,x,y,z,colourMatrix);
            hold(obj.ax, 'off');
            view([180 270]);
            axis(obj.ax, 'tight');

            % grid labels            
            obj.hGridLabels = zeros(obj.ncols, obj.ncols);
            for r=1:obj.ncols
                for c=1:obj.ncols
                    if (c < r)
                        v=obj.corrData(r,c);                  
                        s = num2str(v, '%.2f');                         
                        if strcmp(s, '1.00')
                            s='1';
                        else
                            dotIndex = strfind(s, '.');
                            if ~isempty(dotIndex)
                                s = s(dotIndex:end);
                            end
                        end
                        htext = text(r+0.5,c+0.5,1, s,...
                        'VerticalAlignment', 'middle',...
                        'HorizontalAlignment', 'center');
                        set(htext, 'FontSize', obj.gridLabelSize );
                        obj.hGridLabels(r,c) = htext;
                    end
                end
            end
            
            % axis labels
            ticks = 0.5:1:obj.ncols+0.5;
            set(obj.ax, 'XTick', ticks);
            set(obj.ax, 'YTick', ticks);
            %set(obj.ax, 'XTickLabel', [{''} obj.labels ] );
            set(obj.ax, 'XTickLabel', fliplr([ obj.labels {''}]) );  % flip necessary because of rotateXLabels2
            set(obj.ax, 'YTickLabel', [{''} obj.labels] );
            rotateXLabels2(obj.ax,45);
        end

        function updateColourData(obj)
            % Computes grid colour data based on current control settings.
            % Assigns gridColours and gridColourFractions.
            
            obj.gridColours = ones(obj.ncols,obj.ncols,3);
            for r=1:obj.ncols
                for c=1:obj.ncols
                    v = obj.corrData(r,c);
                    if get(obj.fadeCheck, 'value') % faded colouring
                        vdecay = v * ((1/obj.decaySteepness)^(( 1- v)*5));
                        obj.gridColourFractions(r,c) = vdecay;
                        if isnan(vdecay)
                            obj.gridColours(r,c,:) = [1 1 1];                        
                        else
                            obj.gridColours(r,c,:) = obj.colourMap(round(vdecay*255)+1,:);
                        end
                    else  % discrete colouring
                        rev = get(obj.reverseCheck, 'value');
                        if (~rev && v > obj.sliderValue) || (rev && v <= obj.sliderValue)
                            obj.gridColourFractions(r,c) = v;                            
                        else
                            obj.gridColourFractions(r,c) = 0 + rev;
                        end
                        obj.gridColours(r,c,:) = obj.colourMap(round(obj.gridColourFractions(r,c)*255)+1,:);
                    end
                end
            end
         end
        
        function initControls(obj)
            % Create interface controls in bottom panel.
            
            % slider
            pos = [obj.panelMargin obj.panelMargin obj.sliderLength obj.uiControlHeight];
            obj.slider =  uicontrol('Style','slider', 'Parent',obj.bottomPanel,...        
               'min', obj.sliderMin, 'max', obj.sliderMax,...
               'sliderStep', obj.sliderStep, 'value', obj.sliderValue,...
               'Callback', @obj.sliderCallback, 'position', pos);

            % slider value text
            gap = 3;
            kludgeToLowerText=3;
            pos = [obj.panelMargin+obj.sliderLength+gap obj.panelMargin-kludgeToLowerText 30 obj.uiControlHeight];
            obj.textbox = uicontrol('style', 'text', 'Parent', obj.bottomPanel,...
            'HorizontalAlignment', 'left',... 
            'string', num2str(obj.sliderValue), 'position', pos);

            % fade checkbox
            gap =7;
            pos = [pos(1)+pos(3)+gap obj.panelMargin 50 obj.uiControlHeight];
            obj.fadeCheck = uicontrol('style', 'checkbox', 'Parent', obj.bottomPanel,...
            'HorizontalAlignment', 'left','callback', @obj.fadeCheckboxCallback,... 
            'string', 'Fade', 'position', pos, 'value', obj.fadeCheckStateInit);

            % reverse checkbox
            gap =7;
            pos = [pos(1)+pos(3)+gap obj.panelMargin 70 obj.uiControlHeight];
            obj.reverseCheck = uicontrol('style', 'checkbox', 'Parent', obj.bottomPanel,...
            'HorizontalAlignment', 'left','callback', @obj.reverseCheckboxCallback,... 
            'string', 'Reverse', 'position', pos, 'value', obj.reverseCheckStateInit);
        end
        
        function resize(obj, eventdata, handles)
            % Callback on figure resize.
            bottomPanelHeight =  obj.panelMargin*2 + obj.uiControlHeight;
            fpos = get(obj.fig, 'position');            
            set(obj.topPanel, 'position', [0 bottomPanelHeight fpos(3) fpos(4)-bottomPanelHeight]);
            set(obj.bottomPanel, 'position', [0 0 fpos(3) bottomPanelHeight]);
        end
        
        function sliderCallback(obj, eventdata, handles)
            % Slider moved.
            v =get(eventdata, 'value');
            obj.sliderValue = v;
            set(obj.textbox, 'string', sprintf('%.2f', v));
            obj.decaySteepness = obj.minSteep + (obj.maxSteep - obj.minSteep) * v;            
            obj.updateColourData();
            obj.updatePlotColours();
        end        
        
        function fadeCheckboxCallback(obj, eventdata, handles)
            % Fade checkbox selected.                
            obj.updateColourData();
            obj.updatePlotColours();
        end
        
        function reverseCheckboxCallback(obj, eventdata, handles)
            % Reverse checkbox selected.
            obj.colourMap = obj.colourMap(end:-1:1,:);
            obj.updateColourData();
            obj.updatePlotColours();
        end

    end            
end
