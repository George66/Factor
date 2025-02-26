USING: accessors colors kernel locals ui ui.gadgets.borders
ui.gadgets.buttons ui.gadgets.frames ui.gadgets.grids ui.pens.solid ;
IN: 17-frame

:: foo ( -- gadget )
    "button A" [ drop ] <border-button> :> button1
    "button B" [ drop ] <border-button> :> button2
    "button C" [ drop ] <border-button> :> button3
    "button D" [ drop ] <border-button> :> button4
    "button E" [ drop ] <border-button> :> button5
    "button F" [ drop ] <border-button> :> button6
    "button G" [ drop ] <border-button> :> button7
    "button H" [ drop ] <border-button> :> button8
    "button I" [ drop ] <border-button> :> button9
    3 3 <frame> { 10 10 } >>gap { 1 1 } >>filled-cell
    COLOR: grey <solid> >>interior
    button1 { 0 0 } grid-add
    button2 { 1 0 } grid-add
    button3 { 2 0 } grid-add
    button4 { 0 1 } grid-add
    button5 { 1 1 } grid-add
    button6 { 2 1 } grid-add
    button7 { 0 2 } grid-add
    button8 { 1 2 } grid-add
    button9 { 2 2 } grid-add
!    { 5 5 } <border>
    ;

MAIN-WINDOW: hello { { title "Frame" } }
    foo >>gadgets ;
