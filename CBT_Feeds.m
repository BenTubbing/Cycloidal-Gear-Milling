classdef CBT_Feeds
    properties
        % Default feeds for the various CBT_TraceTypes.
        slowCut      = 25;
        cut          = 100;
        traceLeadIn  = 50;
        traceLeadOut = 150;
        layerLeadIn  = 150;
        layerLeadOut = 150;
        traverse     = 500;
    end

    methods (Static)
        function obj = create()
            obj = CBT_Feeds();
        end
    end
    
    methods
        function feed = getFeed(obj, feedType)
            n = size(feedType, 1);
            feed = zeros(n, 1);

            for k = 1:n
                q = feedType(k);

                switch q
                    case CBT_TraceTypes.slowCut
                        ff = obj.slowCut;
                    case CBT_TraceTypes.cut
                        ff = obj.cut;
                    case CBT_TraceTypes.traceLeadIn
                        ff = obj.traceLeadIn;
                    case CBT_TraceTypes.traceLeadOut
                        ff = obj.traceLeadOut;
                    case CBT_TraceTypes.layerLeadIn
                        ff = obj.layerLeadIn;
                    case CBT_TraceTypes.layerLeadOut
                        ff = obj.layerLeadOut;
                    case CBT_TraceTypes.traverse
                        ff = obj.traverse;
                    otherwise
                        error("CBT_Feeds.getFeed: unknown feedType");
                end

                feed(k, 1) = ff;
            end
        end
    end
end
