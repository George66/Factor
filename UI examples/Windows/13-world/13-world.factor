USING: accessors kernel locals ui ui.gadgets.buttons ;
IN: 13-world

:: foo ( -- gadgets )
    "button A" [ drop ] <border-button> :> button1
    "button B" [ drop ] <border-button> :> button2
    "button C" [ drop ] <border-button> :> button3
     { button1 button2 button3 } ;

MAIN-WINDOW: hello { { title "World" } }
    foo >>gadgets ;
