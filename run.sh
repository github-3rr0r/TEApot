#!/usr/bin/env bash
####################################################
# Fuction   : Evaluate whether your system is affected by Meltdown and Spectre
# Platform  : Linux with gcc and other dependent libraries.
# Version   : v1.2.1
# Date      : 2020-11-06
# Author    : https://github.com/github-3rr0r
# Contact   :
####################################################

# Usage
show_usage() {
    cat <<EOF
Usage:
    Test mode                    :  $(basename $0) [-options]
    Generation mode              :  $(basename $0) [-options] -g [output-path]
    Test all vulnerablities      :  $(basename $0) [-o filename] [-m]
    Test specific vulnerablities :  $(basename $0) [-v "list of vulnerablities"] [-o filename] [-m]
    Show usage :                    $(basename $0) -h
    Show supported vulnerablities:  $(basename $0) -l [-m]
Modes:
    Test mode will test all/specific vulnerablities covered in this test suite, if -o option is enabled, valid PoCs will output.
    Generation mode will output PoCs of all/specific vulnerablities without test them.
Options:
    -g              generation mode, specific path to save specific PoCs
    -o              enable and specify a markdown file as output of valid PoCs
    -v              list of vulnerablities to be tested. If not specified, all vuls will be test
    -h              show usage
    -l              show supported vulnerablities
    -s              show simple supported vulnerablities options
    -t              specific timeout time, default 120s
    -m              used in test mode, simple result output will be available. 
                    0 means vulnerable, 1 means not vulnerable, other values mean error or not tested.
Valid args of -v option:
    You can select combination of vulnerabilities with following inputs:
    | Options     | Vulnerabilities to be tested    |
    | ----------- | ------------------------------- |
    | all         | All vulnerabilities             |
    | meltdown    | All Meltdown vulnerabilities    |
    | spectre     | All Spectre vulnerabilities     |
    | spectre_btb | All Spectre_BTB vulnerabilities |
    | spectre_pht | All Spectre_PHT vulnerabilities |
    | spectre_rsb | All Spectre_RSB vulnerabilities |
    You can also use multi_parameters to select specific vulnerabilities and separate them with spaces:
    | Options | Vulnerabilities to be tested | Options    | Vulnerabilities to be tested |
    | ------- | ---------------------------- | ---------- | ---------------------------- |
    | ac      | Meltdown_AC                  | btb_sa_ip  | Spectre_BTB_sa_ip            |
    | br      | Meltdown_BR                  | btb_sa_oop | Spectre_BTB_sa_oop           |
    | de      | Meltdown_DE                  | btb_ca_ip  | Spectre_BTB_ca_ip            |
    | gp      | Meltdown_GP                  | btb_ca_oop | Spectre_BTB_ca_oop           |
    | nm      | Meltdown_NM                  | pht_sa_ip  | Spectre_PHT_sa_ip            |
    | p       | Meltdown_P                   | pht_sa_oop | Spectre_PHT_sa_oop           |
    | pk      | Meltdown_PK                  | pht_ca_ip  | Spectre_PHT_ca_ip            |
    | rw      | Meltdown_RW                  | pht_ca_oop | Spectre_PHT_ca_oop           |
    | ss      | Meltdown_SS                  | rsb_sa_ip  | Spectre_RSB_sa_ip            |
    | ud      | Meltdown_UD                  | rsb_sa_oop | Spectre_RSB_sa_oop           |
    | us      | Meltdown_US                  | rsb_ca_ip  | Spectre_RSB_ca_ip            |
    |         |                              | rsb_ca_oop | Spectre_RSB_ca_oop           |
    |         |                              | stl        | Spectre_STL                  |
Examples:
    $(basename $0)
        Test all vulnerabilities.
    $(basename $0) -m
        Test all vulnerabilities and save simple result to result.txt.
    $(basename $0) -v "meltdown spectre_btb" -o codes
        Test all Meltdown and all Spectre_BTB type vulnerabilities, and save successful PoCs to path "codes".
    $(basename $0) -v "meltdown spectre_btb" -o codes -m
        Test all Meltdown and all Spectre_BTB type vulnerabilities, save simple result to result.txt, and successful PoCs to path "codes".
    $(basename $0) -v "meltdown spectre_btb" -g codes
        PoCs of Meltdown and all Spectre_BTB type vulnerabilities will be saved to path "codes" with out test.
EOF
}

show_supported_vuls() {
    cat <<EOF
Supported vulnerabilities list(Some of them are not valid but included for evaluating systematicly):
    | Systematic type name | CVE                                       | Description                                       |
    | -------------------- | ----------------------------------------- | ------------------------------------------------- |
    | Meltdown_AC          | -                                         | -                                                 |
    | Meltdown_BR          | -                                         | -                                                 |
    | Meltdown_DE          | -                                         | -                                                 |
    | Meltdown_GP          | CVE-2018-3640                             | Spectre V3a, rogue system register read           |
    | Meltdown_NM          | CVE-2018-3665                             | Lazy FP                                           |
    | Meltdown_P           | CVE-2018-3615/CVE-2018-3620/CVE-2018-3646 | Foreshadow, L1 terminal fault                     |
    | Meltdown_PK          | -                                         | -                                                 |
    | Meltdown_RW          |                                           | Spectre V1.2, write to page with read-only flag   |
    | Meltdown_SS          | -                                         | -                                                 |
    | Meltdown_UD          | -                                         | -                                                 |
    | Meltdown_US          | CVE-2017-5754                             | Meltdown, rogue data cache load                   |
    | Spectre_BTB          | CVE-2017-5715                             | Spectre V2, branch target injection               |
    | Spectre_PHT          | CVE-2017-5753                             | Spectre V1, bounds check bypass                   |
    | Spectre_RSB          | -                                         | -                                                 |
    | Spectre_STL          | CVE-2018-3693/CVE-2018-3639               | Spectre V1.1, NG and V4, speculative store bypass |
EOF
}

show_simple_supported_vuls() {
    echo "ac br de gp nm p pk rw ss ud us btb_sa_ip btb_sa_oop btb_ca_ip btb_ca_oop pht_sa_ip pht_sa_oop pht_ca_ip pht_ca_oop rsb_sa_ip rsb_sa_oop rsb_ca_ip rsb_ca_oop stl"
}

gen_mode=0
output_poc=0
gen_simple_result_file=0
timeout_time=120

while getopts "v:o:hlsmg:t:" arg; do
    case $arg in
    g)
        gen_mode=1
        output_file_path=$OPTARG
        ;;
    v)
        vuls=$OPTARG
        ;;
    o)
        output_poc=1
        output_file_path=$OPTARG
        ;;
    h)
        show_usage
        exit -1
        ;;
    l)
        show_supported_vuls
        exit -1
        ;;
    s)
        show_simple_supported_vuls
        exit -1
        ;;
    m)
        gen_simple_result_file=1
        ;;
    t)
        timeout_time=$OPTARG
        ;;
    \?)
        show_usage
        exit -1
        ;;
    esac
done

IFS=" "
arr_vuls=($vuls)
if [[ ${#arr_vuls[@]} == 0 ]]; then
    arr_vuls="all"
fi
all=-1
meltdown=-1
spectre=-1
btb=-1
pht=-1
rsb=-1
ac=-1
br=-1
de=-1
gp=-1
nm=-1
p=-1
pk=-1
rw=-1
ss=-1
ud=-1
us=-1
btb_sa_ip=-1
btb_sa_oop=-1
btb_ca_ip=-1
btb_ca_oop=-1
pht_sa_ip=-1
pht_sa_oop=-1
pht_ca_ip=-1
pht_ca_oop=-1
rsb_sa_ip=-1
rsb_sa_oop=-1
rsb_ca_ip=-1
rsb_ca_oop=-1
stl=-1
for vul in ${arr_vuls[@]}; do
    if [[ $vul == "all" ]]; then
        all=1
        break
    elif [[ $vul == "meltdown" ]]; then
        meltdown=1
    elif [[ $vul == "spectre" ]]; then
        spectre=1
    elif [[ $vul == "spectre_btb" ]]; then
        btb=1
    elif [[ $vul == "spectre_pht" ]]; then
        pht=1
    elif [[ $vul == "spectre_rsb" ]]; then
        rsb=1
    elif [[ $vul == "ac" ]]; then
        ac=1
    elif [[ $vul == "br" ]]; then
        br=1
    elif [[ $vul == "de" ]]; then
        de=1
    elif [[ $vul == "gp" ]]; then
        gp=1
    elif [[ $vul == "nm" ]]; then
        nm=1
    elif [[ $vul == "p" ]]; then
        p=1
    elif [[ $vul == "pk" ]]; then
        pk=1
    elif [[ $vul == "rw" ]]; then
        rw=1
    elif [[ $vul == "ss" ]]; then
        ss=1
    elif [[ $vul == "ud" ]]; then
        ud=1
    elif [[ $vul == "us" ]]; then
        us=1
    elif [[ $vul == "btb_sa_ip" ]]; then
        btb_sa_ip=1
    elif [[ $vul == "btb_sa_oop" ]]; then
        btb_sa_oop=1
    elif [[ $vul == "btb_ca_ip" ]]; then
        btb_ca_ip=1
    elif [[ $vul == "btb_ca_oop" ]]; then
        btb_ca_oop=1
    elif [[ $vul == "pht_sa_ip" ]]; then
        pht_sa_ip=1
    elif [[ $vul == "pht_sa_oop" ]]; then
        pht_sa_oop=1
    elif [[ $vul == "pht_ca_ip" ]]; then
        pht_ca_ip=1
    elif [[ $vul == "pht_ca_oop" ]]; then
        pht_ca_oop=1
    elif [[ $vul == "rsb_sa_ip" ]]; then
        rsb_sa_ip=1
    elif [[ $vul == "rsb_sa_oop" ]]; then
        rsb_sa_oop=1
    elif [[ $vul == "rsb_ca_ip" ]]; then
        rsb_ca_ip=1
    elif [[ $vul == "rsb_ca_oop" ]]; then
        rsb_ca_oop=1
    elif [[ $vul == "stl" ]]; then
        stl=1
    else
        printf "Invalid input \"$vul\", program exit!\n"
        exit -1
    fi
done

if [[ $gen_mode == 1 ]]; then
    printf "Generation mode! No vulnerabilities will be test.\n"
else
    printf "\n*******************************************************************\n"
    printf "***\tTEApot--Transient Execution Attack pot(Test suite)\t***\n"
    printf "*******************************************************************\n\n"
    # Get pagesize and threshold
    printf "\033[32m[Init]\033[0m\tInitialize tests...\n"
    printf "\033[32m[Init]\033[0m\tThese vuls will be tested: $vuls\n"
    pagesize=$(./libcache/get_pagesize)
    threshold=$(./libcache/get_threshold)
    printf "\033[32m[Ready]\033[0m\tPagesize = $pagesize, Threshold = $threshold, Timeout = $timeout_time s\n\n"

    printf "\033[32m[Begin]\033[0m\tTest begins...\n\n"

    result=""
    # Exploit
    # meltdown_ac
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ac == 1 ]]; then
        printf "Meltdown_AC Begins...\n"
        var=`./meltdown/AC/poc $pagesize $threshold $timeout_time 2>&1`
        ac=$?
        printf "$var\n"
        result="$result!!\nac $ac\n$var\n!!\n\n"
        printf "Meltdown_AC Done...\n\n"
    fi
    # meltdown_br
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $br == 1 ]]; then
        printf "Meltdown_BR Begins...\n"
        var=`./meltdown/BR/poc $pagesize $threshold 2>&1`
        br=$?
        printf "$var\n"
        result="$result!!\nbr $br\n$var\n!!\n\n"
        printf "Meltdown_BR Done...\n\n"
    fi
    # meltdown_de
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $de == 1 ]]; then
        printf "Meltdown_DE Begins...\n"
        var=`./meltdown/DE/poc $pagesize $threshold $timeout_time 2>&1`
        de=$?
        printf "$var\n"
        result="$result!!\nde $de\n$var\n!!\n\n"
        printf "Meltdown_DE Done...\n\n"
    fi
    # meltdown_gp
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $gp == 1 ]]; then
        printf "Meltdown_GP Begins...\n"
        var1=`sudo insmod libcr3/kernel_module.ko 2>&1`
        var2=`./meltdown/GP/poc $pagesize $threshold $timeout_time 2>&1`
        gp=$?
        var3=`sudo rmmod libcr3/kernel_module.ko 2>&1`
        printf "$var1\n$var2$var3\n"
        result="$result!!\ngp $gp\n$var1\n$var2$var3\n!!\n\n"
        printf "Meltdown_GP Done...\n\n"
    fi
    # meltdown_nm
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $nm == 1 ]]; then
        printf "Launching victim process for Meltdown_NM...\n"
        taskset 0x2 ./meltdown/NM/victim &
        victimpid=$!
        sleep 3
        printf "Done...\n"
        printf "Meltdown_NM Begins...\n"
        var=`taskset 0x2 ./meltdown/NM/poc $pagesize $threshold $timeout_time 2>&1`
        nm=$?
        printf "$var\n"
        result="$result!!\nnm $nm\n$var\n!!\n\n"
        printf "Meltdown_NM Done...\n"
        printf "Terminating victim process for Meltdown_NM...\n"
        kill $victimpid >/dev/null
        sleep 1
        printf "Done...\n\n"
    fi
    # meltdown_p
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $p == 1 ]]; then
        printf "Meltdown_P Begins...\n"
        var1=`sudo insmod libpte/module/pteditor.ko 2>&1`
        var2=`./meltdown/P/poc $pagesize $threshold $timeout_time 2>&1`
        p=$?
        var3=`sudo rmmod libpte/module/pteditor.ko 2>&1`
        printf "$var1\n$var2$var3\n"
        result="$result!!\np $p\n$var1\n$var2$var3\n!!\n\n"
        printf "Meltdown_P Done...\n\n"
    fi
    # meltdown_pk
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $pk == 1 ]]; then
        printf "Meltdown_PK Begins...\n"
        var=`./meltdown/PK/poc $pagesize $threshold $timeout_time 2>&1`
        pk=$?
        printf "$var\n"
        result="$result!!\npk $pk\n$var\n!!\n\n"
        printf "Meltdown_PK Done...\n\n"
    fi
    # meltdown_rw
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $rw == 1 ]]; then
        printf "Meltdown_RW Begins...\n"
        var=`./meltdown/RW/poc $pagesize $threshold $timeout_time 2>&1`
        rw=$?
        printf "$var\n"
        result="$result!!\nrw $rw\n$var\n!!\n\n"
        printf "Meltdown_RW Done...\n\n"
    fi
    # meltdown_ss
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ss == 1 ]]; then
        printf "Meltdown_SS Begins...\n"
        var=`./meltdown/SS/poc $pagesize $threshold $timeout_time 2>&1`
        ss=$?
        printf "$var\n"
        result="$result!!\nss $ss\n$var\n!!\n\n"
        printf "Meltdown_SS Done...\n\n"
    fi
    # meltdown_ud
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ud == 1 ]]; then
        printf "Meltdown_UD Begins...\n"
        var=`./meltdown/UD/poc $pagesize $threshold $timeout_time 2>&1`
        ud=$?
        printf "$var\n"
        result="$result!!\nud $ud\n$var\n!!\n\n"
        printf "Meltdown_UD Done...\n\n"
        
    fi
    # meltdown_us
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $us == 1 ]]; then
        printf "Meltdown_US Begins...\n"
        var1=`sudo insmod libpte/module/pteditor.ko 2>&1`
        var2=`./meltdown/US/poc $pagesize $threshold $timeout_time 2>&1`
        us=$?
        var3=`sudo rmmod libpte/module/pteditor.ko 2>&1`
        printf "$var1\n$var2$var3\n"
        printf "Meltdown_US Done...\n\n"
        result="$result!!\nus $us\n$var1\n$var2$var3\n!!\n\n"
    fi

    # spectre_btb
    # spectre_btb_ca_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_ip == 1 ]]; then
        printf "Spectre_BTB_ca_ip Begins...\n"
        var=`./spectre/BTB/ca_ip/poc $pagesize $threshold $timeout_time 2>&1`
        btb_ca_ip=$?
        printf "$var\n"
        result="$result!!\nbtb_ca_ip $btb_ca_ip\n$var\n!!\n\n"
        printf "Spectre_BTB_ca_ip Done...\n\n"
    fi
    # spectre_btb_ca_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_oop == 1 ]]; then
        printf "Spectre_BTB_ca_oop Begins...\n"
        cd spectre/BTB/ca_oop
        var=`./exploit.sh 2>&1`
        btb_ca_oop=$?
        printf "$var\n"
        result="$result!!\nbtb_ca_oop $btb_ca_oop\n$var\n!!\n\n"
        printf "Spectre_BTB_ca_oop Done...\n\n"
        cd ../../../
    fi
    # spectre_btb_sa_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_ip == 1 ]]; then
        printf "Spectre_BTB_sa_ip Begins...\n"
        var=`./spectre/BTB/sa_ip/poc $pagesize $threshold $timeout_time 2>&1`
        btb_sa_ip=$?
        printf "$var\n"
        result="$result!!\nbtb_sa_ip $btb_sa_ip\n$var\n!!\n\n"
        printf "Spectre_BTB_sa_ip Done...\n\n"
    fi
    # spectre_btb_sa_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_oop == 1 ]]; then
        printf "Spectre_BTB_sa_oop Begins...\n"
        var=`./spectre/BTB/sa_oop/poc $pagesize $threshold $timeout_time 2>&1`
        btb_sa_oop=$?
        printf "$var\n"
        result="$result!!\nbtb_sa_oop $btb_sa_oop\n$var\n!!\n\n"
        printf "Spectre_BTB_sa_oop Done...\n\n"
    fi

    # spectre_pht
    # spectre_pht_ca_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_ip == 1 ]]; then
        printf "Spectre_PHT_ca_ip Begins...\n"
        var=`./spectre/PHT/ca_ip/poc $pagesize $threshold $timeout_time 2>&1`
        pht_ca_ip=$?
        printf "$var\n"
        result="$result!!\npht_ca_ip $pht_ca_ip\n$var\n!!\n\n"
        printf "Spectre_PHT_ca_ip Done...\n\n"
        
    fi
    # spectre_pht_ca_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_oop == 1 ]]; then
        printf "Spectre_PHT_ca_oop Begins...\n"
        var=`./spectre/PHT/ca_oop/poc $pagesize $threshold $timeout_time 2>&1`
        pht_ca_oop=$?
        printf "$var\n"
        result="$result!!\npht_ca_oop $pht_ca_oop\n$var\n!!\n\n"
        printf "Spectre_PHT_ca_oop Done...\n\n"
    fi
    # spectre_pht_sa_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_ip == 1 ]]; then
        printf "Spectre_PHT_sa_ip Begins...\n"
        var=`./spectre/PHT/sa_ip/poc $pagesize $threshold $timeout_time 2>&1`
        pht_sa_ip=$?
        printf "$var\n"
        result="$result!!\npht_sa_ip $pht_sa_ip\n$var\n!!\n\n"
        printf "Spectre_PHT_sa_ip Done...\n\n"
    fi
    # spectre_pht_sa_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_oop == 1 ]]; then
        printf "Spectre_PHT_sa_oop Begins...\n"
        var=`./spectre/PHT/sa_oop/poc $pagesize $threshold $timeout_time 2>&1`
        pht_sa_oop=$?
        printf "$var\n"
        result="$result!!\npht_sa_oop $pht_sa_oop\n$var\n!!\n\n"
        printf "Spectre_PHT_sa_oop Done...\n\n"
    fi

    # spectre_rsb
    # spectre_rsb_ca_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_ip == 1 ]]; then
        printf "Spectre_RSB_ca_ip Begins...\n"
        var=`./spectre/RSB/ca_ip/poc $pagesize $threshold $timeout_time 2>&1`
        rsb_ca_ip=$?
        printf "$var\n"
        result="$result!!\nrsb_ca_ip $rsb_ca_ip\n$var\n!!\n\n"
        printf "Spectre_RSB_ca_ip Done...\n\n"
    fi
    # spectre_rsb_ca_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_oop == 1 ]]; then
        printf "Spectre_RSB_ca_oop Begins...\n"
        var=`./spectre/RSB/ca_oop/poc $pagesize $threshold $timeout_time 2>&1`
        rsb_ca_oop=$?
        printf "$var\n"
        result="$result!!\nrsb_ca_oop $rsb_ca_oop\n$var\n!!\n\n"
        printf "Spectre_RSB_ca_oop Done...\n\n"
    fi
    # spectre_rsb_sa_ip
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_ip == 1 ]]; then
        printf "Spectre_RSB_sa_ip Begins...\n"
        var=`./spectre/RSB/sa_ip/poc $pagesize $threshold $timeout_time 2>&1`
        rsb_sa_ip=$?
        printf "$var\n"
        result="$result!!\nrsb_sa_ip $rsb_sa_ip\n$var\n!!\n\n"
        printf "Spectre_RSB_sa_ip Done...\n\n"
    fi
    # spectre_rsb_sa_oop
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_oop == 1 ]]; then
        printf "Spectre_RSB_sa_oop Begins...\n"
        var=`./spectre/RSB/sa_oop/poc $pagesize $threshold $timeout_time 2>&1`
        rsb_sa_oop=$?
        printf "$var\n"
        result="$result!!\nrsb_sa_oop $rsb_sa_oop\n$var\n!!\n\n"
        printf "Spectre_RSB_sa_oop Done...\n\n"
    fi

    # spectre_stl
    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $stl == 1 ]]; then
        printf "Spectre_STL Begins...\n"
        var=`./spectre/STL/poc $pagesize $threshold $timeout_time 2>&1`
        stl=$?
        printf "$var\n"
        result="$result!!\nstl $stl\n$var\n!!\n\n"
        printf "Spectre_STL Done...\n\n"
    fi
    printf "\033[32m[Done]\033[0m\tAll tests done!\n"

    # Output report
    result_n="\033[32mN\033[0m"
    result_y="\033[31mY\033[0m"
    result_e="\033[33mE\033[0m"

    if [[ $ac == 0 ]]; then
        result_ac=$result_y
    elif [[ $ac == 1 ]]; then
        result_ac=$result_n
    else
        result_ac=$result_e
    fi

    if [[ $br == 0 ]]; then
        result_br=$result_y
    elif [[ $br == 1 ]]; then
        result_br=$result_n
    else
        result_br=$result_e
    fi

    if [[ $de == 0 ]]; then
        result_de=$result_y
    elif [[ $de == 1 ]]; then
        result_de=$result_n
    else
        result_de=$result_e
    fi

    if [[ $gp == 0 ]]; then
        result_gp=$result_y
    elif [[ $gp == 1 ]]; then
        result_gp=$result_n
    else
        result_gp=$result_e
    fi

    if [[ $nm == 0 ]]; then
        result_nm=$result_y
    elif [[ $nm == 1 ]]; then
        result_nm=$result_n
    else
        result_nm=$result_e
    fi

    if [[ $p == 0 ]]; then
        result_p=$result_y
    elif [[ $p == 1 ]]; then
        result_p=$result_n
    else
        result_p=$result_e
    fi

    if [[ $pk == 0 ]]; then
        result_pk=$result_y
    elif [[ $pk == 1 ]]; then
        result_pk=$result_n
    else
        result_pk=$result_e
    fi

    if [[ $rw == 0 ]]; then
        result_rw=$result_y
    elif [[ $rw == 1 ]]; then
        result_rw=$result_n
    else
        result_rw=$result_e
    fi

    if [[ $ss == 0 ]]; then
        result_ss=$result_y
    elif [[ $ss == 1 ]]; then
        result_ss=$result_n
    else
        result_ss=$result_e
    fi

    if [[ $ud == 0 ]]; then
        result_ud=$result_y
    elif [[ $ud == 1 ]]; then
        result_ud=$result_n
    else
        result_ud=$result_e
    fi

    if [[ $us == 0 ]]; then
        result_us=$result_y
    elif [[ $us == 1 ]]; then
        result_us=$result_n
    else
        result_us=$result_e
    fi

    if [[ $btb_sa_ip == 0 ]]; then
        result_btb_sa_ip=$result_y
    elif [[ $btb_sa_ip == 1 ]]; then
        result_btb_sa_ip=$result_n
    else
        result_btb_sa_ip=$result_e
    fi

    if [[ $btb_sa_oop == 0 ]]; then
        result_btb_sa_oop=$result_y
    elif [[ $btb_sa_oop == 1 ]]; then
        result_btb_sa_oop=$result_n
    else
        result_btb_sa_oop=$result_e
    fi

    if [[ $btb_ca_ip == 0 ]]; then
        result_btb_ca_ip=$result_y
    elif [[ $btb_ca_ip == 1 ]]; then
        result_btb_ca_ip=$result_n
    else
        result_btb_ca_ip=$result_e
    fi

    if [[ $btb_ca_oop == 0 ]]; then
        result_btb_ca_oop=$result_y
    elif [[ $btb_ca_oop == 1 ]]; then
        result_btb_ca_oop=$result_n
    else
        result_btb_ca_oop=$result_e
    fi

    if [[ $pht_sa_ip == 0 ]]; then
        result_pht_sa_ip=$result_y
    elif [[ $pht_sa_ip == 1 ]]; then
        result_pht_sa_ip=$result_n
    else
        result_pht_sa_ip=$result_e
    fi

    if [[ $pht_sa_oop == 0 ]]; then
        result_pht_sa_oop=$result_y
    elif [[ $pht_sa_oop == 1 ]]; then
        result_pht_sa_oop=$result_n
    else
        result_pht_sa_oop=$result_e
    fi

    if [[ $pht_ca_ip == 0 ]]; then
        result_pht_ca_ip=$result_y
    elif [[ $pht_ca_ip == 1 ]]; then
        result_pht_ca_ip=$result_n
    else
        result_pht_ca_ip=$result_e
    fi

    if [[ $pht_ca_oop == 0 ]]; then
        result_pht_ca_oop=$result_y
    elif [[ $pht_ca_oop == 1 ]]; then
        result_pht_ca_oop=$result_n
    else
        result_pht_ca_oop=$result_e
    fi

    if [[ $rsb_sa_ip == 0 ]]; then
        result_rsb_sa_ip=$result_y
    elif [[ $rsb_sa_ip == 1 ]]; then
        result_rsb_sa_ip=$result_n
    else
        result_rsb_sa_ip=$result_e
    fi

    if [[ $rsb_sa_oop == 0 ]]; then
        result_rsb_sa_oop=$result_y
    elif [[ $rsb_sa_oop == 1 ]]; then
        result_rsb_sa_oop=$result_n
    else
        result_rsb_sa_oop=$result_e
    fi

    if [[ $rsb_ca_ip == 0 ]]; then
        result_rsb_ca_ip=$result_y
    elif [[ $rsb_ca_ip == 1 ]]; then
        result_rsb_ca_ip=$result_n
    else
        result_rsb_ca_ip=$result_e
    fi

    if [[ $rsb_ca_oop == 0 ]]; then
        result_rsb_ca_oop=$result_y
    elif [[ $rsb_ca_oop == 1 ]]; then
        result_rsb_ca_oop=$result_n
    else
        result_rsb_ca_oop=$result_e
    fi

    if [[ $stl == 0 ]]; then
        result_stl=$result_y
    elif [[ $stl == 1 ]]; then
        result_stl=$result_n
    else
        result_stl=$result_e
    fi

    printf "\033[32m[Done]\033[0m\tFinal report
|                          REPORT                           |
| --------------------------------------------------------- |
| Meltdowns       | Results | Spectres            | Results |
| --------------- | ------- | ------------------- | ------- |
| Meltdown_AC     | $result_ac       | Spectre_BTB_sa_ip   | $result_btb_sa_ip       |
| Meltdown_BR     | $result_br       | Spectre_BTB_sa_oop  | $result_btb_sa_oop       |
| Meltdown_DE     | $result_de       | Spectre_BTB_ca_ip   | $result_btb_ca_ip       |
| Meltdown_GP     | $result_gp       | Spectre_BTB_ca_oop  | $result_btb_ca_oop       |
| Meltdown_NM     | $result_nm       | Spectre_PHT_sa_ip   | $result_pht_sa_ip       |
| Meltdown_P      | $result_p       | Spectre_PHT_sa_oop  | $result_pht_sa_oop       |
| Meltdown_PK     | $result_pk       | Spectre_PHT_ca_ip   | $result_pht_ca_ip       |
| Meltdown_RW     | $result_rw       | Spectre_PHT_ca_oop  | $result_pht_ca_oop       |
| Meltdown_SS     | $result_ss       | Spectre_RSB_sa_ip   | $result_rsb_sa_ip       |
| Meltdown_UD     | $result_ud       | Spectre_RSB_sa_oop  | $result_rsb_sa_oop       |
| Meltdown_US     | $result_us       | Spectre_RSB_ca_ip   | $result_rsb_ca_ip       |
|                 |         | Spectre_RSB_ca_oop  | $result_rsb_ca_oop       |
|                 |         | Spectre_STL         | $result_stl       |
Note: \033[32m[N]\033[0m: Not vulnerable; \033[31m[Y]\033[0m: Vulnerable; \033[33m[E]\033[0m: Error/Not tested
"

    # generate simple result file
    if [[ $gen_simple_result_file == 1 ]]; then
        if [[ -f result.txt ]]; then
            rm result.txt
        fi
        printf "$result" >> result.txt
        sed -i 's/\[[0-9][0-9]m//' result.txt
        sed -i 's/\[0m//' result.txt
        printf "\n\033[32m[Done]\033[0m\tSimple result file generated(result.txt).\n"
    fi
fi

# Output PoCs
#################
valid_count=1
if [[ $gen_mode == 1 ]]; then
    if [[ -d $output_file_path ]]; then
        rm -rf $output_file_path
    fi
    mkdir $output_file_path
    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ac == 1 ]]; then
        cp meltdown/AC/main.c $output_file_path/meltdown_ac.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $br == 1 ]]; then
        cp meltdown/BR/main.c $output_file_path/meltdown_br.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $de == 1 ]]; then
        cp meltdown/DE/main.c $output_file_path/meltdown_de.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $gp == 1 ]]; then
        cp meltdown/GP/main.c $output_file_path/meltdown_gp.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $nm == 1 ]]; then
        cp meltdown/NM/main.c $output_file_path/meltdown_nm.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $p == 1 ]]; then
        cp meltdown/P/main.c $output_file_path/meltdown_p.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $pk == 1 ]]; then
        cp meltdown/PK/main.c $output_file_path/meltdown_pk.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $rw == 1 ]]; then
        cp meltdown/RW/main.c $output_file_path/meltdown_rw.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ss == 1 ]]; then
        cp meltdown/SS/main.c $output_file_path/meltdown_ss.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ud == 1 ]]; then
        cp meltdown/UD/main.c $output_file_path/meltdown_ud.c
    fi

    if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $us == 1 ]]; then
        cp meltdown/US/main.c $output_file_path/meltdown_us.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_ip == 1 ]]; then
        cp spectre/BTB/sa_ip/main.cpp $output_file_path/spectre_btb_sa_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_oop == 1 ]]; then
        cp spectre/BTB/sa_oop/main.c $output_file_path/spectre_btb_sa_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_ip == 1 ]]; then
        cp spectre/BTB/ca_ip/main.cpp $output_file_path/spectre_btb_ca_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_oop == 1 ]]; then
        cp spectre/BTB/ca_oop/main.c $output_file_path/spectre_btb_ca_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_ip == 1 ]]; then
        cp spectre/PHT/sa_ip/main.c $output_file_path/spectre_pht_sa_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_oop == 1 ]]; then
        cp spectre/PHT/sa_oop/main.c $output_file_path/spectre_pht_sa_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_ip == 1 ]]; then
        cp spectre/PHT/ca_ip/main.c $output_file_path/spectre_pht_ca_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_oop == 1 ]]; then
        cp spectre/PHT/ca_oop/main.c $output_file_path/spectre_pht_ca_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_ip == 1 ]]; then
        cp spectre/RSB/sa_ip/main.c $output_file_path/spectre_rsb_sa_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_oop == 1 ]]; then
        cp spectre/RSB/sa_oop/main.c $output_file_path/spectre_rsb_sa_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_ip == 1 ]]; then
        cp spectre/RSB/ca_ip/main.c $output_file_path/spectre_rsb_ca_ip.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_oop == 1 ]]; then
        cp spectre/RSB/ca_oop/main.c $output_file_path/spectre_rsb_ca_oop.c
    fi

    if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $stl == 1 ]]; then
        cp spectre/STL/main.c $output_file_path/spectre_stl.c
    fi
    printf "\033[32m[Done]\033[0m\tSpecific PoCs have been saved to $output_file_path\n"
else
    if [[ $output_poc == 1 ]]; then
        if [[ -d $output_file_path ]]; then
            rm -rf $output_file_path
        fi
        mkdir $output_file_path
        if [[ $ac == 0 ]]; then
            cp meltdown/AC/main.c $output_file_path/meltdown_ac.c
        fi

        if [[ $br == 0 ]]; then
            cp meltdown/BR/main.c $output_file_path/meltdown_br.c
        fi

        if [[ $de == 0 ]]; then
            cp meltdown/DE/main.c $output_file_path/meltdown_de.c
        fi

        if [[ $gp == 0 ]]; then
            cp meltdown/GP/main.c $output_file_path/meltdown_gp.c
        fi

        if [[ $nm == 0 ]]; then
            cp meltdown/NM/main.c $output_file_path/meltdown_nm.c
        fi

        if [[ $p == 0 ]]; then
            cp meltdown/P/main.c $output_file_path/meltdown_p.c
        fi

        if [[ $pk == 0 ]]; then
            cp meltdown/PK/main.c $output_file_path/meltdown_pk.c
        fi

        if [[ $rw == 0 ]]; then
            cp meltdown/RW/main.c $output_file_path/meltdown_rw.c
        fi

        if [[ $ss == 0 ]]; then
            cp meltdown/SS/main.c $output_file_path/meltdown_ss.c
        fi

        if [[ $ud == 0 ]]; then
            cp meltdown/UD/main.c $output_file_path/meltdown_ud.c
        fi

        if [[ $us == 0 ]]; then
            cp meltdown/US/main.c $output_file_path/meltdown_us.c
        fi

        if [[ $btb_sa_ip == 0 ]]; then
            cp spectre/BTB/sa_ip/main.cpp $output_file_path/spectre_btb_sa_ip.c
        fi

        if [[ $btb_sa_oop == 0 ]]; then
            cp spectre/BTB/sa_oop/main.c $output_file_path/spectre_btb_sa_oop.c
        fi

        if [[ $btb_ca_ip == 0 ]]; then
            cp spectre/BTB/ca_ip/main.cpp $output_file_path/spectre_btb_ca_ip.c
        fi

        if [[ $btb_ca_oop == 0 ]]; then
            cp spectre/BTB/ca_oop/main.c $output_file_path/spectre_btb_ca_oop.c
        fi

        if [[ $pht_sa_ip == 0 ]]; then
            cp spectre/PHT/sa_ip/main.c $output_file_path/spectre_pht_sa_ip.c
        fi

        if [[ $pht_sa_oop == 0 ]]; then
            cp spectre/PHT/sa_oop/main.c $output_file_path/spectre_pht_sa_oop.c
        fi

        if [[ $pht_ca_ip == 0 ]]; then
            cp spectre/PHT/ca_ip/main.c $output_file_path/spectre_pht_ca_ip.c
        fi

        if [[ $pht_ca_oop == 0 ]]; then
            cp spectre/PHT/ca_oop/main.c $output_file_path/spectre_pht_ca_oop.c
        fi

        if [[ $rsb_sa_ip == 0 ]]; then
            cp spectre/RSB/sa_ip/main.c $output_file_path/spectre_rsb_sa_ip.c
        fi

        if [[ $rsb_sa_oop == 0 ]]; then
            cp spectre/RSB/sa_oop/main.c $output_file_path/spectre_rsb_sa_oop.c
        fi

        if [[ $rsb_ca_ip == 0 ]]; then
            cp spectre/RSB/ca_ip/main.c $output_file_path/spectre_rsb_ca_ip.c
        fi

        if [[ $rsb_ca_oop == 0 ]]; then
            cp spectre/RSB/ca_oop/main.c $output_file_path/spectre_rsb_ca_oop.c
        fi

        if [[ $stl == 0 ]]; then
            cp spectre/STL/main.c $output_file_path/spectre_stl.c
        fi
        printf "\033[32m[Done]\033[0m\tValid PoCs have been saved to $output_file_path\n"
    fi
fi
printf "\n\033[32m[Done]\033[0m\tDone!\n\n"
#################
