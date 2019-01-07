# sraX
Allows the analysis of assembled sequence data from FASTA files all the way to Resistome Analysis.

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/lgpdevtools/sraX/blob/master/LICENSE)

## Content
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
  * [Usage](#usage)
    * [Calculating Read Counts](#calculating-read-counts)
    * [Merging GFF Files](#merging-gff-files)
    * [Quantifying Differential Gene Expression](#quantifying-differential-gene-expression)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)
  * [Citation](#citation)

## Introduction
Increased __antimicrobial resistance (AMR)__ is being detected elsewhere in samples from diverse origins and causes a major widespread concern for public health. Consequently, __the accurate detection of the repertoire of antibiotic resistance genes (ARGs) within a collection of genomes (e.g., “resistome” analysis)__ constitutes a valuable portrayal of intricate AMR patterns associated with particular samples. Moreover, the existence of certain mutations on particular loci rationalizes the observed resistant phenotypes. __sraX__ systematize the creation of a locally compiled AMR database (DB) from public or proprietary repositories, identifies the AMR determinants by examining the presence of ARGs or point mutations conferring AMR, extends the SNP analysis for detecting new variants, calculates the fractions of drug classes and type of mutated loci comprising individual AMR patterns and carries out an in-depth gene context exploration. The results are presented in fully navigable HTML-formatted files with graphical representations of previously mentioned analysis.

## Installation
sraX has the following dependencies:

### Required dependencies
 * [BLAST](ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
 * [DIAMOND]( http://github.com/bbuchfink/diamond/)
 * [R](http://www.r-project.org/)
 * [MUSCLE]( http://www.drive5.com/muscle/)

You will also need to download samtools v0.1.18 and build it on your system. Bio-RNASeq makes use of the Samtools v0.1.18 C API. You can get it [here](https://github.com/samtools/samtools/tree/0.1.18).

Once you've downloaded this, in a bash terminal, in the samtools v0.1.18 directory, run
```
make
```
__NOTE:__ You don't need to run `make install`. You don't need to install the older version of samtools on your system.

To install sraX, please see the details provided below. If you encounter an issue when installing sraX please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/lgpdevtools/sraX/issues) or email me at lgpanunzi@gmail.com

Clone the repo:
```
git clone https://github.com/sanger-pathogens/Bio-RNASeq.git
```
To install the required perl modules, in the cloned repo run:
```
dzil authordeps | cpanm
dzil listdeps | cpanm
```
Make sure the tests pass:
```
dzil test
```
Install Bio-RNASeq:
```
dzil install
```
## Usage

There are three components to this application.

### Calculating Read Counts
```
rna_seq_expression
Usage:
  -s|sequence_file           <aligned BAM file>
  -a|annotation_file         <annotation file (GFF)>
  -p|protocol                <standard|strand_specific>
  -o|output_base_filename    <Optional: base name and location to use for output files>
  -q|minimum_mapping_quality <Optional: minimum mapping quality>
  -c|no_coverage_plots       <Dont create Artemis coverage plots>
  -i|intergenic_regions      <Include intergenic regions>
  -b|bitwise_flag            <Only include reads which pass filter>
  -k|parallel_processes      <Number of CPUs to use, defaults to 1>
  -h|help                    <print this message>

This script takes in an aligned sequence file (BAM) and a corresponding annotation file (GFF) and creates a spreadsheet with expression values.
The BAM must be aligned to the same reference that the annotation refers to and must be sorted.
```
The RPKM values are calculated according to two different methodologies:

 1. total number of reads on the bam file that mapped to the reference genome

 2. total number of reads on the bam file that mapped to gene models in the reference genome

The *expression.csv file will contain both datasets. 

Coverage plots compatible with Artemis will also be produced. You can download [Artemis here](http://sanger-pathogens.github.io/Artemis/)

Example usage:
```
rna_seq_expression -s [filename.bam] -a [filename.gff] -p [standard|strand_specific] -o [./foobar]
```

### Merging GFF Files
```
gff3_concat
Usage:
  -i|input_dir        <full path to the directory containing the gff files to concatenate>
  -o|output_dir       <full path to the directory where the concatenated gff file will be written to>
  -t|tag              <the name to tag the concatenated gff file with>
  -h|help             <print this message>

  This script will concatenate several GFF files into one, maintaining GFF3 compatibility.
  It takes in the location of the collection of GFF files [-i|input_dir];
  The path where the final concatenated GFF file should be written to [-o|output_dir];
  A customised tag for the newly created GFF file [t|tag].
```
Example	usage:
```
gff3_concat -i [full path to directory of gff files] -o [full path to output directory] -t [name of the newly merged GFF file]
```

### Quantifying Differential Gene Expression
```
differential_expression_with_deseq
Usage:
  -i|input         <A file with the list of samples to analyse and their corresponding files of expression values
                    in the format ("filepath","condition","replicate","lib_type"). lib_type defaults to paired-end
                    if not specified on the samples file>
  -o|output        <The name of the file that will be used as the DeSeq analysis input. NOTE - The file will be
                    writen wherever you're running deseq_run from>
  -c|column        <Optional: Number of the column you want to use as your read count from your expression files.
                              Defaults to the second column in the expression file if no value is specified>
  -h|help          <print this message>

It makes use of the DESeq Bioconductor R package to carry out differential gene expression analysis.

Simon Anders and Wolfgang Huber (2010): Differential expression
  analysis for sequence count data. Genome Biology 11:R106

It takes as input a file with the list of samples to analyse and their corresponding files of expression
values in the format ("filepath","condition","replicate","lib_type"). It parses this file and accesses
all the files defined in the first column and extracts a gene list and the read counts from them.
It generates a matrix ready for DESeq analysis. It's final output will be a spreadsheet (.csv)
that can be loaded subsequently into a DESeq session or can be visualised in Excel.
```
Example	usage:
```
differential_expression_with_deseq -i [file containing list of files to analyse and key descriptions] -o [name to be used for all the output files generated] -c [Number of the read count column (1-1000)]
```
## License
sraX is free software, licensed under [GPLv3](https://github.com/lgpdevtools/sraX/blob/master/LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/lgpdevtools/sraX/issues) or email lgpanunzi@gmail.com

## Citation
_Panuzi LG (2019): sraX: a one-step tool for resistome profiling._
