USING: accessors alien.c-types alien.data arrays calendar combinators images.loader
kernel literals locals math math.constants math.functions math.matrices multiline
opengl opengl.gl opengl.capabilities opengl.shaders opengl.textures sequences
timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats ;
! To deploy the vocab add the following line and change path "vocab:4-cube/1.jpg" to "./1.jpg" (and put 1.jpg to ./ after deploying)
! USE: images.loader.gdiplus
QUALIFIED-WITH: alien.c-types c
IN: 4-cube

CONSTANT: distance -6.0
CONSTANT: near 0.1
CONSTANT: far  100
CONSTANT: FOV  $[ 2.0 sqrt 1 + ]  ! cotangens(pi/8) calculated at compile time

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
out vec3 texCoords;
uniform mat4 matrix;
void main()
{
gl_Position = matrix * vec4(position.x, position.y, position.z, 1.0f);
texCoords = position;
}
;

STRING: fragment-shader
#version 330 core
in vec3 texCoords;
out vec4 color;
uniform samplerCube ourTexture;
void main()
{
color = texture(ourTexture, texCoords);
}
;

! Vocab "opengl.textures" is out of date !
:: tex-image ( image bitmap -- )
       image image-format :> ( internal-format format type )
       GL_TEXTURE_CUBE_MAP_POSITIVE_X 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D
       GL_TEXTURE_CUBE_MAP_NEGATIVE_X 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D
       GL_TEXTURE_CUBE_MAP_POSITIVE_Y 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D
       GL_TEXTURE_CUBE_MAP_NEGATIVE_Y 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D
       GL_TEXTURE_CUBE_MAP_POSITIVE_Z 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D
       GL_TEXTURE_CUBE_MAP_NEGATIVE_Z 0 internal-format
       image dim>> first2 0
       format type bitmap glTexImage2D ;

: make-texture ( image -- id )
    gen-texture [
       GL_TEXTURE_CUBE_MAP swap glBindTexture
       dup bitmap>> tex-image
       GL_TEXTURE_CUBE_MAP glGenerateMipmap
       GL_TEXTURE_CUBE_MAP GL_TEXTURE_MIN_FILTER GL_LINEAR_MIPMAP_LINEAR glTexParameteri
       GL_TEXTURE_CUBE_MAP GL_TEXTURE_MAG_FILTER GL_LINEAR glTexParameteri
       ] keep ;

TUPLE: cube-world < world
    angle t-matrix pt-matrix program vertex-buffer index-buffer vertex-array texture ;

: (program) ( -- program )
    vertex-shader fragment-shader <simple-gl-program> ;

: (vertex-buffer) ( -- texture-buffer )
      {
        1.0  1.0  1.0  ! top right
        1.0 -1.0  1.0  ! bottom right
       -1.0 -1.0  1.0  ! bottom left
       -1.0  1.0  1.0  ! top left
        1.0  1.0 -1.0  ! top right
        1.0 -1.0 -1.0  ! bottom right
       -1.0 -1.0 -1.0  ! bottom left
       -1.0  1.0 -1.0  ! top left
      }
      c:float >c-array underlying>>
      GL_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

: (index-buffer) ( -- index-buffer )
      {
        0 1 3   ! first triangle
        1 2 3   ! second triangle
        4 5 7
        5 6 7
        0 1 4
        1 4 5
        2 3 7
        2 6 7
      }
      c:uint >c-array underlying>>
      GL_ELEMENT_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

! Function "with-array-element-buffers" from vocab "opengl" does not work with VAO! Never unbind element-buffers!

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

:: perspective-matrix ( xy-dim near far -- matrix )
      xy-dim first2 :> ( x y )
      FOV 640 * x /f :> xf
      FOV 640 * y /f :> yf
      near far + near far - /f :> zf
      2 near far * * near far - /f :> wf
      {
         { xf  0.0  0.0 0.0 }
         { 0.0 yf   0.0 0.0 }
         { 0.0 0.0  zf  wf  }
         { 0.0 0.0 -1.0 0.0 }
      } ;

: (r-matrix) ( angle -- matrix )
     360.0 / 2 * pi *
     { 1.0 0.0 0.0 1.0 } swap rotation-matrix4 ;

: (t-matrix) ( -- matrix )
     0.0 0.0 distance 3array translation-matrix4 ;

: (p-matrix) ( xy-dim -- matrix )
     near far perspective-matrix ;

: increase ( angle -- angle )
     1.0 + dup 360.0 > [ 360.0 - ] when ;

M: cube-world begin-world
     "3.3" require-gl-version
     GL_DEPTH_TEST glEnable
     1.0 1.0 1.0 1.0 glClearColor
     0.0 >>angle
     (program) >>program
     (vertex-buffer) >>vertex-buffer
     (index-buffer) >>index-buffer
     (t-matrix) >>t-matrix
     dup
     [ vertex-buffer>> ] [ index-buffer>> ] bi
     (vertex-array) >>vertex-array
     "vocab:4-cube/1.jpg" load-image make-texture >>texture
     [ [ increase ] change-angle relayout ] curry 25 milliseconds every drop ;

M: cube-world resize-world
     dup
     [ dim>> (p-matrix) ] [ t-matrix>> ] bi m. >>pt-matrix
     dim>> 0 0 rot first2 glViewport ;

M: cube-world end-world
    {
        [ program>> [ delete-gl-program ] when* ]
        [ vertex-buffer>> [ delete-gl-buffer ] when* ]
        [ index-buffer>> [ delete-gl-buffer ] when* ]
        [ vertex-array>> [ delete-vertex-array ] when* ]
        [ texture>> [ delete-texture ] when* ]
    } cleave ;

M: cube-world draw-world*
      GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT bitor glClear
      dup
      GL_TEXTURE_CUBE_MAP swap texture>> glBindTexture
      dup
      vertex-array>>
        [
        dup
        program>>
           [
             "matrix" glGetUniformLocation
              swap [ pt-matrix>> ] [ angle>> (r-matrix) ] bi m.
              { 0 1 2 3 } swap cols concat c:float >c-array
              1 GL_FALSE rot glUniformMatrix4fv

              GL_TRIANGLES 24 GL_UNSIGNED_INT 0 buffer-offset glDrawElements
           ] with-gl-program
       ] with-vertex-array ;

MAIN-WINDOW: cube-window {
        { world-class cube-world }
        { title "Cube" }
        { pixel-format-attributes {
            windowed
            double-buffered
            T{ depth-bits { value 16 } }
        } }
        { pref-dim { 640 640 } }
    } ;
