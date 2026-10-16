// Coin flash
//
// An expanding gold ring every time the cursor moves, like collecting a pickup.
// iCurrentCursor is given in the same pixel space as fragCoord, with .xy at the
// cursor's top-left and .zw its size, so no coordinate flip is needed.
// iTimeCursorChange is the timestamp of the last move, which is what drives the
// animation.
//
// Pair it with cursor_blaze, or use it instead for something less busy.

const float DURATION = 0.35;                  // seconds
const float RADIUS   = 42.0;                  // final ring radius in pixels
const float THICKNESS = 6.0;                  // ring softness in pixels
const vec3  COIN     = vec3(1.0, 0.80, 0.20); // arcade gold

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 src = texture(iChannel0, fragCoord / iResolution.xy);

    float age = (iTime - iTimeCursorChange) / DURATION;
    if (age < 0.0 || age > 1.0) {
        fragColor = src;
        return;
    }

    vec2 centre = vec2(iCurrentCursor.x + iCurrentCursor.z * 0.5,
                       iCurrentCursor.y - iCurrentCursor.w * 0.5);

    float d = distance(fragCoord, centre);
    float ring = smoothstep(THICKNESS, 0.0, abs(d - RADIUS * age));
    float fade = 1.0 - age;

    fragColor = vec4(src.rgb + COIN * ring * fade * 0.9, src.a);
}
