// Tall grass
//
// A strip of Hoenn tall grass along the bottom edge that sways every SWAY
// seconds, like the overworld grass. A shader only ever receives the finished
// terminal image, so each pixel is tested against iBackgroundColor and grass is
// drawn only where the terminal shows background: text is never covered.
//
// Sprite pixels are SCALE font pixels on the same grid as the font, counted
// from the top-left like gba-lcd.glsl, so the grass shares the LCD grid. The
// tuft is TUFT_H * SCALE * PIXEL = 42 device pixels tall, which fits inside the
// 30pt bottom padding; taller grass would reach the last line of text.

const float PIXEL      = 3.0;                        // device pixels per font pixel
const float SCALE      = 2.0;                        // font pixels per sprite pixel
const vec2  ORIGIN     = vec2(36.0, 36.0);           // 18pt top-left padding at 2x
const float SPACING    = 13.0;                       // sprite pixels between tufts
const float GAP_CHANCE = 0.15;                       // share of tufts left out
const float SWAY       = 0.6;                        // seconds per frame
const float THRESHOLD  = 0.04;                       // how close to the background
const vec3  LIGHT      = vec3(0.471, 0.784, 0.314);  // #78c850
const vec3  DARK       = vec3(0.157, 0.408, 0.220);  // #286838

const int TUFT_W = 11;
const int TUFT_H = 7;
// 0 is empty, 1 outline, 2 fill; top row first.
const int TUFT[77] = int[77](
    0,0,1,0,0,0,0,0,1,0,0,
    0,1,2,1,0,0,0,1,2,1,0,
    0,1,2,1,0,1,0,1,2,1,0,
    1,2,2,1,1,2,1,1,2,2,1,
    1,2,2,2,1,2,1,2,2,2,1,
    1,2,2,2,2,2,2,2,2,2,1,
    0,1,1,1,1,1,1,1,1,1,0
);

float hash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}

int tuftPixel(vec2 sprite, float frame) {
    int row = TUFT_H - 1 - int(sprite.y);
    if (row < 0 || row >= TUFT_H) {
        return 0;
    }
    for (int k = -1; k <= 0; k++) {
        float slot = floor(sprite.x / SPACING) + float(k);
        if (hash(slot) < GAP_CHANCE) {
            continue;
        }
        float start = slot * SPACING + floor(hash(slot + 11.0) * (SPACING - float(TUFT_W) + 1.0));
        float x = sprite.x - start;
        if (row < 3 && frame == 1.0) {
            x -= hash(slot + 5.0) > 0.5 ? 1.0 : -1.0;
        }
        if (x < 0.0 || x >= float(TUFT_W)) {
            continue;
        }
        int pixel = TUFT[row * TUFT_W + int(x)];
        if (pixel != 0) {
            return pixel;
        }
    }
    return 0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    if (distance(fragColor.rgb, iBackgroundColor) > THRESHOLD) {
        return;
    }

    float block = PIXEL * SCALE;
    vec2 fromTopLeft = vec2(fragCoord.x, iResolution.y - fragCoord.y) - ORIGIN;
    float lastRow = floor((iResolution.y - ORIGIN.y) / block) - 1.0;
    vec2 sprite = vec2(floor(fromTopLeft.x / block), lastRow - floor(fromTopLeft.y / block));

    int pixel = tuftPixel(sprite, mod(floor(iTime / SWAY), 2.0));
    if (pixel == 1) {
        fragColor.rgb = DARK;
    } else if (pixel == 2) {
        fragColor.rgb = LIGHT;
    }
}
