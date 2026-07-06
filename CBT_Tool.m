classdef CBT_Tool < handle
    properties
        index
        type
        diameter
        length
        tipLength
        radius
    end
   
    methods (Static)
        function obj = create(index, type, diameter, tiplength)
            obj = CBT_Tool();

            if isempty(find(type == enumeration('CBT_ToolTypes'), 1))
                error('CBT_Tool.create: type must be member of CBT_ToolTypes');
            end

            obj.index     = index;
            obj.type      = type;
            obj.diameter  = diameter;
            obj.tipLength = tiplength;
            obj.radius    = diameter / 2.0;

            switch type
                case CBT_ToolTypes.endmill
                    obj.length = obj.tipLength;
                case CBT_ToolTypes.ballnose
                    obj.length = obj.tipLength - obj.radius;
                otherwise
                    error('CBT_Tool.create: unknown tool type');
            end
        end
    end
        
    methods (Access = protected)
        function obj = CBT_Tool()
        end        
    end
end
