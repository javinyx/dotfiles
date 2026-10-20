// Castelia skyline
//
// Unova along the bottom edge: two rows of Castelia towers whose windows light
// up and go dark, antenna beacons, the Nimbasa Ferris wheel turning, and a
// train crossing every TRAIN_EVERY seconds, the first one half that long after
// the window opens. A shader only receives the finished terminal image, so
// each pixel is tested against iBackgroundColor and the scene is drawn only
// where the terminal shows background: text is never covered.
//
// Everything sits on the font-pixel grid, counted from the top-left like
// ds-lcd.glsl, so the scene shares the LCD grid. Ghostty on macOS already
// counts fragCoord down from the top, unlike Shadertoy, so it is used as is;
// flipping it would draw the scene upside down along the top. Rows are counted
// up from the last whole font pixel at the bottom. The tallest tower plus its
// antenna is 17 font pixels, which fits inside the 30pt bottom padding (20 font
// pixels at 2x); anything taller would reach the last line of text.

const float PIXEL       = 3.0;              // device pixels per font pixel
const vec2  ORIGIN      = vec2(36.0, 36.0); // 18pt top-left padding at 2x
const float THRESHOLD   = 0.04;             // how close to the background
const float WHEEL_AT    = 0.78;             // share of the width
const float WHEEL_R     = 7.0;              // font pixels
const float WHEEL_TURN  = 120.0;            // seconds per revolution
const float TRAIN_EVERY = 40.0;             // seconds between trains
const float TRAIN_SPEED = 110.0;            // font pixels per second
const float CAR         = 20.0;             // font pixels per carriage
const float CARS        = 3.0;
const float TAU         = 6.28318;

const int NONE = 0, BACK = 1, FRONT = 2, LIT = 3, UNLIT = 4, BEACON = 5;
const int WHEEL = 6, GONDOLA = 7, TRACK = 8, TRAIN = 9, STRIPE = 10, LAMP = 11;

int gondolaIndex = 0;

float hash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}

int tower(vec2 p, float slotWidth, float minH, float maxH, float seed, bool windows) {
    float slot = floor(p.x / slotWidth);
    float id = slot + seed;
    float width = slotWidth - 1.0 - floor(hash(id) * 3.0);
    float x = p.x - slot * slotWidth - floor(hash(id + 1.0) * (slotWidth - width));
    float height = minH + floor(hash(id + 2.0) * (maxH - minH + 1.0));
    if (x < 0.0 || x >= width) {
        return NONE;
    }

    bool hasAntenna = hash(id + 4.0) > 0.65;
    if (p.y >= height) {
        bool onMast = hasAntenna && x == floor(width / 2.0) && p.y < height + 3.0;
        if (!onMast) {
            return NONE;
        }
        bool blink = fract(iTime / 1.8 + hash(id + 5.0)) < 0.3;
        return p.y == height + 2.0 && blink ? BEACON : (windows ? FRONT : BACK);
    }

    bool stepped = hash(id + 3.0) > 0.55;
    if (stepped && p.y >= height - 2.0 && (x < 1.0 || x >= width - 1.0)) {
        return NONE;
    }

    bool inWindowGrid = mod(x, 2.0) == 1.0 && x < width - 1.0 && mod(p.y, 2.0) == 1.0
        && p.y >= 2.0 && p.y < height - 2.0;
    if (windows && inWindowGrid) {
        float window = id * 31.0 + x * 7.0 + p.y * 13.0;
        float period = 5.0 + hash(window) * 12.0;
        float phase = floor(iTime / period + hash(window + 1.0));
        return hash(window + phase * 3.7) > 0.5 ? LIT : UNLIT;
    }
    return windows ? FRONT : BACK;
}

float segmentDistance(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
    return length(p - a - ab * t);
}

int ferrisWheel(vec2 p, vec2 hub) {
    vec2 d = p - hub;
    float r = length(d);
    float spokes = 8.0;
    float turn = floor(iTime / WHEEL_TURN * 256.0) / 256.0 * TAU;

    for (int k = 0; k < 8; k++) {
        float a = turn + float(k) * TAU / spokes;
        vec2 cabin = floor(hub + WHEEL_R * vec2(cos(a), sin(a)) + 0.5);
        if (p.x >= cabin.x - 1.0 && p.x <= cabin.x && p.y <= cabin.y - 1.0 && p.y >= cabin.y - 2.0) {
            gondolaIndex = k;
            return GONDOLA;
        }
    }

    vec2 foot = vec2(4.0, hub.y);
    bool onLeg = segmentDistance(p, hub, hub - foot) < 0.55
        || segmentDistance(p, hub, hub + vec2(foot.x, -foot.y)) < 0.55;
    if (abs(r - WHEEL_R) < 0.5 || r < 1.0 || onLeg) {
        return WHEEL;
    }

    float sector = TAU / spokes;
    float a = atan(d.y, d.x) - turn;
    float off = mod(a + sector / 2.0, sector) - sector / 2.0;
    if (r < WHEEL_R && abs(r * sin(off)) < 0.5) {
        return WHEEL;
    }
    return NONE;
}

int train(vec2 p, float width) {
    float clock = iTime + TRAIN_EVERY / 2.0;
    float pass = floor(clock / TRAIN_EVERY);
    float since = clock - pass * TRAIN_EVERY;
    bool rightward = mod(pass, 2.0) == 0.0;
    float x = rightward ? p.x : width - p.x;
    float u = since * TRAIN_SPEED - 20.0 - x;
    if (p.y < 1.0 || p.y > 4.0 || u < 0.0 || u >= CARS * (CAR + 1.0)) {
        return NONE;
    }

    float car = floor(u / (CAR + 1.0));
    float c = u - car * (CAR + 1.0);
    if (c >= CAR) {
        return p.y == 2.0 ? TRAIN : NONE;
    }
    if (car == 0.0 && p.y > 2.0 + c) {
        return NONE;
    }
    if (car == 0.0 && c == 0.0 && p.y == 2.0) {
        return LAMP;
    }
    if (p.y == 3.0 && c >= 3.0 && mod(c, 3.0) != 0.0 && c < CAR - 1.0) {
        return STRIPE;
    }
    return TRAIN;
}

int scene(vec2 p, float width) {
    if (p.y < 0.0) {
        return NONE;
    }
    if (p.y == 0.0) {
        return TRACK;
    }

    int t = train(p, width);
    if (t != NONE) {
        return t;
    }

    vec2 hub = vec2(floor(width * WHEEL_AT), WHEEL_R + 1.0);
    int w = ferrisWheel(p, hub);
    if (w != NONE) {
        return w;
    }
    if (abs(p.x - hub.x) <= WHEEL_R + 2.0) {
        return NONE;
    }

    int front = tower(p, 13.0, 3.0, 12.0, 50.0, true);
    if (front != NONE) {
        return front;
    }
    return tower(p + vec2(5.0, 0.0), 9.0, 6.0, 14.0, 0.0, false);
}

vec3 paint(int kind, vec3 bg, vec3 fg, bool light) {
    vec3 gondolas[4] = vec3[4](iPalette[1], iPalette[3], iPalette[2], iPalette[4]);
    if (kind == BACK)    return mix(bg, fg, 0.06);
    if (kind == FRONT)   return mix(bg, fg, 0.13);
    if (kind == UNLIT)   return mix(bg, fg, light ? 0.13 : 0.07);
    if (kind == LIT)     return light ? mix(bg, iPalette[12], 0.35) : mix(bg, iPalette[11], 0.5);
    if (kind == BEACON)  return iPalette[1];
    if (kind == WHEEL)   return mix(bg, fg, 0.22);
    if (kind == GONDOLA) return mix(bg, gondolas[gondolaIndex - gondolaIndex / 4 * 4], 0.7);
    if (kind == TRACK)   return mix(bg, fg, 0.18);
    if (kind == TRAIN)   return mix(bg, fg, 0.45);
    if (kind == STRIPE)  return iCurrentCursorColor.rgb;
    return iPalette[11];
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    if (distance(fragColor.rgb, iBackgroundColor) > THRESHOLD) {
        return;
    }

    vec2 fromTopLeft = fragCoord - ORIGIN;
    float lastRow = floor((iResolution.y - ORIGIN.y) / PIXEL) - 1.0;
    vec2 p = vec2(floor(fromTopLeft.x / PIXEL), lastRow - floor(fromTopLeft.y / PIXEL));
    float width = floor((iResolution.x - ORIGIN.x) / PIXEL);

    int kind = scene(p, width);
    if (kind != NONE) {
        bool light = dot(iBackgroundColor, vec3(0.299, 0.587, 0.114)) > 0.5;
        fragColor.rgb = paint(kind, iBackgroundColor, iForegroundColor, light);
    }
}
