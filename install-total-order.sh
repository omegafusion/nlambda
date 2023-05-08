#!/bin/sh
cabal configure -fTOTAL_ORDER
cabal build
cabal install --lib
