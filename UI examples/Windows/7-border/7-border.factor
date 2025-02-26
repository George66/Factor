USING: accessors colors.constants ui ui.gadgets ui.gadgets.borders ui.pens.solid ;
IN: 7-border

: foo ( -- gadget )
   <gadget> { 300 100 } >>dim COLOR: blue <solid> >>interior
   { 20 10 } <border> ;

MAIN-WINDOW: hello { { title "Border" } }
    foo >>gadgets ;
