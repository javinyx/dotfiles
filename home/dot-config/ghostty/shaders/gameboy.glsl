// Game Boy DMG-01
//
// Collapses the whole terminal onto the original Game Boy's four greens, with a
// 2x2 ordered dither so large flat areas band a little less brutally. Works over
// any theme - it quantises whatever is already on screen - but pairs best with
// the game-boy theme, which stops colour information being invented and then
// immediately thrown away.
//
// Raise PIXEL above 1.0 to get chunkier, more obviously low-resolution pixels.

const vec3  GB_DARKEST  = vec3(0.0588, 0.2196, 0.0588); // #0f380f
const vec3  GB_DARK     = vec3(0.1882, 0.3843, 0.1882); // #306230
const vec3  GB_LIGHT    = vec3(0.5451, 0.6745, 0.0588); // #8bac0f
const vec3  GB_LIGHTEST = vec3(0.6078, 0.7373, 0.0588); // #9bbc0f

const float PIXEL  = 1.0;  // 1 = native, 2-3 = chunky
const float DITHER = 0.03; // 0 = hard banding

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 coord = floor(fragCoord / PIXEL) * PIXEL + PIXEL * 0.5;
    vec4 src = texture(iChannel0, coord / iResolution.xy);

    // 2x2 Bayer matrix, centred on zero.
    vec2 cell = mod(floor(fragCoord), 2.0);
    float bayer = (cell.x + 2.0 * cell.y) / 4.0 - 0.375;

    float l = clamp(luma(src.rgb) + bayer * DITHER, 0.0, 1.0);

    vec3 col = GB_LIGHTEST;
    if (l < 0.25) {
        col = GB_DARKEST;
    } else if (l < 0.50) {
        col = GB_DARK;
    } else if (l < 0.75) {
        col = GB_LIGHT;
    }

    fragColor = vec4(col, src.a);
}
