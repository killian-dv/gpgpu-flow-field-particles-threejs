# GPGPU Flow Field Particles — Three.js Journey

Quick recap of the **GPGPU Flow Field Particles** lesson from [Three.js Journey](https://threejs-journey.com/) by Bruno Simon.

## What this project covers

This project shows how to animate a large particle cloud by moving simulation work to the GPU with `GPUComputationRenderer`. Instead of updating every particle on the CPU, particle positions are stored in a floating-point texture and updated each frame in a dedicated simulation shader. A flow field generated from 4D simplex noise drives motion, while each particle also has a lifecycle value in alpha to respawn and keep the system alive.

- **GPGPU simulation** using `GPUComputationRenderer` to update particle state inside a texture each frame.
- A **simulation fragment shader** (`src/shaders/gpgpu/particles.glsl`) that reads previous particle data, applies flow-field velocity, and writes the next state.
- A render pipeline with **`THREE.Points` + `ShaderMaterial`** where the vertex shader samples the simulation texture and places each point in world space.
- A **UV lookup attribute** (`aParticlesUv`) that maps each rendered particle to one pixel in the simulation texture.
- Per-particle **lifecycle** encoded in alpha (`particle.a`) to control birth/death and respawn from base model positions.
- **lil-gui controls** for artistic tuning (`uFlowFieldInfluence`, `uFlowFieldStrength`, `uFlowFieldFrequency`, particle size, clear color).

## What I built

- Loaded `model.glb` with `GLTFLoader` and `DRACOLoader`, then used the first mesh geometry as the particle spawn source.
- Computed a square simulation resolution with `Math.ceil(Math.sqrt(count))` so every vertex can be stored in the compute texture.
- Filled an initial data texture where:
  - `rgb` = base position from model vertices
  - `a` = random lifecycle seed per particle
- Added a compute variable (`uParticles`) and wired self-dependency so each frame reads the previous frame state.
- Sent simulation uniforms for time integration and flow behavior: `uTime`, `uDeltaTime`, `uBase`, `uFlowFieldInfluence`, `uFlowFieldStrength`, `uFlowFieldFrequency`.
- Built a render geometry with:
  - `aParticlesUv` for texture fetch coordinates
  - `aColor` from mesh vertex colors
  - `aSize` random multiplier for point-size variation
- In the render vertex shader, sampled `uParticlesTexture` to get final positions and scaled `gl_PointSize` by resolution and perspective.
- In the render fragment shader, shaped points as circles via `gl_PointCoord`, then applied Three.js tone mapping and color space includes.

## What I learned

### 1) Why GPGPU is useful for particles

- Updating thousands of particles on the CPU quickly becomes expensive.
- Storing particle state in a texture and updating it in a shader lets the GPU handle massively parallel work.
- `GPUComputationRenderer` abstracts framebuffer ping-pong so the simulation loop is practical in Three.js.

### 2) How to encode particle state in textures

- A single RGBA texel can carry full state:
  - `x, y, z` for position
  - `a` for age/lifecycle
- The draw geometry only needs a UV-to-texel mapping (`aParticlesUv`) to fetch the current state.
- This separates **simulation data layout** from **render geometry layout**.

### 3) Flow field motion with simplex noise

- 4D simplex noise (`xyz + time`) gives smooth, evolving vector fields.
- Sampling noise 3 times (with offsets) creates a 3D direction vector, then normalizing gives stable velocity direction.
- Influence + smoothstep remapping helps control where/when the flow force is strong.

### 4) Stable motion with delta time

- Multiplying velocity by `uDeltaTime` keeps movement framerate-independent.
- This is essential in shader simulations to avoid speed changes between machines.

### 5) Particle lifecycle and respawn logic

- Alpha acts as age; particles increase age over time.
- When age exceeds a threshold, the particle respawns at its base position from `uBase` and age wraps with `mod`.
- This creates a continuous loop without allocating or destroying particles.

### 6) Rendering details that matter

- `gl_PointSize` should include both viewport scaling (`uResolution.y`) and perspective compensation (`1.0 / -viewPosition.z`).
- Circular sprites from `gl_PointCoord` avoid square artifacts.
- Keeping simulation and rendering shaders separate makes the system easier to reason about and tune.

## Run the project

```bash
npm install
npm run dev
```

## Credits

Part of the **Three.js Journey** course by Bruno Simon.
