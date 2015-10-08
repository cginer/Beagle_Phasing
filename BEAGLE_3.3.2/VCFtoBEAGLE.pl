#!/usr/bin/perl
use Getopt::Long;

GetOptions('vcf=s' => \$file,
#'chromosome_number=s' => \$chromosome,
);

open(INPUT, "$file") or die "Error 1";
@archiu = <INPUT>;	

foreach $_ (@archiu) 
{
	push (@archiu2, $_) if ($_ =~ /^#CHROM/ or $_ =~ /^\d/); #clean headers ##
}

#print "@archiu2";

$header = shift(@archiu2);
@values = split('\t', $header);
$sample = $#values-8;
unshift(@archiu2,$header);

$header =shift @archiu2;	
@positions = "";
@archiu2 = grep /SNP/, @archiu2; #choosing Single Nucleotide Variants

foreach $row (@archiu2) 
	{	
		@snp = split(/\t/, $row);
		push (@positions,$snp[1]) if ($snp[4] ne "." and $snp[2] ne "."); #choosing SNPs with rs
	}

#print "marker	alleleA	alleleB

#print "@archiu";

unshift(@archiu2,$header);

for ($count = $sample+8; $count >= 9; $count--) 
	{
		unshift (@samplesize,$count);
	}	

#print "@samplesize";

chomp (@archiu2);

foreach $row (@archiu2)		
	{ 
		@mother = "";
		
		foreach $individual (@samplesize) 
		{			
			if ($row =~ /^\d/) {   
				@snp = split(/\t/, $row);
				@genotype = split(/:/, $snp[$individual]);
				@probs = split(/,/, $genotype[2]); 
					# $probs[0] = homozygote 0
					# $probs[1] = heterozygote
					# $probs[2] = homozygote 1
				@sorted_probs = @probs; 
				$first =  sprintf("%.4f", 10 ** $sorted_probs[0]);
				$second = sprintf("%.4f", 10 ** $sorted_probs[1]);
				$third =  sprintf("%.4f", 10 ** $sorted_probs[2]);
				
				push (@mother,"$first\t$second\t$third\t") if ($snp[4] ne "." and $snp[2] ne "." );		
			}	
			
			if ($row =~ /^#CHROM/) {
				@snp = split(/\t/, $row);
				$id = $snp[$individual];
				push (@mother,"$id\t$id\t$id\t")
			}		
		}
		#push (@mother,"\n");
		unshift (@mother,"$snp[2]	$snp[3]	$snp[4]	") if ($snp[4] ne "." and $snp[2] ne "." );
		print  "@mother\n"; 
	}



exit

