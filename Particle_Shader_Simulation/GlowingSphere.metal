#include <metal_stdlib>
using namespace metal;

// Generates a pseudo-random value (0.0 to 1.0) based on 3D coordinates
float hash3D(float3 position) {
    const float HASH_DISTRIBUTION_PRIME = 0.1031;
    const float HASH_MIX_OFFSET = 33.33;
    
    // Scramble the position coordinates to avoid repeating patterns
    float3 scaledPos = fract(position * HASH_DISTRIBUTION_PRIME);
    scaledPos += dot(scaledPos, scaledPos.yzx + HASH_MIX_OFFSET);
    
    // Flatten 3D vector into a single chaotic decimal
    return fract((scaledPos.x + scaledPos.y) * scaledPos.z);
}

// Rotates a point around the Y-axis (like a spinning globe)
float3 rotateY(float3 position, float angle) {
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Apply 2D rotation matrix logic to the X and Z axes
    float rotatedX = position.x * cosAngle + position.z * sinAngle;
    float rotatedZ = -position.x * sinAngle + position.z * cosAngle;
    
    return float3(rotatedX, position.y, rotatedZ);
}

float drawCircle(float3 surfacePos, float density, float baseSize, float time) {
    const float STAR_SPARSITY      = 0.85;  // Higher = fewer stars (0.98 = only 2% visible)
    const float PULSE_BASE_SPEED   = 2.5;   // Minimum twinkle speed
    const float PULSE_VAR_RANGE    = 2.5;  // Randomness of twinkle speed
    const float PULSE_AMPLITUDE    = 0.3;   // How much the star grows/shrinks
    const float PULSE_BASE_SIZE    = 0.35;  // The "resting" size of the star
    const float EDGE_SOFTNESS      = 0.1;   // Smoothness of the circle edge
    const float GRID_CENTER_OFFSET = 0.5;
    const float TWINKLE_SCRAMBLE_SEED = 145.67;
    const float TIME_PHASE_SCRAMBLE = 100.0;
    
    // 2. TILING: Divide the sphere surface into a grid of cells
    float3 scaledGrid = surfacePos * density;
    float3 cellCoordinates = fract(scaledGrid) - GRID_CENTER_OFFSET; // Center local UVs
    float cellID = hash3D(floor(scaledGrid)); // Unique ID for each grid tile
    
    // 3. SELECTION: Randomly hide 98% of cells to create a sparse starfield
    float particleVisibility = step(STAR_SPARSITY, cellID);
    
    // 4. TWINKLE: Calculate unique blink speed and time offset for each star
    float blinkSpeed = PULSE_BASE_SPEED + (fract(cellID * TWINKLE_SCRAMBLE_SEED) * PULSE_VAR_RANGE);
    float timeOffset = cellID * TIME_PHASE_SCRAMBLE;
    float brightnessPulse = (sin(time * blinkSpeed + timeOffset) * PULSE_AMPLITUDE) + PULSE_BASE_SIZE;
    
    // 5. DRAWING: Render the circle with soft, anti-aliased edges
    float finalRadius = baseSize * brightnessPulse;
    return smoothstep(finalRadius, finalRadius - EDGE_SOFTNESS, length(cellCoordinates)) * particleVisibility;
}

[[ stitchable ]] half4 particleSphere(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float radius,
    float density,
    float rotationSpeed
) {
    const float UV_CENTER_OFFSET = 0.5;
    const float NDC_RANGE_MULTIPLIER = 2.0;
    const float ROTATION_SPEED = rotationSpeed;
    const float FRESNEL_EXPONENT = 4.0;
    const float FRESNEL_BIAS = 1.0;
    const float INTENSITY_DIMMER = 0.15;
    const float FRONT_STAR_INTENSITY = 2.5;
    const float BACK_STAR_INTENSITY  = 0.8;
    const float DENSITY = density;
    const float STARTSIZE = 0.85;
    const float SURFACE_OPACITY = 1.0;
    const float CAMERA_OFFSET = -2.5;
    const float FOCAL_LENGTH = 1.5;
    const float RADIUS = radius;
    const float AURA_INTENSITY = 1.0;
    const float GLOW_STRENGTH = 0.04;
    const float GLOW_OFFSET = 0.5;
    const float GLOW_MIN_LIMIT = 0.001;
    const float HIT_THRESHOLD = 0.0;
    const float2 DEFAULT_CAMERA_CENTERED = float2(0.0, 0.0);
    const half3 DEEP_BLUE_HUE = half3(0.02, 0.05, 0.15);
    const half3 GLOW_COLOR_CYAN = half3(0.0, 0.2, 0.5);
    const half3 FRONT_STAR_HUE = half3(1.0, 1.0, 1.0);
    const half3 BACK_STAR_HUE  = half3(0.2, 0.5, 1.0);
    const half3 DARK_CANVAS = half3(0.01, 0.01, 0.02);
    const half3 AURA_HUE = half3(0.0, 0.3, 0.7);
    
    const float2 uv = position / size;
    float2 centered = (uv - UV_CENTER_OFFSET) * NDC_RANGE_MULTIPLIER;
    
    const float aspect_ratio = size.x / size.y;
    centered.x *= aspect_ratio;
    
    float outerGlow = GLOW_STRENGTH / (max(GLOW_MIN_LIMIT, length(centered) - (RADIUS - GLOW_OFFSET)));
    outerGlow = clamp(outerGlow, 0.0, 1.0);
    
    float3 cameraPosition = float3(DEFAULT_CAMERA_CENTERED, CAMERA_OFFSET);
    float3 rayDirection = normalize(float3(centered, FOCAL_LENGTH));
    float midpointDistance = dot(cameraPosition, rayDirection);
    float originOffset = dot(cameraPosition, cameraPosition) - (RADIUS * RADIUS);
    float insideSphereSquared = midpointDistance * midpointDistance - originOffset;
    bool isIntersecting = insideSphereSquared > HIT_THRESHOLD;
    
    if (isIntersecting) {
        float distanceToFrontSurface = -midpointDistance - sqrt(insideSphereSquared);
        float distanceToBackSurface = -midpointDistance + sqrt(insideSphereSquared);
        float3 positionFrontSurface = cameraPosition + rayDirection * distanceToFrontSurface;
        float3 positionBackSurface = cameraPosition + rayDirection * distanceToBackSurface;
        
        float3 rotatedFrontSurface = rotateY(positionFrontSurface, time * ROTATION_SPEED);
        float3 rotatedBackSurface = rotateY(positionBackSurface, time * ROTATION_SPEED);
        
        float3 surfaceNormal = normalize(positionFrontSurface);
        float fresnel = pow(FRESNEL_BIAS + dot(rayDirection, surfaceNormal), FRESNEL_EXPONENT);
        half3 bodyTint = DEEP_BLUE_HUE * INTENSITY_DIMMER;
        half3 shellGlow = GLOW_COLOR_CYAN * half(fresnel);
        
        float frontPatternMask = drawCircle(rotatedFrontSurface, DENSITY, STARTSIZE, time);
        float backPatternMask = drawCircle(rotatedBackSurface, DENSITY, STARTSIZE, time);
        
        half3 frontLayerStars = FRONT_STAR_HUE * half(frontPatternMask * FRONT_STAR_INTENSITY);
        half3 backLayerStars  = BACK_STAR_HUE  * half(backPatternMask  * BACK_STAR_INTENSITY);
        
        half3 finalRGB = frontLayerStars + backLayerStars + bodyTint + shellGlow;
        return half4(finalRGB, SURFACE_OPACITY);
    } else {
        half3 auraColor = AURA_HUE * half(outerGlow);
        return half4(DARK_CANVAS + auraColor, AURA_INTENSITY);
    }
}
