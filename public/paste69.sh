#!/bin/bash
# Paste69 CLI script

# Check if `curl` is installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed"
  exit 1
fi

# Check if `jq` is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed"
  exit 1
fi

# Show help text
function show_help {
  echo "Usage:"
  echo "  paste69 <file> [options]"
  echo "Options:"
  echo "  -l, --language <language>  Set the language of the paste"
}

# Check if a path to a file was provided, otherwise read from stdin. If all
# else fails, show the help text.
if [ -z "$1" ]; then
  if [ -p /dev/stdin ]; then
    data=$(cat -)
  else
    echo "Error: no file provided"
    show_help
    exit 1
  fi
else
  if [ ! -f "$1" ]; then
    echo "Error: file $1 does not exist"
    exit 1
  fi
  file=$1
fi

# Check if a language was provided
if [ ! -z "$2" ]; then
  if [ "$2" == "-l" ] || [ "$2" == "--language" ]; then
    if [ -z "$3" ]; then
      echo "Error: no language provided"
      show_help
      exit 1
    fi
    language="$3"
  else
    echo "Error: invalid option $2"
    show_help
    exit 1
  fi
fi

# Build the URL
url="https://0x45.st/api/v1/paste"
if [ ! -z "$language" ]; then
  url="$url?language=$language"
fi

# Make the request
if [ ! -z "$file" ]; then
  response=$(curl -s -X POST -H "Content-Type: text/plain" --data-binary "@$file" $url)
else
  # Check if the data is too large
  if [ ${#data} -gt 10000 ]; then
    echo "Error: stdin input too large. Use a file instead."
    exit 1
  fi
  response=$(curl -s -X POST -H "Content-Type: text/plain" -d "$data" $url)
fi

if [ $? -ne 0 ]; then
  echo "An error occurred while making the request"
  exit 1
fi

# Check if `success` is true
if [ $(echo $response | jq -r '.success') != "true" ]; then
  echo "Error: $(echo $response | jq -r '.error')"
  exit 1
fi

# Print the URL from `paste.link`
echo $(echo $response | jq -r '.paste.link')