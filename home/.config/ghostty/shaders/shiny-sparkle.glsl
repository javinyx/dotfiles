// Shiny sparkle
//
// The burst of four-point stars a shiny Pokemon gives off as it enters battle,
// drawn as pixel sprites around the cursor whenever a new prompt appears.
//
// Ghostty cannot tell a prompt from any other cursor move, so a new prompt is
// recognised by where the cursor lands: on a different line, PROMPT_COLUMN
// cells in, just after the prompt's "► ". Typing moves one cell at a time and
// command output leaves the cursor at column 0, so neither sets it off. Change
// PROMPT_COLUMN if the width of the prompt's second line changes.
//
// Sprite pixels are two font pixels, snapped to the same grid as the font, so
// the stars read as part of the screen rather than an overlay. Run this before
// ds-lcd.glsl so they get the LCD grid too.

const float DURATION      = 0.5;  // seconds, including the stagger
const float LIFETIME      = 0.32; // seconds each star is visible
const float SPRITE        = 6.0;  // device pixels per sprite pixel: two font pixels
const float MAX_ARM       = 2.0;  // sprite pixels from a star's centre to its tip
const float PADDING_X     = 36.0; // 18pt window padding at 2x
const float PROMPT_COLUMN = 2.0;
const vec3  CORE_ON_DARK  = vec3(0.973, 0.973, 0.973); // #f8f8f8
const vec3  TIP_ON_DARK   = vec3(0.973, 0.910, 0.471); // #f8e878
const vec3  CORE_ON_LIGHT = vec3(0.973, 0.722, 0.000); // #f8b800
const vec3  TIP_ON_LIGHT  = vec3(0.816, 0.408, 0.000); // #d06800

// Offsets from the cursor's top-left in sprite pixels (y up), and start delays.
const vec3 STARS[5] = vec3[5](
    vec3(-3.0,  2.0, 0.00),
    vec3( 5.0,  1.0, 0.07),
    vec3( 6.0, -5.0, 0.14),
    vec3(-2.0, -9.0, 0.11),
    vec3( 2.0,  4.0, 0.18)
);

bool atNewPrompt() {
    bool changedLine = abs(iCurrentCursor.y - iPreviousCursor.y) > 1.0;
    float column = floor((iCurrentCursor.x - PADDING_X) / iCurrentCursor.z + 0.5);
    return changedLine && column == PROMPT_COLUMN;
}

// 0 outside the star, 1 for its core, 2 for its tips.
float starPixel(vec2 cell, vec2 centre, float age) {
    if (age <= 0.0 || age >= 1.0) {
        return 0.0;
    }
    float size = floor(MAX_ARM * sin(3.14159 * age) + 0.5);
    vec2 d = abs(cell - centre);
    bool onCross = (d.x == 0.0 && d.y <= size) || (d.y == 0.0 && d.x <= size);
    if (size == 0.0 || !onCross) {
        return 0.0;
    }
    return max(d.x, d.y) == size ? 2.0 : 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float elapsed = iTime - iTimeCursorChange;
    if (elapsed < 0.0 || elapsed > DURATION || !atNewPrompt()) {
        return;
    }

    vec2 cell = floor((fragCoord - iCurrentCursor.xy) / SPRITE);
    for (int i = 0; i < 5; i++) {
        float pixel = starPixel(cell, STARS[i].xy, (elapsed - STARS[i].z) / LIFETIME);
        if (pixel > 0.0) {
            bool lightTheme = dot(iBackgroundColor, vec3(0.299, 0.587, 0.114)) > 0.5;
            vec3 core = lightTheme ? CORE_ON_LIGHT : CORE_ON_DARK;
            vec3 tip = lightTheme ? TIP_ON_LIGHT : TIP_ON_DARK;
            fragColor = vec4(pixel == 2.0 ? tip : core, 1.0);
            return;
        }
    }
}
