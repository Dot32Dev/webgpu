// Get the canvas size
@group(0) @binding(0) var<uniform> canvas: vec2f;

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
	let uv = (in.clip_position.xy*2.0 - canvas)/canvas;

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
		
		// colour = vec3f(i)/80.0;

		if distance_to_object < 0.001 {
			colour = (1.0 - i/80.0) * vec3f(1.0, 0.2, 0.1);
			break;
		}
		if distance_travelled > 100 {
			colour = vec3f(0.1);
			break;
		}
	}
	// colour = vec3f(distance_travelled/5.0);
	return vec4f(colour, 1.0);
}

fn map(point: vec3f) -> f32 {
	return min(min(min(min(min(sdCircle(point, 1.0), sdCircle(point - vec3f(0.0, -1.0, 0.0), 0.7)), sdVerticalCapsule(point - vec3f(-1.2, 0.0, 0.0), 1.0, 0.3)), sdVerticalCapsule(point - vec3f(1.2, 0.0, 0.0), 1.0, 0.3)), sdVerticalCapsule(point - vec3f(0.4, 0.6, 0.0), 1.0, 0.3)), sdVerticalCapsule(point - vec3f(-0.4, 0.6, 0.0), 1.0, 0.3));
}

// float sdVerticalCapsule( vec3 p, float h, float r )
// {
//   p.y -= clamp( p.y, 0.0, h );
//   return length( p ) - r;
// }
fn sdCircle(point: vec3f, radius: f32) -> f32 {
	return length(point) - radius;
}

fn sdVerticalCapsule(point_immutable: vec3f, height: f32, radius: f32) -> f32 {
	var point = point_immutable;
	point.y -= clamp(point.y, 0.0, height);
	return length(point) - radius;
}