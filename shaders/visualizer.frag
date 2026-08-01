// GLSL Fragment Shader for G.A - Song Visualizer
// 
// Supports multiple visualization shapes:
// 0 = Circle/Radial bars
// 1 = Vertical bars
// 2 = Waveform
// 3 = Spectrum tunnel
// 4 = Starfield
// 5 = Oscilloscope
// 6 = Radial burst

#version 460 core

// ─── Uniforms ───────────────────────────────────────────────────────────────
// Plain uniform declarations (no UBO block) so the shader is compatible with
// both the Skia (SkSL) and Impeller backends. setFloat() indices follow
// declaration order: 0=u_time, 1=u_energy, 2=u_beat, 3=u_shape,
// 4=u_sensitivity, 5=u_numBars, 6=u_width, 7=u_height, 8=u_bass, 9=u_mid,
// 10=u_high, 11-13=u_accentColor.
uniform float u_time;           // Global time in seconds
uniform float u_energy;         // Smoothed audio energy [0, 1]
uniform float u_beat;           // Beat intensity [0, 1]
uniform float u_shape;          // Visualizer shape (0-6) - float because FragmentShader only supports setFloat
uniform float u_sensitivity;    // Audio sensitivity multiplier
uniform float u_numBars;        // Number of bars/rays - float for the same reason
uniform float u_width;          // Canvas width
uniform float u_height;         // Canvas height
uniform float u_bass;           // Bass frequency energy
uniform float u_mid;            // Mid frequency energy  
uniform float u_high;           // High frequency energy
uniform vec3  u_accentColor;    // Accent color (RGB 0-1)

// ─── Constants ──────────────────────────────────────────────────────────────
#define PI 3.14159265359
#define TAU (2.0 * PI)
#define MAX_BARS 256

// ─── Utility Functions ──────────────────────────────────────────────────────

// Hash function for pseudo-randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float x) {
    return fract(sin(x * 127.1) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Smooth noise
float snoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * snoise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Smoothstep helpers
float smoothstep3(float a, float b, float x) {
    float t = clamp((x - a) / (b - a), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

float smootherstep(float a, float b, float x) {
    float t = clamp((x - a) / (b - a), 0.0, 1.0);
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// ─── Shape-Specific Functions ───────────────────────────────────────────────

// 0: Circle/Radial Bars
vec3 drawCircleBars(vec2 uv, vec2 center, float radius) {
    vec3 color = vec3(0.0);
    float angle = atan(uv.y - center.y, uv.x - center.x);
    float dist = length(uv - center);
    
    float barAngle = TAU / float(u_numBars);
    float barIndex = floor((angle + PI) / barAngle);
    float barAngleCenter = barIndex * barAngle - PI;
    float angleDiff = abs(angle - barAngleCenter);
    
    // Get FFT data for this bar
    float dataIndex = float(int(barIndex)) * 100.0 / u_numBars;
    // We'll approximate FFT data using available uniforms
    float fftValue = u_bass;
    if (barIndex > float(u_numBars) * 0.33) fftValue = u_mid;
    if (barIndex > float(u_numBars) * 0.66) fftValue = u_high;
    
    float barHeight = 4.0 + fftValue * 350.0 * (1.0 + barIndex / 50.0);
    barHeight = clamp(barHeight, 4.0, 180.0);
    
    float innerRadius = radius;
    float outerRadius = radius + barHeight;
    
    if (dist > innerRadius && dist < outerRadius && angleDiff < barAngle * 0.5) {
        float intensity = (dist - innerRadius) / (outerRadius - innerRadius);
        vec3 barColor = hsv2rgb(vec3(
            (0.75 - intensity * 0.6) * 360.0 / 360.0,
            1.0,
            1.0
        ));
        color = mix(color, barColor, smoothstep3(0.0, 0.02, angleDiff / (barAngle * 0.5)));
    }
    
    return color;
}

// 1: Vertical Bars
vec3 drawVerticalBars(vec2 uv) {
    vec3 color = vec3(0.0);
    float barWidth = u_width / float(u_numBars);
    float barIndex = floor(uv.x / barWidth);
    float barX = barIndex * barWidth;
    float barRight = barX + barWidth - 4.0;
    
    if (uv.x >= barX && uv.x <= barRight) {
        float dataIndex = barIndex * 100.0 / float(u_numBars);
        float fftValue = u_bass;
        if (barIndex > float(u_numBars) * 0.33) fftValue = u_mid;
        if (barIndex > float(u_numBars) * 0.66) fftValue = u_high;
        
        float multiplier = 1.0 + (dataIndex / 40.0);
        float height = (fftValue * 300.0 * multiplier + 4.0);
        height = clamp(height, 4.0, u_height);
        
        if (uv.y > u_height - height) {
            float intensity = (uv.y - (u_height - height)) / height;
            vec3 barColor = hsv2rgb(vec3(
                (0.75 - intensity * 0.6) / 360.0,
                1.0,
                1.0
            ));
            
            // Add reflection
            float reflectionY = u_height - height * 0.4;
            float reflection = 0.0;
            if (uv.y > reflectionY && uv.y < u_height) {
                reflection = 0.2 * (1.0 - (uv.y - reflectionY) / (u_height - reflectionY));
            }
            
            color = mix(color, barColor, 1.0) + vec3(reflection);
        }
    }
    return color;
}

// 2: Waveform
vec3 drawWaveform(vec2 uv) {
    vec3 color = vec3(0.0);
    const int points = 80;
    float step = u_width / float(points - 1);
    
    for (int i = 0; i < points; i++) {
        float x = float(i) * step;
        float dataIndex = float(i) * 100.0 / float(points);
        float fftValue = u_bass; // Would use actual FFT data
        
        float multiplier = 1.0 + (dataIndex / 40.0);
        float height = clamp(fftValue * 320.0 * multiplier, 0.0, u_height);
        
        float waveX = x;
        float waveY = u_height - height - sin(float(i) * 0.2 + u_time * 10.0) * 10.0;
        
        float dist = length(uv - vec2(waveX, waveY));
        if (dist < 3.0) {
            float t = 1.0 - dist / 3.0;
            vec3 waveColor = hsv2rgb(vec3(
                (270.0 - 60.0 * t) / 360.0,
                0.9,
                1.0
            ));
            color = mix(color, waveColor, t * 0.8);
        }
    }
    return color;
}

// 3: Spectrum Tunnel
vec3 drawSpectrumTunnel(vec2 uv, vec2 center) {
    vec3 color = vec3(0.0);
    
    if (u_energy < 0.005) return color;
    
    float dist = length(uv - center);
    float maxRadius = min(u_width, u_height) * 0.45;
    const int numRings = 20;
    
    for (int ring = numRings - 1; ring >= 0; ring--) {
        float depthFactor = float(ring + 1) / float(numRings);
        float baseRadius = maxRadius * depthFactor;
        
        float bandIndex = float(ring) / float(numRings) * 80.0;
        float bandValue = u_bass; // Would use actual FFT
        float pulseAmount = bandValue * 65.0 * depthFactor;
        float currentRadius = baseRadius + pulseAmount;
        float drift = mod(u_time * 30.0 + float(ring) * 15.0, maxRadius * 1.2);
        float animatedRadius = mod(currentRadius + drift, maxRadius * 1.2);
        
        if (animatedRadius < 10.0) continue;
        
        float ringHue = mod(270.0 + float(ring) * 12.0 + u_time * 20.0, 360.0);
        float alpha = clamp(1.0 - animatedRadius / (maxRadius * 1.2), 0.1, 0.8);
        
        float ringDist = abs(dist - animatedRadius);
        float thickness = clamp(3.0 * (1.0 - depthFactor * 0.5), 1.0, 4.0);
        
        if (ringDist < thickness) {
            float ringAlpha = alpha * (1.0 - ringDist / thickness);
            vec3 ringColor = hsv2rgb(vec3(ringHue / 360.0, 0.9, 1.0));
            color = mix(color, ringColor, ringAlpha);
        }
    }
    
    // Center glow
    float glowDist = length(uv - center);
    if (glowDist < 30.0 + u_energy * 20.0) {
        float glowAlpha = clamp(0.3 + u_energy * 0.4, 0.0, 0.7);
        vec3 glowColor = hsv2rgb(vec3(mod(270.0 + u_time * 20.0, 360.0) / 360.0, 0.7, 1.0));
        color = mix(color, glowColor, glowAlpha * smoothstep3(0.0, 30.0 + u_energy * 20.0, glowDist));
    }
    
    return color;
}

// 4: Starfield
vec3 drawStarfield(vec2 uv, vec2 center) {
    vec3 color = vec3(0.0);
    
    // We'll use a deterministic approach for stars
    const int starCount = 200;
    
    for (int i = 0; i < starCount; i++) {
        // Deterministic star position
        float seed = float(i) * 1.41421356;
        float angle = fract(sin(seed * 127.1) * 43758.5453) * TAU;
        float dist = 0.5 + fract(sin(seed * 311.7) * 43758.5453) * 0.5;
        
        float z = 0.5 + fract(sin(seed * 746.3) * 43758.5453) * 0.5;
        float speed = 10.0 + fract(sin(seed * 269.5) * 43758.5453) * 40.0;
        float radius = 1.0 + fract(sin(seed * 183.3) * 43758.5453) * 2.0 * (0.5 + z * 0.5);
        
        float baseX = fract(sin(seed * 127.1) * 43758.5453) * u_width;
        float baseY = fract(sin(seed * 311.7) * 43758.5453) * u_height;
        float driftX = cos(angle + u_time * speed * 0.02) * 30.0 * (1.0 - z);
        float driftY = sin(angle * 1.3 + u_time * speed * 0.02) * 30.0 * (1.0 - z);
        
        float x = mod(baseX + driftX, u_width);
        float y = mod(baseY + driftY, u_height);
        
        // Wrap
        if (x < 0.0) x += u_width;
        if (y < 0.0) y += u_height;
        
        float projectedRadius = radius * (0.5 + z * 0.5);
        float alpha = 0.5 + z * 0.5;
        
        float starDist = length(uv - vec2(x, y));
        if (starDist < projectedRadius) {
            // Star color from palette (SkSL has no % operator)
            int paletteIdx = i - (i / 20) * 20;
            float hue = float(paletteIdx) * 18.0 / 360.0;
            vec3 starColor = hsv2rgb(vec3(hue, 0.7, 1.0));
            
            color = mix(color, starColor, alpha * (1.0 - starDist / projectedRadius));
        }
    }
    
    // Bottom wave
    if (u_energy > 0.0) {
        float waveHeight = u_height * 0.08;
        float baseY = u_height - 20.0;
        float waveY = baseY;
        
        // Simple wave using noise
        float waveDist = uv.y - waveY;
        if (abs(waveDist) < waveHeight * 3.0) {
            float xNorm = uv.x / u_width;
            float waveVal = sin(xNorm * 80.0 + u_time * 10.0) * u_energy * waveHeight * 3.0;
            if (waveDist > waveVal) {
                float t = 1.0 - abs(waveDist - waveVal) / (waveHeight * 3.0);
                vec3 waveColor = hsv2rgb(vec3(((270.0 - u_energy * 60.0) / 360.0), 0.7, 1.0));
                color = mix(color, waveColor, t * 0.3);
            }
        }
    }
    
    return color;
}

// 5: Oscilloscope
vec3 drawOscilloscope(vec2 uv) {
    vec3 color = vec3(0.0);
    
    // Grid
    float gridAlpha = 0.1;
    for (int i = 0; i <= 10; i++) {
        float x = u_width * float(i) / 10.0;
        if (abs(uv.x - x) < 0.5) color = mix(color, vec3(0.0, 1.0, 0.0), gridAlpha);
    }
    for (int i = 0; i <= 8; i++) {
        float y = u_height * float(i) / 8.0;
        if (abs(uv.y - y) < 0.5) color = mix(color, vec3(0.0, 1.0, 0.0), gridAlpha);
    }
    
    // Waveform
    const int points = 128;
    float step = u_width / float(points - 1);
    float midY = u_height / 2.0;
    
    for (int i = 0; i < points; i++) {
        float x = float(i) * step;
        float fftValue = u_bass; // Would use FFT data
        
        float y = midY - fftValue * u_height * 0.4;
        
        float dist = length(uv - vec2(x, y));
        if (dist < 2.0) {
            color = mix(color, vec3(0.0, 1.0, 0.5), 1.0 - dist / 2.0);
        }
    }
    
    return color;
}

// 6: Radial Burst
vec3 drawRadialBurst(vec2 uv, vec2 center) {
    vec3 color = vec3(0.0);
    
    if (u_energy == 0.0) return color;
    
    float maxRadius = min(u_width, u_height) * 0.45;
    float baseHue = (1.0 - min(u_energy * 2.5, 1.0)) * 270.0;
    
    // Center glow
    float glowDist = length(uv - center);
    if (glowDist < 40.0 + u_energy * 30.0) {
        float glowAlpha = clamp(0.4 + u_energy * 0.5, 0.0, 0.8);
        vec3 glowColor = hsv2rgb(vec3(baseHue / 360.0, 0.9, 1.0));
        color = mix(color, glowColor, glowAlpha * (1.0 - glowDist / (40.0 + u_energy * 30.0)));
    }
    
    const int numRays = 60;
    float angleStep = TAU / float(numRays);
    
    for (int i = 0; i < numRays; i++) {
        float dataIndex = float(i) * 120.0 / float(numRays);
        float fftValue = u_bass; // Would use actual FFT
        
        float rayLength = 60.0 + fftValue * maxRadius * 1.5;
        float angle = float(i) * angleStep + u_time;
        
        vec2 innerPoint = center + vec2(cos(angle), sin(angle)) * 50.0;
        vec2 outerPoint = center + vec2(cos(angle), sin(angle)) * rayLength;
        
        // Distance from line segment
        vec2 lineVec = outerPoint - innerPoint;
        vec2 pointVec = uv - innerPoint;
        float lineLen = length(lineVec);
        float t = clamp(dot(pointVec, lineVec) / (lineLen * lineLen), 0.0, 1.0);
        vec2 closest = innerPoint + lineVec * t;
        float dist = length(uv - closest);
        
        if (dist < 3.0 + fftValue * 5.0 && t > 0.0 && t < 1.0) {
            float rayHue = mod(baseHue + float(i) * 2.0, 360.0);
            vec3 rayColor = hsv2rgb(vec3(rayHue / 360.0, 0.9, 1.0));
            float rayAlpha = 0.8 * (1.0 - dist / (3.0 + fftValue * 5.0));
            color = mix(color, rayColor, rayAlpha);
        }
    }
    
    return color;
}

// ─── Main ───────────────────────────────────────────────────────────────────

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 center = vec2(u_width / 2.0, u_height / 2.0);
    vec3 finalColor = vec3(0.0);
    
    // Select visualizer based on shape
    if (u_shape == 0.0) {
        finalColor = drawCircleBars(gl_FragCoord.xy, center, min(u_width, u_height) * 0.35);
    } else if (u_shape == 1.0) {
        finalColor = drawVerticalBars(gl_FragCoord.xy);
    } else if (u_shape == 2.0) {
        finalColor = drawWaveform(gl_FragCoord.xy);
    } else if (u_shape == 3.0) {
        finalColor = drawSpectrumTunnel(gl_FragCoord.xy, center);
    } else if (u_shape == 4.0) {
        finalColor = drawStarfield(gl_FragCoord.xy, center);
    } else if (u_shape == 5.0) {
        finalColor = drawOscilloscope(gl_FragCoord.xy);
    } else if (u_shape == 6.0) {
        finalColor = drawRadialBurst(gl_FragCoord.xy, center);
    }
    
    // Apply beat flash
    if (u_beat > 0.0) {
        finalColor += u_accentColor * u_beat * 0.3;
    }
    
    // Gamma correction
    finalColor = pow(finalColor, vec3(1.0 / 2.2));
    
    // Output
    fragColor = vec4(finalColor, 1.0);
}