#!/bin/bash
cava -p ~/.config/cava/config | sed -u "s/;//g; /^0*$/ s/.*//; s/0/$(printf '\xc2\xa0')/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g"
