use strict;
use File::Basename;
use Getopt::Long qw(GetOptions);

my($singlevcf, $multivcf, $outfile, $help, $row, $varid, $sampleid, %GARscore, @files, @line);

#Get options
GetOptions(
	'singleVCF=s' => \$singlevcf,
	'multiVCF=s' => \$multivcf,
	'output=s' => \$outfile,
	'help!' => \$help,
) or die "Uncorrect or missing arguments. Type --help for usage guide\n";

#Display usage guide if help is called
if ($help) {
	print "########################################################################\n";
	print "USAGE: AddScoreToMultisample.pl --singleVCF sample1.vcf[.gz],sample2.vcf[.gz],sample3.vcf[.gz] --multiVCF sample123.merged.vcf[.gz] --output output.vcf\n\n";
	print "Read GARFIELD scores for each sample from annotated single sample VCF files\n";
	print "and add these scores to the multisample VCF\n";
	exit;
}

print "Command line arguments as interpreted:\n";
print "\tSingle-sample VCFs: $singlevcf\n";
print "\tMulti-sample VCF: $multivcf\n";
print "\tOutput VCF: $outfile\n\n";

@files = split(",",$singlevcf);

#Check VCF output file existance
if (-f $outfile) {die "FATAL! Output file $outfile already exists!"}

#Process each one of the singgle-sample VCF files
foreach (@files) {

print "INFO:\tReading file $_ \n";

#Check VCF input file existance
if (!-f $_) {die "FATAL! File $_ does not exist!"}

#Check VCF file format
if ($_ =~ /.vcf$/) {
        open (VCF, $_);
} elsif ($_ =~ /.vcf.gz$/) {
	#Check if bgzip is accessible to read .vcf.gz
	system("which bgzip > /dev/null 2>&1");
        if ($? != 0) {die "FATAL! Unable to launch bgzip. It is not installed or not in your path. bgzip needed to open .vcf.gz file\nError code: $!\n"}
	open (VCF, "bgzip -dc $_ |");
}

#Read file
while ($row=<VCF>) {
	next if ($row =~ /^##/); #Skip header lines
	if ($row =~ /^#/) {
		  chomp($row);
		  @line = split("\t", $row);
		  $sampleid = $line[9]."_true";
		  next;
	}
		
	chomp($row);
	@line = split("\t", $row);
	$varid = $line[0]."_".$line[1]."_".$line[3]."_".$line[4];
		
	#Extract GARFIELD score
	$line[7] =~ /($sampleid=[0-9.]+)/;
	push(@{$GARscore{$varid}}, $1);
}
close(VCF);
}

print "\nAnnotating multi-sample VCF...\n";

#Add GARFIELD scores to multi-sample VCF
open(IN, $multivcf);
open(OUT, ">>$outfile");
while ($row=<IN>) {
	if ($row =~ /^#/) {
		print OUT $row; #Print out header lines
		next;
	}
		
	chomp($row);
	@line = split("\t", $row);
	$varid = $line[0]."_".$line[1]."_".$line[3]."_".$line[4];
		
	#Add GARFIELD scores to INFO column
	$line[7] .= ";".join(";", @{$GARscore{$varid}});
	print OUT join("\t", @line)."\n";
}
close(IN);
close(OUT);

