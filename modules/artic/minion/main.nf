process ARTIC_MINION {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::artic=1.2.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/artic:1.2.1--py_0' :
        'quay.io/biocontainers/artic:1.2.1--py_0' }"

    input:
    tuple val(meta), path(fastq)
    path  fast5_dir
    path  sequencing_summary
    path  ("primer-schemes/${scheme}/V${scheme_version}/${scheme}.reference.fasta")
    path  ("primer-schemes/${scheme}/V${scheme_version}/${scheme}.scheme.bed")
    path  medaka_model
    val   scheme
    val   scheme_version

    output:
    tuple val(meta), path("${prefix}.*")                              , emit: results
    tuple val(meta), path("${prefix}.sorted.bam")                     , emit: bam
    tuple val(meta), path("${prefix}.sorted.bam.bai")                 , emit: bai
    tuple val(meta), path("${prefix}.trimmed.rg.sorted.bam")          , emit: bam_trimmed
    tuple val(meta), path("${prefix}.trimmed.rg.sorted.bam.bai")      , emit: bai_trimmed
    tuple val(meta), path("${prefix}.primertrimmed.rg.sorted.bam")    , emit: bam_primertrimmed
    tuple val(meta), path("${prefix}.primertrimmed.rg.sorted.bam.bai"), emit: bai_primertrimmed
    tuple val(meta), path("${prefix}.consensus.fasta")                , emit: fasta
    tuple val(meta), path("${prefix}.pass.vcf.gz")                    , emit: vcf
    tuple val(meta), path("${prefix}.pass.vcf.gz.tbi")                , emit: tbi
    tuple val(meta), path("*.json"), optional:true                    , emit: json
    path  "versions.yml"                                              , emit: versions

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    def version  = scheme_version.toString().toLowerCase().replaceAll('v','')
    def fast5    = fast5_dir ? "--fast5-directory $fast5_dir"             : ""
    def summary  = sequencing_summary ? "--sequencing-summary $sequencing_summary" : ""
    def model    = ""
    if (args.tokenize().contains('--medaka')) {
        fast5   = ""
        summary = ""
        model = file(medaka_model).exists() ? "--medaka-model ./$medaka_model" : "--medaka-model $medaka_model"
    }
    """
    artic \\
        minion \\
        $args \\
        --threads $task.cpus \\
        --read-file $fastq \\
        --scheme-directory ./primer-schemes \\
        --scheme-version $version \\
        $model \\
        $fast5 \\
        $summary \\
        $scheme \\
        $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        artic: \$(artic --version 2>&1 | sed 's/^.*artic //; s/ .*\$//')
    END_VERSIONS
    """
}
