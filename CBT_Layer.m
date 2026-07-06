classdef CBT_Layer < handle
    properties
        traces    % cell array of CBT_Trace
    end
    
    methods (Static)
        function obj = create(trace)
            obj = CBT_Layer();
            obj.traces = {};
            if nargin > 0
                obj.traces{1} = trace;
            end
        end
    end
    
    methods
        function addTraceAfter(obj, trace)
            if ~isa(trace, 'CBT_Trace')
                error("CBT_Layer.addTraceAfter: input trace must be a CBT_Trace object");
            end

            if isempty(obj.traces)
                obj.traces{1} = trace;
            else
                obj.traces{end+1} = trace;
            end
        end

        function addTraceBefore(obj, trace)
            if ~isa(trace, 'CBT_Trace')
                error("CBT_Layer.addTraceBefore: input trace must be a CBT_Trace object");
            end

            if isempty(obj.traces)
                obj.traces{1} = trace;
            else
                obj.traces = [{trace}, obj.traces];
            end
        end

        function swapDirection(obj)
            for i = 1:numel(obj.traces)
                obj.traces{i}.swapDirection();
            end
            obj.traces = fliplr(obj.traces);
        end

        function alternateTraces(obj)
            direction = false;
            for i = 1:numel(obj.traces)
                if direction
                    obj.traces{i}.swapDirection();
                end
                direction = ~direction;
            end
        end
        
        function plotLayer(obj)
            ntrace = numel(obj.traces);

            for i = 1:ntrace
                if i == 1
                    x1s = obj.traces{1}.x1(1);
                    x2s = obj.traces{1}.x2(1);
                    x3s = obj.traces{1}.x3(1);
                else
                    x1s = obj.traces{i-1}.x1(end);
                    x2s = obj.traces{i-1}.x2(end);
                    x3s = obj.traces{i-1}.x3(end);
                end
                obj.traces{i}.plotTrace(x1s, x2s, x3s);
            end
        end
        
        function plotToolOrientation(obj, length)
            if nargin == 1
                length = 10;
            end
            for i = 1:numel(obj.traces)
                obj.traces{i}.plotToolOrientation(length);
            end
        end
    end
    
    methods (Access = protected)
        function obj = CBT_Layer()
            obj.traces = {};
        end
    end
end
