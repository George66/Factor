USING: accessors alien.c-types alien.data calendar combinators images.loader images.loader.gdiplus kernel
locals math math.constants math.matrices multiline opengl opengl.gl3 opengl.capabilities
opengl.shaders opengl.textures sequences timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats ;
QUALIFIED-WITH: alien.c-types c
IN: cube

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 texcoords;
out vec3 texCoords;
uniform mat4 rmatrix;
uniform mat4 tmatrix;
uniform mat4 pmatrix;
void main()
{
gl_Position = pmatrix * tmatrix * rmatrix * vec4(position.x, position.y, position.z, 1.0f);
texCoords = texcoords;
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

! The vocab opengl.textures is outdated!
:: tex-image ( image bitmap -- )
        image image-format :> ( internal-format format type )
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 1 + 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 2 + 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 3 + 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 4 + 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D
        GL_TEXTURE_CUBE_MAP_POSITIVE_X 5 + 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D ;

: make-texture ( image -- id )
    gen-texture [
        GL_TEXTURE_CUBE_MAP swap glBindTexture
        dup bitmap>> tex-image
        GL_TEXTURE_CUBE_MAP glGenerateMipmap
        GL_TEXTURE_CUBE_MAP GL_TEXTURE_MIN_FILTER GL_LINEAR_MIPMAP_LINEAR glTexParameteri
        GL_TEXTURE_CUBE_MAP GL_TEXTURE_MAG_FILTER GL_LINEAR glTexParameteri
        GL_TEXTURE_CUBE_MAP GL_TEXTURE_WRAP_S GL_REPEAT glTexParameteri
        GL_TEXTURE_CUBE_MAP GL_TEXTURE_WRAP_T GL_REPEAT glTexParameteri
        GL_TEXTURE_CUBE_MAP GL_TEXTURE_WRAP_R GL_REPEAT glTexParameteri
        ] keep ;

TUPLE: rotation-world < world
    angle program vertex-buffer texture-buffer index-buffer vertex-array texture ;

: (program) ( -- program )
    vertex-shader fragment-shader <simple-gl-program> ;

: (vertex-buffer) ( -- vertex-buffer )
    {
      1.5  1.5  1.5  ! top right
      1.5 -1.5  1.5  ! bottom right
     -1.5 -1.5  1.5  ! bottom left
     -1.5  1.5  1.5  ! top left
      1.5  1.5 -1.5  ! top right
      1.5 -1.5 -1.5  ! bottom right
     -1.5 -1.5 -1.5  ! bottom left
     -1.5  1.5 -1.5  ! top left
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

: (texture-buffer) ( -- texture-buffer )
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

! The function "with-array-element-buffers" from the vocab "opengl" does not work with VAO! Never unbind element-buffer!    

: (vertex-array) ( vertex-buffer texture-buffer index-buffer -- vertex-array )
   gen-vertex-array [
      [
        GL_ELEMENT_ARRAY_BUFFER swap glBindBuffer

        GL_ARRAY_BUFFER swap
        [
        1 3 GL_FLOAT GL_FALSE c:float heap-size 3 * 0 buffer-offset glVertexAttribPointer
        ] with-gl-buffer

        GL_ARRAY_BUFFER swap
        [
        0 3 GL_FLOAT GL_FALSE c:float heap-size 3 * 0 buffer-offset glVertexAttribPointer
        ] with-gl-buffer

        0 glEnableVertexAttribArray
        1 glEnableVertexAttribArray
     ]
     with-vertex-array ] keep  ;

: (r-matrix) ( angle -- matrix )
     360.0 / 2 * pi *
     { 1.0 0.0 0.0 1.0 } swap rotation-matrix4
     { 0 1 2 3 } swap cols concat
     c:float >c-array ;

: (t-matrix) ( -- matrix )
     { 0.0 0.0 -10.0 } translation-matrix4
     { 0 1 2 3 } swap cols concat
     c:float >c-array ;

: (p-matrix) ( -- matrix )
     { 0.04 0.04 } 0.1 500.0 frustum-matrix4
     { 0 1 2 3 } swap cols concat
     c:float >c-array ;

: increase ( angle -- angle )
    1.0 + dup 360.0 > [ 360.0 - ] when ;

M: rotation-world begin-world
    "3.3" require-gl-version
    GL_DEPTH_TEST glEnable
    1.0 1.0 1.0 1.0 glClearColor
    0.0 >>angle
    (program) >>program
    (vertex-buffer) >>vertex-buffer
    (texture-buffer) >>texture-buffer
    (index-buffer) >>index-buffer
    dup
    [ vertex-buffer>> ] [ texture-buffer>> ] [ index-buffer>> ] tri
    (vertex-array) >>vertex-array
    "vocab:cube/1.jpg" load-image make-texture >>texture
    [ [ increase ] change-angle relayout ] curry 25 milliseconds every drop
 ;

M: rotation-world end-world
    {
        [ program>> [ delete-gl-program ] when* ]
        [ vertex-buffer>> [ delete-gl-buffer ] when* ]
        [ texture-buffer>> [ delete-gl-buffer ] when* ]
        [ index-buffer>> [ delete-gl-buffer ] when* ]
        [ vertex-array>> [ delete-vertex-array ] when* ]
        [ texture>> [ delete-texture ] when* ]
    } cleave ;

M: rotation-world draw-world*
      GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT bitor glClear
      dup
      GL_TEXTURE_CUBE_MAP swap texture>> glBindTexture
      dup
      vertex-array>>
        [
        dup
        program>>
           [

            [ "tmatrix" glGetUniformLocation (t-matrix) 1 GL_FALSE rot glUniformMatrix4fv ] keep
            [ "pmatrix" glGetUniformLocation (p-matrix) 1 GL_FALSE rot glUniformMatrix4fv ] keep
             "rmatrix" glGetUniformLocation swap angle>> (r-matrix) 1 GL_FALSE rot glUniformMatrix4fv

              GL_TRIANGLES 24 GL_UNSIGNED_INT 0 buffer-offset glDrawElements
           ] with-gl-program
       ] with-vertex-array
;

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
