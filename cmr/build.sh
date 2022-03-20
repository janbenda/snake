#!/bin/bash
if [ $1 == debug ];then
    hbc.sh cmr.hbp -b
else 
    hbc.sh cmr.hbp
fi
