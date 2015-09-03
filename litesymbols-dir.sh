#!/bin/bash
#Usage:  listsymbols-dir.sh [APPLICATION_PATH] ([TARGET_FOLDER])
APPLICATION_PATH="$1"
TARGET_FOLDER="$2"

if [ -z "$TARGET_FOLDER" ]; then
	TARGET_FOLDER="."
fi

for file in $TARGET_FOLDER/*.crash
do
	echo "Processing $file ..."
	eval "litesymbols.sh $APPLICATION_PATH $file > $file.symbolicated 2> /dev/null"
done
