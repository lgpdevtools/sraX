# sraX
The proposed tool constitutes a Perl package, composed of functional modules, that allows performing a one-step accurate resistome analysis of assembled sequence data from FASTA files.

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/lgpdevtools/sraX/blob/master/LICENSE)

## Content
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
  * [Usage](#usage)
    * [Minimal command](#minimal-command)
    * [Extended options](#extended-options)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)
  * [Citation](#citation)

## Introduction
__sraX__ is designed to read assembled sequence files in FASTA format and systematically detect the presence of AMR determinants and, ultimately, describe the repertoire of antibiotic resistance genes (ARGs) within a collection of genomes (the __“resistome” analysis__). The following assignments are fully automated:
- creation and compilation of a local AMR database (DB) using public or proprietary repositories
- accurate identification of AMR determinants (ARGs or SNPs presence) in a non-redundant manner
- detection of putative new variants through the SNP analysis
- calculation and graphical representation of drug classes and type of mutated loci
- in-depth gene context exploration

The results are presented in fully navigable HTML-formatted files with embedded plots of previously mentioned analysis.

Workflow schematic:

![workflow](https://user-images.githubusercontent.com/45903129/50822537-421cff80-1332-11e9-9efb-188a179301e4.png)


## Installation
sraX has the following dependencies:


### _Dependencies_

**1.** Though **sraX** is fully written in Perl and should work with any OS, it has only been tested with a 64-bit Linux distribution.

**2.** Perl version 5.26.x or higher. You can verify on your own computer by typing the following command under a bash terminal:
```
perl -h
```

The latest version of Perl can be obtained from the [official website](http://www.perl.org). Consult the installation guide.

The following Perl libraries are also required and can be installed using [CPAN](http://www.cpan.org):
    - Data::Dumper
    - LWP::Simple
    - JSON
    - File::Slurp
    - FindBin
    - Cwd

**3.** Required third-party software
 * [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download) [[1]](#references)
 * [DIAMOND](http://github.com/bbuchfink/diamond/) [[2]](#references)
 * [R](http://www.r-project.org/) [[3]](#references), plus the following packages:
 * [`dplyr`](https://cran.r-project.org/web/packages/dplyr/) [[4]](#references)
 * [`ggplot2`](https://cran.r-project.org/web/packages/ggplot2/) [[5]](#references)
 * [`gridExtra`](https://cran.r-project.org/web/packages/gridExtra/) [[6]](#references)
 * [MUSCLE](http://www.drive5.com/muscle/) [[7]](#references)
  
__NOTE:__ In order to confirm the existence of these dependencies in your computer, a bash script ('`install.sh`') is provided for properly installing them.

To successfully install sraX, please see the details provided below. If you encounter an issue during the process, please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/lgpdevtools/sraX/issues) or email me at lgpanunzi@gmail.com

Open a bash terminal and clone the repository:
```
git clone https://github.com/lgpdevtools/sraX.git
```
To verify the existence of required dependencies and ultimately install the perl modules composing sraX, inside the cloned repository run:
```
bash install.sh
```
## Usage

sraX effectively operates as one-step application. It means that just a single command is required to obtain the totality of results and their visualization.   

__NOTE:__ For a detailed explanation and examples from real datasets, please follow the [Tutorial.](https://github.com/lgpdevtools/sraX/blob/master/Tutorial.md)

### Parameters
```
Usage:
  -d|genome_directory	<Mandatory: input genome directory>
  -o|output		<Optional: name of output folder>
  -p|blast_x        	<Optional: sequence aligning algorithm (default: dblastx)>
  -e|eval    		<Optional: evalue cut-off to filter false positives (default: 1e-05)>
  -c|aln_cov       	<Optional: fraction of aligned query to the reference sequence (default: 60)>
  -i|id      		<Optional: sequence identity percentage cut-off to filter false positives (default: 85)>
  -t|threads      	<Optional: number of threads to use (default: 6)>
  -v|version		<print current version>
  -h|help               <print this message>
```
### Minimal command
Example usage:
```
sraX -d [input genome directory]
```
Where:
```
-d	Full path to the mandatory directory containing the input sequence data, which must
	be in FASTA format and consisting of individual assembled genome sequences.
```


### Extended options
Example usage:
```
sraX -p blastx -i 95 -c 90 -t 12 -o [output results directory] -d [input genome directory]
```
Where:
```
-p	The translated alignments of assembled genome(s) are queried using dblastx
	(DIAMOND blastx) or blastx (NCBI blastx). In any case, the process is parallelized
	(up to 100 genome files are run simultaneously) for reducing computing times
	(default: dblastx)

-i	Use this percent identity cut-off to filter false positives (default: 85)			

-c	Use this fraction aligned query to the reference sequence (default: 60)

-e	Use this evalue cut-off to filter false positives (default: 1e-05)

-t	Use this number of threads (default: 6)

-o	Full path to the directory where the output results will be written in. If not provided,
	the following default name will be taken:
			
	'genome_directory'_'sraX'_'id'_'aln_cov'_'blast_x'

	Example: input directory = 'Test'; id = 85; aln_cov = 95; blast_x = dblastx
			
	Output directory = 'Test_sraX_85_95_dblastx'
		
-d	Full path to the mandatory directory containing the input sequence data, which must
	be in FASTA format and consisting of individual assembled genome sequences.
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
[1] Altschul SF _et al._ (1990). Basic local alignment search tool. _JMB_, 215, 403–410.

[2] Buchfink B, Xie C & Huson DH (2015). Fast and sensitive protein alignment using DIAMOND. _Nature Methods_ 12, 59-60.

[3] R Core Team (2013). R: A Language and Environment for Statistical Computing.

[4] Wickham H, Romain Francois R, Henry L and Müller K (2017). dplyr: A Grammar of Data Manipulation.

[5] Wickham H (2016). ggplot2: Elegant Graphics for Data Analysis. _Springer-Verlag New York_.

[6] Auguie B, Antonov A and Auguie MB (2016).

[7] Edgar RC (2004) MUSCLE: multiple sequence alignment with high accuracy and high throughput. _Nucleic Acids Res._ 32(5):1792-1797.
