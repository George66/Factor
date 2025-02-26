USING: accessors colors kernel locals ui ui.gadgets.buttons
ui.gadgets.grids ui.pens.solid ;
IN: 14-grid

:: foo ( -- gadget )
    "button A" [ drop ] <border-button> :> button1
    "button B" [ drop ] <border-button> :> button2
    "button C" [ drop ] <border-button> :> button3
    "button D" [ drop ] <border-button> :> button4
    { { button1 button2 } { button3 button4 } } <grid>
    { 10 10 } >>gap
    COLOR: grey <solid> >>interior ;

MAIN-WINDOW: hello { { title "Grid" } }
    foo >>gadgets ;
