process GATK4_INTERVALLISTTOOLS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::gatk4=4.2.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.4.0--hdfd78af_0' :
        'quay.io/biocontainers/gatk4:4.2.4.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(interval_list)

    output:
    tuple val(meta), path("*_split/*/*.interval_list"), emit: interval_list
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK IntervalListTools] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """

    mkdir ${prefix}_split

    gatk --java-options "-Xmx${avail_mem}g" \\
        IntervalListTools \\
        -I ${interval_list} \\
        -O ${prefix}_split \\
        $args

    python3 <<CODE
    import glob, os
    # The following python code snippet rename the output files into different name to avoid overwriting or name conflict
    intervals = sorted(glob.glob("*_split/*/*.interval_list"))
    for i, interval in enumerate(intervals):
        (directory, filename) = os.path.split(interval)
        newName = os.path.join(directory, str(i + 1) + filename)
        os.rename(interval, newName)
    CODE

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
