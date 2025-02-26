USING: accessors kernel locals ui ui.gadgets ui.gadgets.borders ui.gadgets.buttons
ui.gadgets.labels ui.gadgets.packs ;
IN: 10-visibility

:: toggle ( label -- button )
   "Press me" [ drop label [ not ] change-visible? relayout-1 ] <border-button> ;

: foo  ( -- shelf )  <shelf> { 50 0 } >>gap 0.5 >>align
   "Hello world" <label> [ add-gadget ] keep
    toggle add-gadget
    { 20 10 } <border> ;

MAIN-WINDOW: hello { { title "Visibility" } }
    foo >>gadgets ;
