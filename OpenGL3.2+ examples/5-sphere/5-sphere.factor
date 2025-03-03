USING: accessors alien.c-types alien.data arrays calendar combinators images.loader
kernel literals locals math math.constants math.functions math.matrices.simd
math.vectors.simd multiline namespaces opengl opengl.gl opengl.capabilities opengl.shaders
opengl.textures sequences timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats ;
! To deploy the vocab add one of the following lines
! USE: images.loader.gdiplus   ! for Windows
! USE: images.loader.gtk       ! for Linux
! then replace "vocab:5-sphere/1.jpg" with "./1.jpg" (for Windows)
! or with "1.jpg" (for Linux) and put 1.jpg near the executable file after deploying
QUALIFIED-WITH: alien.c-types c
IN: 5-sphere

CONSTANT: N 50                    ! latitude bands number
CONSTANT: M 50                    ! longitude bands number
CONSTANT: distance -9.0
CONSTANT: near 0.1
CONSTANT: far  100
CONSTANT: FOV  $[ pi 8 / ]       ! calculated at compile time
SYMBOL: indexNumber

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

TUPLE: sphere-world < world
    angle t-matrix pt-matrix program vertex-buffer index-buffer vertex-array texture ;

: (program) ( -- program )
    vertex-shader fragment-shader <simple-gl-program> ;

:: triangle ( n m -- n array )
    n pi * N / :> phi
    phi cos :> cosPhi
    phi sin :> sinPhi
    m 2 * pi * M / :> theta
    theta sin :> sinTheta
    theta cos :> cosTheta
    n
    cosTheta sinPhi *
    cosPhi
    sinTheta sinPhi *
    3array ;

: (vertex-buffer) ( -- vertex-buffer )
    N 1 + <iota> [ M 1 + <iota> [ triangle ] map concat nip ] map concat
    c:float >c-array underlying>>
    GL_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

:: triangles ( n m -- n array )
    n M 1 + * m + :> firstIndex
    firstIndex M + 1 + :> secondIndex
    n
    firstIndex secondIndex firstIndex 1 + 3array
    secondIndex secondIndex 1 + firstIndex 1 + 3array
    append ;

: (index-buffer) ( -- index-buffer )
    N <iota> [ M <iota> [ triangles ] map concat nip ] map concat
    dup length indexNumber set
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

:: perspective-matrix ( w h near far FOV -- matrix )
      FOV 2 / tan :> fov
      fov near * w * 640 /f :> right
      fov near * h * 640 /f :> top
      right -1 * :> left
       top  -1 * :> bottom
      { right top left bottom } >float-4 near far frustum-matrix4 ;

: (r-matrix) ( angle -- matrix )
      360.0 / 2 * pi *
      float-4{ 0.0 1.0 0.0 1.0 } swap rotation-matrix4 ;

: (t-matrix) ( -- matrix )
      0.0 0.0 distance 1.0 4array >float-4 translation-matrix4 ;

: (p-matrix) ( xy-dim -- matrix )
     first2 near far FOV perspective-matrix ;

: increase ( angle -- angle )
     1.0 + dup 360.0 > [ 360.0 - ] when ;

M: sphere-world begin-world
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
     "vocab:5-sphere/1.jpg" load-image make-texture >>texture
     [ [ increase ] change-angle relayout ] curry 25 milliseconds every drop ;

M: sphere-world resize-world
     dup
     [ dim>> (p-matrix) ] [ t-matrix>> ] bi m4. >>pt-matrix
     dim>> 0 0 rot first2 glViewport ;

M: sphere-world end-world
    {
        [ program>> [ delete-gl-program ] when* ]
        [ vertex-buffer>> [ delete-gl-buffer ] when* ]
        [ index-buffer>> [ delete-gl-buffer ] when* ]
        [ vertex-array>> [ delete-vertex-array ] when* ]
        [ texture>> [ delete-texture ] when* ]
    } cleave ;

M: sphere-world draw-world*
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
              swap [ pt-matrix>> ] [ angle>> (r-matrix) ] bi m4.
              1 GL_FALSE rot glUniformMatrix4fv
              GL_TRIANGLES indexNumber get GL_UNSIGNED_INT 0 buffer-offset glDrawElements
           ] with-gl-program
       ] with-vertex-array ;

MAIN-WINDOW: sphere-window {
        { world-class sphere-world }
        { title "Sphere" }
        { pixel-format-attributes {
            windowed
            double-buffered
            T{ depth-bits { value 16 } }
        } }
        { pref-dim { 640 640 } }
    } ;
