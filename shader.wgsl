@vertex
fn vertexMain(@location(0) pos: vec2f) -> @builtin(position) vec4f {
	// return vec4f(pos.x, pos.y, 0, 1);
	return vec4f(pos, 0, 1);
}

@fragment
fn fragmentMain() -> @location(0) vec4f {
	return vec4f(1.0, 0.3, 0.2, 1);
}