#!/bin/env bash 
# Copyright 2017-2019 (c) all rights reserved by S D Rausty 
# Adapted from Adi Lima https://github.com/fx-adi-lima/android-tutorials
#####################################################################
set -Eeuo pipefail
shopt -s nullglob globstar

_SBOTRPERROR_() { # Run on script error.
	local RV="$?"
	echo "$1 $2 $3"
	if [[ "$2" = ecj ]]  
	then 
		mkdir -p "$RDR/var/tmp"
		CER="conf.$NUM.err"
		echo "$1 $2 $3 $RV" > "$RDR/var/tmp/$CER" # https://stackoverflow.com/questions/11162406/open-and-write-data-to-text-file-using-bash-shell-scripting
		echo Fixing ecj error...
		echo Please wait a moment...
		sleep 0.64
		if [[ "$(command getprop ro.build.version.sdk)" -gt 23 ]] 
		then
			echo Installing package ecj_4.7.2-1_all.deb...
 			. "$RDR/fix.ecj.error.bash"
			echo "Package ecj_4.7.2-1_all.deb installed; Continuing..."
		else
			echo "Installing package ecj4.6_4.6.2_all.deb..." 
 			. "$RDR/fix.ecj4.6.error.bash"
			echo "Package ecj4.6_4.6.2_all.deb installed; Continuing..."
		fi
	else
		printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s ERROR:  Signal %s received!  More information in \`%s/var/log/stnderr.%s.%s.log\` file.\\e[0m\\n" "${0##*/}" "$RV" "$RDR" "${JID,,}" "$NUM"
	fi
	if [[ "$RV" = 1 ]] 
	then 
		printf "\\e[?25h\\e[1;7;38;5;0mOn Signal 1 try running %s again; This error can be resolved by running %s in a directory that has the \`AndroidManifest.xml\` file.  More information in \`%s/var/log/stnderr.%s.%s.log\` file.\\e[0m\\n" "${0##*/}" "${0##*/}" "$RDR" "${JID,,}" "$NUM"
		ls
	fi
	if [[ "$RV" = 255 ]]
	then 
		printf "\\e[?25h\\e[1;7;38;5;0mOn Signal 255 try running %s again if the error includes R.java and similar; This error might have been corrected by clean up.  More information in \`%s/var/log/stnderr.%s.%s.log\` file.\\e[0m\\n" "${0##*/}" "$RDR" "${JID,,}" "$NUM"
	fi
	exit 160
}

_SBOTRPEXIT_() { # Run on exit.
	local RV="$?"
	if [[ "$RV" != 0 ]]  
	then 
		printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs signal %s received by %s in %s.  More information in \`%s/var/log/stnderr.%s.%s.log\` file.\\n\\n" "$RV" "${0##*/}" "$PWD" "$RDR" "${JID,,}" "$NUM"
		echo "running: tail -n 16 $RDR/var/log/stnderr.${JID,,}.$NUM.log"
		echo 
		tail -n 16 "$RDR/var/log/stnderr.${JID,,}.$NUM.log"
		printf "\\e[0m\\n\\n" 
	fi
	if [[ "$RV" = 220 ]]  
	then 
		printf "\\n\\n\\e[1;7;38;5;143m	Signal %s generated in %s by %s; Downgrading the version of \`ecj\` is a potential solution if this signal was generated while ecj was compiling.  Version ecj/stable,now 4.7.2-2 does not run very well; This might be solved through sharing here https://github.com/termux/termux-packages/pulls and https://github.com/termux/termux-packages/issues/3157 here.  First comment on Dec 20, 2018\\n\\n	More information about keeping a system as stable as possible by downgrading a package when the want arrises is https://sdrausty.github.io/au here.\\n\\n	\`ecj_4.7.2-1\` works better than the version currently in use, so it is included for convience in \`buildAPKs/debs\`.  Use \`dpkg --purge ecj\` followed by \`dpkg --install ecj_4.7.2-1_all.deb\` to downgrade \`ecj\` to a stable version.\\n\\n" "$RV" "$PWD" "${0##*/}" 
		sleep 4
	fi
	if [[ "$RV" = 223 ]]  
	then 
		printf "\\e[?25h\\e[1;7;38;5;0mSignal 223 generated in %s; Try running %s again; This error can be resolved by running %s in a directory that has an \`AndroidManifest.xml\` file.  More information in \`stnderr*.log\` files.\\n\\nRunning \`ls\`:\\n" "$PWD" "${0##*/}" "${0##*/}"
		ls
	fi
	if [[ "$RV" = 224 ]]  
	then 
		printf "\\e[?25h\\e[1;7;38;5;0mSignal 224 generated in %s;  Cannot run in $HOME!  See \`stnderr*.log\` file.\\n\\nRunning \`ls\`:\\n" "$PWD" "${0##*/}" "${0##*/}"
	fi
	sleep 1
	printf "\\e[1;38;5;151m%s\\n\\e[0m" "Cleaning up..."
 	rm -rf ./bin 2>/dev/null ||:  
	rm -rf ./gen 2>/dev/null ||:  
 	rm -rf ./obj 2>/dev/null ||:  
	find . -name R.java -exec rm {} \; 2>/dev/null ||:  
	printf "\\e[1;38;5;151mCompleted tasks in ~/%s.\\n\\n\\e[0m" "${PWD:33}"
	printf "\\e[?25h\\e[0m"
	set +Eeuo pipefail 
	exit 0
}

_SBOTRPSIGNAL_() { # Run on signal.
	printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s WARNING:  Signal %s received!\\e[0m\\n" "${0##*/}" "$?"
 	exit 161 
}

_SBOTRPQUIT_() { # Run on quit.
	printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s WARNING:  Quit signal %s received!\\e[0m\\n" "${0##*/}" "$?"
 	exit 162 
}

trap '_SBOTRPERROR_ $LINENO $BASH_COMMAND $?' ERR 
trap _SBOTRPEXIT_ EXIT
trap _SBOTRPSIGNAL_ HUP INT TERM 
trap _SBOTRPQUIT_ QUIT 
NOW=$(date +%s)
if [[ -z "${1:-}" ]] 
then
	EXT=""
else
	EXT="$1"
fi
if [[ -z "${2:-}" ]] 
then
	JDR=""
else
	JDR="$2"
fi
if [[ "$PWD" = "$HOME" ]] 
then
	echo "Cannot run in $HOME!  Signal 224 generated in $PWD."
	exit 224
fi
printf "\\n\\e[1;38;5;116mBeginning build in ~/%s...\\n\\e[0m" "${PWD:33}"
if [[ ! -e "./assets" ]]
then
	mkdir -p ./assets
fi
if [[ ! -d "./bin" ]]
then
	mkdir -p ./bin
fi
if [[ ! -d "./gen" ]]
then
	mkdir -p ./gen
fi
if [[ ! -d "./obj" ]]
then
	mkdir -p ./obj
fi
if [[ ! -d "./res" ]]
then
	mkdir -p ./res
fi
if [[ ! -d "/storage/emulated/0/Download/builtAPKs/$EXT$DAY" ]]
then
	mkdir -p "/storage/emulated/0/Download/builtAPKs/$EXT$DAY"
fi
printf "\\e[1;38;5;115m%s\\n\\e[0m" "aapt: started..."
aapt package -f \
	-M ./AndroidManifest.xml \
	-J gen \
	-S res \
	-m
printf "\\e[1;38;5;148m%s;  \\e[1;38;5;114m%s\\n\\e[0m" "aapt: done" "ecj: begun..."
if [[ -d "$TMPDIR/buildAPKsLibs" ]] && [[ -d "$JDR/libs" ]] # directories exist
then # loads artifacts
        ecj -d ./obj -classpath "$TMPDIR/buildAPKsLibs:$JDR/libs" -sourcepath . "$(find . -type f -name "*.java")"
elif [[ -d "$TMPDIR/buildAPKsLibs" ]]
then
        ecj -d ./obj -classpath "$TMPDIR/buildAPKsLibs" -sourcepath . "$(find . -type f -name "*.java")"
else
        ecj -d ./obj -sourcepath . "$(find . -type f -name "*.java")"
fi
printf "\\e[1;38;5;149m%s;  \\e[1;38;5;113m%s\\n\\e[0m" "ecj: done" "dx: started..."
dx --dex --output=./bin/classes.dex ./obj
printf "\\e[1;38;5;148m%s;  \\e[1;38;5;112m%s\\n\\e[0m" "dx: done" "Making the apk..."
aapt package -f \
	--min-sdk-version 1 \
	--target-sdk-version 23 \
	-M ./AndroidManifest.xml \
	-S ./res \
	-A ./assets \
	-F bin/step2.apk
printf "\\e[1;38;5;113m%s\\n\\e[0m" "Adding the classes.dex to the apk..."
cd bin || exit
aapt add -f step2.apk classes.dex
printf "\\e[1;38;5;114m%s\\n" "Signing step2.apk..."
apksigner ../step2-debug.key step2.apk ../step2.apk
cd ..
cp step2.apk "/storage/emulated/0/Download/builtAPKs/$EXT$DAY/step$NOW.apk"
printf "\\e[1;38;5;115mCopied to /sdcard/Download/builtAPKs/%s/step%s.apk\\n" "$EXT$DAY" "$NOW"
printf "\\e[1;38;5;149mYou can install it from /sdcard/Download/builtAPKs/%s/step%s.apk\\n" "$EXT$DAY" "$NOW" 
printf "\\e[?25h\\e[1;7;38;5;34mShare %s here; Share everwhere%s!\\e[0m\\n" "https://wiki.termux.com/wiki/Development" "🌎🌍🌏🌐"

#EOF
