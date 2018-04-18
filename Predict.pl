use strict;
use File::Basename;
use Getopt::Long qw(GetOptions);

#Declare variables
my($inputvcf, $platform, $outfile, $help, $h, $i, $code, $row, $scriptpath, $scriptfile, $scriptsuffix);
my(@relevant, @samples, @line, @files);
my(%infos, %GTS);

#Get script path
my($scriptfile, $scriptpath, $scriptsuffix) = fileparse(__FILE__);

#Parsing command line options
GetOptions(
	'input=s' => \$inputvcf,
	'platform=s' => \$platform,
	'output=s' => \$outfile,
	'help!' => \$help,
) or die "Uncorrect or missing arguments. Type --help for usage guide\n";

#Display usage guide if help is called
if ($help) {
	print "########################################################################\n";
	print "GARFIELD: Genomic vARiants FIltering by dEep Learning moDels\n";
	print "By Viola Ravasio and Edoardo Giacopuzzi (edoardo.giacopuzzi\@unibs.it)\n";
	print "Version 1.0\n\n";
	print "USAGE: Predict.pl --input input.vcf[.gz] --output output.vcf --platform [illumina/ion]\n\n";
	print "Add GARFIELD scores for each variants in INFO field in a new file (output.vcf).\n";
	print "Prediction scores are marked as [Sample Name]_true=[value] in the output VCF.\n";
	print "Platform for prediction [ion/illumina] must be specified by --platform\n";
	exit;
}

#Check mandatory options
if (! $inputvcf || ! $outfile || ! $platform) {die "Uncorrect or missing arguments. Type --help for usage guide\n"}

print "Command line arguments as interpreted:\n";
print "\tInput VCF: $inputvcf\n";
print "\tOutput VCF: $outfile\n";
print "\tPlatform: $platform\n\n";

my $start_time = time();

#Store output path for tmp files
my($outname, $outpath, $outsuffix) = fileparse($outfile);

#Set relevant INFO tags based on platform
if ($platform eq "illumina") { 
	@relevant = ("BaseQRankSum","ClippingRankSum","ReadPosRankSum","DP","FS","MQ","MQRankSum","QD","SOR","QUAL"); 
	$code = "ILM";
} elsif ($platform eq "ion") {
	$code = "ION";	
	@relevant = ("FDP","FAO","QD","FSAF","FSAR","FXX","LEN","HRUN","RBI","VARB","STB","STBP","PB","PBP","MLLD","SSEN","SSEP","SSSB","QUAL");
} else {die "FATAL! Only illumina or ion are admitted as platform\n"}

#Check VCF input file existance
if (!-f $inputvcf) {die "FATAL! File $inputvcf does not exist!"} 
if (-f $outfile) {die "FATAL! Output file $outfile already exists!"}
my($inputfile, $inputpath, $inputsuffix) = fileparse($inputvcf);

#Check file extension and open VCf file
if ($inputvcf =~ /.vcf$/) {
	open (IN, $inputvcf);
} elsif ($inputvcf =~ /.vcf.gz$/) {
	system("which bgzip > /dev/null 2>&1");	#Check if bgzip is accessible to read .vcf.gz
	if ($? != 0) {die "FATAL! Unable to launch bgzip. It is not installed or not in your path. bgzip needed to open .vcf.gz file\nError code: $!\n"}
	open (IN, "bgzip -dc $inputvcf |");
} else { die "FATAL! Input file must have .vcf or .vcf.gz extension\n"}

#Extract relevant values and generate table files for SNP/INDEL prediction, 1 for each sample in VCF. Multiallelic vars are not scored
print "Reading file: $inputvcf...\n";
my ($mykey, $headline, $mytag, $indelcount, $snpcount, $dropped, $output, $totalvars);

while ($row=<IN>) {
		next if ($row =~ /^##/); #Skip header lines
		
		if ($row =~ /^#/) {	#Read samples names
			chomp($row);
			@line = split("\t", $row);
			@samples[9..$#line] = @line[9..$#line];
			tr/ /_/ foreach (@samples);	#Substitutes spaces in samples name with underscore
			
			foreach $mykey(@relevant) {$headline .= ",$mykey"}
			for ($h=9; $h<=$#line; $h++) {
				open (TABLE, ">$outpath/GARFIELD.$samples[$h].INDEL.table");			
				print TABLE "var".$headline.",GQ\n";
				close(TABLE);
				open (TABLE, ">$outpath/GARFIELD.$samples[$h].SNP.table");			
				print TABLE "var".$headline.",GQ\n";
				close(TABLE);
								
			}	
			next;		
		}	
	
		$totalvars++;
		$output = "";

		chomp($row);
		@line = split("\t", $row);
	
		#Extract info tags values
		my @tags=split(";", $line[7]);
		foreach $mytag(@tags) {
			$mytag =~ /([A-Za-z_]+)=(.+)/;
			$infos{$1}=$2;
		}
	
		#Save QUAL value
		$infos{QUAL} = $line[5];
	
		#Save GT values
		my @format = split (":", $line[8]);

		for ($h=9; $h<=$#line; $h++) {		
			my @values = split (":", $line[$h]);
			for ($i=0; $i<=$#values; $i++) {
				$GTS{$h}{$format[$i]}=$values[$i];
			}	
		}
		
		#Generate output
		foreach $mykey(@relevant) {
			$output .= ",$infos{$mykey}";
		}
		$output = $line[0]."_".$line[1]."_".$line[3]."_".$line[4].$output;
		for ($h=9; $h<=$#line; $h++) {
			if ($line[4] =~ /,/) { #Drop variants with multiple alleles and save them in separate file
				$dropped++;
				open (DROP, ">>$outpath/Dropped.GARFIELD.vars");
				print DROP "$row\n";
				close(DROP);
			} elsif (length($line[3]) == length($line[4])) { #Save SNP table
				$snpcount++;
				open (TABLE, ">>$outpath/GARFIELD.$samples[$h].SNP.table");			
				print TABLE $output.",$GTS{$h}{GQ}\n";
				close(TABLE);
			} elsif (length($line[3]) != length($line[4])) { #Save INDEL table
				$indelcount++;
				open (TABLE, ">>$outpath/GARFIELD.$samples[$h].INDEL.table");			
				print TABLE $output.",$GTS{$h}{GQ}\n";
				close(TABLE);					
			}
		}

}

print "INFO\tTotal variants: $totalvars\n";
print "INFO\tSNP variants: $snpcount\n";
print "INFO\tINDEL variants: $indelcount\n\n";
if ($dropped>0) {print "WARNING: Variants with multiple alleles detected. $dropped variants will not be scored\nIt is suggested to split and normalize your VCF file using vt or similar tools before scoring\nDropped variants saved to Dropped.GARFIELD.vcf\n\n"}

#Launch java script to perform predictions
my $myfile;
print "Performing predictions on INDEL...\n";
@files = <$outpath/GARFIELD.*.INDEL.table>;
foreach $myfile(@files) {
	my $command = "java -cp .:".$scriptpath.$code."_INDEL_model.jar:".$scriptpath."h2o-genmodel.jar NewPredictCsv --header --model deeplearning_".$code."_INDEL --input $myfile --output $myfile.h2o";
	system($command);
	if ($? == -1) {die "Error in prediction!!\nError code: $!\n"}
	system("paste -d\",\" $myfile $myfile.h2o > $myfile.predictions");
}

print "Performing predictions on SNP...\n";
@files = <$outpath/GARFIELD.*.SNP.table>;
foreach $myfile(@files) {
	my $command = "java -cp .:".$scriptpath.$code."_SNP_model.jar:".$scriptpath."h2o-genmodel.jar NewPredictCsv --header --model deeplearning_".$code."_SNP --input $myfile --output $myfile.h2o";
	system($command);
	if ($? == -1) {die "Error in prediction!\nError code: $!\n"}
	system("paste -d\",\" $myfile $myfile.h2o > $myfile.predictions");
}


#Read prediction tables and add values in VCF file
print "Adding predictions to VCF file and saving to $outfile\n\n";

#Create INFO tags for each scored variants
my (%scoredvar, %newheader);
my $toolheadline;

@files =<$outpath/GARFIELD.*.predictions>;
foreach $myfile(@files) {
	open(IN, $myfile);
	$myfile =~ /GARFIELD.([^.]+)./;
	my $sampleid = $1;	
	while ($row=<IN>) {
		chomp($row);
		@line = split(",", $row);
		$scoredvar{$line[0]} .= ";".$sampleid."_true=".sprintf("%.3f",$line[$#line]);
		$newheader{$sampleid} = "##INFO=<ID=".$sampleid."_true,Number=1,Type=Float,Description=\"GARFIELD prediction for variant in $sampleid sample\">\n"
	}
	close(IN);
}
foreach $mykey(keys %newheader) {
	$toolheadline .= $newheader{$mykey};
}

#Read input VCF, add GARFIELD INFO tag and print to output file
my $id;
if ($inputvcf =~ /.vcf$/) {
	open (VCF, $inputvcf);
} elsif ($inputvcf =~ /.vcf.gz$/) {
	open (VCF, "bgzip -dc $inputvcf |");
}

open(OUT, ">>$outfile");
while ($row=<VCF>) {
	if ($row =~ /^##/) {	#print header lines to output
		print OUT $row;
		next;	
	} elsif ($row =~ /^#CHROM/) {	#add GARFIELD to VCF INFO header
		print OUT $toolheadline;
		print OUT $row;
		next;	
	}
	chomp($row);
	@line = split("\t", $row);
	$id = $line[0]."_".$line[1]."_".$line[3]."_".$line[4];
	print OUT join("\t", @line[0..6])."\t$line[7]$scoredvar{$id}\t".join("\t", @line[8..$#line])."\n";
	
}
close(VCF);
close(OUT);

#Clean up temporary files
print "Cleaning up temp files...\n\n";
system("rm $outpath/GARFIELD.*");

my $end_time=time();

#End message
print "All done!\n";
print "Run time: ".($end_time - $start_time)." secs\n";

