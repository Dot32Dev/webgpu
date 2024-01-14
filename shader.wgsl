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
	let uv = (in.clip_position.xy*2.0 - 512)/512.0;
	return vec4f(uv, 0., 1);
}