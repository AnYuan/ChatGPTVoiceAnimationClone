#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// A simple vertex function that outputs a full-screen quad
vertex VertexOut vertex_main(uint vertexID [[ vertex_id ]]) {
    // Two triangles making up a full-screen quad:
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);

    // UV goes from 0..1 across the screen
    out.uv = positions[vertexID] * 0.5 + 0.5;
    return out;
}

float random(float2 st) {
    return fract(sin(dot(st, float2(12.9898,78.233))) * 43758.5453123);
}

float noise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x)
    + (c - a)*u.y*(1.0-u.x)
    + (d - b)*u.x*u.y;
}

#define NUM_OCTAVES 5

float fbm(float2 st) {
    float value = 0.0;
    float amp   = 0.5;
    float2 shift = float2(100.0);
    float2x2 rot = float2x2(cos(0.5), sin(0.5),
                            -sin(0.5), cos(0.5));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        value += amp * noise(st);
        st = rot * st * 2.0 + shift;
        amp *= 0.5;
    }
    return value;
}

// A fragment function that applies the fractal logic
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float &u_time [[buffer(0)]]) {
    float2 st = in.uv * 3.0;

    // Compute fractal patterns
    float2 q = float2( fbm(st + 0.00 * u_time),
                      fbm(st + float2(1.0)) );

    float2 r = float2( fbm(st + q + float2(1.7, 9.2) + 0.15 * u_time),
                      fbm(st + q + float2(8.3, 2.8) + 0.126 * u_time));

    float f = fbm(st + r);

    float3 color = mix(float3(0.101961, 0.619608, 0.666667),
                       float3(0.666667, 0.666667, 0.498039),
                       clamp((f*f)*4.0, 0.0, 1.0));

    // length(q) is fine, since q is float2
    color = mix(color,
                float3(0, 0, 0.164706),
                clamp(length(q), 0.0, 1.0));

    // Use abs(r.x) instead of length(r.x)
    color = mix(color,
                float3(0.666667, 1, 1),
                clamp(abs(r.x), 0.0, 1.0));

    float factor = f*f*f + 0.6*f*f + 0.5*f;
    return float4(factor * color, 1.0);
}
