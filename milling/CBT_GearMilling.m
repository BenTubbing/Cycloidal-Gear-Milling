classdef CBT_GearMilling < handle
    properties
        cycloidGear
        safeR
        safeZ
        rStock
        ptFStart
        alphaFStart
        ptsFCut
        ptRStart
        alphaRStart
        ptsRCutCells
    end

    methods (Static)
        function obj = create(cycloidGear, safeR, safeZ)
            obj = CBT_GearMilling();
            obj.cycloidGear = cycloidGear;
            obj.rStock      = obj.cycloidGear.radiusOuter;
            obj.safeR       = safeR;
            obj.safeZ       = safeZ;
            obj.ptsRCutCells = {};
        end
    end

    methods
        function createFinishingMillCurve(obj, tol, millDiameter, stockToLeave, xClearance)
            millRadius = millDiameter / 2.0;

            if millRadius > obj.cycloidGear.radiusFillet
                error("CBT_GearMilling.createFinishingMillCurve: mill radius > fillet radius");
            end

            radiusStart = obj.rStock + millRadius + xClearance;
            [obj.ptFStart, obj.alphaFStart] = obj.cycloidGear.offsetAlphaAtX(radiusStart, millRadius + stockToLeave);

            funO = @(a) obj.cycloidGear.offsetToothCurve(a, millRadius + stockToLeave);
            ptsO = CBT_CycloidGear.adaptiveSample(funO, obj.alphaFStart, 0.0, tol);

            ptsOMirror = [1 0; 0 -1] * ptsO;
            ptsOMirror = flip(ptsOMirror, 2);
            ptsOMirror(:, 1) = [];

            obj.ptsFCut = [ptsO ptsOMirror];
            obj.plotF();
        end

        function millPath = createFinishingMillPath(obj, zCut, zRetract)
            x1 = obj.ptsFCut(1, :)';
            x2 = obj.ptsFCut(2, :)';
            ze = zeros(size(x1));
            x3 = zCut * ones(size(x1));

            traceCut     = CBT_Trace.create(x1, x2, x3, ze, ze, CBT_TraceTypes.cut);
            traceLeadIn  = CBT_Trace.create(x1(1), x2(1), zRetract, 0.0, 0.0, CBT_TraceTypes.traceLeadIn);
            traceLeadOut = CBT_Trace.create(x1(end), x2(end), zRetract, 0.0, 0.0, CBT_TraceTypes.traceLeadOut);

            layer = CBT_Layer.create(traceLeadIn);
            layer.addTraceAfter(traceCut);
            layer.addTraceAfter(traceLeadOut);

            millPath = CBT_MillPath.create(layer);
            millPath.setZeroPoint(0.0, 0.0, 0.0, 0.0, 0.0);
        end

        function cutMax = getMaxRoughingCutDepth(obj, millDiameter, stockToLeave)
            millRadius = millDiameter / 2.0;
            xmin = obj.cycloidGear.radiusInner + millRadius + stockToLeave;
            cutMax = obj.cycloidGear.radiusOuter + millRadius - xmin;
        end

        function createRoughingMillCurve(obj, tol, millDiameter, stockToLeave, xClearance, cutDepth)
            millRadius = millDiameter / 2.0;
            offset     = millRadius + stockToLeave;

            xStart = obj.rStock + millRadius + xClearance;
            [obj.ptRStart, obj.alphaRStart] = obj.cycloidGear.offsetAlphaAtX(xStart, offset);

            funO = @(a) obj.cycloidGear.offsetToothCurve(a, offset);
            xMin = obj.rStock - cutDepth + millRadius;

            obj.ptsRCutCells = {};
            alphaCurrent = obj.alphaRStart;

            for i = 1:numel(xMin)
                if xMin(i) < obj.cycloidGear.radiusInner + millRadius + stockToLeave
                    error("CBT_GearMilling.createRoughingMillCurve: cutDepth too large for mill + STL");
                end

                [ptA, alphaXMin] = obj.cycloidGear.offsetAlphaAtX(xMin(i), offset);
                if ptA(2, 1) < 0.0
                    error("CBT_GearMilling.createRoughingMillCurve: mill + STL too large for cutDepth = %g", cutDepth(i));
                end

                ptsA = CBT_CycloidGear.adaptiveSample(funO, alphaCurrent, alphaXMin, tol);

                ptsA(:, end + 1) = [ptsA(1, end); 0.0];
                ptsA(:, end + 1) = [ptsA(1, end); -ptA(2, 1)];

                [ptB, alphaXBack] = obj.cycloidGear.offsetAlphaAtX(xMin(i) + millDiameter / 4, offset);
                ptsB = CBT_CycloidGear.adaptiveSample(funO, alphaXMin, alphaXBack, tol);
                ptsB = [1 0; 0 -1] * ptsB;
                ptsB(:, 1) = [];

                alphaCurrent = alphaXBack;

                ptsB(:, end + 1) = [ptsB(1, end); 0.0];
                if i < numel(xMin)
                    ptsB(:, end + 1) = [ptsB(1, end); ptB(2, 1)];
                end

                ptsA = [ptsA ptsB];
                obj.ptsRCutCells{i} = ptsA;
            end

            obj.plotR();
        end

        function millPath = createRoughingMillPath(obj, zCut, zRetract)
            layer   = CBT_Layer.create();
            millPath = CBT_MillPath.create();
            millPath.setZeroPoint(0.0, 0.0, 0.0, 0.0, 0.0);

            pts = obj.ptsRCutCells{1};
            x1_1 = pts(1, 1);
            x2_1 = pts(2, 1);
            traceLeadIn = CBT_Trace.create(x1_1, x2_1, zRetract, 0.0, 0.0, CBT_TraceTypes.traverse);

            x1_e = pts(1, end);
            x2_e = pts(2, end);
            traceLeadOut = CBT_Trace.create(x1_e, x2_e, zRetract, 0.0, 0.0, CBT_TraceTypes.traceLeadOut);

            layer.addTraceAfter(traceLeadIn);

            for i = 1:numel(obj.ptsRCutCells)
                pts = obj.ptsRCutCells{i};
                x1 = pts(1, :)';
                x2 = pts(2, :)';
                ze = zeros(size(x1));
                x3 = zCut * ones(size(x1));

                traceTrav = CBT_Trace.create(x1(1), x2(1), x3(1), ze(1), ze(1), CBT_TraceTypes.traverse);
                traceCut  = CBT_Trace.create(x1, x2, x3, ze, ze, CBT_TraceTypes.cut);

                layer.addTraceAfter(traceTrav);
                layer.addTraceAfter(traceCut);
            end

            layer.addTraceAfter(traceLeadOut);
            millPath.addLayerAfter(layer);
        end

        function str = getGCodeForPattern(obj, subName)
            nl = newline;
            str = "";

            str = str + nl;
            str = str + ";G code for the circular pattern in gear milling" + nl + nl;
            str = str + ";Inner diameter of gear: " + 2 * obj.cycloidGear.radiusInner + nl;
            str = str + ";Outer diameter of gear: " + 2 * obj.cycloidGear.radiusOuter + nl + nl;

            str = str + ";Inputs" + nl;
            str = str + "#200 = " + obj.cycloidGear.toothCount + "        ;ToothCount" + nl;
            str = str + "#202 = " + obj.safeZ + "        ;ZSafe" + nl;
            str = str + "#203 = " + obj.safeR + "        ;RSafe" + nl;
            str = str + nl;

            str = str + ";Preliminaries" + nl;
            str = str + "G28" + nl;
            str = str + "M3                    ;Spindle" + nl;
            str = str + "M7                    ;Mist" + nl;
            str = str + "G43" + nl;
            str = str + "G69                   ;Clear G68 rotation" + nl;
            str = str + nl;

            str = str + "G0 X#203 Y0 F150       ;To a safe point to start" + nl;
            str = str + "G1 Z#202               ;To Z retract" + nl;
            str = str + nl;

            str = str + "#301 = 0              ;Loop counter, zero-based" + nl;
            str = str + "while [#301 < #200]" + nl;
            str = str + "  #302 = [#301 * 360 / #200]              ;The rotation angle" + nl;
            str = str + "  G68 R#302                               ;Set the angle" + nl;
            str = str + "  msg ""Execute at angle:  "" #302" + nl;
            str = str + "  GOSUB " + subName + "                   ;Execute" + nl;
            str = str + "  #301 = [#301 + 1]                       ;Update counter" + nl;
            str = str + "endwhile" + nl;
            str = str + nl;

            str = str + ";Wrap up" + nl;
            str = str + "G69                   ;Clear G68 rotation" + nl;
            str = str + "M9                    ;Coolant off" + nl;
            str = str + "G28" + nl;
            str = str + "M2                    ;Program end" + nl;
            str = str + nl + nl;
        end

        function plot1(obj)
            figure();
            hold on

            lim = obj.ptFStart(1) * 1.1;

            beta = linspace(-pi / 2, pi / 2, 100);
            plot(obj.rStock * cos(beta), obj.rStock * sin(beta), "--k");

            fun = @(a) obj.cycloidGear.toothCurve(a);
            tol = 1.0e-3;
            pts = CBT_CycloidGear.adaptiveSample(fun, 0.0, 3.0, tol);
            plot(pts(1, :), pts(2, :), ".g")

            title("GEAR MILLING")
            axis([0 lim -lim/2 lim/2])
            axis square
            hold off
        end

        function plotF(obj)
            obj.plot1();
            hold on;
            plot(obj.ptsFCut(1, :), obj.ptsFCut(2, :), ".r")
            plot(obj.ptFStart(1), obj.ptFStart(2), "*b");
            hold off
        end

        function plotR(obj)
            obj.plot1();
            hold on;
            for i = 1:numel(obj.ptsRCutCells)
                pts = obj.ptsRCutCells{i};
                plot(pts(1, :), pts(2, :), ".r")
            end
            plot(obj.ptRStart(1), obj.ptRStart(2), "*b");
            hold off
        end
    end
end
