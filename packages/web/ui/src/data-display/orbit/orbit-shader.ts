import type { KOrbitPalette } from "./orbit-draw.js";

interface ProgramState {
  gl: WebGLRenderingContext;
  program: WebGLProgram;
  uSize: WebGLUniformLocation;
  uOrigin: WebGLUniformLocation;
  uTime: WebGLUniformLocation;
  uShadow: WebGLUniformLocation;
  uBase: WebGLUniformLocation;
  uHighlight: WebGLUniformLocation;
  uRim: WebGLUniformLocation;
}

const states = new WeakMap<HTMLCanvasElement, ProgramState | null>();
const observed = new WeakSet<HTMLCanvasElement>();

const vertexSource = `
attribute vec2 position;
void main() { gl_Position = vec4(position, 0.0, 1.0); }
`;

const fragmentSource = `
precision highp float;
uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uShadow;
uniform vec4 uBase;
uniform vec4 uHighlight;
uniform vec4 uRim;

void main() {
  vec2 localFrag = gl_FragCoord.xy - uOrigin;
  vec2 p = localFrag / uSize * 2.0 - 1.0;
  float radius2 = dot(p, p);
  if (radius2 > 1.0) discard;
  vec3 normal = normalize(vec3(p, sqrt(max(0.0, 1.0 - radius2))));
  float light = max(0.0, dot(normal, normalize(vec3(-0.6, 0.8, 1.1))));
  float angle = uTime * 0.12;
  vec3 surface = vec3(normal.x * cos(angle) + normal.z * sin(angle),
    normal.y, -normal.x * sin(angle) + normal.z * cos(angle));
  float wave = sin(surface.y * 19.0 + sin(surface.x * 8.0 + uTime * 0.12) * 1.8 + surface.z * 4.0);
  float grain = sin(surface.x * 155.0) * sin(surface.y * 155.0) * 0.012;
  float latitude = abs(sin(asin(clamp(surface.y, -1.0, 1.0)) * 12.0));
  float longitude = abs(sin(atan(surface.z, surface.x) * 14.0));
  float grid = (1.0 - smoothstep(0.0, 0.035, min(latitude, longitude))) * 0.055;
  float rim = pow(1.0 - max(normal.z, 0.0), 3.0);
  vec3 bronze = mix(uShadow.rgb * 0.58, uBase.rgb, light);
  bronze += uHighlight.rgb * pow(light, 7.0) * 0.32;
  bronze += vec3(wave * 0.025 + grain + grid);
  bronze += uRim.rgb * rim * 0.42;
  float alpha = uBase.a * (1.0 - smoothstep(0.985, 1.0, sqrt(radius2)));
  gl_FragColor = vec4(bronze * alpha, alpha);
}
`;

export function drawKOrbitCenterShader(
  canvas: HTMLCanvasElement,
  width: number,
  height: number,
  pixelRatio: number,
  center: { x: number; y: number },
  palette: KOrbitPalette,
  time: number,
  radius: number,
  baseColor = palette.primary,
): boolean {
  const state = stateFor(canvas);
  if (!state || state.gl.isContextLost()) return false;
  const { gl } = state;
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.clearColor(0, 0, 0, 0);
  gl.clear(gl.COLOR_BUFFER_BIT);
  gl.useProgram(state.program);
  const diameter = radius * 2 * pixelRatio;
  gl.uniform2f(state.uSize, diameter, diameter);
  gl.uniform2f(
    state.uOrigin,
    center.x * pixelRatio - diameter / 2,
    (height - center.y) * pixelRatio - diameter / 2,
  );
  gl.uniform1f(state.uTime, time);
  const shadow = color(palette.shadow);
  const base = color(baseColor);
  const highlight = color(palette.surface);
  const rim = color(palette.muted);
  if (!shadow || !base || !highlight || !rim) return false;
  gl.uniform4fv(state.uShadow, shadow);
  gl.uniform4fv(state.uBase, base);
  gl.uniform4fv(state.uHighlight, highlight);
  gl.uniform4fv(state.uRim, rim);
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  return gl.getError() === gl.NO_ERROR;
}

function stateFor(canvas: HTMLCanvasElement): ProgramState | null {
  if (!observed.has(canvas)) {
    observed.add(canvas);
    canvas.addEventListener("webglcontextlost", (event) =>
      event.preventDefault(),
    );
    canvas.addEventListener("webglcontextrestored", () =>
      states.delete(canvas),
    );
  }
  const known = states.get(canvas);
  if (known !== undefined) return known;
  try {
    const gl = canvas.getContext("webgl", {
      alpha: true,
      antialias: true,
      premultipliedAlpha: true,
    });
    if (!gl) return remember(canvas, null);
    const vertex = compile(gl, gl.VERTEX_SHADER, vertexSource);
    const fragment = compile(gl, gl.FRAGMENT_SHADER, fragmentSource);
    if (!vertex || !fragment) return remember(canvas, null);
    const program = gl.createProgram();
    if (!program) return remember(canvas, null);
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS))
      return remember(canvas, null);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
      gl.STATIC_DRAW,
    );
    const position = gl.getAttribLocation(program, "position");
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
    gl.disable(gl.BLEND);
    const state: ProgramState = {
      gl,
      program,
      uSize: uniform(gl, program, "uSize"),
      uOrigin: uniform(gl, program, "uOrigin"),
      uTime: uniform(gl, program, "uTime"),
      uShadow: uniform(gl, program, "uShadow"),
      uBase: uniform(gl, program, "uBase"),
      uHighlight: uniform(gl, program, "uHighlight"),
      uRim: uniform(gl, program, "uRim"),
    };
    return remember(canvas, state);
  } catch {
    return remember(canvas, null);
  }
}

function compile(
  gl: WebGLRenderingContext,
  type: number,
  source: string,
): WebGLShader | null {
  const shader = gl.createShader(type);
  if (!shader) return null;
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  return gl.getShaderParameter(shader, gl.COMPILE_STATUS) ? shader : null;
}

function uniform(
  gl: WebGLRenderingContext,
  program: WebGLProgram,
  name: string,
): WebGLUniformLocation {
  const location = gl.getUniformLocation(program, name);
  if (!location) throw new Error(`Missing KOrbit shader uniform ${name}`);
  return location;
}

function remember<T extends ProgramState | null>(
  canvas: HTMLCanvasElement,
  value: T,
): T {
  states.set(canvas, value);
  return value;
}

function color(value: string): Float32Array | null {
  const hex = value.match(/^#([0-9a-f]{6}|[0-9a-f]{8})$/i)?.[1];
  if (hex)
    return new Float32Array([
      parseInt(hex.slice(0, 2), 16) / 255,
      parseInt(hex.slice(2, 4), 16) / 255,
      parseInt(hex.slice(4, 6), 16) / 255,
      hex.length === 8 ? parseInt(hex.slice(6, 8), 16) / 255 : 1,
    ]);
  const rgb = value.match(
    /rgba?\(\s*([\d.]+)[, ]+([\d.]+)[, ]+([\d.]+)(?:\s*[,/]\s*([\d.]+))?/i,
  );
  return rgb
    ? new Float32Array([
        Number(rgb[1]) / 255,
        Number(rgb[2]) / 255,
        Number(rgb[3]) / 255,
        rgb[4] === undefined ? 1 : Number(rgb[4]),
      ])
    : null;
}
