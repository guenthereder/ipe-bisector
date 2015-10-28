# ipe-bisector
An ipelet programmed in lua that lets you create a bisector between two line
segments, or between every line segment of a given polychain.

Download the .lua file and place it in your $HOME/.ipe/ipelets directory.

- if two parallel line segments are chosen then a line segment centered between them is drawn

- if two adjacent edges are chosen the bisector starts in their common endpoint

- if a polyline is selected a bisector is drawn between every consecutive edge
