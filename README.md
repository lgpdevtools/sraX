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
**sraX** has the following dependencies:


### _Dependencies_

**1.** Though **sraX** is fully written in Perl and should work with any OS, it has only been tested with a 64-bit Linux distribution.

**2.** Perl version 5.26.x or higher. You can verify on your own computer by typing the following command under a bash terminal:
```
perl -h
```
The latest version of Perl can be obtained from the [official website](http://www.perl.org). Consult the installation guide.

- The following Perl libraries are also required and can be installed using [CPAN](http://www.cpan.org):
	- LWP::Simple
	- Data::Dumper
	- JSON
	- File::Slurp
	- FindBin
	- Cwd

 **3.** Third-party software
 * [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download) [[1]](#references)
 * [DIAMOND](http://github.com/bbuchfink/diamond/) [[2]](#references)
 * [R](http://www.r-project.org/) [[3]](#references), plus the following packages:
 * [`dplyr`](https://cran.r-project.org/web/packages/dplyr/) [[4]](#references)
 * [`ggplot2`](https://cran.r-project.org/web/packages/ggplot2/) [[5]](#references)
 * [`gridExtra`](https://cran.r-project.org/web/packages/gridExtra/) [[6]](#references)
 * [MUSCLE](http://www.drive5.com/muscle/) [[7]](#references)
  
__NOTE:__ The bash script '`install_srax.sh`' is provided, in order to confirm the existence of these dependencies in your computer. If any of them would be missing, the bash script will guide you for a proper installation.

To successfully install **sraX**, please see the details provided below. If you encounter an issue during the process, please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/lgpdevtools/sraX/issues) or email me at lgpanunzi@gmail.com

Open a bash terminal and clone the repository:
```
git clone https://github.com/lgpdevtools/sraX.git
```
To verify the existence of required dependencies and ultimately install the perl modules composing sraX, inside the cloned repository run:
```
sudo bash install_srax.sh
```
## Usage

**sraX** effectively operates as one-step application. It means that just a single command is required to obtain the totality of results and their visualization.   

__NOTE:__ For a detailed explanation and examples from real datasets, please follow the [Tutorial.](https://github.com/lgpdevtools/sraX/blob/master/Tutorial.md)

### Parameters
```
Usage:
  -i|input		<Mandatory: input genome directory>
  -o|output		<Optional: name of output folder>
  -p|align_seq        	<Optional: sequence aligning algorithm (default: dblastx)>
  -e|eval    		<Optional: evalue cut-off to filter false positives (default: 1e-05)>
  -c|aln_cov       	<Optional: fraction of aligned query to the reference sequence (default: 60)>
  -id      		<Optional: sequence identity percentage cut-off to filter false positives (default: 85)>
  -u|user_sq		<Optional: input private AMR DB>
  -t|threads      	<Optional: number of threads to use (default: 6)>
  -v|version		<print current version>
  -d|debug		<Optional: print verbose output for debugging (default: No)>
  -h|help               <print this message>
```
### Minimal command
Example usage:
```
sraX -i [/path/to/input_genome_directory]
```
Where:
```
-i	Full path to the mandatory directory containing the input sequence data, which must
	be in FASTA format and consisting of individual assembled genome sequences.
```


### Extended options
Example usage:
```
sraX -p blastx -id 95 -c 90 -t 12 -o [/path/to/output_results_directory] -i [/path/to/input_genome_directory]
```
Where:
```
  Mandatory:
  ----------

  -i|input		Input directory [/path/to/input_dir] containing the input file(s), which
			must be in FASTA format and consisting of individual assembled genome sequences.

  Optional:
  ---------
	
  -o|output		Directory to store obtained results [/path/to/output_dir]. While not
			provided, the following default name will be taken:
			
			'input_directory'_'sraX'_'id'_'aln_cov'_'align_seq'

			Example:
			--------
				Input directory: 'Test'
				Options: -id 85; -c 95; -p dblastx
				Output directory: 'Test_sraX_85_95_dblastx'

  -p|align_seq		The algorithm employed for aligning the assembled genome(s) to a locally
			compiled AMR DB. The possible choices are dblastx (DIAMOND blastx) or blastx (NCBI blastx). In any
			case, the process is parallelized (up to 100 genome files are run simultaneously) for reducing
			computing times. [string] Default: dblastx (default: dblastx)
 
  -e|eval		Minimum evalue cut-off to filter false positives. [number] Default: 1e-05

  -id			Minimum identity cut-off to filter false positives. [number] Default: 85

  -c|aln_cov		Minimum length of the query which must align to the reference sequence.
			[number] Default: 60

  -u|user_sq            Customary AMR DB provided by the user. The sequences must be in FASTA format.

  -t|threads		Number of threads when running sraX. [number] Default: 6

  -h|help		Displays this help information and exits.

  -v|version		Displays version information and exits.

  -d|debug		Verbose output (for debugging).

```

## License
**sraX** is free software, licensed under [GPLv3](https://github.com/lgpdevtools/sraX/blob/master/LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/lgpdevtools/sraX/issues) or email lgpanunzi@gmail.com

## About
**sraX** is developed by Leonardo G. Panunzi.

## Citation
Panunzi LG, "sraX: a novel comprehensive resistome analysis tool", submitted to _Frontiers in Microbiology_ for publication.

## References.
[1] Altschul SF _et al._ (1990). Basic local alignment search tool. _JMB_, 215, 403–410.

[2] Buchfink B, Xie C & Huson DH (2015). Fast and sensitive protein alignment using DIAMOND. _Nature Methods_ 12, 59-60.

[3] R Core Team (2013). R: A Language and Environment for Statistical Computing.

[4] Wickham H, Romain Francois R, Henry L and Müller K (2017). dplyr: A Grammar of Data Manipulation.

[5] Wickham H (2016). ggplot2: Elegant Graphics for Data Analysis. _Springer-Verlag New York_.

[6] Auguie B, Antonov A and Auguie MB (2016).

[7] Edgar RC (2004) MUSCLE: multiple sequence alignment with high accuracy and high throughput. _Nucleic Acids Res._ 32(5):1792-1797.
