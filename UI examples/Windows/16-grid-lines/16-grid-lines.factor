USING: accessors colors.constants kernel locals ui ui.gadgets.borders
ui.gadgets.buttons ui.gadgets.grids ui.gadgets.grid-lines ui.pens.solid ;
IN: 16-grid-lines

:: foo ( -- gadget )
    "button A" [ drop ] <border-button> :> button1
    "button B" [ drop ] <border-button> :> button2
    "button C" [ drop ] <border-button> :> button3
    "button D" [ drop ] <border-button> :> button4
    { { button1 button2 } { button3 button4 } } <grid>
    { 10 10 } >>gap
    COLOR: grey <solid> >>interior
    COLOR: black <grid-lines> >>boundary
    { 5 5 } <border>
    ;

MAIN-WINDOW: hello { { title "Grid-lines" } }
    foo >>gadgets ;
