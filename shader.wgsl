struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
};

@vertex
fn vertexMain(@location(0) pos: vec2f) -> VertexOutput {
	// return vec4f(pos.x, pos.y, 0, 1);
	// return vec4f(pos, 0, 1);

	var out: VertexOutput;
	out.clip_position = vec4<f32>(pos, 0, 1);
	return out;
}

@fragment
fn fragmentMain(in: VertexOutput) -> @location(0) vec4f {
	// let x = (in.clip_position.x*2.0 - 512)/512.0;
	// let y = (in.clip_position.y*2.0 - 512)/512.0;
	let uv = (in.clip_position.xy*2.0 - 512)/512.0;
	return vec4f(uv, 0., 1);
}