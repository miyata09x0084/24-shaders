import './style.css'
import * as THREE from 'three'
// import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import * as dat from 'dat.gui'
import testVertexShader from './shaders/test/vertex.glsl'
import testFragmentShader from './shaders/test/fragment.glsl'

import matcap from '../static/textures/hotspot.png'

var container;
var camera, scene, renderer, clock;
var imageAspect;

container = document.getElementById( 'container' );

const sizes = {
    width: window.innerWidth,
    height: window.innerHeight
};

camera = new THREE.Camera();
camera.position.z = 1;

scene = new THREE.Scene();
clock = new THREE.Clock();

var geometry = new THREE.PlaneBufferGeometry( 2, 2 );

var material = new THREE.ShaderMaterial( {
    uniforms: {
        time: { type: "f", value: 1.0 },
        progress: { type: "f", value: 0.0 },
        matcap: { value: new THREE.TextureLoader().load(matcap) },
        resolution: { type: "v4", value: new THREE.Vector4() },
        mouse: { type: "v2", value: new THREE.Vector2(0, 0) }
    },
    vertexShader: testVertexShader,
    fragmentShader: testFragmentShader
} );

var mesh = new THREE.Mesh( geometry, material );
scene.add( mesh );  

renderer = new THREE.WebGLRenderer();
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

container.appendChild( renderer.domElement );

onWindowResize();
window.addEventListener( 'resize', onWindowResize, false );

const mouse = new THREE.Vector2();
window.addEventListener('mousemove', (e) => {
    mouse.x = e.pageX / sizes.width - 0.5;
    mouse.y = - e.pageY / sizes.height + 0.5;
})  

var settings = {
    progress: 0,
};
const gui = new dat.GUI();
gui.add(settings, "progress", 0, 1, 0.01);

function onWindowResize( event ) {

    sizes.width = window.innerWidth
    sizes.height = window.innerHeight

    renderer.setSize( sizes.width, sizes.height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio), 2)

    imageAspect = 1;
    let a1; let a2;
    if( sizes.height / sizes.width > imageAspect ){
        a1 = ( sizes.width / sizes.height ) * imageAspect;
        a2 = 1;
    }else{
        a1 = 1;
        a2 = (sizes.height / sizes.width) * imageAspect
    }
    material.uniforms.resolution.value.x = renderer.domElement.width;
    material.uniforms.resolution.value.y = renderer.domElement.height;
    material.uniforms.resolution.value.z = a1;
    material.uniforms.resolution.value.w = a2;
}
    

function render() {

    material.uniforms.time.value += clock.getDelta();

    material.uniforms.progress.value = settings.progress;
    material.uniforms.mouse.value = mouse;    

    renderer.render( scene, camera );

    window.requestAnimationFrame(render);
}

render();