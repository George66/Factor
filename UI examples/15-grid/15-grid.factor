USING: accessors colors kernel locals ui ui.gadgets
ui.gadgets.buttons ui.gadgets.grids ui.pens.solid ;
IN: 15-grid

:: foo ( -- gadget )
    <gadget> { 150 100 } >>dim COLOR: green <solid> >>interior :> gadget
    "button B" [ drop ] <border-button> :> button2
    "button C" [ drop ] <border-button> :> button3
    "button D" [ drop ] <border-button> :> button4
    { { gadget button2 } { button3 button4 } } <grid>
    { 10 10 } >>gap t >>fill?
    COLOR: grey <solid> >>interior ;

MAIN-WINDOW: hello { { title "Filling" } }
    foo >>gadgets ;
