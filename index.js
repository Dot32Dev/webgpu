
// Download the shader
const response = await fetch("/shader.wgsl");
const shaderData = await response.text();

// Get the canvas
const canvas = document.querySelector("canvas");

// Throw error when attempting to run from a browser that doesn't support WebGPU
if (!navigator.gpu) {
    throw new Error("WebGPU not supported on this browser.");
}

// Get the GPU I think
const adapter = await navigator.gpu.requestAdapter();
if (!adapter) {
    // This might happen if the users browser supports WebGPU but their GPU can't support all of its features
    throw new Error("No appropriate GPUAdapter found.");
}

// Get the real GPU or something
const device = await adapter.requestDevice();

// Get the canvas and enable WebGPU on it, 
// for example, getting a WebGL context would instead get a WebGL context 🤯
const context = canvas.getContext("webgpu");
// Get the GPU's prefered texture format 
const canvasFormat = navigator.gpu.getPreferredCanvasFormat();
// Here we pass in the GPU device and the texture format to the canvas's WebGPU context
context.configure({
  device: device,
  format: canvasFormat,
})

// This is a typed array, which lets us better control what we're sending to the GPU
const vertices = new Float32Array([
    // This is a square with two triangles
    -1.0, -1.0, // Triangle 1
     1.0, -1.0,
     1.0,  1.0,

    -1.0, -1.0, // Triangle 2
     1.0,  1.0,
    -1.0,  1.0,
]);

// This moves our vertices array to the GPU 
const vertexBuffer = device.createBuffer({
    // The label is optional
    label: "Vertices",
    size: vertices.byteLength,
    // We specify that we want to use it as our vertex data, and that we want to copy data into it
    usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
});

// Move our vertices array into the vertex buffer on the GPU
device.queue.writeBuffer(vertexBuffer, /*bufferOffset=*/0, vertices);

// We tell da vertex buffer how to vertex buffer
const vertexBufferLayout = {
    // Number of bytes to skip forward when the GPU wants the next vertex
    // A 32-bit float is 4 bytes, so two floats is 8 bytes
    arrayStride: 8,
    // Attributes are the individual pieces of information encoded into each vertex
    attributes: [{
        // Two 32bit floats
        format: "float32x2",
        // How many bytes into the vertex the attribute starts. As this is the first and only attribute, it is 0
        offset: 0,
        // A number from 0 to 15 that must be unique for every attribute
        // Does this mean you can only have 15 attributes?
        shaderLocation: 0,
    }],
};

// Define the shader
const shaderModule = device.createShaderModule({
    label: "Shader",
    code: shaderData,
});

// "The render pipeline controls how geometry is drawn, including things like which 
// shaders are used, how to interpret data in vertex buffers, which kind of geometry 
// should be rendered (lines, points, triangles...), and more!"
const pipeline = device.createRenderPipeline({
    label: "Pipeline",
    // Describes what kind of input other than vertex we need. Because we only have vertices we can use auto
    layout: "auto",
    vertex: {
        // The shader module we defined which includes vert and frag shaders
        module: shaderModule,
        entryPoint: "vs_main",
        buffers: [vertexBufferLayout]
    },
    fragment: {
        module: shaderModule,
        entryPoint: "fs_main",
        targets: [{
            format: canvasFormat
        }]
    }
  });

// We use this to give the GPU instructions
const encoder = device.createCommandEncoder();

// In order to use the GPU for rendering, we must tell it that we want to render, which we do by defining a render pass
const pass = encoder.beginRenderPass({
    // Each attachment is a texture the GPU gives information to
    // Advanced use cases might involve drawing to multiple textures (attachments), for example a depth buffer
    // Here we just define one for colour
    colorAttachments: [{
        // The .getCurrentTexture() gets the texture from our canvas context, and turns it into a view
        // .createView() with no arguments assumes you want to use the entire texture
        view: context.getCurrentTexture().createView(),
        // Clear the screen when the render pass starts
        loadOp: "clear",
        // Optional parameter to set the clear colour, defaults to black
        clearValue: { r: 0, g: 0, b: 0.4, a: 1 },
        // Store results from drawing into the texture (duh?)
        storeOp: "store",
    }]
});
// Render instructions go here

pass.setPipeline(pipeline);
pass.setVertexBuffer(0, vertexBuffer);
pass.draw(vertices.length / 2); // 6 vertices

// End the render pass
pass.end();

// The render pass doesn't actually run the thing on the GPU, just stores the instructions we want to do
// To actually run it we need the following code
// This is an "opaque handle" to the recorded commands
const commandBuffer = encoder.finish();
// Add all the GPU instructions onto the GPU's intruction queue!
device.queue.submit([commandBuffer]);
