// GBA LCD
//
// The Game Boy Advance screen had no backlight and a visible gap between its
// pixels. This darkens a one-pixel line around every font pixel to bring that
// grid back.
//
// The grid only sits between font pixels because the sizes line up exactly:
// Departure Mono is drawn on an 11-unit em, so at 16.5pt on a 2x display each
// font pixel is 3x3 device pixels and every cell (21x42) is a whole number of
// them. ORIGIN is the window padding in device pixels from the top-left corner,
// which is why window-padding-balance has to stay off: balancing moves the
// cells by an amount the shader cannot see. A 1x display cannot align at all;
// set GRID to 0 there.

const float PIXEL  = 3.0;                    // device pixels per font pixel
const vec2  ORIGIN = vec2(36.0, 36.0);       // 18pt window padding at 2x
const float GRID   = 0.14;                   // how dark the gaps between pixels are
const vec3  TINT   = vec3(1.0, 0.985, 0.94); // the unlit screen's warm cast

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 src = texture(iChannel0, fragCoord / iResolution.xy);

    vec2 fromTopLeft = vec2(fragCoord.x, iResolution.y - fragCoord.y) - ORIGIN;
    vec2 withinPixel = mod(floor(fromTopLeft), PIXEL);
    float gap = max(step(PIXEL - 1.0, withinPixel.x), step(PIXEL - 1.0, withinPixel.y));

    fragColor = vec4(src.rgb * TINT * (1.0 - GRID * gap), src.a);
}
