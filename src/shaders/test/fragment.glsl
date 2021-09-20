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

// //行列による回転
// vec3 rotate(vec3 p,float radX,float radY,float radZ){
//     mat3 mx = mat3(
//         1.0,0.0,0.0,
//         0.0,cos(radX),-sin(radX),
//         0.0,sin(radX),cos(radX)
//     );
//     mat3 my = mat3(
//         cos(radY),0.0,sin(radY),
//         0.0,1.0,0.0,
//         -sin(radY),0.0,cos(radY)
//     );
//     mat3 mz = mat3(
//         cos(radZ),-sin(radZ),0.0,
//         sin(radZ),cos(radZ),0.0,
//         0.0,0.0,1.0
//     );
//     return mx * my * mz * p;
// }

// //球形に座標アニメーション
// vec3 sphericalPolarCoord(float radius, float rad1, float rad2){
//     return vec3(
//         sin(rad1) * cos(rad2) * radius,
//         sin(rad1) * sin(rad2) * radius,
//         cos(rad1) * radius
//     );
// }

// //スムーズに結合するための補間
// float smoothMin(float d1, float d2, float k){
//     float h = exp(-k * d1) + exp(-k * d2);
//     return -log(h) / k;
// }

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

float sdf(vec3 p){
    vec3 p1 = rotate(p, vec3(1.), time/2.);
    float box = smin(sdBox(p1, vec3(0.25)), distanceFuncSphere(p, 0.3), 0.3);
    float realsphere = distanceFuncSphere(p1, 0.3);
    float final = mix(box, realsphere, progress); // Morphing
    float sphere = distanceFuncSphere(p - vec3(mouse * resolution.zw * 3.5, 0.0), 0.2);
    return smin(final, sphere, 0.4);
}

// //距離関数
// float distanceFunc(vec3 p){
//     float n1 = snoise(p * 0.3 + time / 100.0);

//     vec3 p1 = rotate(p,radians(time),radians(time),radians(time));
//     vec3 s1 = sphericalPolarCoord(3.0,radians(time),radians(-time * 2.0));
//     float d1 = distanceFuncSphere(p1+s1,1.25) - n1 * 0.25;

//     vec3 p2 = rotate(p,radians(time),radians(time),radians(time));
//     vec3 s2 = sphericalPolarCoord(3.0,radians(-time * 5.0),radians(-time));
//     float d2 = distanceFuncSphere(p2+s2,1.25) - n1 * 0.25;

//     vec3 p3 = rotate(p,radians(time),radians(time),radians(time));
//     vec3 s3 = sphericalPolarCoord(3.0,radians(time),radians(-time * 5.0));
//     float d3 = distanceFuncSphere(p3+s3,1.25) - n1 * 0.25;

//     return smoothMin(smoothMin(d1,d2,2.0),d3,2.0);
// }

//distanceFunc
vec3 getNormal(vec3 p)
{
    float d = 0.0001; // dy dx
    return normalize(vec3(
        sdf(p + vec3(d, 0.0, 0.0)) - sdf(p + vec3(-d, 0.0, 0.0)),
        sdf(p + vec3(0.0, d, 0.0)) - sdf(p + vec3(0.0, -d, 0.0)),
        sdf(p + vec3(0.0, 0.0, d)) - sdf(p + vec3(0.0, 0.0, -d))
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
    vec3 backGrd = mix(vec3(0.3), vec3(0.0), dist);

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
        float h = sdf(pos);
        if(h<0.001 || t>tMax) break;
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

        float fresnel = pow(1. + dot(ray, normal), 3.);
        // color = vec3(fresnel);

        color = mix(color, backGrd, fresnel);
    }

    gl_FragColor = vec4(color, 1.);
    // gl_FragColor = vec4(backGrd, 1.);
    // {
    //     float n = snoise(rPos * 0.2 + time / 100.0);
    //     vec3 p = rotate(rPos,radians(time * -2.0),radians(time * 2.0),radians(time * -2.0));
    //     float d = distanceFuncSphere(p,1.6) - n;

    //     if(d > 2.0){
    //         gl_FragColor = vec4(hsv(dot(normal,cUp) * 0.8 + time / 200.0, 0.2, dot(normal,cUp) * 0.6 + 0.6), 1.0);
    //     }else if(d < 2.0 && d > 1.0){
    //         gl_FragColor = vec4(hsv(dot(normal,cUp) * 0.1 + time / 100.0, 0.8, dot(normal,cUp) * 0.3 + 0.8), 1.0);
    //     }else{
    //         gl_FragColor = vec4(hsv(dot(normal,cUp) * 0.8 + time / 200.0,0.2,dot(normal,cUp) * 0.6 + 0.5), 1.0);
    //     }
    // }else 
    // {
    //     gl_FragColor = vec4(vec3(0.0), 1.0);
    // }
}