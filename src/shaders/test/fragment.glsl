precision highp float;

uniform float time;
uniform float progress;
uniform sampler2D matcap;
uniform vec2 mouse;
uniform vec4 resolution;
varying vec2 vUv;
float PI = 3.141592653589793238;
mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}
vec2 getMatcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}
vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//球体の距離関数
float distanceFuncSphere(vec3 p,float r){
    return length(p) - r;
}

//箱の距離関数
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//ランダム生成関数
float rand(vec2 co){
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}
// Value noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( rand( i + vec2(0.0,0.0) ),
                     rand( i + vec2(1.0,0.0) ), u.x),
                mix( rand( i + vec2(0.0,1.0) ),
                     rand( i + vec2(1.0,1.0) ), u.x), u.y);
}

//距離関数
vec2 sdf(vec3 p){
    // vec3 p1 = rotate(p, vec3(1.), time/2.);
    // float num = 0.3 + 0.1*sin(time/3.) + 0.2*cos(time/6.) + 0.05*sin(time);
    float num = 0.2 + 0.1*cos(time/4.) + 0.3*sin(time/7.) + 0.04*(cos(time));
    // float box = smin(sdBox(p1, vec3(0.2)), distanceFuncSphere(p, 0.2), 0.3);

    float realsphere = distanceFuncSphere(p, 0.35);
    // float final = mix(box, realsphere, 0.5 + 0.5 * sin(time/2.)); // Morphing

    for(float i=0.; i<6.; i++){
        float randOffset = noise(vec2(i, 0.));
        float progr = 1. - fract(time/12. + randOffset*4.);
        vec3 pos = vec3(sin(randOffset*2.*PI)*2.5, cos(randOffset*2.*PI), 0.); 
        float gotoCneter = distanceFuncSphere(p - pos*progr, 0.15);
        realsphere = smin(realsphere, gotoCneter, 0.2);
    }

    float mouseSphere = distanceFuncSphere(p - vec3(mouse * resolution.zw * 3.5, 0.0), 0.2 + num*0.5);
    return vec2(smin(realsphere, mouseSphere, 0.4), 0.1);
}

//distanceFunc
vec3 getNormal(vec3 p)
{
    float d = 0.0001; // dy dx
    return normalize(vec3(
        sdf(p + vec3(d, 0.0, 0.0)).x - sdf(p + vec3(-d, 0.0, 0.0)).x,
        sdf(p + vec3(0.0, d, 0.0)).x - sdf(p + vec3(0.0, -d, 0.0)).x,
        sdf(p + vec3(0.0, 0.0, d)).x - sdf(p + vec3(0.0, 0.0, -d)).x
    ));
}

void main( void ) {
    // vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    // vec3 camPos = vec3(0.0, 0.0, 1.0); //Camera Position
    // vec3 camDir = vec3(0.0, 0.0, -1.0); //Camera Front Direction
    // vec3 camUp = vec3(0.0, 1.0, 0.0); //Camera Up Direction
    // vec3 camSide = cross(camDir, camUp); //Camera Side Direction

    // float ta = 1.; //Traget Depth
    // vec3 ray = normalize(camSide * p.x + camUp * p.y + camDir * ta);

    float dist = length(vUv - vec2(0.5));
    vec3 backGrd = mix(vec3(0.3), vec3(0.0), dist); // BackgroundColor

    vec2 newUV = (vUv - vec2(0.5))*resolution.zw + vec2(0.5);
    vec3 camPos = vec3(0., 0., 3.5);
    vec3 ray = normalize(vec3((vUv - vec2(0.5))*resolution.zw, -1));

    float dis = 0.0; //Minimum distance btween the ray and the object
    float rLen = 0.0; //Length to add to the ray
    vec3 rayPos = camPos;
    float t = 0.;
    float tMax = 5.;

    //マーチングループ
    for(int i = 0; i < 256; i++)
    {
        // dis = distanceFunc(rPos);
        // rLen += dis;

        // rPos = cPos + ray * rLen; 
        vec3 pos = camPos + t * ray; //Current Position
        float h = sdf(pos).x;
        if(h<0.0001 || t>tMax) break;
        t += h;
    }

    // vec3 normal = getNormal(rPos);

    vec3 color = backGrd;
    //Collide Check
    if (t < tMax){
        vec3 pos = camPos + t * ray;
        color = vec3(1.);
        vec3 normal = getNormal(pos);
        color = normal;
        float diff = dot(vec3(1.), normal);
        vec2 matcapUV = getMatcap(ray, normal);
        color = vec3(diff);
        color = texture2D(matcap, matcapUV).rgb;

        float fresnel = pow(1. + dot(ray, normal), 10.); // Reflectional effect

        color = mix(color, backGrd, fresnel);
    }

    gl_FragColor = vec4(color, 0.);
}