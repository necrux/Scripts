#!/bin/bash
# This script finds image files in a given directory,
# determines if the images are landscape or portrait,
# and resizes them to a predetermined size.

# This script can be useful for standardizing photo
# sizes. In order to use the script, populate the 3
# variables below. The ${PIC_DIR} variable is the
# location of your pictures, the ${L_SIDE} variable
# is the desired size of the larger side of the image, 
# and the ${S_SIDE} variable is the desried size of the 
# smaller side of the image.

PIC_DIR=
L_SIDE=
S_SIDE=

# Check if a command is installed.
function is_command {
  local FAILURE

  for program in $@; do
    hash ${program} > /dev/null 2>&1
    if [ $? != 0 ]; then
      echo "Command not found: ${program}" >&2
      FAILURE='true'
    fi
  done

  if [ ! -z ${FAILURE} ]; then
    exit 127
  fi
}

# Locate the image files in ${PIC_DIR}.
function find_pics {
  local IFS=$'\n'

  for pic in $(find ${PIC_DIR} -maxdepth 1 -type f -exec file {} \; | awk -F': ' 'BEGIN{IGNORECASE = 1}/image/ {print $1}'); do
    echo ${pic}
  done
}

# Convert portrait pictures.
function portrait {
  convert $1 -resize ${S_SIDE}x${L_SIDE}\!\> $1
}

# Convert landscape pictures.
function landscape {
  convert $1 -resize ${L_SIDE}x${S_SIDE}\!\> $1
}

is_command identify convert

for pic in $(find_pics); do
  if [ "$(identify -format '%W' ${pic})" -gt "$(identify -format '%H' ${pic})" ]; then
    if [ "${L_SIDE}" -lt "$(identify -format '%W' ${pic})" ]; then
      landscape ${pic}
    fi
  else
    if [ "${L_SIDE}" -lt "$(identify -format '%H' ${pic})" ]; then
      portrait ${pic}
    fi
  fi
done
