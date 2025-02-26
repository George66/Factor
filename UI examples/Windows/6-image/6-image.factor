USING: accessors kernel ui ui.gadgets ui.images ui.pens.image ;
IN: 6-image

: foo ( -- gadget )
   <gadget> "vocab:6-image/1.jpg" <image-name> [ image-dim >>dim ] keep
    <image-pen> >>interior ;
! To deploy the vocab change "vocab:6-image/1.jpg" to "./1.jpg" (and put 1.jpg to ./ after deploying)  

MAIN-WINDOW: hello { { title "Image-gadget" } }
    foo >>gadgets ;
