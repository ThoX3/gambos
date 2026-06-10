shader_type canvas_item;

uniform float speed = 0.5;
uniform float line_width = 0.15;
uniform float angle = 0.785398; // 45 degrees in radians
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform bool active = false; // Toggle the sweep

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (!active) {
        COLOR = tex_color;
    } else {
        // Rotate UVs for the diagonal sweep
        float s = sin(angle);
        float c = cos(angle);
        vec2 rotated_uv = vec2(
            UV.x * c - UV.y * s,
            UV.x * s + UV.y * c
        );
        
        // Calculate the sweep position over time
        float sweep_pos = fract(TIME * speed);
        // Map sweep_pos from [0, 1] to [-line_width, 1.0 + line_width] to ensure it passes completely across
        sweep_pos = -line_width + sweep_pos * (1.0 + line_width * 2.0);
        
        // Create the shiny line
        float dist = abs(rotated_uv.x - sweep_pos);
        float intensity = 1.0 - smoothstep(0.0, line_width, dist);
        
        vec4 final_color = shine_color;
        final_color.a *= intensity;
        
        COLOR = final_color;
    }
}
