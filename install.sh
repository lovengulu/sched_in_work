#!/bin/bash
# Simple shell script install *** TBD  *** #TODO !!!
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

    # TODO: Shai commented that need test we are on RHEL7. Actually not clear why???

    if [ $(cat /proc/sys/kernel/sched_domain/cpu0/domain*/name | egrep -c -e "NUMA|ALL") -lt 2 ]; then
        local msg="Scheduler Domain tree does not require changes."
		echo "$msg"
		echo "$msg" > $SYSTEM_MSG
		return $RET_INST_NOT_SUPP
    fi

    set_changes_arrays
	prep_sysctl_params
	if [ -z "$CHANGE_LIST" ]; then
		# If the list is empty this means the parameters already
		# have the correct value
		local msg="$(
				echo
				echo "The $appname sysctl parameters are already correctly set."
				echo "Installation will be skipped."
				echo
			)"

		echo "$msg"
		return $RET_INST_INST
	fi
	return $RET_INST_NOT

}

#################################################################
# utils functions
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
	    # If we get it, it is a coding bug. exit so it easy to find and fix.
        echo "ERROR: calc_new_flags_value() requires one mandatory parameter: [ set | clear ]. Entered: $flag_action"
        exit 1
    fi

    echo "${return_value}"

}


immediate_flags_change() {
    # using the pre-set arrays (PARAMETER & VALUE), change the flags.
    # IMPORTANT: the flags change is thought the file system, so all changes are gone once system reboots.

    for idx in $(seq 0 $(( ${#PARAMETER[@]} - 1 ))); do
        printf "DEBUG Changing:  %-40s %6x => %6x \n" ${PARAMETER[${idx}]}  ${ORIG_VALUE[${idx}]} ${VALUE[${idx}]}

        dest_file=$(echo "/proc/sys/${PARAMETER[${idx}]}" | tr '.' '/')
        echo "DEBUG: echo ${VALUE[${idx}]} > ${dest_file}"
        # TODO: don't forget to perform here the actual change
    done

    # TODO - consider again if return value is required.

}

set_changes_arrays() {
    # create three arrays of the 'sysctl' parameters to revise: PARAMETER, VALUE, & ORIG_VALUE
    # Those arrays are used (or may be used) for debugging, logging and assisting in actual

    # Input:
    #   bits_action: as required by calc_new_flags_value()

    bits_action=$1

	if [ -z "$bits_action" ]; then
	    # If we get it, it is a coding bug. exit so it easy to find and fix.
        echo "ERROR: set_changes_arrays() requires one mandatory parameter"
        exit 1
	fi


    NUM_CPUS=$(grep -c processor /proc/cpuinfo)
    # Currently we are not SD_LOAD_BALANCE for various reasons. may consider again later.
    SD_LOAD_BALANCE=$((0x0001))
    SD_BALANCE_NEWIDLE=$((0x0002))
    SD_SERIALIZE=$((0x0400))

    system_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 1)
    board_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 2 | head -n 1)

    # The following arrays assist for setting the parameters using 'sysctl'
    PARAMETER=()
    VALUE=()
    # ORIG_VALUE is for debugging only.
    ORIG_VALUE=()
    CHANGE_LIST=""

    for cpu in $(seq 0 $((NUM_CPUS-1))) ; do
        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags)
        sys_dom_flags=$((SD_BALANCE_NEWIDLE | SD_SERIALIZE))
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${sys_dom_flags})

        PARAMETER+=(kernel.sched_domain.cpu$cpu.$system_domain.flags)
        ORIG_VALUE+=(${cur_flags})
        VALUE+=(${upd_flags})

        #TODO: DEBUG: only
        cur_flags0=$cur_flags
        upd_flags0=$upd_flags


        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$board_domain/flags)
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${SD_SERIALIZE})

        PARAMETER+=(kernel.sched_domain.cpu$cpu.$board_domain.flags)
        ORIG_VALUE+=(${cur_flags})
        VALUE+=(${upd_flags})

        # TODO: DEBUG START section
        #printf "DEBUG: %03d  0x%x -> 0x%x ; 0x%x -> 0x%x  \n" $cpu $cur_flags0 $upd_flags0 $cur_flags $upd_flags
        #exit
        # TODO: DEBUG  END  section

    done
}


temporary() {
    # perform temporary flags change (via file system)
    # input - as required by calc_new_flags_value(). Default: 'clear'
    temporary_action=${1:-clear}

    set_changes_arrays ${temporary_action}
    immediate_flags_change ${temporary_action}

}
#################################################################
# INSTALLATION
#################################################################

install() {

    echo "Installing $appname:"


    set_changes_arrays clear
    prep_sysctl_params
    set_sysctl_params
    immediate_flags_change clear

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

	echo "Reverting $appname settings:"
	set_changes_arrays clear
	undo_sysctl_params
	if [ "$?" -ne "0" ]; then
		echo "Problem with reverting $appname  settings."
		echo "There was a problem reverting the $appname setting.  You may revert it by manually editing /etc/sysctl.conf"
		return $RET_UNINST_UNINST
    else
        # undo_sysctl_params() can leave many empty lines. If at EOF easy to remove them.
        file_with_no_empty_lines_at_eof=$(</etc/sysctl.conf)
        printf '%s\n' "${file_with_no_empty_lines_at_eof}" > /etc/sysctl.conf
	fi

	echo "$appname settings reverted successfully."
	return $RET_UNINST_SUCCESS
}


case "$1" in
	"pre"		) pre $2;;
	"install"	) install $2;;
	"post"		) post $2;;
	            # temporary() sets the flags for enhancements testing without 'sysctl'. So changes gone once we reboot
	"temporary" ) temporary;;
	"uninstall"	) uninstall;;
	*		)
			  pre
			  install
			  post;;
esac

