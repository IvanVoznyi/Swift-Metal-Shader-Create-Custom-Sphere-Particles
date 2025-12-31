    const float UV_CENTER_OFFSET = 0.5;
    const float NDC_RANGE_MULTIPLIER = 2.0;
    const float2 DEFAULT_CENTERED = float2(0.0, 0.0);

-------------------------------------------------------
    float2 uv = position / size;

It converts pixel coordinates (like 800px, 400px) into normalized coordinates (between 0.0 and 1.0).
    - position: This is the current pixel the computer is drawing (e.g., Pixel #450).
    - size: This is the total resolution of the canvas (e.g., 1000px wide).
    - uv: The result is a ratio.
    
The Main Purpose: Resolution Independence

The main goal is to make your math work the same way regardless of how big the screen is.

If you want to draw a circle in the center of a screen:
    
    - Without UVs: On a phone, the center might be x = 180. 
      On a 4K monitor, the center might be x = 1920. You would have to write different code for every device.
    - With UVs: The center is always 0.5. You write the code once, and it looks perfect on every screen size.
-------------------------------------------------------
    float2 centered = (uv - UV_CENTER_OFFSET) * NDC_RANGE_MULTIPLIER;

In shader math, this line is used to "recenter" and "rescale" your coordinate system. 

This line of code is the "bridge" between the flat 2D screen and the 3D world you are trying to create. 
Its main purpose is to standardize the coordinate system so that the center of your screen becomes the mathematical "zero point."

1. What it does (The Transformation)
    
By default, the screen uses UV coordinates, which look like a graph starting from the bottom-left corner.
    
    - Center:      (0.5, 0.5)
    - Bottom-Left: (0, 0)
    - Top-Right:   (1, 1)

This code transforms that coordinate system into NDC (Normalized Device Coordinates):

    - Center:       (0, 0)
    - Left Edge:    (-1.0)
    - Right Edge:   (+1.0)
```    
UV space (0..1)                                     NDC space (-1..+1)

(0,1) ------------------ (1,1)          (-1, 1) ---------------- (1, 1)
  |                        |                |                       |
  |                        |                |                       |
  |      [0.5, 0.5]        |                |        [0, 0]         | 
  |                        |                |                       |
  |                        |                |                       |
(0,0) ------------------ (1,0)          (-1, -1) --------------- (1, -1)
```
2. Why all the numbers? (The Logic)

UV_CENTER_OFFSET (0.5)
    
    - The Problem: In a standard UV map, (0,0) is the corner. 
      If you try to draw a circle from the corner, you only see one-quarter of it.
      
The Fix: By subtracting $0.5$, you shift the entire coordinate system.
    
    - Old (0.5, 0.5) becomes New (0, 0).
    - Old (0, 0) becomes New (-0.5, -0.5).
    
Purpose: It puts the "anchor point" for your sphere exactly in the middle of the screen.

NDC_RANGE_MULTIPLIER (2.0)

The Problem: After subtracting 0.5, your screen goes from -0.5 to +0.5. 
This is only a total width of 1.0.

The Fix: Multiplying by 2.0 expands that range.
    
    - -0.5 x 2 = -1.0
    - +0.5 x 2 = 1.0
    
Purpose: It creates a "Unit Space." This is standard in 3D math because it makes calculations for spheres and rays much cleaner. If your radius is 1.0, it will now perfectly touch the edges of the screen.
-------------------------------------------------------
    const float aspect_ratio = size.x / size.y;
    centered.x *= aspect_ratio;

This line is the "Aspect Ratio Correction." Its purpose is to stop the sphere from looking like a squashed egg or a stretched oval when the screen isn't a perfect square.

1. What it does

It adjusts the horizontal scale (x) based on the relationship between the width (size.x) and the height (size.y).

    - If the screen is wide (Landscape): 
      It stretches the x coordinates so that "1 unit" of distance is the same width as "1 unit" of height.
    - If the screen is tall (Portrait): It shrinks the x coordinates to compensate.
    
2. The Problem: "The Rubber Band Effect"

Imagine your coordinate system is like a square rubber grid. 
If you take that square grid and stretch it to fit a wide TV screen, everything drawn on it (like a circle) gets pulled sideways.

Before Correction (on a 2:1 wide screen):

    - x goes from -1 to 1 over a long distance.
    - y goes from -1 to 1 over a short distance.
    - Result: A circle looks like a wide oval.
```
            Screen Width (2.0)
  <-------------------------------------->
(-1, 0)            (0,0)              (1, 0)  <-- Distorted!
   ______________________________________
  |                  |                   |
  |       (The circle looks flat)        |
  |__________________|___________________|
```  
With Correction (centered.x *= 2.0 / 1.0):
The x coordinates now go from -2 to 2. 
This makes the "space" between numbers the same as the vertical space.
```
(-2, 0)    (-1, 0)     (0,0)      (1, 0)     (2, 0)
   ___________|__________|__________|___________
  |           |          |          |           |
  |           |   (Perfect Circle)  |           |
  |___________|__________|__________|___________|
```
-------------------------------------------------------
UV_CENTER_OFFSET = 0.5: Used to shift coordinates from (0 to 1) to (-0.5 to 0.5). This centers the image so your sphere appears in the middle of the screen rather than the top-right corner.

NDC_RANGE_MULTIPLIER = 2.0: "Normalized Device Coordinates." This expands the range to -1.0 to 1.0, which is standard for raymasting/3D math.

CAMERA_OFFSET = -2.5: Moves the virtual camera backward.

    - Increase (e.g., -5.0): The sphere looks smaller and further away.
    - Decrease (e.g., -1.2): The sphere fills the screen or cuts off (too close).
    
FOCAL_LENGTH = 1.5: Acts like a zoom lens.

    - Higher: Narrow field of view (Telephoto zoom).
    - Lower: Wide-angle view (Distorts the sphere more).
    
FRESNEL_EXPONENT = 4.0: Controls how "sharp" the rim light is.

    - Increase: The glow stays very close to the very edge of the sphere.
    - Decrease: The glow spreads further toward the center.
    
FRESNEL_BIAS = 1.0: Shifts the baseline of the Fresnel effect.

FRONT_STAR_INTENSITY = 2.5 vs BACK_STAR_INTENSITY = 0.8: This creates depth. Stars on the side of the sphere facing you are much brighter than those on the far side, making it look like a transparent 3D volume rather than a flat circle.

AURA_INTENSITY = 1.0: The overall brightness of the exterior glow.

GLOW_STRENGTH = 0.04: How quickly the light "falls off" into the darkness.

    - Increase: A thick, foggy atmosphere around the sphere.
    - Decrease: A very thin, subtle halo.
    
GLOW_OFFSET = 0.5: Adjusts the starting point of the glow relative to the sphere's surface.

RADIUS = radius: The actual size of the sphere in 3D space.

ROTATION_SPEED: Linked to an external variable to determine how fast the starfield spins.

INTENSITY_DIMMER = 0.15: A master multiplier to prevent the colors from "blowing out" (becoming pure white and losing detail).
-------------------------------------------------------
    const float cameraPosition = -2.5;
    const float3 cameraPosition = float3(DEFAULT_CENTERED, cameraPosition);
    const float focalLength = 1.5;
    
Together, these values define how rays are cast from the camera into the scene.

cameraPosition tells you where the eye is.

focalLength tells you how strong the perspective projection is.

This is crucial for raymarching, procedural rendering, or any shader that simulates a 3D view. 
Without them, you’d only have flat 2D UVs.

1. What it does (The "Flashlight" Metaphor)

    - cameraPosition (ro): This is where you are standing. You are at (0, 0, -2.5).
    - DEFAULT_CENTERED: This is like pointing your head. 
      Even though you are standing in one spot, you look at different pixels.
    - focalLength: This is the distance from your eye to the "window" of the screen.
    
2. Why all the numbers and the main purpose?

The -2.5 in cameraPosition
    - Purpose: It moves the camera back so you can see the whole sphere.
    - Why: The sphere is at center (0,0,0). If you were at 0,0,0, you'd be inside it.
      If you were at -0.5, you'd be too close to see the edges. 
      -2.5 gives a "portrait" view of the sphere.
The 1.5 in focalLength
    - Purpose: It controls the Field of View (FOV).
    - Why: A smaller number (0.5) makes the sphere look huge and curved (wide-angle).
      A larger number (3.0) makes the sphere look small and flat (zoom).
      1.5 is the "natural" look.
```      
    [cameraPosition]
       (0,0,-2.5)
           |
           | <--- focalLength (1.5)
           |
    _______V_______  <--- The Screen (DEFAULT_CENTERED lives here)
   |       .       |
   |   rd  .  rd   |  <--- The Rays (rd) spread out from the eye 
   |     \ | /     |       through the DEFAULT_CENTERED points
   |______\|/______|
           |
        [Sphere]
         (0,0,0)
```
| VARIABLE | MAIN PURPOSE | REAL WORLD EXAMPLE |
| :--- | :--- | :--- |
| **cameraPosition** | Defines where the viewer is | Where you stand in a physical room |
| **focalLength** | Defines the "Zoom" level | The specific lens you put on a camera |
| **rd** (Ray Direction) | Defines the "Line of Sight" | The path from your eye through the window |
-------------------------------------------------------
    float3 rayDirection = normalize(float3(DEFAULT_CENTERED, focalLength));
    
This line of code is the "Point and Shoot" mechanism of your shader.
It determines exactly where each individual pixel on your screen is "looking" in the 3D world.

1. What it does

It takes a 2D position on your screen (DEFAULT_CENTERED) and gives it a "depth" (focalLength) to turn it into a 3D direction vector. 
The normalize function then ensures this vector has a length of exactly 1.0.
    
    - DEFAULT_CENTERED: This is the (x, y) coordinate. It tells the ray to point left, right, up, or down.
    - focalLength: This is the z coordinate. It pushes the ray forward into the screen.
    - normalize: It "cleans" the vector so the math for the sphere intersection doesn't break later.

Visualizing the "Standardized Step" (Normalize)

Imagine the camera is at (0,0,0). The vectors point to a flat screen. 
The vectors in the corners are longer thanthe vector in the center because they have further to travel to reach the flat plane.
```
       [ FLAT SCREEN ]
    (-1,1)  (0,1)  (1,1)
      \       |       /
       \      |      /
  Longer\     |     /
  Vector \    |    / Shorter Vector (Center)
          \   |   /
           \  |  /
            (0,0)  <-- Camera/Eye
```
The Normalized Vector (Unit Sphere)

When you call normalize(), you "pull" or "push" all those vectors so they land exactly on the surface of a circle (or sphere) with a radius of 1.
```
          [ UNIT CIRCLE ]
              (0,1)
          .  -  |  -  .
       /        |        \
      /         |         \
 (x,y)----------|----------(x,y)  <-- All lengths are now 1.0
      \         |         /
       \        |        /
          '  -  |  -  '
              (0,0) <-- Camera
```
Why this matters for Ray Tracing

If you don't normalize, your "steps" into the scene are uneven. 
If you move "1 unit" along the ray:

    - Unnormalized: The corner ray moves 1.4 units into the world, while the center ray moves 1.0 unit. 
      This causes a "fish-eye" distortion where the center of the image looks closer than the edges.
    - Normalized: Every ray moves exactly 1.0 unit into the world, ensuring the geometry looks flat and perspectively correct.

2. Why we need this code

Without this, the computer wouldn't know how to translate a flat pixel on your screen into a 3D path.

The "Perspective" Problem: In a real 3D view, rays of light don't travel in straight parallel lines (like a flat scanner).
They fan out from your eye.

    - Pixels at the edge of the screen need to look "sideways" at an angle.
    - Pixels in the center need to look straight ahead. 
      This line calculates that specific angle for every single pixel.
```      
      [ Eye / ro ]
            *
           /|\
          / | \  <-- Rays fan out (Ray Direction)
         /  |  \
   _____/___|___\_____  <-- The Screen (DEFAULT_CENTERED)
  |    /    |    \    |
  |   * * * | <-- Each pixel gets its own unique 'rd'
  | (Left) (Center) (Right)
  |___________________|
            |
            V
        [ SPHERE ]
```        
3. Examples of how it changes the look

The focalLength acts like a camera lens. 
If you change that number, the "angle" of the rays changes.

| FOCAL LENGTH | EFFECT | RESULT |
| :--- | :--- | :--- |
| **0.5** (Low) | **Wide Angle / Fisheye** | Rays fan out wide. Sphere looks huge and distorted. |
| **1.5** (Standard) | **Natural View** | Rays fan out like a human eye. Sphere looks natural. |
| **5.0** (High) | **Telephoto / Zoom** | Rays are almost parallel. Sphere looks flat/far away. |
-------------------------------------------------------
    float midpointDistance = dot(cameraPosition, rayDirection);

This is the mathematical "bridge" between where you are standing and where the sphere is floating.
In 3D math, specifically Raytracing, this line is how we calculate "how far along the path" the object sits.

1. What it does

It calculates the Scalar Projection. 
It takes your 3D position in space (cameraPosition) and projects it onto the line you are looking down (rayDirection).

Because your ray is "normalized" (length of 1), the Dot Product returns a simple number: the distance from your eye to the point on the ray that is directly "sideways" from the center of the sphere.

2. Why do we need it?

A shader needs to know if a pixel should be colored as "Sphere" or "Background."
To find out, we have to solve a triangle problem. Imagine the ray is a long stick. 
We need to find the point on that stick that is closest to the sphere's center.

 - If midpointDistance is 2.5: The center of the sphere is 2.5 units "deep" into your screen.
 - If midpointDistance is negative: The sphere is behind your head, so the shader shouldn't draw anything.
 
 3. Visualizing
 
 Think of the rayDirection as a laser beam and the cameraPosition as your starting point.
``` 
                      ( Sphere Surface )
                          .  -  -  .
                      .      / | \      .
                    .       /  |  \       .
                   :       /   |   \       :
  (Sphere Center) @--------------------------+  <-- Radius (0.65)
                   :     /     |     \     :
                    .   /      |      \   .
                      . \_ _ _ | _ _ _ / .
                               |
       [ HIT! ]                | (Distance to center)
          |                    |
          V                    V
---*------*--------------------X--------------------*------> [ Ray ]
 [Eye]  Entry                  |                   Exit
 (ro)                          |
                               |
                               |
          |<------- "b" ------>|
            (midpointDistance)
```      
What is 'X'? 'X' is the "Midpoint." It is the spot on the laser beam that is exactly "next to" the heart of the sphere.

| TERM | MAIN PURPOSE | REAL WORLD METAPHOR |
| :--- | :--- | :--- |
| **Origin (0,0,0)** | The Sphere's Heart | The center of a marble. |
| **Sphere Edge** | The "Wall" of the object | The glass surface of the marble. |
| **Closest Point** | The "Closest Pass" | The point on a path closest to a tree. |
| **midpointDistance** | The depth of the "Pass" | How far you walked to get next to the tree. |
-------------------------------------------------------
    float originOffset = dot(cameraPosition, cameraPosition) - (radius * radius);
    
This line calculates how far your Eye is from the Sphere before you even start looking.

    - dot(cameraPosition, cameraPosition): This is the squared distance from your eye to the center of the world @.
    - radius * radius: This is the size of the sphere.
    - The subtraction: By subtracting the radius, originOffset represents the distance from your eye to the "shell" of the sphere.
-------------------------------------------------------
    float insideSphereSquared = midpointDistance * midpointDistance - originOffset;

2. What it does

This is the "Moment of Truth" for your shader.
It compares the distance you traveled toward the center (midpointDistance) against the distance where the sphere actually begins (originOffset).
    
    - If insideSphereSquared > 0: The ray is passing through the sphere.
    - If insideSphereSquared < 0: The ray missed the sphere and is heading into empty space.
    - If insideSphereSquared == 0: The ray perfectly "grazes" the very edge of the sphere.
    
| NAME | MAIN PURPOSE | REAL WORLD METAPHOR |
| :--- | :--- | :--- |
| **insideSphereSquared (h)** | Determines IF there is a hit and HOW THICK the hit is. | Like a metal detector beeping when it finds something under the surface. |
| **b * b - c** | The Pythagorean subtraction. | Checking if your "jump" was long enough to reach the other side of a pit. |
-------------------------------------------------------
    if (insideSphereSquared > 0.0) {

This if statement is the binary switch of your shader.
It is the moment the GPU decides: "Is this pixel part of the sphere or part of the background?"

1. What it does

It checks the Discriminant (insideSphereSquared).
    - If the value is greater than 0, it means the math found a real intersection point.
    - If the value is less than 0, the math involves imaginary numbers (square roots of negatives), which in the real world means the ray missed the sphere entirely.
    
| RESULT OF CHECK | LOGICAL MEANING | GPU ACTION |
| :--- | :--- | :--- |
| **> 0.0** | **HIT!** The ray is inside the sphere's volume. | Run lighting, shading, and coloring code for this pixel. |
| **== 0.0** | **GRAZE!** The ray is perfectly touching the outer edge. | Draw the very edge (silhouette) of the sphere. |
| **< 0.0** | **MISS!** The ray passes by the sphere into the distance. | Skip all sphere math; show the background/sky instead. |

      ( MISS )  < 0.0
          |
          |       ( GRAZE ) == 0.0
          |          |
          |          |       (  HIT  ) > 0.0
          V          V          V
          |          |     . - @ - . 
          |          |   .     :     .
          |          |  :      :      :
          |          |   .     :     .
          |          |     ' - - - ' 
          |          |         |
          |          |         |
          +----------+---------+---------- [ Eye ]
          
3. Why we need it

Efficiency and Correctness. Lighting math (calculating shadows, reflections, and colors) is "expensive" for a computer.
This if statement ensures the computer only spends its energy on the pixels that actually matter.
It’s like a "security guard" at the door of the sphere.
```
PIXEL GRID                 insideSphereSquared            FINAL RESULT
                                     CHECK
    . . . . . . .              . . . - - . . .             . . . . . . .
    . . . . . . .              . . - + + - . .             . . [SHADE] .
    . . . . . . .      --->    . - + + + + - .     --->    . [SHADE][S].
    . . . . . . .              . . - + + - . .             . . [SHADE] .
    . . . . . . .              . . . - - . . .             . . . . . . .

                               (+) = Greater than 0
                               (-) = Less than 0
```
-------------------------------------------------------
        float distanceToFrontSurface = -midpointDistance - sqrt(insideSphereSquared);

1. What it represents

If your ray is an arrow, distanceToFrontSurface is the length of the arrow at the exact moment the tip touches the sphere.

    - midpointDistance: Gets you to the center of the "tunnel" through the sphere.
    - sqrt(insideSphereSquared): Is the "radius" of the sphere as measured along your line of sight.
    - The Subtraction: By taking the center depth and subtracting the internal radius, you arrive at the front surface.

-------------------------------------------------------
        float distanceToBackSurface = -midpointDistance + sqrt(insideSphereSquared);

This variable represents the exit point of your ray.
While the "Front Surface" is what you usually see, the distanceToBackSurface tells you how far the ray travels before it leaves the sphere and heads back into empty space.

1. Why the Plus Sign (+)?

    - To get to the Front, you start at the midpoint and step back toward yourself (-).
    - To get to the Back, you start at the midpoint and step further away (+).
    
The value sqrt(insideSphereSquared) acts as the "half-width" of the intersection.
By adding it to your midpoint distance, you reach the far edge of the sphere's volume.

2. When do you actually use the Back Surface?

In a simple opaque (solid) sphere, you usually ignore the back surface because you can't see through the front. However, you need distanceToBackSurface if:

    - Transparency: You are making a glass or water sphere.
    - Volumetrics: You are making a sphere made of "fog" or "smoke" and need to know how thick it is.
    - Camera Inside: If your camera moves inside the sphere, the "front" distance becomes negative, and the "back" surface becomes the only thing you can see!
-------------------------------------------------------
    float3 frontHitPoint = cameraPosition + rayDirection * distanceToFrontSurface;
    
This line is the final step of the ray–sphere intersection: it computes the actual 3D point where the ray hits the front surface of the sphere.
-------------------------------------------------------
    float3 positionBackSurface = cameraPosition + rayDirection * distanceToBackSurface;

This line is the second half of the ray–sphere intersection: it computes the exit point where the ray leaves the sphere after passing through it.
-------------------------------------------------------
        float3 rotatedFrontSurface = rotate(positionFrontSurface, time * ROTATION_SPEED);
        float3 rotatedBackSurface = rotate(positionBackSurface, time * ROTATION_SPEED);

This part of your code takes the two specific 3D points where your laser beam "pierced" the sphere (the front entrance and the back exit) and applies a rotation transformation to them based on a timer.
-------------------------------------------------------
        float fresnel = pow(1.0 + dot(rayDirection, normalize(positionFrontSurface)), 4.0);

This line of code calculates a Fresnel effect. 
In the real world, this is the phenomenon where a surface becomes more reflective or "brighter" when you look at it from a grazing angle (the edges), and more transparent or darker when looking at it head-on.

The Fresnel effect is what gives a 2D circle the "look" of a 3D bubble or a polished marble.

              ( SPHERE )
             .  -  -  -  .
         .      glow       .
       .      . - - - .      .
      :      :         :      :
      : glow :  [DARK] : glow :  <-- Fresnel is 1.0 at edges
      :      :         :      :      Fresnel is 0.0 at center
       .      . - - - .      .
         .       glow      .
           .  -  -  -  .

      [ VIEW DIRECTION ] ------>
      
| COMPREHENSIVE NAME | MAIN PURPOSE | REAL WORLD METAPHOR |
| :--- | :--- | :--- |
| **edgeGlow** (Fresnel) | Makes the edges of the sphere brighter than the middle. | Looking at a soap bubble or a glass marble; the edges look "thicker." |
| **pow(fresnel, 4.0)** | Controls the "Falloff" (Sharpness). | Focusing a flashlight beam into a tight circle vs. a wide glow. |
| **surfaceNormal** | The direction the "skin" faces. | An arrow pointing straight out from the surface at any point. |
-------------------------------------------------------
        half3 bodyTint = half3(0.02, 0.05, 0.15) * 0.15;

This line of code defines the Base Color of the sphere's material. 
It creates a very dark, deep blue color that serves as the "foundation" before you add highlights or glow.

-------------------------------------------------------
    half3 shellGlow = GLOW_COLOR_CYAN * half(fresnel);
-------------------------------------------------------
    float frontPatternMask = drawCircle(rotatedFrontSurface, density, dotSize, time, isMoveParticle);
    float backPatternMask = drawCircle(rotatedBackSurface, density, dotSize, time, isMoveParticle);
    
This code creates a procedural pattern (like a grid of dots or particles) that wraps around the sphere.
Because you are using rotatedFrontSurface and rotatedBackSurface, these dots will spin along with the sphere.

-------------------------------------------------------
    float hash3D(float3 position) {

Imagine you have a big box of colorful LEGO bricks, and you want to pick one special "secret number" based on where a brick is sitting in the box.

This code is like a magic blender. 
You put in a location (where the brick is), and it spits out a random-looking number between 0 and 1. Here is how it works, step-by-step:

1. Shrink the Numbers

The code starts with your position (like x=10, y=20, z=30) and multiplies it by 0.1031.
     
     - The Goal: It makes the numbers smaller so they fit into a tiny space.
     - The "Fract" Trick: It only keeps the numbers after the decimal point.
       For example, if it gets 1.45, it throws away the 1 and only keeps 0.45.
       This keeps the numbers from getting too huge.

2. The "Mix-Up" (The Dot Product)

This is where the magic happens.
The code takes your shrunk numbers and mixes them together like a smoothie.
    
    - It adds a "secret ingredient" (33.33) to the numbers.
    - It multiplies the numbers by each other in a weird order (x times y, y times z, etc.).
    - Why? This ensures that if you move your position just a tiny bit, the final result changes completely. It’s like shuffling a deck of cards so you can't guess what's next.

3. Flattening into One Number
    
Now we have three mixed-up numbers, but we only want one answer.
    
    - The code adds the first two numbers together and multiplies them by the third.
    - It uses that "Fract" trick one last time to make sure the final result is a decimal between 0 and 1.
    
A Simple Example

Let's pretend we are using 2D (just X and Y) to make it easier to see:

    - Input: You are at position (5, 2).
    - Shrink: We multiply by a small number. Let's say we get (0.51, 0.20).
    - Mix: We add our secret 33.33 and multiply them together.
      Suddenly, our small numbers turn into something messy, like 18.4567.
    - Final Result: We use fract to keep only the end: 0.4567.
    
1. The Input (3D Space)

Imagine a grid. Your float3 position is a specific dot in this grid.

      Z 
      |  . (x, y, z)  <-- Your Input
      | /
      |/____ X
     /
    Y
    
2. The Scramble (The "Mix-Up")

The code multiplies the numbers and adds 33.33.
This is like taking your coordinates and throwing them into a lottery machine.

Before Scramble: (Nice, organized coordinates)
```
[ 1.0 ]  [ 2.0 ]  [ 3.0 ]
```
After Scramble (The "Mix"): The numbers get stretched, added, and flipped.
The dot product creates a "cross-talk" where X knows about Y, and Y knows about Z.
```
   \  /      \  /      \  /
    \/        \/        \/    <-- Mixing logic
   /  \      /  \      /  \
[ 42.103 ] [ 9.554 ] [ 88.21 ]
```
3. The Flattening (To 1D)

We take those three messy numbers and crush them together into one single value.
```
 (  X   +   Y ) *    Z
 [42.1] + [9.5] * [88.2]
          |
          v
   [ 4550.6234... ]  <-- One giant messy number
```   
4. The Final "Fract" (The Result)

The fract function is like a guillotine.
It chops off everything except the decimals.
This ensures our answer is always between 0 and 1.
```
    KEEP ONLY THE END
          vvvvvv
  4550 . 6234891...
          |
          v
       [ 0.6234 ]    <-- Your Final "Random" Hash!
```
What does the output look like?

If you ran this code for every pixel on your screen, it wouldn't look like a smooth photo. It would look like TV Static (Noise):
```
. : * . # : . * : . # .
* . # : . * : . # : . *
: . * : . # . : * . # :
```
-------------------------------------------------------
float drawCircle(float3 surfacePos, float density, float baseSize, float time, float isAnimated) {

Part 1: The Constant Variables (The "Knobs")

These numbers define the look and feel of your stars.

STAR_SPARSITY = 0.85: Controls how many stars appear.

    - Increase (e.g., 0.99): Fewer stars (only 1% remain).

    - Decrease (e.g., 0.50): More stars (50% of the grid filled).

PULSE_BASE_SPEED = 2.5: The minimum speed at which a star twinkles.

    - Increase: All stars blink faster.

PULSE_VAR_RANGE = 2.5: Adds variety to the speed.

    - Increase: Creates a larger difference between the "fast" stars and "slow" stars.

PULSE_AMPLITUDE = 0.3: The "intensity" of the pulse.

    - Increase: Stars grow much larger and shrink much smaller while twinkling.

PULSE_BASE_SIZE = 0.35: The standard size scale before pulsing.

EDGE_SOFTNESS = 0.1: The blurriness of the circle edge.

    - Increase: Stars look like glowing "fuzz-balls."

    - Decrease (e.g., 0.01): Stars look like sharp, hard dots.
    
-------------------------------------------------------
    float3 scaledGrid = surfacePos * density;
    
    float3 cellCoordinates = fract(scaledGrid) - GRID_CENTER_OFFSET;
    
    float cellID = hash3D(floor(scaledGrid));
    
        - The Math: By multiplying the position by density, you scale the coordinate system. fract keeps only the decimals (0.0 to 1.0), repeating the pattern in a grid.
        - The Center: Subtracting 0.5 (GRID_CENTER_OFFSET) shifts the local coordinate of each cell so (0,0,0) is in the middle of the tile rather than the corner.
        - The ID: floor(scaledGrid) gives every tile a whole number (like 1, 2, 3). The hash function turns that number into a "random" decimal between 0 and 1.
-------------------------------------------------------
    float particleVisibility = step(STAR_SPARSITY, cellID);
    
        - Purpose: This decides if a star exists in this tile.
        - How it works: step(0.85, cellID) returns 0.0 if the random ID is below 0.85, and 1.0 if it is above. This effectively "kills" 85% of the stars, leaving the rest scattered.
-------------------------------------------------------
    float blinkSpeed = PULSE_BASE_SPEED + (fract(cellID * TWINKLE_SCRAMBLE_SEED) * PULSE_VAR_RANGE);
    
    float timeOffset = cellID * TIME_PHASE_SCRAMBLE;
    
    float brightnessPulse = (sin(time * blinkSpeed + timeOffset) * PULSE_AMPLITUDE) + PULSE_BASE_SIZE;
    
3. Twinkle Calculations

        - Blink Speed: It uses the cellID to ensure every star has a unique speed. Without this, every star would pulse at the exact same rhythm, which looks unnatural.
        - Brightness Pulse: Uses a Sine Wave (sin). This creates a smooth back-and-forth motion between -1 and 1. The PULSE_AMPLITUDE and BASE_SIZE remap this so the star never fully disappears (unless you want it to).
-------------------------------------------------------
    float finalRadius = baseSize * brightnessPulse;
    
    return smoothstep(finalRadius, finalRadius - EDGE_SOFTNESS, length(cellCoordinates)) * particleVisibility;
    
        - Length: length(cellCoordinates) calculates the distance from the center of the tile.
        - Smoothstep: This is the magic "drawing" function. 
          If the distance is less than the radius, it returns 1 (white).
          If it's more, it returns 0 (black). The EDGE_SOFTNESS creates the gradient between the two.
        - The Multiplier: Finally, it multiplies by particleVisibility.
          If the star failed the "lottery" earlier, the whole result becomes 0 (invisible).
-------------------------------------------------------
