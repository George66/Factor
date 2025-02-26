USING: accessors colors.constants ui ui.gadgets ui.pens.gradient ;
IN: 2-gadget

: foo ( -- gadget )
   <gadget> { 300 100 } >>dim { COLOR: blue COLOR: green COLOR: red } <gradient> >>interior ;

MAIN-WINDOW: hello { { title "Gradient" } }
    foo >>gadgets ;
