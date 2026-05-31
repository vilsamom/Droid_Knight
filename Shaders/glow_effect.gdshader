shader_type canvas_item;

// --- Flash White (Hurtbox System) ---
instance uniform bool flash_white = false;

// --- First Glowing Color ---
instance uniform vec4 target_color_1 : source_color = vec4(1.0, 0.0, 0.0, 1.0);
instance uniform float glow_intensity_1 : hint_range(0.0, 20.0) = 5.0;
instance uniform float tolerance_1 : hint_range(0.0, 1.0) = 0.05;

// --- Second Glowing Color ---
instance uniform vec4 target_color_2 : source_color = vec4(0.0, 0.0, 1.0, 1.0);
instance uniform float glow_intensity_2 : hint_range(0.0, 20.0) = 5.0;
instance uniform float tolerance_2 : hint_range(0.0, 1.0) = 0.05;

// --- Third Glowing Color ---
instance uniform vec4 target_color_3 : source_color = vec4(0.0, 1.0, 0.0, 1.0);
instance uniform float glow_intensity_3 : hint_range(0.0, 20.0) = 5.0;
instance uniform float tolerance_3 : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    // 1. Get the original pixel from the sprite sheet
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 2. Priority One: If the hurtbox triggers a hit-flash, force flat white
    if (flash_white) {
        COLOR = vec4(1.0, 1.0, 1.0, tex_color.a);
    } 
    // 3. Priority Two: If not flashing from a hit, look for your custom glow colors
    else if (tex_color.a > 0.0) {
        // Calculate distances for both target colors
        float dist_1 = distance(tex_color.rgb, target_color_1.rgb);
        float dist_2 = distance(tex_color.rgb, target_color_2.rgb);
        float dist_3 = distance(tex_color.rgb, target_color_3.rgb);
        
        // Check if pixel matches Color 1
        if (dist_1 <= tolerance_1) {
            COLOR = vec4(tex_color.rgb * glow_intensity_1, tex_color.a);
        } 
        // Check if pixel matches Color 2
        else if (dist_2 <= tolerance_2) {
            COLOR = vec4(tex_color.rgb * glow_intensity_2, tex_color.a);
        } 
        else if (dist_3 <= tolerance_3) {
            COLOR = vec4(tex_color.rgb * glow_intensity_3, tex_color.a);
        } 
        // If it matches neither, draw the regular texture pixel normally
        else {
            COLOR = tex_color;
        }
    } 
    // 4. Fallback for transparent pixels
    else {
        COLOR = tex_color;
    }
}