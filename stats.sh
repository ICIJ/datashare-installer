#!/usr/bin/env bash

curl https://api.github.com/repos/ICIJ/datashare-installer/releases | jq -r '.[]|[.tag_name, .assets[].download_count] | @csv' > /tmp/ds_stats.csv
sed  -i '1i release,mac,windows,linux' /tmp/ds_stats.csv

function create_plot_file {
cat > /tmp/ds_stats.plot << EOF
set grid
set xtics rotate by -45
set datafile separator ","

set term png enhanced size 1024,800
set output "ds_stats.png"

 set style data histogram
 set style histogram rowstacked
 set style fill solid border rgb "black"
 set auto x
 set yrange [0:*]

set xlabel "releases"
set ylabel "nb downloads"
set title "Datashare downloads"
plot '/tmp/ds_stats.csv' using 3:xtic(1) title col, \
        '' using 2:xtic(1) title col, \
        '' using 4:xtic(1) title col
EOF
}

create_plot_file
gnuplot /tmp/ds_stats.plot
