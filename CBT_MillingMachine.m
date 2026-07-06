classdef CBT_MillingMachine < handle
    properties
        %MACHINE SETTINGS
        tool = NaN;
        toolIsSet = false;      %True if tool is set, false after machine reset
        swivelAngle = 0;        %Default value, swivel will be set by the zeroPoint theta of the millPath
        fh_mapping              %Handle to mapping function
        fh_inverseMapping       %Handle to inverse mapping function
        %UTILITY TO CHANGE MACHINE X DIRECTION OF OBJECT - rotate around Z = 0
        flipInFixture = false;  %Default, see the relevant function
        xTranslation = 0;       %Default, see the relevant function
        %THE MILL PATH OBJECT AND ITS G CODE
        millPath                %The CBT_MillPath object
        millPathIsSet = false;  %True if the millPath is set, then blocking certain functions from changing the settings
        millPathGCode           %The G Code string 
        feeds                   %A CBT_Feeds object managing feeds for the various btTraceTypes 
        feedsIsSet = false;     %True is feeds are set, false after machine reset
    end    
    
    methods (Static)
        %Create a machine with the A // X ApX; A//Z (ApZ); 3-axis with swivel
        function obj = createApX()
            obj = CBT_MillingMachine();
            obj.fh_mapping = @CBT_MillingMachine.map_ApX;
            obj.fh_inverseMapping = @CBT_MillingMachine.inverseMap_ApX;
            obj.feeds = CBT_Feeds.create();
        end
        function obj = create3Axis()
            obj = CBT_MillingMachine();
            obj.fh_mapping = @CBT_MillingMachine.map_3Axis;
            obj.fh_inverseMapping = @CBT_MillingMachine.inverseMap_3Axis;
            obj.feeds = CBT_Feeds.create();
        end
        function obj = createApZ()
            obj = CBT_MillingMachine();
            obj.fh_mapping = @CBT_MillingMachine.map_ApZ;
            obj.fh_inverseMapping = @CBT_MillingMachine.inverseMap_ApZ;
            obj.feeds = CBT_Feeds.create();
        end
        %Creation of a single 4 axis G Code line
        function gCodeString = writeXyza(x, y, z, a, f)
           if nargin > 5, error('CBT_MillingMachine.writeXyza is called with too many input arguments'); end
           if nargin < 4, error('CBT_MillingMachine.writeXyza is called with too few input arguments'); end
           if nargin == 4
               %If no feed input is passed              
               for i = 1 : size(x, 1)
                    str = str + newline + sprintf("G1 X%+08.3f  Y%+08.3f  Z%+08.3f  A%+08.3f", x(i), y(i), z(i), a(i));
               end
           else
               %If a feed is passed, it is written in the first line of the
               %trace
               %str = sprintf("G1 X%+08.3f  Y%+08.3f  Z%+08.3f  A%+08.3f F%08.3f", x(1), y(1), z(1), a(1), f);
               str = "";
               for i = 1 : size(x, 1)
                    str = str + sprintf("G1 X%+08.3f  Y%+08.3f  Z%+08.3f  A%+08.3f F%08.3f", x(i), y(i), z(i), a(i), f(i)) + newline;
               end
           end           
           gCodeString = str + newline;                     
        end 
        %STATIC MAPPING FUNCTIONS (from which the required one will be selected in the object creator)
        %MAPPINGS FOR A MACHINE WITH A PARALLEL X, OBJECT Z aligned with A
        function [x, y, z, a, b] = map_ApX(u, v, w, phi, theta, toolLength, flipInFixture, xTranslation)
            rotaryZ = u .* cos(phi) + v .* sin(phi);
            rotaryY = v .* cos(phi) - u .* sin(phi);
            rotaryX = w;
            x = rotaryX + toolLength * cos(theta);            
            %The sign of Y changes because the swap X <> Z, for
            %right-handed systems, implies a change of direction of Y
            y = - rotaryY;               
            z = rotaryZ + toolLength * sin(theta);
            %Before 20230302
            a = - phi * 180.0 / pi;
            b = (pi / 2 - theta) * 180.0 / pi;
            if flipInFixture
                x = -x + xTranslation;
                y = -y;
                a = -a;
                b = -b;
            end
        end
        function [u, v, w, phi, theta] = inverseMap_ApX(x, y, z, a, b, toolLength, flipInFixture, xTranslation)
            if flipInFixture
               x = - ( x - xTranslation);
               y = -y;
               a = -a;
               b = -b;
            end
            theta = pi / 2 - b * pi / 180;
            %Before 20230302
            %phi = a * pi / 180.0;
            %After 20230302
            phi = - a * pi / 180.0;            
            rotaryX = x - toolLength * cos(theta);
            
            %DEBUG, change the sign           
            rotaryY =  - y;
            
            rotaryZ = z - toolLength * sin(theta);
            u = rotaryZ .* cos(phi) - rotaryY .* sin(phi);
            v = rotaryY .* cos(phi) + rotaryZ .* sin(phi);
            w = rotaryX;                                            
        end                        
        %NEW MAPPINGS 2026 FOR A TRIVIAL 3 AXIS MACHINE 
        function [x, y, z, a, b] = map_3Axis(u, v, w, phi, theta, toolLength, flipInFixture, xTranslation)
            %Trivial mapping. Note use of G43 to be looked at
            b = theta * 180.0 / pi;
            a = zeros(size(u, 1));
            x = u + toolLength * sin(theta);
            y = v;
            z = w + toolLength * cos(theta); 
        end
        function [u, v, w, phi, theta] = inverseMap_3Axis(x, y, z, a, b, toolLength, flipInFixture, xTranslation)
            theta = b * pi / 180.0;
            phi = zeros(size(x, 1));
            u = x - toolLength *sin(theta);
            v = y - toolLength * cos(theta);
            w = z;                                        
        end                            
        %NEW MAPPINGS 2026 FOR A MACHINE WITH A PARALLEL Z, ROTARY ON XY TABLE
        function [x, y, z, a, b] = map_ApZ(u, v, w, phi, theta, toolLength, flipInFixture, xTranslation)
            rotaryX = u .* cos(phi) + v .* sin(phi);
            rotaryY = v .* cos(phi) - u .* sin(phi);
            rotaryZ = w;
            z = rotaryZ + toolLength * cos(theta);            
            %The sign of Y changes because the swap X <> Z, for
            %right-handed systems, implies a change of direction of Y
            %20230302: I changed the sign of A on the machine, in order to
            %for A and Y to be consistent.
            y = - rotaryY;               
            x = rotaryX + toolLength * sin(theta);
            %Before 20230302
            %a = phi * 180.0 / pi;
            %After 20230302, because of a correction on mill setup /
            %and consistency of coordinates 
            a = - phi * 180.0 / pi;
            b = (pi / 2 - theta) * 180.0 / pi;
            if flipInFixture
                z = -z + xTranslation;
                y = -y;
                a = -a;
                b = -b;
            end
        end
        function [u, v, w, phi, theta] = inverseMap_ApZ(x, y, z, a, b, toolLength, flipInFixture, xTranslation)
            if flipInFixture
               z = - ( z - xTranslation);
               y = -y;
               a = -a;
               b = -b;
            end
            theta = pi / 2 - b * pi / 180;
            %Before 20230302
            %phi = a * pi / 180.0;
            %After 20230302
            phi = - a * pi / 180.0;            
            rotaryZ = zx - toolLength * cos(theta);
            
            %DEBUG, change the sign           
            rotaryY =  - y;
            
            rotaryX = x - toolLength * sin(theta);
            u = rotaryX .* cos(phi) - rotaryY .* sin(phi);
            v = rotaryY .* cos(phi) + rotaryX .* sin(phi);
            w = rotaryZ;                                            
        end                        
    end  %of static methods        
    methods
        %OBJECT TO MACHINE COORDINATE MAPPINGS
        %The mapping functions, calling the functions defined by the
        %function handle properties
        function [x, y, z, a, b] = map(obj, u, v, w, phi, theta)
            [x, y, z, a, b] = obj.fh_mapping(u, v, w, phi, theta, obj.tool.length, obj.flipInFixture, obj.xTranslation);
        end
        function [u, v, w, phi, theta] = inverseMap(obj, x, y, z, a, b)
            [u, v, w, phi, theta] = obj.fh_inverseMapping(x, y, z, a, b, obj.tool.length, obj.flipInFixture, obj.xTranslation);                                            
        end
        %MACHINE SET UP
        %Setting the feeds for the various move types, with reference to btTraceTypes
        function setFeeds(obj, slowCut, cut, traceLeadIn, traceLeadOut, layerLeadIn, layerLeadOut, traverse)
            if(~obj.toolIsSet), error("CBT_Millingmachine: tool must be set before setting feeds"); end
            obj.feeds.slowCut = slowCut;
            obj.feeds.cut = cut;
            obj.feeds.traceLeadIn = traceLeadIn;
            obj.feeds.traceLeadOut = traceLeadOut;
            obj.feeds.layerLeadIn = layerLeadIn;
            obj.feeds.layerLeadOut = layerLeadOut;
            obj.feeds.traverse = traverse;
            obj.feedsIsSet = true;
        end
        %Setting the tool object of type CBT_Tool
        function setTool(obj, tool)
           %202606: allow to change tool without changing machine, but
           %resets the millPath because G code needs to be regenerated
           if obj.millPathIsSet
               obj.resetMillPath()
               uiwait(msgbox("CBT_MillingMachine.setTool: millpath reset, best set tool before setting millPath", 'modal'));              
           end
           if ~isa(tool, 'CBT_Tool')
                error('The tool should be an object of class CBT_Tool');                
            end
            obj.tool = tool; 
            obj.toolIsSet = true;
        end
        %Flip the X direction of the object in the fixtureand translates the object
        function setFlipInFixture(obj, flipInFixture, xTranslation)
           if obj.millPathIsSet
                error("CBT_MillingMachine.setFlipInFixture: this must be called prior to setting the millPath");               
           end
           %Effects a rotaion of 180° around the z-axis, and a subsequent
           %translation in X. Use if you want to machine the part with the
           %opposite end in the fixture.
           obj.flipInFixture = flipInFixture;
           obj.xTranslation = xTranslation;
        end
        %EXECUTION
        %Sets the mill path and trigger G Code generation
        function setMillPath(obj, millPath)
            if ~obj.toolIsSet, error("CBT_MillingMachine.setMillPath: tool must be set before setting the millPath"); end
            if ~obj.feedsIsSet,  error("CBT_MillingMachine.setMillPath: feeds must be set before setting the millPath"); end
            obj.millPath = millPath;
            obj.millPathIsSet = true;
            obj.validateMillPath();            
            zep = obj.millPath.zeroPoint;
            [~, ~, ~, ~, b] = obj.map(zep.x1, zep.x2, zep.x3, zep.phi, zep.theta);
            obj.swivelAngle = b;
            obj.writeMillPathGCode();
        end
        %Resets the mill path, e.g. is invoked by with a tool change
        function resetMachine(obj)
            delete(obj.millPath);
            obj.millPathIsSet = false;
            obj.toolIsSet = false;
            obj.feedsIsSet = false;
        end
        %Wraps up the G Code as an EDING CNC subroutine
        function string = getMillPathGCodeAsSub(obj, subName)
            string = "SUB " + subName + newline + obj.getCommentsBlock() + newline + obj.millPathGCode + newline + "ENDSUB";
        end
        %Creates a comment block, included in an EDING CNC subroutine
        function string = getCommentsBlock(obj)
            string = ";TOOL" + newline;
            string = string + ";   Index:      " + obj.tool.index + newline;            
            string = string + ";   Diameter:   " + obj.tool.diameter + newline;
            string = string + ";   Length:     " + obj.tool.length + newline;
            string = string + ";SwivelAngle:   " + obj.swivelAngle + newline;
            string = string + ";LayerCount:    " + size(obj.millPath.layers, 2) + newline;
            string = string + ";Cutting feed:  " + obj.feeds.cut + newline;           
        end
    end
    %PROTECTED METHODS    
    methods (Access = protected)
        %Constructor
        function obj = CBT_MillingMachine()            
        end
        %Validation of the millPath        
        function validateMillPath(obj)
            if ~isa(obj.millPath, "CBT_MillPath")
                error("CBT_MillingMachine.validateMillPath: millPath is not a valid CBT_MillPath object");
            end
            if ~isa(obj.millPath.zeroPoint, "CBT_Trace")
                error("CBT_MillingMachine.validateMillPath: millPath.zeroPoint is not a valid CBT_Trace object");
            end
            if size(obj.millPath.zeroPoint.x1, 1) ~= 1
                error("CBT_MillingMachine.validateMillPath: millPath.zeroPoint should contain exactly one point, but doesn't");                  
            end
            if ~iscell(obj.millPath.layers)
                error("CBT_MillingMachine.validateMillPath: millPath.layers is not a valid cell array");
            end
            if size(obj.millPath.layers, 2) < 1
                error("CBT_MillingMachine.validateMillPath: millPath.layers is an empty cell array");                
            end
            if ~isa(obj.tool, "CBT_Tool")
                error("CBT_MillingMachine.validateMillPath: no tool is set or tool is not a CBT_Tool object");                  
            end
            %Verify that no negative B values are generated with this map:
            %not possibe on EMCO F1CNC.
            zep = obj.millPath.zeroPoint;
            [x0, y0, z0, a0, b0] = obj.map(zep.x1, zep.x2, zep.x3, zep.phi, zep.theta);
            if b0 < 0
                %The EMCO F1CNC doesn't allow -ve swivel
                error("CBT_MillingMachine.validateMillPath: the MillPath would result in -ve values for the swivel");                 
            end
            %Verify that B values are the same over the entire millPath.
            layerCount = size(obj.millPath.layers, 2);
            for nn = 1 : layerCount
                layer = obj.millPath.layers{nn};
                for tt = 1 : size(layer.traces, 2)
                    [~, ~, ~, ~, b] = obj.map(layer.traces{tt}.x1, layer.traces{tt}.x2, layer.traces{tt}.x3, layer.traces{tt}.phi, layer.traces{tt}.theta);
                    bmin = min(b);
                    bmax = max(b);
                    if bmin ~= b0
                        error("CBT_MillingMachine.validateMillPath: the MillPath contains conflicting values for the swivel angle");                         
                    end
                    if bmax ~= b0
                        error("CBT_MillingMachine.validateMillPath: the MillPath contains conflicting values for the swivel angle");                         
                    end                    
                end                               
            end
        end
        %Write the G Code        
        function writeMillPathGCode(obj)            
            layerCount = size(obj.millPath.layers, 2);
            gcString = ";MILLPATH" + newline;
            zep = obj.millPath.zeroPoint;
            for nn = 1 : layerCount
                layer = obj.millPath.layers{nn};
                gcString = gcString + ";LAYER:  " + nn + newline;
                for tt = 1 : size(layer.traces, 2)
                    gcString = gcString + ";Layer:  " + nn + "  Trace:  " + tt + "  Type:  " + char(layer.traces{tt}.type) + newline;
                    [x, y, z, a, ~] = obj.map(layer.traces{tt}.x1, layer.traces{tt}.x2, layer.traces{tt}.x3, layer.traces{tt}.phi, layer.traces{tt}.theta);
%Subtract the xyza of an object reference point
                    [x0, y0, z0, a0, ~] = obj.map(zep.x1, zep.x2, zep.x3, zep.phi, zep.theta);
%                    f = obj.feeds.getFeed(layer.traces{tt}.typePerPoint);
                    f = obj.feeds.getFeed(layer.traces{tt}.type);
                    
                    gcString = gcString + CBT_MillingMachine.writeXyza(x - x0, y - y0, z - z0, a - a0, f);
                end                               
            end
            gcString = gcString + ";END LAYERS" + newline;                
            obj.millPathGCode = gcString;            
        end        
    end    
end