var THREE = require("three");

var fs = require("fs");
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );

var renderer = new THREE.WebGLRenderer();
renderer.setSize( window.innerWidth, window.innerHeight );

module.exports = {domElement: renderer.domElement};

var geometry = new THREE.SphereGeometry(2, 50, 50, 0);
var attributes = {
  displacement: {
    type: 'f', // a float
    value: [] // an empty array
  }
};
var uniforms = {
  amplitude: {
    type: 'f', // a float
    value: 0 // an empty array
  }
};

var material = new THREE.ShaderMaterial({
  attributes: attributes,
  uniforms: uniforms,
  vertexShader: fs.readFileSync(__dirname + '/vertex_shader.glsl'),
  fragmentShader: fs.readFileSync(__dirname + '/fragment_shader.glsl')
});

var vertices = geometry.vertices;
var values = attributes.displacement.value;
for (var i = 0, _len = vertices.length; i < _len; i++) {
  values.push(Math.random()*10);
}

var cube = new THREE.Mesh(geometry, material);

scene.add(cube);

camera.position.z = 12;

var clock = new THREE.Clock();
animate();

function animate() {
  requestAnimationFrame(animate);
  render();
}

var frame = 0.0;
function render() {

  var time = Date.now() * 0.0002;
  var delta = clock.getDelta();

  uniforms.amplitude.value = Math.sin(frame += delta)*+0.5;
  cube.rotation.x = time * 0.45;
  cube.rotation.y = time * 0.45;


  renderer.render(scene, camera);

}