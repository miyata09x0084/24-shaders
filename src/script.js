import './style.css'
import * as THREE from 'three'
// import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
// import * as dat from 'dat.gui'
import testVertexShader from './shaders/test/vertex.glsl'
import testFragmentShader from './shaders/test/fragment.glsl'

import matcap from '../static/textures/hotspot.png'

var container;
var camera, scene, renderer, clock;
var uniforms;

container = document.getElementById( 'container' );

camera = new THREE.Camera();
camera.position.z = 1;

scene = new THREE.Scene();
clock = new THREE.Clock();

var geometry = new THREE.PlaneBufferGeometry( 2, 2 );

uniforms = {
    time: { type: "f", value: 1.0 },
    matcap: { value: new THREE.TextureLoader().load(matcap) },
    resolution: { type: "v2", value: new THREE.Vector2() },
    mouse: { type: "v2", value: new THREE.Vector2(0, 0) }
};

var material = new THREE.ShaderMaterial( {
    uniforms: uniforms,
    vertexShader: testVertexShader,
    fragmentShader: testFragmentShader
} );

var mesh = new THREE.Mesh( geometry, material );
scene.add( mesh );

renderer = new THREE.WebGLRenderer();
renderer.setPixelRatio( window.devicePixelRatio );

container.appendChild( renderer.domElement );

onWindowResize();
window.addEventListener( 'resize', onWindowResize, false );

const mouse = new THREE.Vector2();
window.addEventListener('mousemove', (e) => {
    mouse.x = e.pageX / width - 0.5;
    mouse.y = - e.pageY / height + 0.5;
})  

function onWindowResize( event ) {
    renderer.setSize( window.innerWidth, window.innerHeight );
    uniforms.resolution.value.x = renderer.domElement.width;
    uniforms.resolution.value.y = renderer.domElement.height;
}
    

function render() {

    uniforms.time.value += clock.getDelta();
    if(mouse) {
        uniforms.mouse.value = mouse;    
    }

    renderer.render( scene, camera );

    window.requestAnimationFrame(render);
}

render();