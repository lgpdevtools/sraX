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
Increased __antimicrobial resistance (AMR)__ is being detected elsewhere in samples from diverse origins and causes a major widespread concern for public health. __sraX__ is designed to read assembled sequence files in FASTA format and systematically detect the presence of the repertoire of antibiotic resistance genes (ARGs) within a collection of genomes (the __“resistome” analysis__). The following assignments are fully automated:
- the creation of a locally compiled AMR database (DB) from public or proprietary repositories
- identifies the AMR determinants by examining the presence of ARGs or point mutations conferring AMR
- extends the SNP analysis for detecting new variants
- calculates the fractions of drug classes and type of mutated loci comprising individual AMR patterns.
- in-depth gene context exploration.
- The results are presented in fully navigable HTML-formatted files with graphical representations of previously mentioned analysis.

## Installation
sraX has the following dependencies:

### Required dependencies
 * [BLAST][[1]](ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
 * [DIAMOND][[2]]( http://github.com/bbuchfink/diamond/)
 * [R][[3]](http://www.r-project.org/)
 * [MUSCLE][[4]](http://www.drive5.com/muscle/)

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

### one-step systematic resistome analysis (sraX)
```
--genome_directory	Mandatory directory containing the input file(s), which must be in FASTA format and
			consisting of individual assembled genome sequences.

--output		Output folder. If not provided, the following default name will be taken:
			
			'genome_directory'_'sraX'_'id'_'aln_cov'_'blast_x'

			Example: input folder = 'Test'; id = 85; aln_cov = 95; blast_x = dblastx
			
			Output folder = 'Test_sraX_85_95_dblastx'

--blast_x		The translated alignments of assembled genome(s) are queried using dblastx
			(DIAMOND blastx) or blastx (NCBI blastx). In any case, the process is parallelized
			(up to 100 genome files are run simultaneously) for reducing computing times
			(default: dblastx)

--eval			Use this evalue cut-off to filter false positives (default: 1e-05)

--id			Use this percent identity cut-off to filter false positives (default: 85)			

--aln_cov		This fraction of the query must align to the reference sequence (default: 60)

--threads		Use this number of threads when running sraX (default: 6)

--help			Displays this help information and exits.

--version		Displays version information and exits.

--verbose		Verbose output (for debugging).
                                   
```

Example usage:
```
sraX  [options] --genome_dir / -d [input file(s)]
```

## License
sraX is free software, licensed under [GPLv3](https://github.com/lgpdevtools/sraX/blob/master/LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/lgpdevtools/sraX/issues) or email lgpanunzi@gmail.com

## About
sraX is developed by Leonardo G. Panunzi at the lab, Institute, Paris, France.

## Citation
Panunzi LG, "sraX: a one-step tool for resistome profiling", submitted to _Bioinformatics_ for publication.

## References.
[1] Altschul,S.F. et al. (1990). Basic local alignment search tool. JMB, 215, 403–410.

[2] Buchfink B, Xie C, Huson DH, "Fast and sensitive protein alignment using DIAMOND", Nature Methods 12, 59-60 (2015).

[3] Altschul,S.F. et al. (1990). Basic local alignment search tool. JMB, 215, 403–410.

[4] Edgar, R.C. (2004) MUSCLE: multiple sequence alignment with high accuracy and high throughput Nucleic Acids Res. 32(5):1792-1797.

[5] Croucher NJ, et al. (2015). Rapid phylogenetic analysis of large samples of recombinant bacterial whole genome sequences using Gubbins. Nucleic Acids Res 43:e15.


