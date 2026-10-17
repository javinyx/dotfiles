// Quick Attack
//
// When the cursor jumps rather than steps - a new prompt, a click, a word
// jump - it leaves a trail of afterimages along the way, like a Pokemon using
// Quick Attack. Typing moves one cell at a time and never sets it off.
//
// The afterimages fade by ordered dithering on the font-pixel grid instead of
// by transparency, the way DS games faded sprites, and they are drawn only
// over background so text is never covered. Time is stepped at STEP seconds so
// the fade moves in visible frames.

const float PIXEL       = 3.0;   // device pixels per font pixel
const float DURATION    = 0.22;  // seconds
const float STEP        = 1.0 / 30.0;
const float THRESHOLD   = 0.04;  // how close to the background
const int   AFTERIMAGES = 4;

const float BAYER[16] = float[16](
     0.0,  8.0,  2.0, 10.0,
    12.0,  4.0, 14.0,  6.0,
     3.0, 11.0,  1.0,  9.0,
    15.0,  7.0, 13.0,  5.0
);

float ditherThreshold(vec2 fragCoord) {
    vec2 q = mod(floor(fragCoord / PIXEL), 4.0);
    return (BAYER[int(q.y) * 4 + int(q.x)] + 0.5) / 16.0;
}

bool jumped() {
    vec2 moved = abs(iCurrentCursor.xy - iPreviousCursor.xy);
    return moved.x > 1.5 * iCurrentCursor.z || moved.y > 0.5 * iCurrentCursor.w;
}

bool insideCursorAt(vec2 topLeft, vec2 fragCoord) {
    vec2 size = iCurrentCursor.zw;
    return fragCoord.x >= topLeft.x && fragCoord.x < topLeft.x + size.x
        && fragCoord.y <= topLeft.y && fragCoord.y > topLeft.y - size.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float elapsed = floor((iTime - iTimeCursorChange) / STEP) * STEP;
    if (elapsed < 0.0 || elapsed >= DURATION || !jumped()) {
        return;
    }
    if (distance(fragColor.rgb, iBackgroundColor) > THRESHOLD) {
        return;
    }

    float fade = 1.0 - elapsed / DURATION;
    float threshold = ditherThreshold(fragCoord);
    for (int k = 1; k <= AFTERIMAGES; k++) {
        float behind = float(k) / float(AFTERIMAGES + 1);
        vec2 at = mix(iCurrentCursor.xy, iPreviousCursor.xy, behind);
        at = iPreviousCursor.xy + floor((at - iPreviousCursor.xy) / PIXEL + 0.5) * PIXEL;
        float density = fade * (1.0 - behind);
        if (insideCursorAt(at, fragCoord) && density > threshold) {
            fragColor.rgb = iCurrentCursorColor.rgb;
            return;
        }
    }
}
