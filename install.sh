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

    # TODO: Shai commented that need test we are on RHEL7. Actually not clear why???

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
    echo TBD
}

test_temporary_tune() {
    # change_all_bits manipulates flag's bits.
    # Input:
    #   bits_action: as required by calc_new_flags_value()

    bits_action=$1

    NUM_CPUS=$(grep -c processor /proc/cpuinfo)
    # Currently we are not SD_LOAD_BALANCE for various reasons. may consider again later.
    SD_LOAD_BALANCE=$((0x0001))
    SD_BALANCE_NEWIDLE=$((0x0002))
    SD_SERIALIZE=$((0x0400))

    system_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 1)
    board_domain=$(ls /proc/sys/kernel/sched_domain/cpu0 | tail -n 2 | head -n 1)

    for cpu in $(seq 0 $((NUM_CPUS-1))) ; do
        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$system_domain/flags)
        sys_dom_flags=$((SD_BALANCE_NEWIDLE | SD_SERIALIZE))
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${sys_dom_flags})

        #TODO: DEBUG: only
        cur_flags0=$cur_flags
        upd_flags0=$upd_flags


        cur_flags=$(cat /proc/sys/kernel/sched_domain/cpu$cpu/$board_domain/flags)
        upd_flags=$(calc_new_flags_value ${bits_action} ${cur_flags} ${SD_SERIALIZE})


        # TODO: DEBUG START section
        printf "DEBUG: %03d  0x%x -> 0x%x ; 0x%x -> 0x%x  \n" $cpu $cur_flags0 $upd_flags0 $cur_flags $upd_flags
        exit
        # TODO: DEBUG  END  section

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
	# TODO: if changing via sysctl, the return message should be that need to reboot in order for the change to have impact.
	return $RET_POST_SUCCESS
}

uninstall() {

	echo "Uninstalling $appname:"


	echo "Uninstall of $appname is complete."
	return $RET_UNINST_SUCCESS
}

case "$1" in
	"pre"		) pre $2;;
	"install"	) install $2;;
	"post"		) post $2;;
	"test"      ) test_temporary_tune;;
	"uninstall"	) uninstall;;
	*		)
			  pre
			  install
			  post;;
esac

