#!/bin/bash
content=("herry pear banana grape peah apple")
ESC=$(printf '\033')

typingGame(){
  element=$1
  typed=$element
  n=0
  clear
  echo "${ESC}[33m$element${ESC}[m"

  while true; do
    if [ ${#element} -eq 0 ]; then
      break
    fi
    read -s -n 1 a
    if [ $a == ${element:0:1} ]; then
      clear
      n=$((n + 1))
      typed_element=${typed:0:n}
      element=${element:1}
      echo -n "${ESC}[34m$typed_element${ESC}[m"
      echo -n -e "${ESC}[33m$element\n${ESC}[m"
    fi
  done
}

for value in ${content[@]}; do
  typingGame $value
done
