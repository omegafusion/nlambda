#!/bin/sh
cabal configure
cabal build
cabal install --lib
