#!/bin/bash
# Simple shell script install libhoard
# Authors: Kiran Thirumalai <kiran@scalemp.com>
#	   Josh Hunt <josh@scalemp.com>
#	   David Cho <david@scalemp.com>
# Copyright (C) ScaleMP Inc, 2009
#
# Rules:
# - These install scripts must have a pre-install/install/post
#   install phases -- clearly seperated
# - The script should return 0 on success and > 0 on error
# - These scripts should never wait for user input
#

source ../functions

appname=examples_TBD

#DV=2.0-090212
#appname=examples
#RPM_LIST="$appname-$DV.x86_64.rpm"
#
#INSTALL_LIST=""
#
#check_list() {
#
#	INSTALL_LIST=""
#	for x in $(echo $RPM_LIST | sed 's/.x86_64.rpm//g')
#	do
#		# Check if rpm is already installed?
#		rpm -q $x > /dev/null 2>&1
#
#		if [ "$?" -ne "0" ]; then
#			INSTALL_LIST="$INSTALL_LIST $x.x86_64.rpm"
#		fi
#	done
#
#}

#################################################################
# PRE INSTALL CHECK
#################################################################
pre() {

    if [ "$1" -eq "1" ]; then
            msg="$(
                    echo "this is an update"
                    echo "uninstalling previous installation"
            )"

            echo "$msg"
            uninstall
    fi


#	# Check to see if the rpms in the list are already installed.  If
#	# they are, then we just return back with a msg and the user can
#	# choose if they would like to force install of all the packages
#
#	#check_list
#
#	if [ -z "$INSTALL_LIST" ]; then
#		local msg="$(
#				echo "All $appname packages are up to date."
#				echo "Skipping install."
#			)"
#
#		echo "$msg"
#		return $RET_INST_INST
#	fi

	return $RET_INST_NOT
}

#################################################################
# INSTALLATION
#################################################################
install() {
	echo "Installing $appname:"


	return $RET_INST_SUCCESS

}

#################################################################
# POST INSTALLATION
#################################################################

post() {
	echo "Install of $appname is complete."
	return $RET_POST_SUCCESS
}

uninstall() {

	UNINSTALL_LIST="$RPM_LIST"

	echo "Uninstalling $appname:"

	check_list

#	#if some of the RPMs are missing we should remove them from the RPM list to remove
#	if [ -n "$INSTALL_LIST" ]; then
#
#		for rpm in "$INSTALL_LIST"
#		do
#			UNINSTALL_LIST="$(echo $UNINSTALL_LIST | sed 's/'"$rpm"'//')"
#		done
#
#		#if the list is empty we should return "already installed"
#		if [ -z "$UNINSTALL_LIST" ]; then
#			echo "already uninstalled"
#			return $RET_UNINST_UNINST
#		fi
#
#		echo "Missing the following RPMs: [$INSTALL_LIST]. Trying to remove the rest of the RPMs (if any left)"
#	fi
#
#	echo "removing [$UNINSTALL_LIST]"
#	rpm -e $(echo $UNINSTALL_LIST | sed 's/.x86_64.rpm//g') > /dev/null 2>&1
#
#	if [ "$?" -ne "0" ]; then
#
#		local msg1="$(
#				echo "There were problems uninstalling the $appname RPMs."
#				echo "Please try and remove them manually."
#			)"
#		echo "$msg1"
#		echo "$msg1" > $SYSTEM_MSG
#
#		return $RET_UNINST_FAIL
#	fi

	echo "Uninstall of $appname is complete."
	return $RET_UNINST_SUCCESS
}

case "$1" in
	"pre"		) pre $2;;
	"install"	) install $2;;
	"post"		) post $2;;
	"uninstall"	) uninstall;;
	*		)
			  pre
			  install
			  post;;
esac

