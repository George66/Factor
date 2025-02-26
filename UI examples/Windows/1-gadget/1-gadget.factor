USING: accessors colors.constants ui ui.gadgets ui.pens.solid ;
IN: 1-gadget

: foo ( -- gadget )
   <gadget> { 300 100 } >>dim COLOR: blue <solid> >>interior ;

MAIN-WINDOW: hello { { title "Solid" } }
    foo >>gadgets ;
