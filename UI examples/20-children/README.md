Click the label with the left and right mouse buttons. A gadget may have children.\
In this example the pile is the parent of the label and the label is the second child of the pile.\
Try to change `parent>> children>> first` to `parent>> children>> second`\
Use `relayout-1` to redraw if the gadget's dimensions do not change (for example, only the color has changed).\
Otherwise, use `relayout`, this function will redraw all parents of the gadget in turn.\
If the dimensions of some gadget never change, mark it as "root" (`gadget t >>root?`)