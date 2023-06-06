#!/bin/sh
cp ../step2/*.tf .
patch -s -p1 < update.patch
