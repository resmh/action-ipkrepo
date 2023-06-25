#!/bin/bash

# ######################################################################
# ######################################################################
#
# IPKREPO
# Creates and signs an ipk package repository from a given folder
# 
# ######################################################################
# ######################################################################



# ######################################################################
# ######################################################################
#
# ######################################################################
# ######################################################################

set -e

INPUT_STRICT=${INPUT_STRICT:-''}
INPUT_INPUT=${INPUT_INPUT:-'.'}
INPUT_OUTPUT=${INPUT_OUTPUT:-'.'}
INPUT_PRIVATEGPG=${INPUT_PRIVATEGPG:-''}
INPUT_PRIVATESIGNIFY=${INPUT_PRIVATESIGNIFY:-''}
INPUT_CACHE=${INPUT_CACHE:-''}
#INPUT_=${INPUT_:-''}



# ######################################################################
# ######################################################################
#
# ######################################################################
# ######################################################################



# ######################################################################
#
# ######################################################################

function initIndex() {
	
	if [ -f "${INPUT_OUTPUT}/Packages" ]; then
		echo "Removing existing index file"
		if ! rm "${INPUT_OUTPUT}/Packages"; then echo "Failed to remove existing index file."; return 1; fi		
	fi
	return 0
	
}


# ######################################################################
#
# ######################################################################

function includeCache() {

	if [ "$INPUT_OUTPUT" == "" ] || [ ! -f "$INPUT_CACHE" ]; then
		echo "Creating package index"
		touch "${INPUT_INPUT}/Packages"
	else
		echo "Including cache file"
		if ! cp "$INPUT_CACHE" "${INPUT_OUTPUT}/Packages"; then echo "Failed to include cache file"; return 1; fi		
	fi
	return 0

}


# ######################################################################
#
# ######################################################################

function addPackage() {

	local PKG="$1"

	# GET IPK CONTROL FILE TEXT WITHOUT SIZE AND HASH
	if ! pkginfo=$(tar -zxOf $PKG control.tar.gz | tar -zxO './control' | sed '/^Size: .*/d' | sed '/^SHA256sum: .*/d'); then echo "Failed to extract package info"; return 2; fi
	
	# DETERMINE SIZE AND HASH
	if ! pkgsize=$(stat -c %s $PKG); then echo "Failed to determine package size"; return 3; fi
	if ! pkghash=$(sha256sum $PKG | grep -o "^[^ ]*"); then echo "Failed to determine package hash"; return 4; fi
	
	# APPEND PACKAGE INFO TO INDEX
	echo "$pkginfo" >> "${INPUT_OUTPUT}/Packages"

	# APPEND PACKAGE SIZE AND HASH FIELDS TO INDEX
	echo "Size: $pkgsize" >> ./Packages
	echo "SHA256sum: $pkghash" >> ./Packages

	return 0
	
}


# ######################################################################
#
# ######################################################################

function getPackageInfo() {
	
	
}


# ######################################################################
#
# ######################################################################

function addGpgSignature() {
	
	if [ ! "$INPUT_PRIVATEGPG" == "" ]; then return 0; fi
	echo "Signing package index with gpg"

	echo "Importing key"
	if ! echo -n "$INPUT_PKGGPGREPOKEY" | base64 --decode | gpg --import; then echo "Failed to import key"; return 2; fi

	echo "Creating signature Packages.asc" 
	if ! gpg -a --output "${INPUT_OUTPUT}/Packages.asc" --detach-sig "${INPUT_OUTPUT}/Packages"; then echo "Failed to create signature"; return 3; fi

	echo "Package index signed with gpg"
	return 0
	
}


# ######################################################################
#
# ######################################################################

function addSignifySignature() {

	if [ ! "$INPUT_PKGSIGNIFYREPOKEY" == "" ]; then return 0; fi
	echo "Signing package index with gpg"
		
	if ! which signify-openbsd; then
		echo "Installing signify-openbsd..."
		if ! sudo apt-get install -y signify-openbsd; then echo "Failed to install signify-openbsd"; return 2; fi
	fi			

	echo "Importing key"
	if ! echo -n "$INPUT_PKGSIGNIFYREPOKEY" | base64 --decode > "key.sec"; then echo "Failed to import key"; return 3; fi
		
	echo "Creating signature  Packages.sig"
	if ! signify-openbsd -S -s "key.sec" -m "Packages"; then
		rm "key.sec"
		echo "Failed to create signature"
		return 4
	else
		rm "key.sec"
	fi
	
	echo "Package index signed with signify"
	return 0
	
}


# ######################################################################
# ######################################################################
#
# ######################################################################
# ######################################################################

function strictExit() { echo "$2"; if [ "$INPUT_STRICT" == "1" ]; then exit $1; fi }

echo "Creating repository"

echo "Initializing repository"
if ! initIndex; then echo "Failed to initialize repository"; exit 1; fi
if ! includeCache; then echo "Failed to include cache"; exit 2; fi

echo "Processing ipk files in ${INPUT_INPUT}"
while read -r pkgfile; do

	echo "Processing $pkgfile"
	if ! addPackage pkgfile; then strictExit 3 "Failed to process $pkgfile"; fi

done < <$(find "${INPUT_INPUT}" -iname '*.ipk')
echo "Processing completed."

if ! addGpgSignature(); then strictExit 4 "Failed to gpg sign package index."; fi
if ! addSignifySignature(); then strictExit 4 "Failed to signify sign package index."; fi

echo "Repository created."

echo "Successfully packed ${INPUT_PKGNAME}.ipk."
exit 0


# ######################################################################
# ######################################################################
# ######################################################################

#INPUT_INPUT=$(realpath --relative-to "$(pwd)" "$INPUT_INPUT")"/"
