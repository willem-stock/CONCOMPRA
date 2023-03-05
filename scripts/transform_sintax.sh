sed -i 's/\+.*//g' $1
sed -i 's/\t\n/\n/g' $1
sed -i 's/[A-Za-z]://g' $1
sed -i 's/([^()]*)//g' $1
sed -i 's/,/\t/g' $1
sed -i '1 i\OTU_id\tdomain\tphylum\tclass\torder\tfamily\tgenus\tspecies' $1
