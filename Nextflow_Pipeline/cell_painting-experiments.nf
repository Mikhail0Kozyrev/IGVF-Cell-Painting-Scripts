#!/usr/bin/env nextflow

/*NOTE: All plate IDs within a batch must end in a '_1' to be recognized by Nextflow in this script*/
params.userid=''
params.batch=''
params.cellprofanalysis=''
nextflow.enable.dsl=2

params.image_dir_ch = Channel.fromPath("/home/misha/cell-photos/",type: 'dir').map { [ it.name, it] }

params.plateid="Misha_1"
params.plate_id_file=file("${params.plateid}_pwd.txt")
params.lettertonum=file("/home/misha/PycharmProjects/IGVF-Cell-Painting-Scripts/Preparing_For_CellProfiler/letter_to_number.r")
params.cippe_file=file("/home/misha/PycharmProjects/IGVF-Cell-Painting-Scripts/Pipelines/Cell_Painting_Illum_8x_remade.cppipe")



process pwdloaddata {
    cache 'lenient'
    label 'coreutils'
    tag "${plateid}"

    input:
     val(plateid)
     file({imagedir})

    output:
    val(plateid)

    script:
    """
    echo ${plateid}
   echo /cell-photos > ${plateid}_pwd.txt
    """
}

process createLoadDataCsvs{
    cache 'lenient'
    label 'pycytoandr'
    tag "${plateid}"

    input:
    val(plateid)
    file("${plateid}_pwd.txt")
    file($imagedir)
    file lettertonum

    output:
    file("${plateid}_load_data.csv")

    script:
    """
    echo '${plateid}' > 'platename.txt'
    mv 'platename.txt' '${params.image_dir_ch}'
    mv '${plateid}_pwd.txt' '${params.image_dir_ch}'
    cp '${lettertonum}' "/home/misha/cell-photos/letter_to_number.r"
    sh /home/misha/PycharmProjects/IGVF-Cell-Painting-Scripts/Preparing_For_CellProfiler/generate_load_data.sh "/home/misha/cell-photos/"
    pwd
    mv "/home/misha/cell-photos/load_data.csv" ${plateid}_load_data.csv
    """
}

process illuminationMeasurement{
    cache 'lenient'
    tag "${plateid}"
    label 'cellprof'

    input:
    val(plateid)
    file("${plateid}_load_data.csv")
    file("imagedir")
    file('Cell_Painting_Illum_8x_remade.cppipe')

    output:
    val(plateid)
    path("${plateid}_out/${plateid}_illumAGP.npy")
    path("${plateid}_out/${plateid}_illumDNA.npy")
    path("${plateid}_out/${plateid}_illumER.npy")
    path("${plateid}_out/${plateid}_illumMito.npy")
    file("${plateid}_load_data.csv")
    path("imagedir")

    script:
    """
    cellprofiler -c --log-level=DEBUG -r -p ${params.cippe_file} --data-file ${plateid}_load_data.csv -i $imagedir -o ${plateid}_out
    echo I'm here 1
    cp \$(cat ${params.cippe_file}) .
    echo I'm here 2
    ${plateid}_load_data.csv -i params.image_dir_ch -o ${plateid}_out
    echo I'm here 3
    mv ${plateid}_out/IGVF/Plate_illumAGP.npy ${plateid}_out/${plateid}_illumAGP.npy
    echo I'm here 4
    mv ${plateid}_out/IGVF/Plate_illumDNA.npy ${plateid}_out/${plateid}_illumDNA.npy
    echo I'm here 5
    mv ${plateid}_out/IGVF/Plate_illumER.npy ${plateid}_out/${plateid}_illumER.npy
    echo I'm here 6
    mv ${plateid}_out/IGVF/Plate_illumMito.npy ${plateid}_out/${plateid}_illumMito.npy
    echo I'm here 7

    """
}

workflow {
    pwdloaddata(params.plateid, params.image_dir_ch)
    createLoadDataCsvs(params.plateid, params.plate_id_file, params.image_dir_ch, params.lettertonum)
    illuminationMeasurement(params.plateid, createLoadDataCsvs.out, params.image_dir_ch, params.cippe_file)

}
