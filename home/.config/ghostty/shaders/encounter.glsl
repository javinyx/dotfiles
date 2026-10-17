// Encounter
//
// The wild-battle transition, played once when a window, tab or split opens:
// the screen flashes twice, closes behind horizontal bars, and the bars slide
// away in alternate directions to reveal the terminal. iTime counts from each
// surface's first frame, which is the only signal a shader gets that it has
// just opened.
//
// Time is stepped at STEP seconds rather than running smoothly, so the wipe
// moves in visible frames like a DS animation. Bars are BAR font pixels tall
// and their edges move in whole font pixels, so they share the LCD grid. Run
// this before ds-lcd.glsl.

const float PIXEL   = 3.0;    // device pixels per font pixel
const float BAR     = 8.0;    // font pixels per bar
const float STEP    = 1.0 / 24.0;
const float FLASHES = 2.0;
const float FLASH   = 0.06;   // seconds per flash, and per gap between flashes
const float OPEN    = 0.36;   // seconds for one bar to slide away
const float SPREAD  = 0.2;    // seconds from the middle bar starting to the outer ones
const float EDGE    = 2.0;    // font pixels of accent on each bar's edge

vec3 inverted(vec3 c) {
    return vec3(1.0) - c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float t = floor(iTime / STEP) * STEP;
    float flashing = 2.0 * FLASHES * FLASH;
    float rows = ceil(iResolution.y / (BAR * PIXEL));
    float end = flashing + OPEN + SPREAD;
    if (t >= end) {
        return;
    }

    if (t < flashing) {
        if (mod(floor(t / FLASH), 2.0) == 0.0) {
            fragColor.rgb = inverted(fragColor.rgb);
        }
        return;
    }

    float row = floor((iResolution.y - fragCoord.y) / (BAR * PIXEL));
    float fromMiddle = min(abs(row - floor(rows / 2.0)) / (rows / 2.0), 1.0);
    float progress = clamp((t - flashing - fromMiddle * SPREAD) / OPEN, 0.0, 1.0);
    float progressSq = progress * progress;

    float columns = ceil(iResolution.x / PIXEL);
    float column = floor(fragCoord.x / PIXEL);
    float fromSide = mod(row, 2.0) == 0.0 ? column : columns - 1.0 - column;
    float edge = floor(progressSq * (columns + EDGE));

    if (fromSide < edge - EDGE) {
        return;
    }

    bool light = dot(iBackgroundColor, vec3(0.299, 0.587, 0.114)) > 0.5;
    vec3 shutter = light ? iForegroundColor : vec3(0.02, 0.03, 0.04);
    fragColor.rgb = fromSide < edge ? iCurrentCursorColor.rgb : shutter;
}
