uniform float amplitude;
attribute float displacement;

// create a shared variable for the
// VS and FS containing the normal
varying vec3 vNormal;

void main() {

    // set the vNormal value with
    // the attribute value passed
    // in by Three.js

    vNormal = normal;
  
    // push the displacement into the three
    // slots of a 3D vector so it can be
    // used in operations with other 3D
    // vectors like positions and normals
    vec3 newPosition = position + 
                       normal * 
                       vec3(displacement) * amplitude;

    gl_Position = projectionMatrix *
                  modelViewMatrix *
                  vec4(newPosition,1.0);
}