USING: accessors alien.c-types alien.data calendar combinators kernel
math math.constants math.matrices multiline opengl opengl.gl opengl.capabilities
opengl.shaders sequences timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats ;
QUALIFIED-WITH: alien.c-types c
IN: 2-rotation

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
uniform mat4 matrix;
void main()
{
gl_Position = matrix * vec4(position.x, position.y, position.z, 1.0);
}
;

STRING: fragment-shader
#version 330 core
out vec4 color;
void main()
{
color = vec4(0.0f, 0.0f, 1.0f, 1.0f);
}
;

TUPLE: rotation-world < world
    angle program location vertex-buffer index-buffer vertex-array ;

: (program) ( -- program )
     vertex-shader fragment-shader <simple-gl-program> ;

: (vertex-buffer) ( -- vertex-buffer )
    {
      0.5  0.5 0.0  ! top right
      0.5 -0.5 0.0  ! bottom right
     -0.5 -0.5 0.0  ! bottom left
     -0.5  0.5 0.0  ! top left
    }
    c:float >c-array underlying>>
    GL_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

: (index-buffer) ( -- index-buffer )
    {
      0 1 3   ! first triangle
      1 2 3   ! second triangle
    }
    c:uint >c-array underlying>>
    GL_ELEMENT_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

! The function "with-array-element-buffers" from the vocab "opengl" does not work with VAO! Never unbind element-buffer!

: (vertex-array) ( vertex-buffer index-buffer -- vertex-array )
   gen-vertex-array [
      [
        GL_ELEMENT_ARRAY_BUFFER swap glBindBuffer

        GL_ARRAY_BUFFER swap
        [
        0 3 GL_FLOAT GL_FALSE c:float heap-size 3 * 0 buffer-offset glVertexAttribPointer
        ] with-gl-buffer

        0 glEnableVertexAttribArray
      ]
      with-vertex-array ] keep  ;

: (matrix) ( angle -- matrix )
     360.0 / 2 * pi *
     { 0.0 0.0 1.0 1.0 } swap rotation-matrix4
     { 0 1 2 3 } swap cols concat
     c:float >c-array ;

: increase ( angle -- angle )
     1.0 + dup 360.0 > [ 360.0 - ] when ;

M: rotation-world begin-world
     "3.3" require-gl-version
     1.0 1.0 1.0 1.0 glClearColor
     0.0 >>angle
     (program) [ >>program ] keep
     "matrix" glGetUniformLocation >>location
     (vertex-buffer) >>vertex-buffer
     (index-buffer) >>index-buffer
     dup
     [ vertex-buffer>> ] [ index-buffer>> ] bi
     (vertex-array) >>vertex-array
     [ [ increase ] change-angle relayout ] curry 25 milliseconds every drop ;

M: rotation-world end-world
    {
      [ program>> [ delete-gl-program ] when* ]
      [ vertex-buffer>> [ delete-gl-buffer ] when* ]
      [ index-buffer>> [ delete-gl-buffer ] when* ]
      [ vertex-array>> [ delete-vertex-array ] when* ]
    } cleave ;

M: rotation-world draw-world*
    GL_COLOR_BUFFER_BIT  glClear
    dup
    vertex-array>>
      [
      dup
      program>>
         [
         swap
         [ location>> ] [ angle>> ] bi (matrix)
         1 GL_FALSE rot glUniformMatrix4fv
         GL_TRIANGLES 6 GL_UNSIGNED_INT 0 buffer-offset glDrawElements drop
         ] with-gl-program
      ] with-vertex-array ;

MAIN-WINDOW: rotation-window {
      { world-class rotation-world }
      { title "Rotation" }
      { pixel-format-attributes {
          windowed
          double-buffered
          T{ depth-bits { value 16 } }
      } }
      { pref-dim { 640 640 } }
    } ;
