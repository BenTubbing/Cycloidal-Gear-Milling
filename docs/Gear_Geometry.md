
# Cycloidal Gear Geometry

The key characteristic of a gear is the pitch circle. It is a circle roughly going through the middle of the teeth. When two gears are properly mated, their pitch circles touch and do not slip.

A second key characteristic is the module. It determines the size of the gear through the equation:

```
Dp = m * N
where
- Dp is the pitch diameter
- m is the module
- N is the number of teeth
```

Hence a gear witha  module of 1 and 10 teeth has a diameter of 10mm. Increasing the module simply scales the size.

Because module is a simple scaler, it is customary to express other gear properties (rolling circles and tooth heights, see below) as fractions of the module. In that way, the module scales the entire wheel.

We focus here on cycloidal gears, a specific kind of gear historically, and presently, favoured in clocks and precision instruments for reasons of their lower wear in conditions of small loads.

The shape of the tooth outside of the pitch circle is described by an epi-cycloidal curve. This is a curve that is traced by rolling a circle on the outside of the pitch circle. Similarly, the shape inside the pitch circle is described by a hypo-cycloidal curve. The diameter of these rolling circles is a matter for the designer of the gear. A mainstream choice is half the pitch diameter for both the epi and hypo rolliung circles. *We note that it is perfectly possible to use different diameters for epi and hypo, but that the epi-diameter of a gear must equal the hypo diameter of the matching gear and vice-versa.* 

So the shape of the tooth is given by the rolling circles. Meanwhile, the height or depth of the tooth is given by an addendum circle and the depth by a dedendum circle. These circles lie outside / inside the pitch circle by a normalised distance (i.e. normalised on m) of hA and hD respectively. Again, the values of hA and hD are designer choices. It is logical that hD is larger than hA so the tip of a tooth doesn't crash into the dedendum of the mating gear. Common values are hA = 1.0, hD = 1.25.

At this point we need to consider the particularity of CNC milling of a gear. Clearly, in order to mill the dedendum, the cut will need to go deeper than the dedendum depth. And in order to avoid crashing the mill, it is good to design the gear with a fillet rounding off the dedendum gap. Ideally, that fillet should be somewhat larger than the size of the mill.

Now, having a fillet eliminates the above-mentioned risk of the tooth crashing into the mating dedendum. Therefore, an hD of 1.25 is not necessary. One may experiment, but a value of 1.05 is enough. The smaller hD has the result that the filler radius increases and so the gear can be milled with a larger mill (or a smaller gear can be made for a given mill).

**Creating a gear**

In summary, the parameters needed to create a gear shape are:
```
- The module
- The tooth count
- The diameter of the outer (epi) rolling circle   (typ. 2)
- The diameter of the inner (hypo) rolling circle  (typ. 2)
- The height of the addendum  (typ 1.0)
- The height of the dedendum  (typ 1.05)
```
Where we note that the latter four are m-normalised. We also note that the fillet is fully constrained by the dedendi.

With that, we can create a gear. In the software, the initial calculations are carried out in m-normalised dimensions (variables typically called rho...). Afterwards the m scaling is applied to get to physical (mm) dimensions, given as radius instead of diameter.
```
- radiusPitch
- radiusOuter, i.e. radiusPitch + 2 * module * hA
- radiusDedendum, i.e. radiusPitch - 2 * module * hD
- radiusInner, i.e. the radius of the inner fillet points, calculated after the fillet is constructed.
```

At which point, it is needed to consider the mathematics of the epi and hypo cycloidal curves.

**The epi and hypo curves**

The epi curve are created by rolling the rolling ball outside of the pitch circle. The equations are:
```
x = (Rp + Rr) cos(theta) - Rr cos((Rp + Rr)/Rr * theta)
y = (Rp + Rr) sin(theta) - Rr sin((Rp + Rr)/Rr * theta)
where:
- Rp is the pitch radius
- Rr is the rolling radius
- theta is the angle of rolling
```

Similarly for the hypo curve:
```
x = (Rp - Rr) cos(theta) + Rr cos((Rp - Rr)/Rr * theta)
y = (Rp - Rr) sin(theta) - Rr sin((Rp - Rr)/Rr * theta)
```

We now have the curves. It remains to find the precise start and end points, i.e: the point where the hypo curve intersects the dedendum circle and turns into the fillet; and the point where the epi curve intersects the outer circle.

To find these, we square the above equations and add them. This gives equations for the square of the radius versus theta. Setting these equal to the square of the addendum / dedendum radius respectively, and solving (numerically using MATLAB fzero) for theta, gives us these precise endpoints. 

Importantly, we have these curves (fillet, hypo, epi) as functions, not as simply arrays of points.

**Adaptive sampling**
It would be straightforward to create arrays of points for each curve by using MATLAB linspace. However, doing that would result in a very uneven density of points, with the result that, for a given accuracy, we need far too many points.

To avoid that, we parametrise the total curve in an arbitrary parameter alpha, defined and scaled such that:
```
- alpha runs from 0 to 1 over the fillet
- from 1 to 2 over the hypo curve
- from 2 to 3 over the epi curve
- above 3, as a a straight line extrapolation of the epi curve.
```
The latter is needed as we will need to move the mill centre outside of the gear.

With this parametrisation, we apply an adaptive sampling algorithm. Starting with a domain stretching from 0 to (say) 4, the algorithm takes a line from one end of the domain to the other. It checks how close the midpoint of the line is from the curve. If it is more than a given tolerance away, the algorithm halves the domain. And so on, recursively. The end result is a set of points spaced to obtain the necessary tolerance, but not more. Practical values for tolerance are in the range of 0.01 to 0.001, in mm. Tighter tolerances obviously lead to more points.

**Importing files into Fusion**
The resulting point sets can then be exported as a CSV file, or turned into an OBJ mesh, with a given thickness. These files can be imported in Fusion.

It appears that Fusion, which is spline-based, is not very fond of files with lots of points: it can become very slow. For that reason, the exports contain only one gap section. It seems best, after importing the CSV or the mesh into Fusion, to work as long as possible with a single sector: sketch any additions on the sector. Then extrude the sector. And only apply the circular pattern and combine the sectors at the end. Also, avoid unnecessarily small values for the tolerance of the curves.

