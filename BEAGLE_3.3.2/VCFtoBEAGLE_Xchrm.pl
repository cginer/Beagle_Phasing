#!/usr/bin/perl
use Getopt::Long;

GetOptions('vcf=s' => \$file,
'gender=s' => \$file2,
);

open(INPUT, "$file") or die "Error 1";
@archiu = <INPUT>;	
open(INPUT2, "$file2") or die "Error 2";
@archiu3 = <INPUT2>;	


foreach $_ (@archiu) 
{
	push (@archiu2, $_) if ($_ =~ /^X/); #clean headers # OJO con el chromosoma! 
}

shift(@archiu3);

# print @archiu3;

$header = shift(@archiu2);
@values = split('\t', $header);
$sample = $#values-8;
@archiu2 = grep /SNP/, @archiu2; #choosing Single Nucleotide Variants
unshift(@archiu2,$header);

for ($count = $sample+8; $count >= 9; $count--) 
	{
		unshift (@samplesize,$count);
	}	

print "marker\talleleA\talleleB\t";

foreach $line (@archiu3)
{
	#print $line;
	@gender = split(/\t/, $line);
	@genot = split(/:/, $gender[1]);
	@likel = split(/,/, $genot[2]);
	if ($#likel eq "2")
	{
		print "$gender[0]\t$gender[0]\t$gender[0]\t";
	}
	if ($#likel eq "1")
	{
		print "$gender[0]\t$gender[0]\t$gender[0]\t";
	}
}
print "\n";

foreach $row (@archiu2)		
{ 
	chomp $row;
	@mother = "";

	foreach $individual (@samplesize) 
	{			
		@snp = split(/\t/, $row);
		@genotype = split(/:/, $snp[$individual]);
		@probs = split(/,/, $genotype[2]); 

		if ($row =~ /^X/) #OJO#
		{
			if ($#probs eq "2") ### FEMALES ###
			{
				my @sorted_probs = @probs; 
				my $first =  sprintf("%.4f", 10 ** $sorted_probs[0]);
				my $second = sprintf("%.4f", 10 ** $sorted_probs[1]);
				my $third =  sprintf("%.4f", 10 ** $sorted_probs[2]);
				push (@mother,"$first\t$second\t$third\t") if ($snp[4] ne "." and $snp[2] ne "." );	
			}

			if ($#probs eq "1") ### MALES ###
			{
				my @sorted_probs = @probs; 
				my $first =  sprintf("%.4f", 10 ** $sorted_probs[0]); #homozigoto 0
				my $second = sprintf("%.4f", 10 ** $sorted_probs[1]); #homozigoto 1
				my $third = "0.0000"; # los heterozigotos tienen probabilidad 0
				push (@mother,"$first\t$third\t$second\t") if ($snp[4] ne "." and $snp[2] ne "." );	
			}
		}
	}

	unshift (@mother,"$snp[2]	$snp[3]	$snp[4]	") if ($snp[4] ne "." and $snp[2] ne "." );
	print  "@mother\n"; 

}


exit

