struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
};

@vertex
fn vs_main(@location(0) pos: vec2f) -> VertexOutput {
	var out: VertexOutput;
	out.clip_position = vec4<f32>(pos, 0, 1);
	return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4f {
	// Turns pixels coorindate into normalised -1 to 1 space
	let uv = (in.clip_position.xy*2.0 - 512)/512.0;

	// Initialising
	let ray_origin = vec3f(0.0, 0.0, -3.0); // Rays begin 3 units behind the camera on the negative Z axis
	let ray_direction = normalize(vec3(uv, 1)); // Current pixel's ray direction is at the x/y of the UV and pointing forwards, then normalised.
	var distance_travelled = 0.0; // A mutable variable that stores how far the ray has travelled

	// Raymarching
	var colour = vec3f(0.0,0.0,0.0);
	for(var i: f32 = 0; i < 80.0; i+=1) {
		var point = ray_origin + ray_direction * distance_travelled; // Position along the ray
		let distance_to_object = map(point); // How far away the nearest object is
		distance_travelled += distance_to_object; // "March" the ray by that distance
		
		colour = vec3f(i)/80.0;

		if distance_to_object < 0.001 {
			break;
		}
		if distance_travelled > 100 {
			break;
		}
	}
	colour = vec3f(distance_travelled/5.0);
	return vec4f(colour, 1.0);
}

fn map(point: vec3f) -> f32 {
	return min(min(length(point) - 1.0, length(point - vec3f(0.0, 1.5, 0.0)) - 1.3), length(point - vec3f(0.0, -1.0, 0.0)) - 0.7);
}