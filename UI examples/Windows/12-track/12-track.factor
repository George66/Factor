USING: accessors colors.constants kernel ui ui.gadgets ui.gadgets.buttons
ui.gadgets.tracks ui.pens.solid ;
IN: 12-track

: foo ( -- track ) vertical <track> { 0 50 } >>gap 0.5 >>align 0.0 >>fill
    COLOR: gray <solid> >>interior
    "button 2/3" [ drop ] <border-button> 2 track-add
    "button 1/3" [ drop ] <border-button> 1 track-add
    "button f"   [ drop ] <border-button> f track-add
     ;

MAIN-WINDOW: hello { { title "Vertical Track" } }
    foo >>gadgets ;
