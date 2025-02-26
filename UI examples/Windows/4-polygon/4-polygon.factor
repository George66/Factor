USING: accessors colors.constants ui ui.pens.polygon ;
IN: 4-polygon

: foo ( -- gadget )
    COLOR: gray { { 50 50 } { 200 300 } { 400 200 } } <polygon-gadget> ;

MAIN-WINDOW: hello { { title "Polygon-gadget" } }
    foo >>gadgets ;
