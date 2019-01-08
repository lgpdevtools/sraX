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
__sraX__ is designed to read assembled sequence files in FASTA format and systematically detect the presence of the repertoire of antibiotic resistance genes (ARGs) within a collection of genomes (the __“resistome” analysis__). The following assignments are fully automated:
- creation and compilation of a local AMR database (DB) using public or proprietary repositories
- accurate identification of AMR determinants (ARGs or SNPs presence) in a non-redundant manner
- detection of putative new variants through the SNP analysis
- calculation and graphical representation of drug classes and type of mutated loci
- in-depth gene context exploration

The results are presented in fully navigable HTML-formatted files with embedded plots of previously mentioned analysis.

## Installation
sraX has the following dependencies:

### Required dependencies
 * [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download) [[1]](#references)
 * [DIAMOND](http://github.com/bbuchfink/diamond/) [[2]](#references)
 * [R](http://www.r-project.org/) [[3]](#references), plus the following packages:
 * [`dplyr`](https://cran.r-project.org/web/packages/dplyr/) [[4]](#references)
 * [`ggplot2`](https://cran.r-project.org/web/packages/ggplot2/) [[5]](#references)
 * [`gridExtra`](https://cran.r-project.org/web/packages/gridExtra/) [[6]](#references)
 * [MUSCLE](http://www.drive5.com/muscle/) [[7]](#references)
  
__NOTE:__ In order to confirm the existence of these dependencies in your computer, a bash script ('`install.sh`') is provided for properly installing them.

To successfully install sraX, please see the details provided below. If you encounter an issue during the process, please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/lgpdevtools/sraX/issues) or email me at lgpanunzi@gmail.com

Clone the repository:
```
git clone https://github.com/lgpdevtools/sraX.git
```
To verify the existence of required dependencies and ultimately install the perl modules composing sraX, inside the cloned repository, open a bash terminal and run:
```
bash install.sh
```

Make sure the tests pass:
```
```
## Usage

There are three components to this application.

__NOTE:__ For a detailed explanation and examples from real datasets, please follow the [Tutorial.](https://github.com/lgpdevtools/sraX/edit/master/Tutorial.md)

### Parameters
```
Usage:
  -d|genome_directory	<Mandatory: input genome directory>
  -o|output		<Optional: name of output folder>
  -p|blast_x        	<Optional: standard|strand_specific>
  -e|eval    		<Optional: evalue cut-off to filter false positives (default: 1e-05)>
  -c|aln_cov       	<Optional: Fraction of aligned query to the reference sequence (default: 60)>
  -i|id      		<Optional: sequence identity percentage cut-off to filter false positives (default: 85)>
  -t|threads      	<Optional: Number of threads to use, defaults to 6>
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
-d	Mandatory directory containing the input file(s), which must be in FASTA format and
	consisting of individual assembled genome sequences.
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

-o	Output folder. If not provided, the following default name will be taken:
			
	'genome_directory'_'sraX'_'id'_'aln_cov'_'blast_x'

	Example: input folder = 'Test'; id = 85; aln_cov = 95; blast_x = dblastx
			
	Output folder = 'Test_sraX_85_95_dblastx'
		
-d	Mandatory directory containing the input file(s), which must be in FASTA format and
	consisting of individual assembled genome sequences.                                   
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
[1] Altschul,S.F. et al. (1990). Basic local alignment search tool. _JMB_, 215, 403–410.

[2] Buchfink B, Xie C & Huson DH (2015). Fast and sensitive protein alignment using DIAMOND. _Nature Methods_ 12, 59-60.

[3] R Core Team (2013). R: A Language and Environment for Statistical Computing.

[4] Wickham H, Romain Francois R, Henry L and Müller K (2017). dplyr: A Grammar of Data Manipulation.

[5] Wickham H. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2016.

[6] Auguie B, Antonov A, Auguie MB. 2016.

[7] Edgar, R.C. (2004) MUSCLE: multiple sequence alignment with high accuracy and high throughput. _Nucleic Acids Res._ 32(5):1792-1797.
