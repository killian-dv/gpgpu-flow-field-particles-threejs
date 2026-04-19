uniform float uTime;
uniform float uDeltaTime;
uniform sampler2D uBase;

#include ../includes/simplex-noise-4D.glsl;

void main()
{
  float time = uTime * 0.2;
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  vec4 particle = texture(uParticles, uv);
  vec4 base = texture(uBase, uv);

  // dead
  if (particle.a > 1.0) {
    particle.a = mod(particle.a, 1.0);
    particle.xyz = base.xyz;
  } else {
    // alive
    vec3 flowField = vec3(
      simplexNoise4d(vec4(particle.xyz, time)),
      simplexNoise4d(vec4(particle.xyz + 1.0, time)),
      simplexNoise4d(vec4(particle.xyz + 2.0, time))
    );
    flowField = normalize(flowField);
    particle.xyz += flowField * 0.5 * uDeltaTime;

    // decay
    particle.a += 0.3 * uDeltaTime;
  }

  gl_FragColor = particle;
}