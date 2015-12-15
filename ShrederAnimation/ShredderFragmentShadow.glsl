#version 300 es

precision highp float;

uniform sampler2D s_tex;
uniform float u_columnWidth;

in vec2 v_texCoord;
in vec3 v_normal;
in vec2 v_position;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 color = texture(s_tex, v_texCoord);
    vec3 normal = normalize(v_normal);
    float offset = gl_FragCoord.x - v_position.x;
    float alpha = offset / u_columnWidth;
    out_color = vec4(color.rgb,  color.a);
}