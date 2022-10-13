USING: accessors alien.c-types alien.data combinators kernel math
multiline opengl opengl.gl3 opengl.capabilities opengl.shaders
ui ui.gadgets.worlds ui.pixel-formats ;
QUALIFIED-WITH: alien.c-types c
IN: rectangle

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
void main()
{
gl_Position = vec4(position.x, position.y, position.z, 1.0);
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

TUPLE: rectangle-world < world
    program vertex-buffer index-buffer vertex-array ;

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

M: rectangle-world begin-world
    "3.3" require-gl-version
    GL_DEPTH_TEST glEnable
    1.0 1.0 1.0 1.0 glClearColor
    (program) >>program
    (vertex-buffer) >>vertex-buffer
    (index-buffer) >>index-buffer
    dup
    [ vertex-buffer>> ] [ index-buffer>> ] bi
    (vertex-array) >>vertex-array
    drop ;

M: rectangle-world end-world
    {
        [ program>> [ delete-gl-program ] when* ]
        [ vertex-buffer>> [ delete-gl-buffer ] when* ]
        [ index-buffer>> [ delete-gl-buffer ] when* ]
        [ vertex-array>> [ delete-vertex-array ] when* ]
    } cleave ;

M: rectangle-world draw-world*
      GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT bitor glClear
      dup
      vertex-array>>
        [
        program>>
           [
           GL_TRIANGLES 6 GL_UNSIGNED_INT 0 buffer-offset glDrawElements drop
           ] with-gl-program
        ] with-vertex-array
;

MAIN-WINDOW: rectangle-window {
        { world-class rectangle-world }
        { title "Rectangle" }
        { pixel-format-attributes {
            windowed
            double-buffered
            T{ depth-bits { value 16 } }
        } }
        { pref-dim { 640 480 } }
    } ;
