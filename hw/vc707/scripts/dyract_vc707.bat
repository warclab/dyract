ngdbuild -intstyle ise -dd _ngo -sd ../src/ipcore_dir -nt timestamp -uc ../src/v7_top.ucf -p xc7vx485t-ffg1761-2 preserved/top.ngc top.ngd
map -intstyle ise -p xc7vx485t-ffg1761-2 -w -logic_opt on -ol high -xe n -t 1 -xt 0 -register_duplication on -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf
par -w -intstyle ise -ol high -xe n -mt off top_map.ncd top.ncd top.pcf
bitgen -intstyle ise -f preserved/top.ut top.ncd
