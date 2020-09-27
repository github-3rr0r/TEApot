printf "\n***\tTEApot--Transient Execution Attack pot(Test suite)\t***\n\n"
# Select vulnerabilities
printf "You can select combination of vulnerabilities with following inputs:
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
| stl     | Spectre_STL                  | rsb_ca_oop | Spectre_RSB_ca_oop           |

\033[32m[Input]\033[0m Please select the vulnerabilities to be tested (default all): "
read vuls
IFS=" "
arr_vuls=($vuls)
if [[ ${#arr_vuls[@]} == 0 ]]; then
    arr_vuls="all"
fi
all=0
meltdown=0
spectre=0
btb=0
pht=0
rsb=0
ac=0
br=0
de=0
gp=0
nm=0
p=0
pk=0
rw=0
ss=0
ud=0
us=0
btb_sa_ip=0
btb_sa_oop=0
btb_ca_ip=0
btb_ca_oop=0
pht_sa_ip=0
pht_sa_oop=0
pht_ca_ip=0
pht_ca_oop=0
rsb_sa_ip=0
rsb_sa_oop=0
rsb_ca_ip=0
rsb_ca_oop=0
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

# Choose whether to output PoC
########################
# To-do
########################

# Get pagesize and threshold
printf "\nInitial tests...\n"
pagesize=$(./libcache/get_pagesize)
threshold=$(./libcache/get_threshold)
printf "\033[32m[OK]\033[0m pagesize = $pagesize, threshold = $threshold\n\n"

# Exploit
# meltdown_ac
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ac == 1 ]]; then
    ./meltdown/AC/poc $pagesize $threshold
fi
# meltdown_br
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $br == 1 ]]; then
    ./meltdown/BR/poc $pagesize $threshold
fi
# meltdown_de
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $de == 1 ]]; then
    ./meltdown/DE/poc $pagesize $threshold
fi
# meltdown_gp
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $gp == 1 ]]; then
    sudo insmod libcr3/kernel_module.ko
    ./meltdown/GP/poc $pagesize $threshold
    sudo rmmod libcr3/kernel_module.ko
fi
# meltdown_nm
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $nm == 1 ]]; then
    printf "Launching victim process for Meltdown_NM...\n"
    taskset 0x2 ./meltdown/NM/victim &
    victimpid=$!
    sleep 3
    printf "Done...\n"
    taskset 0x2 ./meltdown/NM/poc $pagesize $threshold
    printf "Terminating victim process for Meltdown_NM...\n"
    kill $victimpid >/dev/null 1>&1
    sleep 1
    printf "Done...\n\n"
fi
# meltdown_p
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $p == 1 ]]; then
    sudo insmod libpte/module/pteditor.ko
    ./meltdown/P/poc $pagesize $threshold
    sudo rmmod libpte/module/pteditor.ko
fi
# meltdown_pk
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $pk == 1 ]]; then
    ./meltdown/PK/poc $pagesize $threshold
fi
# meltdown_rw
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $rw == 1 ]]; then
    ./meltdown/RW/poc $pagesize $threshold
fi
# meltdown_ss
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ss == 1 ]]; then
    ./meltdown/SS/poc $pagesize $threshold
fi
# meltdown_ud
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ud == 1 ]]; then
    ./meltdown/UD/poc $pagesize $threshold
fi
# meltdown_us
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $us == 1 ]]; then
    sudo insmod libpte/module/pteditor.ko
    ./meltdown/US/poc $pagesize $threshold
    sudo rmmod libpte/module/pteditor.ko
fi

# spectre_btb
# spectre_btb_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_ip == 1 ]]; then
    ./spectre/BTB/ca_ip/poc $pagesize $threshold
    wait $!
    sleep 3
fi
# spectre_btb_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_oop == 1 ]]; then
    cd spectre/BTB/ca_oop
    ./exploit.sh
    cd ../../../
fi
# spectre_btb_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_ip == 1 ]]; then
    ./spectre/BTB/sa_ip/poc $pagesize $threshold
fi
# spectre_btb_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_oop == 1 ]]; then
    ./spectre/BTB/sa_oop/poc $pagesize $threshold
fi

# spectre_pht
# spectre_pht_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_ip == 1 ]]; then
    ./spectre/PHT/ca_ip/poc $pagesize $threshold
fi
# spectre_pht_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_oop == 1 ]]; then
    ./spectre/PHT/ca_oop/poc $pagesize $threshold
fi
# spectre_pht_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_ip == 1 ]]; then
    ./spectre/PHT/sa_ip/poc $pagesize $threshold
fi
# spectre_pht_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_oop == 1 ]]; then
    ./spectre/PHT/sa_oop/poc $pagesize $threshold
fi

# spectre_rsb
# spectre_rsb_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_ip == 1 ]]; then
    ./spectre/RSB/ca_ip/poc $pagesize $threshold
fi
# spectre_rsb_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_oop == 1 ]]; then
    ./spectre/RSB/ca_oop/poc $pagesize $threshold
fi
# spectre_rsb_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_ip == 1 ]]; then
    ./spectre/RSB/sa_ip/poc $pagesize $threshold
fi
# spectre_rsb_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_oop == 1 ]]; then
    ./spectre/RSB/sa_oop/poc $pagesize $threshold
fi

# spectre_stl
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $stl == 1 ]]; then
    ./spectre/STL/poc $pagesize $threshold
fi
printf "\033[32m[OK]\033[0m All tests done!\n"

# Output report
##############
# To-do
##############
