/*
This pipeline is for making the Quality Control reports of the fastq files in order to also make the 
cleaning file. 
The input of the pipeline is a table csv with this columns 
srrid,path_fastq,path_fastq_2
Arguments: 


*/ 
params.outdir = "results/nf/"
params.metadata = "data/metadata.csv"
params.conda_env = "/export/space3/users/ismadlsh/conda/bio_informatics"
params.trimF = 10
params.threads = 4
params.fastp_env= "fastp"

process fastQC {
    //name of the nextflow job 
    tag "${srr_id}_QCreps_${type}"
    //save options 
    publishDir "${params.outdir}/${type}/FastQC/${srr_id}", mode: 'copy'

    input:
        tuple val(srr_id), path(srr_files),val(type)
    output: 
        tuple val(srr_id), path("*_fastqc.zip"), emit: fastq_out
    script:
    """
    fastqc -t ${params.threads} ${srr_files.join(' ')}
    """
}

process fastp {
    //name of the nextflow job 
    tag "${srr_id}_fastp"
    //save options 
    publishDir "${params.outdir}/clean_data/clean_fastq/${srr_id}", mode: 'copy'

    input:
        tuple val(srr_id), path(srr_files), path(fastqc_res)
    output: 
        tuple val(srr_id), path("*_clean.fastq"), emit: fastq_clean
    script:
    """ 
    #make this for every zip file 
    bash ${projectDir}/run_fastp.sh ${params.trimF} ${params.fastp_env} ${fastqc_res.join(' ')}
    

    """
} 

process multiQC{
    //name of the nextflow job 
    tag "multiQC_${type}"
    //save options 
    publishDir "${params.outdir}/${type}/multiQC/", mode: 'copy'

    input:
        tuple val(type), path(fastqc_reps)
    output: 
        path("*.html"), emit: multiqc_res
    script: 
    """
    multiqc ${fastqc_reps.join(' ')}
    """
}


workflow report_cleaned {

    take:
        cleaned_fastqs

    main:
        clean_fastqc = fastQC(cleaned_fastqs).fastq_out

        clean_fastqc
            .map { _id, zip_pths -> zip_pths }
            .flatten()
            .collect()
            .set { all_fastqc_clean }

        multiQC( all_fastqc_clean.map{ tuple("clean_data", it) } )
}

workflow {
    //check if the user is providing paired data or not 
    meta_ch = channel.fromPath(params.metadata)
        .splitCsv(header: false, sep: ",")
        .map {row ->
            def reads = row.size() > 2 && row[2] ? 
            [ file(row[1]), file(row[2]) ] :
            [ file(row[1]) ]
            tuple(row[0], reads)
        }

    //QC proccess
    raw_fastqc=fastQC(meta_ch.map{ _id, _paths -> tuple (_id , _paths, "raw_data")}).fastq_out 
    //merge the with the data paths 
    combine_ch=meta_ch.join(raw_fastqc)

    //clean the data 
    clean_data=fastp(combine_ch).fastq_clean
    //now we can make the fastqc reports of the clean data 
    report_cleaned(clean_data.map{ _id, _paths -> tuple (_id , _paths, "clean_data")})

    //condensate all the fastqc 
    raw_fastqc
        .map { _id, zip_pths -> zip_pths}
        .flatten()
        .collect()
        .set { all_fastqc_raw } 
    
    //now multiqc the reports 
    multiQC( all_fastqc_raw.map{ tuple("raw_data", it) } )
} 
