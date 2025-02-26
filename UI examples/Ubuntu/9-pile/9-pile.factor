USING: accessors colors kernel ui ui.gadgets ui.gadgets.buttons
ui.gadgets.packs ui.pens.solid ;
IN: 9-pile

: foo ( -- gadget )
   <pile> { 0 50 } >>gap 0.5 >>align 0.5 >>fill
   COLOR: grey <solid> >>interior
   "button A" [ drop ] <border-button> add-gadget
   "button B" [ drop ] <border-button> add-gadget
   "button C" [ drop ] <border-button> add-gadget ;

MAIN-WINDOW: hello { { title "Pile" } }
    foo >>gadgets ;
