GARFIELD-NGS provides four different models optimized for SNPs and INDELs from Illumina or ION data. 
The tool takes standard VCF4.2 files as input and produce a standard VCF output with prediction value(s) for each variant added to INFO column. The new tag has the form: [Sample_name]_true=[value].
The tool requires VCF files produced by GATK Haplotypecaller or Unified Genotyper for Illumina data and VCF files produced by TVC (Torrent Variant Caller) for ION data.

GARFIELD-NGS uses Perl and Java to perform prediction. Ensure that Perl 5 or greater and Java 

1. Move to desired folder for installation and clone the git repository by:
    
    git clone https://github.com/gedoardo83/GARFIELD-NGS
    
  This will create a new folder named "GARFIELD-NGS" in the current location

2. Within the program folder you will find the prediction script "Predict.pl" and the four models compiled in java (.jar files). You can move GARFIELD-NGS folder wherever you want on your system, but jar models and prediction script have to remain together in the same folder.

3. The release include 2 VCF files in the tutorial folder for testing.

4. To perform prediction
