# ipe-bisector

An ipelet programmed in lua that lets you create a weighted bisector between two line
segments, or between every line segment of a given polychain.

## Install

- Download the `.lua`-file and place it in your `$HOME/.ipe/ipelets` directory.

- Open `ipe`, look in `ipelets` -> `Bisector`

## Properties

- weights are defined by the pen-size of an edge

- if two parallel line segments are chosen then a line segment centered between them is drawn

- if two adjacent edges are chosen the bisector starts in their common endpoint

- if a polyline is selected a bisector is drawn between every consecutive edge

# l2-bisector

The second .lua file, "l2bisector.lua" constructs the weighted Euclidean bisector between
two points. The points are represented by "marks" and the weight is given as size of these marks.

## TODO's

- embed the l2-bisector in the other bisector file

