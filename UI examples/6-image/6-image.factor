USING: accessors kernel ui ui.gadgets ui.images ui.pens.image ;
IN: 6-image

: foo ( -- gadget )
   <gadget> "vocab:6-image/1.jpg" <image-name> [ image-dim >>dim ] keep
    <image-pen> >>interior ;
! To deploy the vocab replace "vocab:6-image/1.jpg" with "./1.jpg" (for Windows)
! or with "1.jpg" (for Linux) and put 1.jpg near the executable file after deploying    

MAIN-WINDOW: hello { { title "Image-gadget" } }
    foo >>gadgets ;
