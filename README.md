# ipe-bisector

An ipelet programmed in lua that lets you create a (weighted) bisector between two line
segments, or between two points (marks).

## Install

- Download the `.lua`-file and place it in your `$HOME/.ipe/ipelets` directory.

- Open `ipe`, look in `ipelets` -> `Bisector`

## Properties

- weights are defined by the pen-size of a line-segment or size of a mark

- if two parallel line segments are chosen then a line segment centered between them is drawn

- if two adjacent edges are chosen the bisector starts in their common endpoint

- if a polyline is selected a bisector is drawn between every consecutive edge

