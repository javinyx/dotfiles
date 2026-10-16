const float BACKGROUND_TOLERANCE = 0.08;
const float GRAIN_STRENGTH = 0.018;
const float FIBRE_STRENGTH = 0.007;
const float EDGE_STRENGTH = 0.018;

float paperNoise(vec2 position) {
    return fract(sin(dot(position, vec2(12.9898, 78.233))) * 43758.5453);
}

float paperGrain(vec2 coordinate) {
    float fineGrain = paperNoise(floor(coordinate * 0.65)) - 0.5;
    vec2 fibreCell = vec2(floor(coordinate.x / 36.0), floor(coordinate.y / 2.0));
    float horizontalFibre = paperNoise(fibreCell) - 0.5;
    return fineGrain * GRAIN_STRENGTH + horizontalFibre * FIBRE_STRENGTH;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 source = texture(iChannel0, uv);
    float backgroundAmount = 1.0 - smoothstep(
        0.0,
        BACKGROUND_TOLERANCE,
        distance(source.rgb, iBackgroundColor)
    );
    vec2 centred = uv * 2.0 - 1.0;
    float edgeShade = dot(centred, centred) * EDGE_STRENGTH;
    vec3 texturedPaper = source.rgb + vec3(paperGrain(fragCoord) - edgeShade);
    fragColor = vec4(mix(source.rgb, texturedPaper, backgroundAmount), source.a);
}
