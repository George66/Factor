USING: accessors alien.c-types alien.data calendar combinators images.loader kernel
locals math math.constants math.matrices multiline opengl opengl.gl3 opengl.capabilities
opengl.shaders opengl.textures sequences timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats
images.loader.gdiplus ;
QUALIFIED-WITH: alien.c-types c
IN: texture

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoords;
out vec2 texCoords;
void main()
{
gl_Position = vec4(position.x, position.y, position.z, 1.0);
texCoords = texcoords;
}
;

STRING: fragment-shader
#version 330 core
in vec2 texCoords;
out vec4 color;
uniform sampler2D ourTexture;
void main()
{
color = texture(ourTexture, texCoords);
}
;

! The vocab opengl.textures is outdated!
:: tex-image ( image bitmap -- )
        image image-format :> ( internal-format format type )
        GL_TEXTURE_2D 0 internal-format
        image dim>> first2 0
        format type bitmap glTexImage2D ;

: make-texture ( image -- id )
    gen-texture [
        GL_TEXTURE_2D swap glBindTexture
        dup bitmap>> tex-image
        GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_LINEAR glTexParameteri
        GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri
        GL_TEXTURE_2D GL_TEXTURE_WRAP_S GL_REPEAT glTexParameteri
        GL_TEXTURE_2D GL_TEXTURE_WRAP_T GL_REPEAT glTexParameteri
        ] keep ;

TUPLE: texture-world < world
    program vertex-buffer texture-buffer index-buffer vertex-array texture ;

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

: (texture-buffer) ( -- texture-buffer )
    {
      1.0  1.0   ! top right
      1.0  0.0   ! bottom right
      0.0  0.0   ! bottom left
      0.0  1.0   ! top left
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

: (vertex-array) ( vertex-buffer texture-buffer index-buffer -- vertex-array )
   gen-vertex-array [
      [
        GL_ELEMENT_ARRAY_BUFFER swap glBindBuffer

        GL_ARRAY_BUFFER swap
        [
        1 2 GL_FLOAT GL_FALSE c:float heap-size 2 * 0 buffer-offset glVertexAttribPointer
        ] with-gl-buffer

        GL_ARRAY_BUFFER swap
        [
        0 3 GL_FLOAT GL_FALSE c:float heap-size 3 * 0 buffer-offset glVertexAttribPointer
        ] with-gl-buffer

        0 glEnableVertexAttribArray
        1 glEnableVertexAttribArray
     ]
     with-vertex-array ] keep  ;

M: texture-world begin-world
    "3.3" require-gl-version
    GL_DEPTH_TEST glEnable
    1.0 1.0 1.0 1.0 glClearColor    
    (program) >>program
    (vertex-buffer) >>vertex-buffer
    (texture-buffer) >>texture-buffer
    (index-buffer) >>index-buffer
    dup
    [ vertex-buffer>> ] [ texture-buffer>> ] [ index-buffer>> ] tri
    (vertex-array) >>vertex-array
    "vocab:texture/1.jpg" load-image make-texture >>texture
    drop ;

M: texture-world end-world
    {
        [ program>> [ delete-gl-program ] when* ]
        [ vertex-buffer>> [ delete-gl-buffer ] when* ]
        [ texture-buffer>> [ delete-gl-buffer ] when* ]
        [ index-buffer>> [ delete-gl-buffer ] when* ]
        [ vertex-array>> [ delete-vertex-array ] when* ]
        [ texture>> [ delete-texture ] when* ]
    } cleave ;

M: texture-world draw-world*
      GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT bitor glClear
      dup
      GL_TEXTURE_2D swap texture>> glBindTexture
      dup
      vertex-array>>
        [
        program>>
           [
           GL_TRIANGLES 6 GL_UNSIGNED_INT 0 buffer-offset glDrawElements drop
           ] with-gl-program
        ] with-vertex-array
;

MAIN-WINDOW: texture-window {
        { world-class texture-world }
        { title "Texture" }
        { pixel-format-attributes {
            windowed
            double-buffered
            T{ depth-bits { value 16 } }
        } }
        { pref-dim { 640 640 } }
    } ;
