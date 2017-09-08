GARFIELD-NGS provides four different models optimized for SNPs and INDELs from Illumina or ION data. 
The tool takes standard VCF4.2 files (.vcf or compressed .vcf.gz) as input and produce a standard VCF output with prediction value(s) for each variant added to INFO column. The new tag has the form: [Sample_name]_true=[value].

The tool requires VCF files produced by GATK Haplotypecaller or Unified Genotyper for Illumina data and VCF files produced by TVC (Torrent Variant Caller) for ION data and expect standard .vcf or .vcf.gz extensions.
GARFIELD-NGS uses Perl and Java to perform prediction. Ensure that Perl 5 or greater and Java 1.8 or greater are installed on your system. bgzip is also needed and available from your path to handle compressed VCF files. 

HOW TO PERFORM PREDICTIONS:

1. Move to desired folder for installation and clone the git repository by:
    
    git clone https://github.com/gedoardo83/GARFIELD-NGS
    
  This will create a new folder named "GARFIELD-NGS" in the current location

2. Within the program folder you will find the prediction script "Predict.pl" and the four models compiled in java (.jar files). You can move GARFIELD-NGS folder wherever you want on your system, but jar models and prediction script have to remain together in the same folder.

3. The release include 2 VCF files in the tutorial folder for testing.

4. To perform predictions move to the GARFIELD-NGS folder and use the Predict.pl script, specifying the desired platform for prediction. 

    for Illumina file
    perl Predict.pl --input tutorial/Test_ILM.vcf.gz --output tutorial/Test_ILM_prediction.vcf --platform illumina

    for ION file
    perl Predict.pl --input tutorial/Test_ION.vcf.gz --output tutorial/Test_ION_prediction.vcf --platform ion
    
This will produce VCF files including the GARFIELD predictions for each variants. Predictions are addedd as separate tags in the INFO column of output VCF file, in the form [Sample_name]_true=[value].
Multisample VCF can be processed. In this case, an independent tag reporting the CP value is added in INFO column for each sample in the format [Sample_name]_true=[value].
