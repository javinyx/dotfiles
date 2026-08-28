// Arcade Cabinet CRT
//
// Scanlines, an aperture-grille phosphor mask, a vignette and a touch of
// chromatic aberration. Deliberately flat by default: barrel distortion is what
// makes most CRT shaders tiring to actually work in, because it bends text near
// the edges. Raise CURVATURE if you want the bulging glass anyway.
//
// Every effect is a constant below, so this is meant to be edited.

const float SCANLINE_STRENGTH = 0.12;   // 0 = off, 0.3 = heavy banding
const float GRILLE_STRENGTH   = 0.08;   // RGB stripe mask
const float VIGNETTE_STRENGTH = 0.18;   // corner falloff, higher = darker
const float ABERRATION        = 0.0006; // red/blue split, in UV units
const float CURVATURE         = 0.0;    // 0 = flat, try 0.10 for bulged glass

vec2 curveScreen(vec2 uv, float amount) {
    if (amount <= 0.0) {
        return uv;
    }
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
    uv += uv * offset * offset * amount;
    return uv * 0.5 + 0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 cuv = curveScreen(uv, CURVATURE);

    // Anything the curve pushed off-screen becomes bezel.
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration: pull red and blue apart very slightly.
    vec4 centre = texture(iChannel0, cuv);
    vec3 col;
    col.r = texture(iChannel0, cuv + vec2(ABERRATION, 0.0)).r;
    col.g = centre.g;
    col.b = texture(iChannel0, cuv - vec2(ABERRATION, 0.0)).b;

    // Scanlines, one dark band per physical pixel row.
    float scan = sin(cuv.y * iResolution.y * 3.14159265) * 0.5 + 0.5;
    col *= 1.0 - SCANLINE_STRENGTH * scan;

    // Aperture grille: vertical R/G/B phosphor stripes.
    float px = fragCoord.x * 3.14159265 / 1.5;
    vec3 grille = vec3(sin(px), sin(px + 2.0943951), sin(px + 4.1887902)) * 0.5 + 0.5;
    col *= 1.0 - GRILLE_STRENGTH * (1.0 - grille);

    // Vignette.
    vec2 v = cuv * (1.0 - cuv.yx);
    float vig = pow(clamp(v.x * v.y * 16.0, 0.0, 1.0), VIGNETTE_STRENGTH);
    col *= vig;

    fragColor = vec4(col, centre.a);
}
