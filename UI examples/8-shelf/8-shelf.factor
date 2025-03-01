USING: accessors colors kernel ui ui.gadgets ui.gadgets.buttons
ui.gadgets.packs ui.pens.solid ;
IN: 8-shelf

: foo ( -- gadget )
   <shelf> { 50 0 } >>gap 0.5 >>align 0.0 >>fill
   COLOR: grey <solid> >>interior
   "button A" [ drop ] <border-button> add-gadget
   "button B" [ drop ] <border-button> add-gadget
   "button C" [ drop ] <border-button> add-gadget ;

MAIN-WINDOW: hello { { title "Shelf" } }
    foo >>gadgets ;
