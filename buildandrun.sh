#!/bin/bash

docker build -t ftestenv . && docker run -it --rm ftestenv
