USING: accessors colors kernel ui ui.gadgets ui.gadgets.buttons
ui.gadgets.tracks ui.pens.solid ;
IN: 11-track

: foo ( -- track ) horizontal <track> { 50 0 } >>gap 0.5 >>align 0.0 >>fill
    COLOR: gray <solid> >>interior
    "button 2/3" [ drop ] <border-button> 2 track-add
    "button 1/3" [ drop ] <border-button> 1 track-add
    "button f"   [ drop ] <border-button> f track-add
     ;

MAIN-WINDOW: hello { { title "Horizontal Track" } }
    foo >>gadgets ;
