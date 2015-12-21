#version 300 es

precision highp float;

uniform sampler2D s_tex;
uniform float u_columnWidth;
uniform float u_shredderPosition;

in vec2 v_texCoord;
in vec3 v_normal;
in vec2 v_position;
in vec2 v_pieceWidthRange;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 color = texture(s_tex, v_texCoord);
    vec3 normal = normalize(v_normal);
    float alpha = 1.0;
    if (v_position.y <= u_shredderPosition) {
//        float offset = v_position.x - v_pieceWidthRange.x;
//        alpha = 0.4 + offset / ((v_pieceWidthRange.y - v_pieceWidthRange.x) / 2.0);
//        alpha = clamp(0.0, 0.90, alpha);
//        offset = v_pieceWidthRange.y - v_position.x;
//        float alpha2 = 0.4 + offset / ((v_pieceWidthRange.y - v_pieceWidthRange.x) / 2.0);
//        alpha = clamp(0.0, alpha, alpha2);
        float widthHalf = (v_pieceWidthRange.y - v_pieceWidthRange.x) / 2.0;
        float middle = widthHalf + v_pieceWidthRange.x;
        float a = -0.5 / widthHalf / widthHalf;
        float x = v_position.x - middle;
        alpha = a * x * x + 0.9;
    }
    out_color = vec4(color.rgb * alpha, color.a);
}