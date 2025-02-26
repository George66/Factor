USING: accessors alien.c-types alien.data arrays calendar combinators images.loader
kernel literals locals math math.constants math.functions math.matrices multiline
namespaces opengl opengl.gl opengl.capabilities opengl.framebuffers opengl.shaders
opengl.textures sequences timers ui ui.gadgets ui.gadgets.worlds ui.pixel-formats ;
! To deploy the vocab add the following line and change path "vocab:7-transparency/1.jpg" to "./1.jpg" (and put 1.jpg to ./ after deploying)
! USE: images.loader.gdiplus
QUALIFIED-WITH: alien.c-types c
IN: 7-transparency

STRING: vertex-init
#version 330 core
in vec3 posAttr;
out vec3 coords;
uniform mat4 matrix;
void main()
{
	gl_Position = matrix * vec4(posAttr, 1.0f);
	coords = posAttr;
}
;

STRING: fragment-init
#version 330 core
in vec3 coords;
out float minusDepth;
void main()
{
	minusDepth = -gl_FragCoord.z;
}
;

STRING: vertex-peel
#version 330
in vec3 posAttr;
out vec3 coords;
out vec3 texCoords;
uniform mat4 matrix;
void main()
{
	gl_Position = matrix * vec4(posAttr, 1.0f);
	coords = posAttr;
	texCoords = posAttr;
}
;

STRING: fragment-peel
#version 330

in vec3 coords;
in vec3 texCoords;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out float minusDepth;

uniform sampler2D frontTexture;
uniform sampler2D depthTexture;
uniform samplerCube cubeMap;

void main(void)
{
	float alpha = 0.5;

	float fragDepth = gl_FragCoord.z;
	float depthBlender = texelFetch(depthTexture, ivec2(gl_FragCoord.xy), 0).x;
	vec4 forwardTemp = texelFetch(frontTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 color = texture(cubeMap, texCoords).rgb;

// Depths and 1.0-alphaMult always increase
// so we can use pass-through by default with MAX blending

//minusDepth = depthBlender;

// Front colors always increase (DST += SRC*ALPHA_MULT)
// so we can use pass-through by default with MAX blending

	fragColor = forwardTemp;
	float nearestDepth = -depthBlender;
	float alphaMultiplier = 1.0 - forwardTemp.a;

	if (fragDepth < nearestDepth) {
// Skip this depth in the peeling algorithm
		minusDepth = -1.0;
	return;
	}

	if (fragDepth > nearestDepth) {
// This fragment needs to be peeled again
		minusDepth = -fragDepth;
	return;
	}

// If we made it here, this fragment is on the peeled layer from last pass
// therefore, we need to shade it, and make sure it is not peeled any farther

	fragColor.rgb = forwardTemp.rgb + color * alpha * alphaMultiplier;
	alphaMultiplier = alphaMultiplier * (1.0 - alpha);
	fragColor.a = 1.0 - alphaMultiplier;
	minusDepth = -1.0;
}
;

STRING: vertex-quad
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

STRING: fragment-quad
#version 330 core
in vec2 texCoords;
layout (location = 0) out vec4 color;
uniform sampler2D ourTexture;
void main()
{
color = texture(ourTexture, texCoords);
}
;

CONSTANT: N 50                    ! latitude bands number
CONSTANT: M 50                    ! longitude bands number
CONSTANT: distance -5.0
CONSTANT: near 0.1
CONSTANT: far  100
CONSTANT: FOV $[ 2.0 sqrt 1 + ]   ! cotangens(pi/8) calculated at compile time
SYMBOL: indexNumber

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

SYMBOL: framebuffers
SYMBOL: textures

! The following function creates two framebuffers with two textures (GL_RGBA and GL_R32F) each.
! This function puts framebuffers { frame1 frame2 } into variable SYMBOL: framebuffers
! and puts textures { { tex11 tex12} { tex21 tex22 } } into SYMBOL: textures.

:: make-framebuffers  ( w h -- )
      V{ } clone framebuffers set
      V{ } clone textures set
      2 [
          V{ } clone :> tex-array
          gen-framebuffer [ GL_FRAMEBUFFER swap glBindFramebuffer ] [ framebuffers get push ] bi
          gen-texture :> tex1
          tex1 [ GL_TEXTURE_2D swap glBindTexture ] [ tex-array push ] bi
          GL_TEXTURE_2D 0 GL_RGBA w h 0 GL_RGBA GL_UNSIGNED_BYTE B{ } glTexImage2D
          GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_LINEAR glTexParameteri
          GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri
          GL_FRAMEBUFFER  GL_COLOR_ATTACHMENT0 GL_TEXTURE_2D tex1 0 glFramebufferTexture2D
          gen-texture :> tex2
          tex2 [ GL_TEXTURE_2D swap glBindTexture ] [ tex-array push ] bi
          GL_TEXTURE_2D 0 GL_R32F w h 0 GL_RED GL_FLOAT B{ } glTexImage2D
          GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_LINEAR glTexParameteri
          GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri
          GL_FRAMEBUFFER  GL_COLOR_ATTACHMENT1 GL_TEXTURE_2D tex2 0 glFramebufferTexture2D
          tex-array textures get push
      ] times ;


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

: (quad-vertex-buffer) ( -- vertex-buffer )
     {
       1.0  1.0 0.0  ! top right
       1.0 -1.0 0.0  ! bottom right
      -1.0 -1.0 0.0  ! bottom left
      -1.0  1.0 0.0  ! top left
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

: (quad-index-buffer) ( -- index-buffer )
     {
       0 1 3   ! first triangle
       1 2 3   ! second triangle
     }
     c:uint >c-array underlying>>
     GL_ELEMENT_ARRAY_BUFFER swap GL_STATIC_DRAW <gl-buffer> ;

! Function "with-array-element-buffers" from vocab "opengl" does not work with VAO! Never unbind element-buffers!

: (quad-vertex-array) ( vertex-buffer texture-buffer index-buffer -- vertex-array )
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
         ]
         with-gl-buffer

         0 glEnableVertexAttribArray
         1 glEnableVertexAttribArray
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
     { 0.0 1.0 0.0 1.0 } swap rotation-matrix4 ;

: (t-matrix) ( -- matrix )
     0.0 0.0 distance 3array translation-matrix4 ;

: (p-matrix) ( xy-dim -- matrix )
     near far perspective-matrix ;

: increase ( angle -- angle )
     1.0 - dup -360.0 < [ 360.0 + ] when ;

TUPLE: rotation-world < world
     angle t-matrix pt-matrix program-init program-peel program-quad vertex-array quad-vertex-array texture ;

M:: rotation-world begin-world ( world -- )
     V{ } clone framebuffers set
     V{ } clone textures set
     "3.3" require-gl-version
     world
     0.0 >>angle
     vertex-init fragment-init <simple-gl-program> >>program-init
     vertex-peel fragment-peel <simple-gl-program> >>program-peel
     vertex-quad fragment-quad <simple-gl-program> >>program-quad
     (t-matrix) >>t-matrix
     (vertex-buffer) (index-buffer) (vertex-array) >>vertex-array
     (quad-vertex-buffer) (texture-buffer) (quad-index-buffer)
     (quad-vertex-array) >>quad-vertex-array
     "vocab:7-transparency/1.jpg" load-image make-texture >>texture

     program-peel>>
     [
      dup
     "frontTexture" glGetUniformLocation 0 glUniform1i
      dup
     "depthTexture" glGetUniformLocation 1 glUniform1i
     "cubeMap"      glGetUniformLocation 2 glUniform1i
     ] with-gl-program

     world
     [ [ increase ] change-angle relayout ] curry 25 milliseconds every drop ;

M: rotation-world resize-world
     framebuffers get [ [ delete-framebuffer ] when* ] each
     textures get [ [ [ delete-texture ] when* ] each ] each
     dup
     dim>> first2 make-framebuffers
     dup
     [ dim>> (p-matrix) ] [ t-matrix>> ] bi m. >>pt-matrix
     dim>> 0 0 rot first2 glViewport ;

M: rotation-world end-world
    {
        [ vertex-array>> [ delete-vertex-array ] when* ]
        [ texture>> [ delete-texture ] when* ]
        [ framebuffers get [ [ delete-framebuffer ] when* ] each  drop ]
    } cleave ;

M:: rotation-world draw-world* ( world -- )
      world [ pt-matrix>> ] [ angle>> (r-matrix) ] bi m.
      { 0 1 2 3 } swap cols concat c:float >c-array :> matrix

      GL_BLEND glEnable
      GL_MAX glBlendEquation

      GL_FRAMEBUFFER framebuffers get first glBindFramebuffer
      GL_COLOR_ATTACHMENT0 glDrawBuffer
      0.0 0.0 0.0 0.0  glClearColor
      GL_COLOR_BUFFER_BIT glClear
      GL_COLOR_ATTACHMENT1 glDrawBuffer
      -1.0 0.0 0.0 0.0  glClearColor
      GL_COLOR_BUFFER_BIT glClear
      world
      vertex-array>>
        [
        world
        program-init>>
           [
             "matrix" glGetUniformLocation
              1 GL_FALSE matrix glUniformMatrix4fv
              GL_TRIANGLES indexNumber get GL_UNSIGNED_INT 0 buffer-offset glDrawElements
           ] with-gl-program
       ] with-vertex-array

! The following code does the following job (this is not Factor)
! previous := 0
! for i = 1,2,i++ {
! current := 1 - previos
! do something with framebuffer[previous] and framebuffer[current]
! previous := current }

    0 2 [| prev | 1 prev - :> curr curr  ! The bracket [| prev | take a number (not 2, look at line 423) from the stack and calls it 'prev'. The last 'curr' is put on the stack.
        GL_FRAMEBUFFER curr framebuffers get nth glBindFramebuffer
        GL_COLOR_ATTACHMENT0 glDrawBuffer
        0.0 0.0 0.0 0.0  glClearColor
        GL_COLOR_BUFFER_BIT glClear
        GL_COLOR_ATTACHMENT1 glDrawBuffer
        -1.0 0.0 0.0 0.0  glClearColor
        GL_COLOR_BUFFER_BIT glClear
        2  GL_COLOR_ATTACHMENT0 GL_COLOR_ATTACHMENT1 2array \ uint >c-array glDrawBuffers
        world
        vertex-array>>
        [
          world
          program-peel>>
          [
           "matrix" glGetUniformLocation
           1 GL_FALSE matrix glUniformMatrix4fv
           GL_TEXTURE0 glActiveTexture
           GL_TEXTURE_2D prev textures get nth first glBindTexture
           GL_TEXTURE1 glActiveTexture
           GL_TEXTURE_2D prev textures get nth second glBindTexture
           GL_TEXTURE2 glActiveTexture
           GL_TEXTURE_CUBE_MAP world texture>> glBindTexture
           GL_TRIANGLES indexNumber get GL_UNSIGNED_INT 0 buffer-offset glDrawElements
          ] with-gl-program
        ] with-vertex-array
  ] times drop

    GL_BLEND glDisable

    GL_FRAMEBUFFER 0 glBindFramebuffer
!    1.0 1.0 1.0 1.0 glClearColor
!    GL_COLOR_BUFFER_BIT glClear
    GL_TEXTURE0 glActiveTexture
    GL_TEXTURE_2D textures get first first glBindTexture
    world
    quad-vertex-array>>
      [
      world
      program-quad>>
        [
          GL_TRIANGLES 6 GL_UNSIGNED_INT 0 buffer-offset glDrawElements drop
        ] with-gl-program
      ] with-vertex-array ;

MAIN-WINDOW: rotation-window {
    { world-class rotation-world }
    { title "Transparency" }
    { pixel-format-attributes {
        windowed
        double-buffered
        T{ depth-bits { value 16 } }
    } }
    { pref-dim { 640 640 } }
    } ;
