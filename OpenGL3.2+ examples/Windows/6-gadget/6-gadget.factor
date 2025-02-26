USING: accessors alien.c-types alien.data arrays colors combinators images.loader
kernel literals locals math math.functions math.matrices multiline namespaces
opengl opengl.gl opengl.capabilities opengl.shaders opengl.textures sequences
ui ui.gadgets ui.gadgets.tracks ui.gadgets.worlds ui.pens.solid ui.render ;
! To deploy the vocab add the following line and change path "vocab:6-gadget/1.jpg" to "./1.jpg" (and put 1.jpg to ./ after deploying)
! USE: images.loader.gdiplus
QUALIFIED-WITH: alien.c-types c
IN: 6-gadget

STRING: vertex-shader
#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoords;
out vec2 texCoords;
uniform mat4 matrix;
void main()
{
gl_Position = matrix * vec4(position.x, position.y, position.z, 1.0);
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

CONSTANT: distance -4.0
CONSTANT: near 0.1
CONSTANT: far  100
CONSTANT: FOV $[ 2.0 sqrt 1 + ]   ! cotangens(pi/8) calculated at compile time

! Vocab "opengl.textures" is out of date !
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
       ] keep ;

TUPLE: OpenGL-gadget < gadget pt-matrix t-matrix
      program vertex-buffer texture-buffer index-buffer vertex-array texture ;

: <OpenGL-gadget> ( -- gadget ) ! Do not specify the dimensions of the gadget here.
      OpenGL-gadget new
      t >>clipped? ; ! Otherwise the gadget will be drawn on top of the others

M: OpenGL-gadget pref-dim* drop { 400 400 } ; ! Specify the dimensions of the gadget here

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

! Function "with-array-element-buffers" from vocab "opengl" does not work with VAO! Never unbind element-buffers!

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

: (t-matrix) ( -- matrix )
      0.0 0.0 distance 3array translation-matrix4 ;

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

: (p-matrix) ( xy-dim -- matrix )
       near far perspective-matrix ;

M: OpenGL-gadget graft*
      dup
      find-gl-context
      (program) >>program
      (vertex-buffer) >>vertex-buffer
      (texture-buffer) >>texture-buffer
      (index-buffer) >>index-buffer
      (t-matrix) >>t-matrix
      dup
      [ vertex-buffer>> ] [ texture-buffer>> ] [ index-buffer>> ] tri
      (vertex-array) >>vertex-array
      "vocab:6-gadget/1.jpg" load-image make-texture >>texture
      drop ;

M: OpenGL-gadget layout*  ! Do not set glviewport here.
      dup
      [ dim>> (p-matrix) ] [ t-matrix>> ] bi m. >>pt-matrix
      drop ;

M: OpenGL-gadget ungraft*
      dup
      find-gl-context
     {
      [ program>> [ delete-gl-program ] when* ]
      [ vertex-buffer>> [ delete-gl-buffer ] when* ]
      [ texture-buffer>> [ delete-gl-buffer ] when* ]
      [ index-buffer>> [ delete-gl-buffer ] when* ]
      [ vertex-array>> [ delete-vertex-array ] when* ]
      [ texture>> [ delete-texture ] when* ]
     } cleave ;

M:: OpenGL-gadget draw-gadget* ( gadget -- )

       gadget parents last :> world
       world dim>> second  :> height
       origin get first :> a          ! SYMBOL: origin defined in vocab "ui.render"
       origin get second gadget dim>> second + :> c
       height c - :> b
       { a b } gadget dim>> gl-viewport

       GL_DEPTH_TEST glEnable
       0.0 1.0 0.0 1.0 glClearColor
       GL_DEPTH_BUFFER_BIT glClear
       GL_COLOR_BUFFER_BIT glClear

       GL_TEXTURE_2D gadget texture>> glBindTexture
       gadget
       vertex-array>>
         [
         gadget
         program>>
           [
             "matrix" glGetUniformLocation
              gadget pt-matrix>>
              { 0 1 2 3 } swap cols concat c:float >c-array
              1 GL_FALSE rot glUniformMatrix4fv
              GL_TRIANGLES 6 GL_UNSIGNED_INT 0 buffer-offset glDrawElements
          ] with-gl-program
        ] with-vertex-array

        { 0 0 } world dim>> gl-viewport
        GL_DEPTH_TEST glDisable ;       ! Don't forget to do this

TUPLE: world-3.3 < world ;

M: world-3.3 begin-world
      "3.3" require-gl-version
    !   GL_DEPTH_TEST glEnable   Don't do this here or Factor's native gadgets won't be visible
       drop ;

: foo  ( -- track )     ! Our OpenGL-gadget between two Factor's native gadgets
       horizontal <track> { 10 0 } >>gap 0.5 >>align 0 >>fill
       gadget new { 400 400 } >>dim 0 0 1 1 <rgba> <solid> >>interior 1 track-add
       <OpenGL-gadget> 1 track-add
       gadget new { 400 400 } >>dim 0 0 1 1 <rgba> <solid> >>interior 1 track-add ;

MAIN-WINDOW: gadget-window {
      { world-class world-3.3 }
      { title "OpenGL-gadget" }
      } foo >>gadgets ;
