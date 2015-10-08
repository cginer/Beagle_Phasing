#!/usr/bin/perl
use Getopt::Long;

GetOptions('file=s' => \$file,
);

open(INPUT, "$file") or die "Error 1";
@archiu = <INPUT>;	

foreach $_ (@archiu) 
{
	push (@head, $_) if ($_ =~ /^##/); #taking headers ##
}
print "@head";

foreach $_ (@archiu) 
{
	push (@body, "$_") if ($_ =~ /^#CHROM/ or $_ =~ /^\d/); #cleaning headers ##
	# push (@body, "$_") if ($_ =~ /^#CHROM/ or $_ =~ /^X/); #cleaning headers ##

	#push (@body, \t)
}

$header = shift(@body);
@values = split('\t', $header);
$sample = $#values-8; #counting chromosomes

#@body = grep /AA=/, @body; #choosing SNPs with known evolutionary state
unshift(@body,$header);

for ($count = $sample+7; $count >= 9; $count--) 
	{
		unshift (@samplesize,$count);
	}

foreach $row (@body)		
	{ 
		@line = "";
		#@line2 = "";		
		@ANC = "";
		@INFO = "";
		#$row .= "\t";

		foreach $individual (@samplesize) 
		{			
			if ($row =~ /^\d/) {   
				@snp = split(/\t/, $row);
				
				$REF = $snp[3];
				$ALT = $snp[4];
				
				@INFO = split(/;/, $snp[7]);
				@ANC = grep(/^AA=/i, @INFO);
#print "@ANC"."\n";
				foreach my $anc (@ANC) {
					@state = split(/=/, $anc);
					$ancestral = $state[1];
				}
				
				$ancestral = uc($ancestral);
				$genotype = $snp[$individual];
#print $REF.$ALT.$genotype.$ancestral."\n";
				
				if ($genotype eq $REF) {$new_genotype = "0"}; # FOR SNPs
				if ($genotype ne $REF) {$new_genotype = "1"}; # FOR SNPs
				if ($genotype eq "S") {$new_genotype = "0"}; # FOR BPs
				if ($genotype eq "I") {$new_genotype = "1"}; # FOR BPs
				#if ($REF eq "S") {$ancestral eq ""}
				$new_REF = $ancestral;
				#if ($ALT eq $ancestral) {$ALT = $REF};

#print $genotype."\t".$ancestral."\n";
			
				push (@line,"$new_genotype\t") if ($REF eq "A" or $REF eq "T" or $REF eq "C" or $REF eq "G" or $REF eq "S");
			}	
			
			if ($row =~ /^#CHROM/) {
				chomp $row;
				@snp = split(/\t/, $row);
				$id = $snp[$individual];
				#$BP = $snp[2];
				#if ($BP eq "I") {
				push (@line,"$id"."m\t") if ($snp[$individual] eq $snp[$individual+1]);
				push (@line,"$id"."f\t") if ($snp[$individual] ne $snp[$individual+1]);
				#}

			}		
		}
		#push (@line,"\n");
		unshift (@line,"$snp[0]	$snp[1]	$snp[2]	$snp[3]	$snp[4]	$snp[5]	$snp[6]	$snp[7]	$snp[8]	") if ($snp[0] eq "#CHROM");
		unshift (@line,"$snp[0]	$snp[1]	$snp[2]	$REF	$ALT	$snp[5]	$snp[6]	$snp[7]	$snp[8]	") if ($REF eq "A" or $REF eq "T" or $REF eq "C" or $REF eq "G");
		unshift (@line,"$snp[0]	$snp[1]	$snp[2]	A	C	$snp[5]	$snp[6]	$snp[7]	$snp[8]	") if ($REF eq "S");
		print  "@line2\n"; 
		print  "@line\n"; 

	}

