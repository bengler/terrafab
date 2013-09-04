 // same name and type as VS
 varying vec3 vNormal;
 
 void main() {
 
     vec3 light = vec3(-0.1,-0.1,-0.1);

     // calculate the dot product of
     // the light to the vertex normal
     float dProd = dot(vNormal, light) - 0.2;
   
     // feed into our frag colour
     gl_FragColor = vec4(0.2+dProd, 0.6+dProd, 0.8+dProd, 1);
   
 }