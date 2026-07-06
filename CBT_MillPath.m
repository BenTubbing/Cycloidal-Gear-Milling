classdef CBT_MillPath < handle
    properties
        layers    % cell array of CBT_Layer
        zeroPoint % CBT_Trace with type zeroPoint
    end
    
    methods (Static)
        function obj = create(layer)
            obj = CBT_MillPath();
            obj.layers = {};
            if nargin > 0
                obj.layers{1} = layer;
            end
        end
    end
    
    methods
        function addLayerAfter(obj, layer)
            if ~isa(layer, 'CBT_Layer')
                error("CBT_MillPath.addLayerAfter: input layer must be a CBT_Layer object");
            end

            if isempty(obj.layers)
                obj.layers{1} = layer;
            else
                obj.layers{end+1} = layer;
            end
        end

        function addLayerBefore(obj, layer)
            if ~isa(layer, 'CBT_Layer')
                error("CBT_MillPath.addLayerBefore: input layer must be a CBT_Layer object");
            end

            if isempty(obj.layers)
                obj.layers{1} = layer;
            else
                obj.layers = [{layer}, obj.layers];
            end
        end

        function swapDirection(obj)
            for i = 1:numel(obj.layers)
                obj.layers{i}.swapDirection();
            end
            obj.layers = fliplr(obj.layers);
        end

        function setZeroPoint(obj, zx1, zx2, zx3, zphi, ztheta)
            obj.zeroPoint = CBT_Trace.create(zx1, zx2, zx3, zphi, ztheta, CBT_TraceTypes.zeroPoint);
        end

        function plotMillPath(obj)
            for il = 1:numel(obj.layers)
                obj.layers{il}.plotLayer();
            end

            for i = 1:(numel(obj.layers) - 1)
                col = obj.layers{i}.traces{end}.getColor();
                quiver3( ...
                    obj.layers{i}.traces{end}.x1(end), ...
                    obj.layers{i}.traces{end}.x2(end), ...
                    obj.layers{i}.traces{end}.x3(end), ...
                    obj.layers{i+1}.traces{1}.x1(1) - obj.layers{i}.traces{end}.x1(end), ...
                    obj.layers{i+1}.traces{1}.x2(1) - obj.layers{i}.traces{end}.x2(end), ...
                    obj.layers{i+1}.traces{1}.x3(1) - obj.layers{i}.traces{end}.x3(end), ...
                    0, col, "lineWidth", 2);
            end
        end

        function plotToolOrientation(obj, length)
            if nargin == 1
                length = 10;
            end
            for il = 1:numel(obj.layers)
                obj.layers{il}.plotToolOrientation(length);
            end
        end
    end

    methods (Access = protected)
        function obj = CBT_MillPath()
            obj.layers = {};
        end
    end
end
