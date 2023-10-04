#!/bin/bash
dir=$1

cd $dir

plate=$(echo Misha_1)

find . -type f -name "*UV*" > FileName_OrigDNA.txt
find . -type f -name "*Blue*" > FileName_OrigER.txt
find . -type f -name "*wv_Red*" > FileName_OrigMito.txt
find . -type f -name "*Green*" > FileName_OrigAGP.txt

sed -i 's#./##g' FileName_OrigDNA.txt
sed -i 's#./##g' FileName_OrigER.txt
sed -i 's#./##g' FileName_OrigMito.txt
sed -i 's#./##g' FileName_OrigAGP.txt

sort -o FileName_OrigDNA.txt FileName_OrigDNA.txt
sort -o FileName_OrigER.txt FileName_OrigER.txt
sort -o FileName_OrigMito.txt FileName_OrigMito.txt
sort -o FileName_OrigAGP.txt FileName_OrigAGP.txt

cat FileName_OrigDNA.txt | awk '{print substr($0,5,2)}' > metadata_col.txt
cat FileName_OrigDNA.txt | awk '{print substr($0,1,1)}' > metadata_row.txt
cat FileName_OrigDNA.txt | awk '{print substr($0,1,6)}' | sed 's/_-_//g' > metadata_well.txt

pwd=$(echo /home/misha/cell-photos/)

count=$(expr $(cat FileName_OrigDNA.txt | wc -l) / 9)
echo 'DEBUG: count =' $count
c=1
if [ $c -le $count ]; then
    seq 9 >> metadata_site.txt
    c=$((c+1))
fi

cell_locations="ER AGP Mito DNA"

for location in $(echo $cell_locations); do linecount=$(cat FileName_Orig${location}.txt | wc -l); for i in $(echo $pwd); do seq 1 ${linecount} | xargs -i -- echo $i > ${location}_pwd.txt; done; for j in $(echo ${plate}); do seq 1 ${linecount} | xargs -i -- echo $j > metadata_plate.txt; done; done

Rscript /home/misha/PycharmProjects/IGVF-Cell-Painting-Scripts/Preparing_For_CellProfiler/letter_to_number.r metadata_row.txt
echo 'DEBUG: metadata_row.txt was created'
echo FileName_OrigER,PathName_OrigER,FileName_OrigAGP,PathName_OrigAGP,FileName_OrigMito,PathName_OrigMito,FileName_OrigDNA,PathName_OrigDNA,Metadata_Plate,Metadata_Well,Metadata_Site,Metadata_Col,Metadata_Row > load_data.csv
echo 'DEBUG: load_data.csv  was created'
paste -d, FileName_OrigER.txt ER_pwd.txt FileName_OrigAGP.txt AGP_pwd.txt FileName_OrigMito.txt Mito_pwd.txt FileName_OrigDNA.txt DNA_pwd.txt metadata_plate.txt metadata_well.txt metadata_site.txt metadata_col.txt metadata_row.txt >> load_data.csv
echo 'DEBUG: data was pasted in load_data.csv'
sed -i 's#./Images/##g' load_data.csv
cp load_data.csv  ${pwd}${plate}_load_data.csv
echo 'DEBUG: file was successfully copied and renamed'
rm *.txt
cd ..
