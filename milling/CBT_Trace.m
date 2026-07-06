classdef CBT_Trace < handle
    properties
        x1
        x2
        x3
        phi
        theta
        type   % CBT_TraceTypes array, one per point
    end
   
    methods (Static)
        function obj = create(x1, x2, x3, phi, theta, type)
            if isempty(find(type == enumeration('CBT_TraceTypes'), 1))
                error('CBT_Trace.create: type must be member of CBT_TraceTypes');
            end

            if size(type, 1) ~= 1 && size(type, 1) ~= size(x1, 1)
                error('CBT_Trace.create: type must be scalar or match number of points');
            end

            if size(type, 1) == 1 && size(x1, 1) > 1
                tPP = repmat(type, size(x1, 1), 1);
                type = tPP;
            end

            CBT_Trace.verify(x1, x2, x3, phi, theta, type);

            obj = CBT_Trace();
            obj.x1    = x1;
            obj.x2    = x2;
            obj.x3    = x3;
            obj.phi   = phi;
            obj.theta = theta;
            obj.type  = type;
        end

        function verify(x1, x2, x3, phi, theta, type)
            if (size(x1, 2) ~= 1 || size(x2, 2) ~= 1 || size(x3, 2) ~= 1 || ...
                size(phi, 2) ~= 1 || size(theta, 2) ~= 1 || size(type, 2) ~= 1)
                error("CBT_Trace.verify: input arrays must be column vectors");
            end

            n = size(x1, 1);
            if (size(x2, 1) ~= n || size(x3, 1) ~= n || ...
                size(phi, 1) ~= n || size(theta, 1) ~= n || size(type, 1) ~= n)
                error("CBT_Trace.verify: input arrays must have same length");
            end
        end
    end
   
    methods
        function addBefore(obj, x1, x2, x3, phi, theta, type)
            if size(type, 1) == 1 && size(x1, 1) > 1
                tPP = repmat(type, size(x1, 1), 1);
                type = tPP;
            end

            CBT_Trace.verify(x1, x2, x3, phi, theta, type);

            obj.x1    = [x1;    obj.x1];
            obj.x2    = [x2;    obj.x2];
            obj.x3    = [x3;    obj.x3];
            obj.phi   = [phi;   obj.phi];
            obj.theta = [theta; obj.theta];
            obj.type  = [type;  obj.type];
        end

        function addAfter(obj, x1, x2, x3, phi, theta, type)
            if size(type, 1) == 1 && size(x1, 1) > 1
                tPP = repmat(type, size(x1, 1), 1);
                type = tPP;
            end

            CBT_Trace.verify(x1, x2, x3, phi, theta, type);

            obj.x1    = [obj.x1;    x1];
            obj.x2    = [obj.x2;    x2];
            obj.x3    = [obj.x3;    x3];
            obj.phi   = [obj.phi;   phi];
            obj.theta = [obj.theta; theta];
            obj.type  = [obj.type;  type];
        end

        function swapDirection(obj)
            obj.x1    = flipud(obj.x1);
            obj.x2    = flipud(obj.x2);
            obj.x3    = flipud(obj.x3);
            obj.phi   = flipud(obj.phi);
            obj.theta = flipud(obj.theta);
            obj.type  = flipud(obj.type);
        end

        function plotTrace(obj, x1s, x2s, x3s)
            col = obj.getColor();

            vx1 = [x1s; obj.x1];
            vx2 = [x2s; obj.x2];
            vx3 = [x3s; obj.x3];

            plot3(vx1, vx2, vx3, col);
            hold on;
            plot3(obj.x1, obj.x2, obj.x3, "." + col);
            hold on;

            if obj.type(1) ~= CBT_TraceTypes.cut
                lv = size(vx1, 1);
                for k = 1:(lv - 1)
                    quiver3( ...
                        vx1(k), vx2(k), vx3(k), ...
                        vx1(k+1) - vx1(k), ...
                        vx2(k+1) - vx2(k), ...
                        vx3(k+1) - vx3(k), ...
                        0, col, "lineWidth", 1);
                end
            end
        end  

        function plotToolOrientation(obj, length)
            if nargin == 1
                length = 10;
            end

            tvx1 = length * sin(obj.theta) .* cos(obj.phi);
            tvx2 = length * sin(obj.theta) .* sin(obj.phi);
            tvx3 = length * cos(obj.theta);

            quiver3(obj.x1, obj.x2, obj.x3, tvx1, tvx2, tvx3, 0, "r");
        end

        function col = getColor(obj)
            switch obj.type(1)
                case CBT_TraceTypes.slowCut
                    col = "b";
                case CBT_TraceTypes.cut
                    col = "b";
                case CBT_TraceTypes.traceLeadIn
                    col = "m";
                case CBT_TraceTypes.traceLeadOut
                    col = "g";
                case CBT_TraceTypes.layerLeadIn
                    col = "m";
                case CBT_TraceTypes.layerLeadOut
                    col = "g";
                case CBT_TraceTypes.traverse
                    col = "r";
                case CBT_TraceTypes.zeroPoint
                    col = "k";
                otherwise
                    col = "k";
            end
        end
    end
   
    methods (Access = protected)
        function obj = CBT_Trace()
        end
    end
end
