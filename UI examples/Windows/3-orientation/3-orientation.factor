USING: accessors colors.constants ui ui.gadgets ui.pens.gradient ;
IN: 3-orientation

: foo ( -- gadget )
   <gadget> { 300 100 } >>dim { COLOR: blue COLOR: green COLOR: red } <gradient> >>interior
   horizontal >>orientation ;

MAIN-WINDOW: hello { { title "Horizontal Gadget" } }
    foo >>gadgets ;
