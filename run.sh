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
|         |                              | rsb_ca_oop | Spectre_RSB_ca_oop           |
|         |                              | stl        | Spectre_STL                  |

\033[32m[Input]\033[0m Please select the vulnerabilities to be tested (default all): "
read vuls
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
printf "\n\033[32m[Input]\033[0m Please choose whether to output successful PoCs(default no)[Y/N]: "
read poc_input
if [[ $poc_input == 'y' ]] || [[ $poc_input == 'Y' ]]; then
    output_poc=1
else
    output_poc=0
fi

# Get pagesize and threshold
printf "\n\nInitialize tests...\n"
pagesize=$(./libcache/get_pagesize)
threshold=$(./libcache/get_threshold)
printf "\033[32m[OK]\033[0m pagesize = $pagesize, threshold = $threshold\n\n"

# Exploit
# meltdown_ac
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ac == 1 ]]; then
    ./meltdown/AC/poc $pagesize $threshold
    ac=$?
fi
# meltdown_br
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $br == 1 ]]; then
    ./meltdown/BR/poc $pagesize $threshold
    br=$?
fi
# meltdown_de
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $de == 1 ]]; then
    ./meltdown/DE/poc $pagesize $threshold
    de=$?
fi
# meltdown_gp
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $gp == 1 ]]; then
    sudo insmod libcr3/kernel_module.ko
    ./meltdown/GP/poc $pagesize $threshold
    gp=$?
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
    nm=$?
    printf "Terminating victim process for Meltdown_NM...\n"
    kill $victimpid >/dev/null 1>&1
    sleep 1
    printf "Done...\n\n"
fi
# meltdown_p
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $p == 1 ]]; then
    sudo insmod libpte/module/pteditor.ko
    ./meltdown/P/poc $pagesize $threshold
    p=$?
    sudo rmmod libpte/module/pteditor.ko
fi
# meltdown_pk
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $pk == 1 ]]; then
    ./meltdown/PK/poc $pagesize $threshold
    pk=$?
fi
# meltdown_rw
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $rw == 1 ]]; then
    ./meltdown/RW/poc $pagesize $threshold
    rw=$?
fi
# meltdown_ss
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ss == 1 ]]; then
    ./meltdown/SS/poc $pagesize $threshold
    ss=$?
fi
# meltdown_ud
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $ud == 1 ]]; then
    ./meltdown/UD/poc $pagesize $threshold
    ud=$?
fi
# meltdown_us
if [[ $all == 1 ]] || [[ $meltdown == 1 ]] || [[ $us == 1 ]]; then
    sudo insmod libpte/module/pteditor.ko
    ./meltdown/US/poc $pagesize $threshold
    us=$?
    sudo rmmod libpte/module/pteditor.ko
fi

# spectre_btb
# spectre_btb_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_ip == 1 ]]; then
    ./spectre/BTB/ca_ip/poc $pagesize $threshold
    btb_ca_ip=$?
    wait $!
    sleep 3
fi
# spectre_btb_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_ca_oop == 1 ]]; then
    cd spectre/BTB/ca_oop
    ./exploit.sh
    btb_ca_oop=$?
    cd ../../../
fi
# spectre_btb_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_ip == 1 ]]; then
    ./spectre/BTB/sa_ip/poc $pagesize $threshold
    btb_sa_ip=$?
fi
# spectre_btb_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $btb == 1 ]] || [[ $btb_sa_oop == 1 ]]; then
    ./spectre/BTB/sa_oop/poc $pagesize $threshold
    btb_sa_oop=$?
fi

# spectre_pht
# spectre_pht_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_ip == 1 ]]; then
    ./spectre/PHT/ca_ip/poc $pagesize $threshold
    pht_ca_ip=$?
fi
# spectre_pht_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_ca_oop == 1 ]]; then
    ./spectre/PHT/ca_oop/poc $pagesize $threshold
    pht_ca_oop=$?
fi
# spectre_pht_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_ip == 1 ]]; then
    ./spectre/PHT/sa_ip/poc $pagesize $threshold
    pht_sa_ip=$?
fi
# spectre_pht_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $pht == 1 ]] || [[ $pht_sa_oop == 1 ]]; then
    ./spectre/PHT/sa_oop/poc $pagesize $threshold
    pht_sa_oop=$?
fi

# spectre_rsb
# spectre_rsb_ca_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_ip == 1 ]]; then
    ./spectre/RSB/ca_ip/poc $pagesize $threshold
    rsb_ca_ip=$?
fi
# spectre_rsb_ca_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_ca_oop == 1 ]]; then
    ./spectre/RSB/ca_oop/poc $pagesize $threshold
    rsb_ca_oop=$?
fi
# spectre_rsb_sa_ip
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_ip == 1 ]]; then
    ./spectre/RSB/sa_ip/poc $pagesize $threshold
    rsb_sa_ip=$?
fi
# spectre_rsb_sa_oop
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $rsb == 1 ]] || [[ $rsb_sa_oop == 1 ]]; then
    ./spectre/RSB/sa_oop/poc $pagesize $threshold
    rsb_sa_oop=$?
fi

# spectre_stl
if [[ $all == 1 ]] || [[ $spectre == 1 ]] || [[ $stl == 1 ]]; then
    ./spectre/STL/poc $pagesize $threshold
    stl=$?
fi
printf "\033[32m[OK]\033[0m All tests done!\n"

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
printf "
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
\033[32m[N]\033[0m: Not vulnerable; \033[31m[Y]\033[0m: Vulnerable; \033[33m[E]\033[0m: Error/Not tested
"

# Output PoCs
#################
# To-do
#################
