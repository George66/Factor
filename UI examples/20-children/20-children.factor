USING: accessors colors fonts kernel sequences ui ui.gadgets
ui.gadgets.borders ui.gadgets.labels ui.gadgets.packs ui.gestures ui.pens.solid ;
IN: 20-children

TUPLE: clickable_label < label ;

 clickable_label H{
   { T{ button-down f f 1 } [ parent>> children>> first COLOR: green <solid> >>interior relayout-1 ] }
   { T{ button-down f f 3 } [ parent>> children>> first COLOR: blue  <solid> >>interior relayout-1 ] }
 } set-gestures

: foo ( -- gadget )
   <pile> 0.5 >>align
   <gadget> { 250 100 } >>dim add-gadget
   clickable_label new " Click me " >>text sans-serif-font >>font add-gadget
   ;

MAIN-WINDOW: hello { { title "Children" } }
    foo >>gadgets ;
