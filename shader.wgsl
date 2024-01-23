// Get the canvas size
@group(0) @binding(0) var<uniform> canvas: vec2f;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
};

struct Surface {
	signed_distance: f32,
	colour: vec3f,
}

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
	let aspect_ration = canvas.x / canvas.y;

	// Initialising
	let ray_origin = vec3f(0.0, 0.0, -3.0); // Rays begin 3 units behind the camera on the negative Z axis
	let ray_direction = normalize(vec3(vec2(uv.x*aspect_ration, uv.y), 1)); // Current pixel's ray direction is at the x/y of the UV and pointing forwards, then normalised.
	var distance_travelled = 0.0; // A mutable variable that stores how far the ray has travelled

	// Raymarching
	var colour = vec3f(0.0,0.0,0.0);
	for(var i: f32 = 0; i < 80.0; i+=1) {
		var point = ray_origin + ray_direction * distance_travelled; // Position along the ray
		let surface = map(point); // How far away the nearest object is, and its cololur
		distance_travelled += surface.signed_distance;; // "March" the ray by the distance to the nearest object
		
		// colour = vec3f(i)/80.0;

		if surface.signed_distance < 0.001 {
			// colour = (1.0 - i/80.0) * vec3f(1.0, 0.2, 0.1);
			// colour =  calculate_normal(point);
			colour = (1.0 - i/80.0) * surface.colour;
			// if calculate_normal(point).y > 0.0 {
				colour = colour - min(max(calculate_normal(point).g, 0.0), 0.1);
			// }
			// colour = colour*(0.5 + (1.0 - calculate_normal(point).g)*0.5);
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

fn map(point: vec3f) -> Surface {
	let head = sdCircle(point - vec3f(0.0, -1.0, 0.0), 0.7, vec3f(0.9,0.7,0.6));
	let body = sdCircle(point, 1.0, vec3f(1.0, 0.2, 0.1));

	var q = vec3f(point.xy * rot2D(-0.3), point.z);
	let left_arm = sdVerticalCapsule(q - vec3f(-1.2, 0.0, 0.0), 1.0, 0.3, vec3f(1.0, 0.2, 0.1));
	q = vec3f(point.xy * rot2D(0.3), point.z);
	let right_arm = sdVerticalCapsule(q - vec3f(1.2, 0.0, 0.0), 1.0, 0.3, vec3f(1.0, 0.2, 0.1));
	let arms = min_with_colour(left_arm, right_arm);

	let torso = min_with_colour(arms, body);

	let left_leg = sdVerticalCapsule(point - vec3f(-0.4, 0.6, 0.0), 1.0, 0.3, vec3f(1.0, 0.2, 0.1));
	let right_leg = sdVerticalCapsule(point - vec3f(0.4, 0.6, 0.0), 1.0, 0.3, vec3f(1.0, 0.2, 0.1));
	let legs = min_with_colour(left_leg, right_leg);

	let human = min_with_colour(torso, legs);

	return min_with_colour(head, human);
}

fn calculate_normal(point: vec3f) -> vec3f {
	// I dont understand this shit I just copied from google
	let epsilon = 0.001; // small number
	let centerDistance = map(point).signed_distance;
	let xDistance = map(point + vec3f(epsilon, 0, 0)).signed_distance;
	let yDistance = map(point + vec3f(0, epsilon, 0)).signed_distance;
	let zDistance = map(point + vec3f(0, 0, epsilon)).signed_distance;
	return (vec3f(xDistance, yDistance, zDistance) - centerDistance) / epsilon;
}

fn min_with_colour(object1: Surface, object2: Surface) -> Surface {
	if object2.signed_distance < object1.signed_distance {
		return object2;
	}
	return object1;
}

fn rot2D(angle: f32) -> mat2x2f {
	let s = sin(angle);
	let c = cos(angle);
	return mat2x2f(c, -s, s, c);
}

fn sdCircle(point: vec3f, radius: f32, colour: vec3f) -> Surface {
	return Surface(length(point) - radius, colour);
}

fn sdVerticalCapsule(point_immutable: vec3f, height: f32, radius: f32, colour: vec3f) -> Surface {
	var point = point_immutable;
	point.y -= clamp(point.y, 0.0, height);
	return Surface(length(point) - radius, colour);
}