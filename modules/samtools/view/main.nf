process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::samtools=1.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.14--hb421002_0' :
        'quay.io/biocontainers/samtools:1.14--hb421002_0' }"

    input:
    tuple val(meta), path(input)
    path fasta

    output:
    tuple val(meta), path("*.bam") , emit: bam , optional: true
    tuple val(meta), path("*.cram"), emit: cram, optional: true
    path  "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--reference ${fasta} -C" : ""
    def file_type = input.getExtension()
    if ("$input" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    samtools \\
        view \\
        --threads ${task.cpus-1} \\
        ${reference} \\
        $args \\
        $input \\
        > ${prefix}.${file_type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
