#rename, relabel and join the UMAP clusters

#rename
for dir in temporary/*; do
  cat "$dir/"*.txthdbscan.output.png >"$dir/${dir##*/}.cluster.png"
done

#move all to folder
mkdir clusterplots
find ./temporary/ -type f -iname "*.cluster.png" -exec mv --backup=numbered -t clusterplots {} +

cd clusterplots
#add file label to picture
mogrify -font Liberation-Sans -fill white -undercolor '#00000080' \
-pointsize 45 -gravity NorthEast -annotate +10+10 %t *.png

#join images in single pdf
convert *.png cluster_plots.pdf

mv cluster_plots.pdf ../results/

