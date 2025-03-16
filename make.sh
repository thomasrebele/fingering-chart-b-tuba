#!/bin/bash

lilypond grifftabelle.ly
cp grifftabelle.pdf grifftabelle-quer.pdf
pdfjam --angle 90 grifftabelle.pdf --paper a4paper  --outfile grifftabelle-hoch.pdf
convert -density 150 -background white -alpha remove -alpha off grifftabelle-quer.pdf grifftabelle-quer.png

