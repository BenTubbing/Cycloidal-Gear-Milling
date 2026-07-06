classdef CBT_CycloidGear < handle
    %CBT_CycloidGear
    %   Encapsulates geometry and export utilities for cycloidal gears.
    %   All radii are stored both in normalised form (rho*) and in
    %   physical units (scaled by module).

    properties
        % Inputs
        module          % Gear module (mm)
        toothCount      % Number of teeth
        rhoA            % Normalised radius of addendum rolling circle
        rhoD            % Normalised radius of dedendum rolling circle
        hA              % Normalised addendum height
        hD              % Normalised dedendum height

        % Derived / normalised
        rhoP            % Normalised pitch radius = toothCount / 2
        epiRoot         % Tangency angle where epi crosses addendum circle
        hypoRoot        % Tangency angle where hypo crosses dedendum circle
        xyFilletCentre  % Normalised centre of fillet arc
        rhoFillet       % Normalised fillet radius
        angleFillet     % Fillet end angle (seen from fillet centre)

        % Derived / physical
        radiusOuter     % Physical outer radius
        radiusFillet    % Physical fillet radius
        radiusInner     % Physical inner radius (bottom of fillet)
        radiusPitch     % Physical pitch radius
    end

    %======================================================================
    % STATIC UTILITIES
    %======================================================================
    methods (Static)
        function obj = create(module, toothCount, rhoA, rhoD, hA, hD)
            %CREATE  Base constructor.
            %
            %   module     : gear module (mm)
            %   toothCount : number of teeth
            %   rhoA       : addendum rolling circle radius (normalised)
            %   rhoD       : dedendum rolling circle radius (normalised)
            %   hA         : addendum height (normalised)
            %   hD         : dedendum height (normalised)

            obj = CBT_CycloidGear();

            % Store inputs
            obj.module     = module;
            obj.toothCount = toothCount;
            obj.rhoP       = toothCount / 2;
            obj.rhoA       = rhoA;
            obj.rhoD       = rhoD;
            obj.hA         = hA;
            obj.hD         = hD;

            % Solve epi / hypo intersection angles
            obj.epiRoot  = obj.getEpiRoot();
            obj.hypoRoot = obj.getHypoRoot();

            if obj.epiRoot == 0.0 || obj.hypoRoot == 0.0
                error('CBT_CycloidGear.create: problem with epi/hypo roots, please review inputs.');
            end

            % Fillet geometry
            [obj.xyFilletCentre, obj.rhoFillet, obj.angleFillet] = obj.getFilletInfo();

            % Physical radii
            obj.radiusOuter = obj.module * (obj.rhoP + obj.hA);
            obj.radiusFillet = obj.module * obj.rhoFillet;
            obj.radiusInner  = obj.module * (obj.xyFilletCentre(1) - obj.rhoFillet);
            obj.radiusPitch  = obj.module * obj.rhoP;
        end

        function obj = createFromPinion(pinion, toothCount, hA, hD)
            %CREATEFROMPINION  Construct a wheel from an existing pinion.
            %
            %   module and rolling radii are taken from the pinion.
            %   Note the swap of rolling circle radii.

            module = pinion.module;
            rhoA   = pinion.rhoD;   % swap
            rhoD   = pinion.rhoA;

            obj = CBT_CycloidGear.create(module, toothCount, rhoA, rhoD, hA, hD);
        end

        %----------------- Cycloid primitives -----------------------------
        function xy = epicycloid(R, r, theta)
            %EPICYCLOID  Epicycloid coordinates for given radii and angle.
            Rr = R + r;
            x  = Rr * cos(theta) - r * cos(Rr / r * theta);
            y  = Rr * sin(theta) - r * sin(Rr / r * theta);
            xy = [x; y];
        end

        function xy = hypocycloid(R, r, theta)
            %HYPOCYCLOID  Hypocycloid coordinates for given radii and angle.
            Rmr = R - r;
            x   = Rmr * cos(theta) + r * cos(Rmr / r * theta);
            y   = Rmr * sin(theta) - r * sin(Rmr / r * theta);
            xy  = [x; y];
        end

        %----------------- Adaptive sampling ------------------------------
        function pts = adaptiveSample(fun, a0, a1, tol)
            %ADAPTIVESAMPLE  Adaptive sampling of a parametric curve.
            %
            %   fun(alpha) returns 2×1 or 3×1 point
            %   a0, a1     : parameter interval
            %   tol        : geometric tolerance

            p0 = fun(a0);
            p1 = fun(a1);
            am = 0.5 * (a0 + a1);
            pm = fun(am);

            chordMid = 0.5 * (p0 + p1);
            dev      = norm(pm - chordMid);

            if dev < tol
                pts = [p0, p1];
            else
                left  = CBT_CycloidGear.adaptiveSample(fun, a0, am, tol);
                right = CBT_CycloidGear.adaptiveSample(fun, am, a1, tol);
                pts   = [left(:, 1:end-1), right];  % avoid duplicate midpoint
            end
        end

        %----------------- Simple geometry helpers ------------------------
        function xyr = rotate(xy, alpha)
            %ROTATE  Rotate 2D point(s) by angle alpha.
            R = [cos(alpha) -sin(alpha); sin(alpha) cos(alpha)];
            xyr = R * xy;
        end

        function xym = mirrorX(xy)
            %MIRRORX  Mirror in Y-axis (flip X).
            M   = [-1 0; 0 1];
            xym = M * xy;
        end

        function xym = mirrorY(xy)
            %MIRRORY  Mirror in X-axis (flip Y).
            M   = [1 0; 0 -1];
            xym = M * xy;
        end

        %----------------- CSV export (Fusion-friendly) -------------------
        function writeCSV(filename, XYZ)
            %WRITECSV  Write 3D points to CSV for Fusion (units in cm).
            %
            %   XYZ : 3×N array, in mm. Converted to cm.

            unit = 0.1; % mm → cm

            fid = fopen(filename, 'w');
            fprintf(fid, "x,y,z\n");
            for k = 1:size(XYZ, 2)
                fprintf(fid, "%.6f,%.6f,%.6f\n", ...
                    XYZ(1, k) * unit, XYZ(2, k) * unit, XYZ(3, k) * unit);
            end
            fclose(fid);
        end
    end

    %======================================================================
    % INSTANCE METHODS
    %======================================================================
    methods
        %----------------- Root finding for epi / hypo --------------------
        function root = getEpiRoot(obj)
            %GETEPIROOT  Tangency angle where epi intersects addendum circle.

            R  = obj.rhoP;
            r  = obj.rhoA;
            s  = R + r;
            rp = obj.rhoP + obj.hA;

            fun = @(x) s^2 + r^2 ...
                - 2 * s * r * (cos(x) * cos(s / r * x) + sin(x) * sin(s / r * x)) ...
                - rp^2;

            domain = pi * r / R;
            v0 = fun(0.0);
            ve = fun(domain);

            if v0 * ve > 0
                root = 0.0;
                return;
            end

            root = fzero(fun, [0, domain]);
        end

        function root = getHypoRoot(obj)
            %GETHYPOROOT  Tangency angle where hypo intersects dedendum circle.

            R  = obj.rhoP;
            r  = obj.rhoD;
            s  = R - r;
            rp = obj.rhoP - obj.hD;

            fun = @(x) s^2 + r^2 ...
                + 2 * s * r * (cos(x) * cos(s / r * x) - sin(x) * sin(s / r * x)) ...
                - rp^2;

            domain = -pi * r / R;
            v0 = fun(0.0);
            ve = fun(domain);

            if v0 * ve > 0
                root = 0.0;
                return;
            end

            root = fzero(fun, [0, domain]);
        end

        %----------------- Normalised curve segments ----------------------
        function xy = epiCurve(obj, parm)
            %EPICURVE  Normalised epicycloid segment, parm in [0,1].
            theta = parm * obj.epiRoot;
            xy    = CBT_CycloidGear.epicycloid(obj.rhoP, obj.rhoA, theta);
            xy    = CBT_CycloidGear.rotate(xy, pi / obj.toothCount / 2);
        end

        function xy = hypoCurve(obj, parm)
            %HYPOCURVE  Normalised hypocycloid segment, parm in [0,1].
            theta = (1 - parm) * obj.hypoRoot;
            xy    = CBT_CycloidGear.hypocycloid(obj.rhoP, obj.rhoD, theta);
            xy    = CBT_CycloidGear.rotate(xy, pi / obj.toothCount / 2);
        end

        function [xyC, rho, thetaEnd] = getFilletInfo(obj)
            %GETFILLETINFO  Fillet centre, radius and end angle.

            p1    = obj.hypoCurve(0.0);
            delta = 1.0e-9;
            p2    = obj.hypoCurve(delta);
            v     = p2 - p1;
            n     = [0 1; -1 0] * v;   % rotate tangent by +90°

            xyC = [p1(1) - p1(2) * n(1) / n(2); 0.0];
            rho = norm(xyC - p1);
            thetaEnd = atan2(p1(2) - xyC(2), p1(1) - xyC(1));
        end

        function xy = filletCurve(obj, parm)
            %FILLETCURVE  Normalised fillet arc, parm in [0,1].
            pa = pi + parm * (obj.angleFillet - pi);
            xy = obj.xyFilletCentre + obj.rhoFillet * [cos(pa); sin(pa)];
        end

        %----------------- Physical tooth curve ---------------------------
        function xy = toothCurve(obj, alpha)
            %TOOTHCURVE  Full tooth curve in physical units.
            %
            %   alpha:
            %     [0,1)  : fillet
            %     [1,2)  : hypo
            %     [2,3]  : epi
            %     >3     : linear extrapolation

            alpha = alpha(:)';     % row
            N     = numel(alpha);
            xy    = zeros(2, N);

            isFillet = (alpha < 1);
            isHypo   = (alpha >= 1 & alpha < 2);
            isEpi    = (alpha >= 2 & alpha <= 3);
            isExt    = (alpha > 3);

            % fillet
            if any(isFillet)
                t = alpha(isFillet);
                xy(:, isFillet) = obj.module * obj.filletCurve(t);
            end

            % hypo
            if any(isHypo)
                t = alpha(isHypo) - 1;
                xy(:, isHypo) = obj.module * obj.hypoCurve(t);
            end

            % epi
            if any(isEpi)
                t = alpha(isEpi) - 2;
                xy(:, isEpi) = obj.module * obj.epiCurve(t);
            end

            % extrapolation beyond alpha = 3
            if any(isExt)
                p3  = obj.module * obj.epiCurve(1.0);
                eps = 1e-6;
                p3a = obj.module * obj.epiCurve(1.0 - eps);
                t3  = p3 - p3a;
                t3  = t3 / norm(t3);

                da = alpha(isExt) - 3.0;
                xy(:, isExt) = p3 + t3 * da;
            end
        end

        function r = radiusAtAlpha(obj, alpha)
            %RADIUSATALPHA  Radius of tooth curve at given alpha.
            p = obj.toothCurve(alpha);
            r = sqrt(p(1, :).^2 + p(2, :).^2);
        end

        function alpha = alphaAtRadius(obj, R, a0, a1)
            %ALPHAATRADIUS  Solve alpha for given radius R in [a0,a1].
            f  = @(a) obj.radiusAtAlpha(a) - R;
            v0 = f(a0);
            v1 = f(a1);
            if v0 * v1 > 0
                error('alphaAtRadius: no sign change in bracket [%g, %g]', a0, a1);
            end
            alpha = fzero(f, [a0, a1]);
        end

        function t = toothTangent(obj, alpha)
            %TOOTHTANGENT  Numerical tangent of tooth curve.
            h     = 1e-6;
            pPlus = obj.toothCurve(alpha + h);
            pMinus = obj.toothCurve(alpha - h);
            t     = (pPlus - pMinus) / (2 * h);
        end

        function n = toothNormal(obj, alpha)
            %TOOTHNORMAL  Unit normal pointing outward.
            t = obj.toothTangent(alpha);
            n = zeros(size(t));
            n(1, :) = -t(2, :);
            n(2, :) =  t(1, :);

            len = sqrt(n(1, :).^2 + n(2, :).^2);
            n(1, :) = n(1, :) ./ len;
            n(2, :) = n(2, :) ./ len;
        end

        %----------------- Milling offsets -------------------------------
        function xy = offsetToothCurve(obj, alpha, d)
            %OFFSETTOOTHCURVE  Offset tooth curve inward by distance d.
            p  = obj.toothCurve(alpha);
            n  = obj.toothNormal(alpha);
            xy = p - d * n;
        end

        function x = offsetToothCurveX(obj, alpha, d)
            %OFFSETTOOTHCURVEX  X-coordinate of offset curve.
            xy = obj.offsetToothCurve(alpha, d);
            x  = xy(1, :);
        end

        function [xy, a] = offsetAlphaAtX(obj, x, d)
            %OFFSETALPHAATX  Solve alpha on offset curve for given X.
            f    = @(a) obj.offsetToothCurveX(a, d) - x;
            lim1 = 0.0;
            lim2 = 20.0;
            f1   = f(lim1);
            f2   = f(lim2);

            if f1 * f2 < 0
                a = fzero(f, [lim1, lim2]);
            else
                a = 0;
            end

            xy = obj.offsetToothCurve(a, d);
        end

        %----------------- Fusion / 3D printing exports ------------------
        function exportCSV(obj, filename)
            %EXPORTCSV  Export half-gap curve to CSV for Fusion.
            fun = @(a) obj.toothCurve(a);
            xy  = CBT_CycloidGear.adaptiveSample(fun, 0, 4.0, 1e-3);
            z   = zeros(1, size(xy, 2));
            xyz = [xy; z];
            CBT_CycloidGear.writeCSV(filename, xyz);
        end

        function [V, F] = meshHalfGap(obj, thickness, alphaMax, tol)
            %MESHHALFGAP  Create a mesh for half the tooth gap.
            %
            %   thickness : wheel thickness (mm)
            %   alphaMax  : max alpha for outer edge (>=3)
            %   tol       : sampling tolerance

            if nargin < 3, alphaMax = 4.0; end
            if nargin < 4, tol = 1e-3; end

            % 1. Half-curve and symmetry line
            fun     = @(a) obj.toothCurve(a);
            xyCurve = CBT_CycloidGear.adaptiveSample(fun, 0, alphaMax, tol);
            xySym   = [xyCurve(1, :); zeros(1, size(xyCurve, 2))];

            N = size(xyCurve, 2);

            % 2. Fillet end index (alpha = 1.0)
            pFilletEnd = obj.toothCurve(1.0);
            [~, idxFillet] = min(vecnorm(xyCurve - pFilletEnd, 2, 1));
            triCount = idxFillet;

            % 3. 2D vertex list: [symmetry, curve]
            V2 = [xySym, xyCurve];

            idxSymStart   = 1;
            idxSymEnd     = N;
            idxCurveStart = N + 1;
            idxCurveEnd   = N + N;

            apexIdx = idxSymStart + triCount - 1;

            % 4. Lower plane vertices (z = -t/2)
            V = [V2; -thickness / 2 * ones(1, size(V2, 2))];

            % 5. Triangle fan
            F = [];
            for k = 1:(triCount - 1)
                a = apexIdx;
                b = idxCurveStart + k - 1;
                c = idxCurveStart + k;
                d = -1;
                F = [F, [a; b; c; d]];
            end

            % 6. Quad strip from fillet → tip
            for k = triCount:(N - 1)
                s1 = idxSymStart   + k - 1;
                s2 = idxSymStart   + k;
                c1 = idxCurveStart + k - 1;
                c2 = idxCurveStart + k;

                a = s1;
                b = s2;
                c = c2;
                d = c1;
                F = [F, [a; b; c; d]];
            end

            % 7. Duplicate for upper plane
            Vupper = V;
            Vupper(3, :) = -Vupper(3, :);

            Fupper = CBT_Meshing.reverseWinding(F);
            [V, F] = CBT_Meshing.meshCat(V, F, Vupper, Fupper);

            % 8. Periphery (side walls)
            FP    = [];
            total = size(V2, 2);

            Bsym   = (idxSymStart + triCount - 1):idxSymEnd;
            Bcurve = idxCurveEnd:-1:idxCurveStart;
            B      = [Bsym, Bcurve];

            K = numel(B);

            for i = 1:(K - 1)
                a = B(i);
                b = B(i + 1);
                c = b + total;
                d = a + total;
                FP = [FP, [a; b; c; d]];
            end

            a = B(K);
            b = B(1);
            c = b + total;
            d = a + total;
            FP = [FP, [a; b; c; d]];

            F = [F, FP];
        end

        function exportOBJ(obj, filename, thickness, alphaMax, tol)
            %EXPORTOBJ  Export half-gap mesh as OBJ.
            %
            %   thickness : wheel thickness (mm)
            %   alphaMax  : max alpha for outer edge
            %   tol       : sampling tolerance

            if nargin < 4, alphaMax = 4.0; end
            if nargin < 5, tol = 1e-3; end

            [V, F] = obj.meshHalfGap(thickness, alphaMax, tol);

            fid = fopen(filename, 'w');

            for i = 1:size(V, 2)
                fprintf(fid, 'v %.6f %.6f %.6f\n', V(1, i), V(2, i), V(3, i));
            end

            for i = 1:size(F, 2)
                f = F(:, i);
                if f(4) < 0
                    fprintf(fid, 'f %d %d %d\n', f(1), f(2), f(3));
                else
                    fprintf(fid, 'f %d %d %d\n', f(1), f(2), f(3));
                    fprintf(fid, 'f %d %d %d\n', f(1), f(3), f(4));
                end
            end

            fclose(fid);
        end

        %----------------- Full gap / full gear ---------------------------
        function angle = getEpiEndOuterAngle(obj)
            %GETEPIENDOUTERANGLE  Angle at outer extreme of epi.
            xy    = obj.toothCurve(3.0);
            angle = atan2(xy(2, 1), xy(1, 1));
        end

        function xyGap = getFullGap(obj, nptsOuter, tol)
            %GETFULLGAP  Full gap curve including outer arcs.
            %
            %   nptsOuter : number of points on outer arc
            %   tol       : sampling tolerance

            if nargin < 3, tol = 1e-2; end
            if nargin < 2, nptsOuter = 10; end

            fun = @(a) obj.toothCurve(a);
            xyC = CBT_CycloidGear.adaptiveSample(fun, 3.0, 0.0, tol);

            phi = linspace(pi / obj.toothCount, obj.getEpiEndOuterAngle(), nptsOuter);
            xyA = obj.radiusOuter * [cos(phi); sin(phi)];
            xyA(:, end) = [];   % drop duplicate

            xyC = [xyA, xyC];

            xyCM = CBT_CycloidGear.mirrorY(xyC);
            xyCM = flip(xyCM, 2);
            xyCM(:, 1) = [];    % drop duplicate

            xyGap = [xyC, xyCM];
            xyGap = flip(xyGap, 2);   % CCW around origin
        end

        function xyWheel = getFullGear(obj, isClosed, nptsOuter, tol)
            %GETFULLGEAR  Full wheel outline from gap curve.
            %
            %   isClosed   : if false, last point is removed
            %   nptsOuter  : points on outer arc
            %   tol        : sampling tolerance

            if nargin < 4, tol = 1e-2; end
            if nargin < 3, nptsOuter = 10; end
            if nargin < 2, isClosed = true; end

            xyGap   = obj.getFullGap(nptsOuter, tol);
            xyWheel = xyGap;

            for i = 1:(obj.toothCount - 1)
                xy = CBT_CycloidGear.rotate(xyGap, i * 2 * pi / obj.toothCount);
                xy(:, 1) = [];  % drop duplicate
                xyWheel = [xyWheel, xy];
            end

            if ~isClosed
                xyWheel(:, end) = [];
            end
        end
    end
end
