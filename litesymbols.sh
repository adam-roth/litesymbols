#!/bin/bash
#Usage:  litesymbols.sh <APPLICATION_PATH> <CRASH FILE>
function abs_path {
  (cd "$(dirname '$1')" &>/dev/null && printf "%s/%s" "$PWD" "${1##*/}")
}

APPLICATION_PATH=$(abs_path $1)
CRASH_FILE=$(abs_path $2)
ARCH="armv6"

#first, collect values for ARCH, OS_VERSION, and APP_NAME
rm tmp > /dev/null 2>&1
cat "$CRASH_FILE" | while read line
do
	#APP_NAME
	if [[ $line == Identifier* ]]
		then
		IFS='.' read -ra IDENT <<< "$line"
		for part in "${IDENT[@]}"; do
			if [ -n "$part" ]; then
				APP_NAME=$part
			fi
		done
		echo "APP_NAME=$APP_NAME" >> tmp
	fi
	
	#OS_VERSION
	if [[ $line == "OS Version"* ]]
		then
		OS_VERSION=
		IFS=' ' read -ra IDENT <<< "$line"
		for part in "${IDENT[@]}"; do
			if [ -n "$part" ]; then
				if [ -n "$OS_VERSION" ]; then
					OS_VERSION="$OS_VERSION $part"
				fi
				if [[ $part =~ [0-9]+\.[0-9+] ]]
					then
					OS_VERSION=$part
				fi
			fi
		done
		echo "OS_VERSION=\"$OS_VERSION\"" >> tmp
	fi
	
	#ARCH
	if [[ $line == *"$APP_NAME armv7"* ]]
		then
		ARCH="armv7"
		echo "ARCH=$ARCH" >> tmp
	fi
	if [[ $line == *"$APP_NAME arm64"* ]]
		then
		ARCH="arm64"
		echo "ARCH=$ARCH" >> tmp
	fi
	if [[ $line == *"$APP_NAME ???"* ]]
		then
		ARCH="arm64"
		echo "ARCH=$ARCH" >> tmp
	fi
	
done

#our loop executes in a subshell which cannot directly modify our context, so source-in the results through a temp-file
. tmp
rm tmp

#HACK:  the abs_path function appears to get confused when working with .app files; we compensate for it here
APPLICATION_PATH="$APPLICATION_PATH.app/$APP_NAME"
SYMBOLS_ROOT="$HOME/Library/Developer/Xcode/iOS DeviceSupport/$OS_VERSION/Symbols"

#echo "$APPLICATION_PATH"
#echo "$CRASH_FILE"
#echo "$APP_NAME"
#echo "$OS_VERSION"
#echo "$ARCH"

#Now we should have everything we need to attempt symbolication; we want to read through the crash file and attempt to run one of the following commands on each stack-trace element (ignoring all other lines):
#	atos -arch <ARCH> -o <APPLICATION_PATH> -l <BASE_PTR> <OFFSET>
#	atos -arch <ARCH> -o ~/Library/Developer/Xcode/iOS\ DeviceSupport/<OS_VERSION>/Symbols/usr/lib/<ASSEMBLY> -l <BASE_PTR> <OFFSET>
#	atos -arch <ARCH> -o ~/Library/Developer/Xcode/iOS\ DeviceSupport/<OS_VERSION>/Symbols/System/Library/Frameworks/<ASSEMBLY>.framework/<ASSEMBLY> -l <BASE_PTR> <OFFSET>
cat "$CRASH_FILE" | while read line
do
	#if [[ $line =~ [0-9]+\ [a-zA-Z\.]+\ 0x[0-9a-f]+\ 0x[0-9a-f]+\ \+\ [0-9]+ ]]
	if [[ $line =~ ^[0-9]+[\ \t]+[a-zA-Z_\.0-9]+[\ \t]+0x[0-9a-f]+[\ \t]+0x[0-9a-f]+[\ \t]+\+[\ \t]+[0-9]+ ]]
		then
		#we've found a line that we should symbolicate; the next question is, can we?
		LINENUM=
		ASSEMBLY=
		BASE_PTR=
		OFFSET=
		IFS=" " read -ra IDENT <<< "$line"
		for part in "${IDENT[@]}"; do
			if [ -n "$part" ]; then
				if [ -z "$LINENUM" ]; then
					LINENUM=$part
				fi
				if [[ $part =~ ^[a-zA-Z][a-zA-Z_\.0-9]+ ]]
					then
					ASSEMBLY=$part
				fi
				if [[ $part =~ ^0x[0-9a-f]+ ]]
					then
					if [[ $OFFSET =~ ^0x[0-9a-f]+ ]]
						then
						BASE_PTR=$part
					else
						OFFSET=$part
					fi
				fi
			fi
		done
		
		#echo "$ASSEMBLY - $BASE_PTR - $OFFSET : $line"
		if [ -n "$ASSEMBLY" ] && [ -n "$BASE_PTR" ] && [ -n "$OFFSET" ]; then
			#we've identified the assembly involved; now see if we can determine where its debugging symbols reside
			APPLICATION_PATH_ESC=`printf %q "$APPLICATION_PATH"`
			DYLIB="$SYMBOLS_ROOT/usr/lib/$ASSEMBLY"
			DYLIB_SYS="$SYMBOLS_ROOT/usr/lib/system/$ASSEMBLY"
			FRAMEWORK="$SYMBOLS_ROOT/System/Library/Frameworks/$ASSEMBLY.framework/$ASSEMBLY"
			FRAMEWORK_PRIV="$SYMBOLS_ROOT/System/Library/PrivateFrameworks/$ASSEMBLY.framework/$ASSEMBLY"
			
			if [[ $ASSEMBLY == $APP_NAME ]]
				then
				#simplest case; we should be able to use the provided APPLICATION_PATH
				CMD="atos -arch $ARCH -o $APPLICATION_PATH_ESC -l $BASE_PTR $OFFSET"
				RESULT=$(eval $CMD)
				echo "$line	$RESULT"
			elif [[ -e "$DYLIB" ]]
				then
				#attempt to symbolicate using the dylib file
				DYLIB_ESC=`printf %q "$DYLIB"`
				CMD="atos -arch $ARCH -o $DYLIB_ESC -l $BASE_PTR $OFFSET"
				RESULT=$(eval $CMD)
				echo "$line	$RESULT"
			elif [[ -e "$DYLIB_SYS" ]]
				then
				#attempt to symbolicate using the system dylib file
				DYLIB_ESC=`printf %q "$DYLIB_SYS"`
				CMD="atos -arch $ARCH -o $DYLIB_ESC -l $BASE_PTR $OFFSET"
				RESULT=$(eval $CMD)
				echo "$line	$RESULT"
			elif [[ -e "$FRAMEWORK" ]]
				then
				#attempt to symbolicate using the framework file
				FRAMEWORK_ESC=`printf %q "$FRAMEWORK"`
				CMD="atos -arch $ARCH -o $FRAMEWORK_ESC -l $BASE_PTR $OFFSET"
				RESULT=$(eval $CMD)
				echo "$line	$RESULT"
			elif [[ -e "$FRAMEWORK_PRIV" ]]
				then
				#attempt to symbolicate using the private framework file
				FRAMEWORK_ESC=`printf %q "$FRAMEWORK_PRIV"`
				CMD="atos -arch $ARCH -o $FRAMEWORK_ESC -l $BASE_PTR $OFFSET"
				RESULT=$(eval $CMD)
				echo "$line	$RESULT"
				#echo "$line	$(atos -arch $ARCH -o $FRAMEWORK_ESC -l $BASE_PTR $OFFSET)"
			else
				#cannot symbolicate as we could not determine where the debugging symbols reside
				echo "$line"
			fi
		else
			#cannot symbolicate as we could not determine what assembly was being used
			echo "$line"
		fi
		
	else
		#just a normal line that we shouldn't process; pass it on verbatim
		echo "$line"
	fi
done
