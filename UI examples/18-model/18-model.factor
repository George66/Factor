USING: accessors colors kernel math models models.arrow models.range
ui ui.gadgets ui.gadgets.sliders ui.gadgets.tracks ui.pens.solid ;
IN: 18-model

TUPLE: color-preview < gadget ;

: <color-preview> ( model -- gadget )
    color-preview new
        swap >>model
        { 200 200 } >>dim ;

M: color-preview model-changed
    swap value>> >>interior relayout-1 ;

: <color-slider> ( range -- slider )
    horizontal <slider> 1 >>line ;

: <slider-and-model> ( -- slider model )
    0 0 0 255 1 <range>
    [ <color-slider> ]
    [ range-model ]
    bi ;

: <color-model> ( model -- model )
    [ 256 /f 0 0 1 <rgba> <solid> ] <arrow> ;

: <color-picker> ( -- gadget )
    vertical <track>
    <slider-and-model>
    [ f track-add ]
    [ <color-model> <color-preview> 1 track-add ]
    bi* ;

MAIN-WINDOW: color-picker-window { { title "Color Picker" } }
    <color-picker> >>gadgets ;
