#rename, relabel and join the UMAP clusters

#move all to folder
mkdir clusterplots
find ./temporary/ -type f -iname "*.png" -exec sh -c '
  for file; do 
    mv --backup=numbered "$file" "clusterplots/$(basename "$(dirname "$file")").${file##*.}"
  done' sh {} +

cd clusterplots
#add file label to picture
mogrify -font Courier -fill white -undercolor '#00000080' \
-pointsize 45 -gravity NorthEast -annotate +10+10 %t *.png

#join images in single pdf
magick *.png cluster_plots.pdf

mv cluster_plots.pdf ../results/

