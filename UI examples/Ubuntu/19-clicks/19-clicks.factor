USING: accessors colors fonts kernel ui ui.gadgets ui.gadgets.borders
ui.gadgets.labels ui.gestures ui.pens.solid ;
IN: 19-clicks

TUPLE: clickable_label < label ;

 clickable_label H{
   { T{ button-down f f 1 } [ parent>> COLOR: green <solid> >>interior relayout-1 ] }
   { T{ button-down f f 3 } [ parent>> COLOR: blue  <solid> >>interior relayout-1 ] }
 } set-gestures

: foo ( -- gadget )
   clickable_label new " Click me " >>text sans-serif-font >>font
   COLOR: gray <solid> >>interior
   { 40 20 } <border>
   ;

MAIN-WINDOW: hello { { title "Clicks" } }
    foo >>gadgets ;
