USING: accessors colors.constants ui ui.pens.polygon ;
IN: 5-boundary

: foo ( -- gadget )
    COLOR: gray { { 50 50 } { 200 300 } { 400 200 } } <polygon-gadget>
    COLOR: blue { { 50 50 } { 200 300 } { 400 200 } } <polygon> >>boundary ;

MAIN-WINDOW: hello { { title "Boundary" } }
    foo >>gadgets ;
