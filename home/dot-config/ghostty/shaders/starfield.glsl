// Starfield
//
// Drifting parallax stars behind the text. The trick is that a shader only ever
// receives the finished terminal image, so there is no "behind" to draw into:
// instead each pixel is tested against iBackgroundColor, and stars are added
// only where the terminal is actually showing background. Text, selections and
// the cursor stay untouched, so nothing becomes harder to read.

const float SPEED      = 0.02; // horizontal drift
const float BRIGHTNESS = 0.5;  // 0 = off
const float THRESHOLD  = 0.12; // how close to the background a pixel must be

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float starLayer(vec2 uv, float t, float scale, float sparsity) {
    uv = uv * scale + vec2(t, 0.0);
    vec2 cell = floor(uv);
    vec2 f = fract(uv) - 0.5;

    float h = hash21(cell);
    if (h < sparsity) {
        return 0.0;
    }

    vec2 offset = vec2(hash21(cell + 1.7), hash21(cell + 3.1)) - 0.5;
    float d = length(f - offset * 0.6);
    float twinkle = 0.6 + 0.4 * sin(iTime * 2.0 + h * 30.0);

    return smoothstep(0.06, 0.0, d) * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 src = texture(iChannel0, uv);

    // 1 where this pixel is terminal background, 0 where it is content.
    float bgness = 1.0 - smoothstep(0.0, THRESHOLD, distance(src.rgb, iBackgroundColor));

    // Correct for aspect so stars stay round rather than stretched.
    vec2 auv = uv * vec2(iResolution.x / iResolution.y, 1.0);

    float stars = starLayer(auv, iTime * SPEED,       18.0, 0.94)
                + starLayer(auv, iTime * SPEED * 1.8, 30.0, 0.96) * 0.6
                + starLayer(auv, iTime * SPEED * 2.6, 48.0, 0.97) * 0.35;

    fragColor = vec4(src.rgb + vec3(stars) * BRIGHTNESS * bgness, src.a);
}
