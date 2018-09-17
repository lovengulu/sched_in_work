#!/bin/bash
# TODO:
# Simple shell script install *** TBD  ***
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

    if [ "$1" = "1" ]; then
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

    # TODO: Shai commented that need test we are on RHEL7. Actually not clear why.

    if [ $(cat /proc/sys/kernel/sched_domain/cpu0/domain*/name | egrep -c -e "NUMA|ALL") -lt 2 ]; then
        local msg="Scheduler Domain tree does not require changes."
		echo "$msg"
		echo "$msg" > $SYSTEM_MSG
		return $RET_INST_NOT_SUPP
    else
        return $RET_INST_NOT
    fi

}

#################################################################
# INSTALLATION
#################################################################

calc_new_flags_value() {
    local flag_action=$1
    local current_flags_settings=$2
    local flag_to_change=$3

    local return_value=0

    if [ "${flag_action}" = 'set' ]; then
        return_value=$((current_flags_settings |  flag_to_change))
    elif [ "${flag_action}" = 'clear' ]; then
        return_value=$((current_flags_settings & ~flag_to_change))
    else
        # should never reach here unless someone changes the code the wrong way, so at least catch it early.
        echo "Wrong flag_action parameter: $flag_action"
        exit 1
    fi

    echo "${return_value}"

}

change_all_bits() {
    # change_all_bits manipulates flag's bits.
    # Input:
    #   bits_action: as required by calc_new_flags_value()

    bits_action=$1

    NUM_CPUS=$(grep -c processor /proc/cpuinfo)
    # TODO: SD_LOAD_BALANCE not used - ask tal.
    SD_LOAD_BALANCE=$((0x0001))
    SD_BALANCE_NEWIDLE=$((0x0002))
    SD_SERIALIZE=$((0x0400))


    # TODO: 'domains' is never used - confirm again
    domains=$(ls /proc/sys/kernel/sched_domain/cpu0 | wc -l)

    system_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 1)
    board_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 2 | head -n 1)

    for cpu in $(seq 0 $((NUM_CPUS-1))) ; do
        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags)
        # TODO - tal touched the same domain in two step. Verify that he actually intended the same domain and not a typo.
        sys_dom_flags=$((SD_BALANCE_NEWIDLE | SD_SERIALIZE))
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${sys_dom_flags})

        #TODO: DEBUG: only
        cur_flags0=$cur_flags
        upd_flags0=$upd_flags

#        echo "Changing system domain flags on CPU $cpu from $FLAGS to $((FLAGS & ~SD_BALANCE_NEWIDLE))"
#        sudo bash -c "echo $((FLAGS & ~SD_BALANCE_NEWIDLE)) >/proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags"
#
#        FLAGS=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags)
#        echo "Changing system domain flags on CPU $cpu from $FLAGS to $((FLAGS & ~SD_SERIALIZE))"
#        sudo bash -c "echo $((FLAGS & ~SD_SERIALIZE)) >/proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags"

        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$board_domain/flags)
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${SD_SERIALIZE})

        printf "0x%x " $SD_SERIALIZE

        printf "DEBUG: %03d  0x%x -> 0x%x ; 0x%x -> 0x%x  \n" $cpu $cur_flags0 $upd_flags0 $cur_flags $upd_flags

        exit

#        FLAGS=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$board_domain/flags)
#        echo "Changing board  domain flags on CPU $cpu from $FLAGS to $((FLAGS & ~SD_SERIALIZE))"
#        sudo bash -c "echo $((FLAGS & ~SD_SERIALIZE)) >/proc/sys/kernel/sched_domain/cpu$cpu/$board_domain/flags"
    done
}

install() {
    echo "Installing $appname:"

    change_all_bits clear

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

#	UNINSTALL_LIST="$RPM_LIST"

	echo "Uninstalling $appname:"

#	check_list
#
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

