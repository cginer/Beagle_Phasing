#!/usr/bin/env perl

use Getopt::Long;

GetOptions('file1=s' => \$file1, #HapMap
'file2=s' => \$file2, #1000G
);


open(INPUT1, "$file1") or die "Error 1";
open(INPUT2, "$file2") or die "Error 2";



@archiu1 = <INPUT1>; #HapMap
@archiu2 = <INPUT2>; #1000G
shift(@archiu2);
shift(@archiu2);

# $t = 0; #total individuals 1000G
# $i  = 0; #SE or Imputation ERROR (IR) total 1000G
# $g  = 0; #experimentally genotyped in 1000G & HapMap
# $i2 = 0; #SE or IR only in experimentally genotyped
# $int = 0;
# $ing = 0;

$genotyped  = 0;
$SEgenotyped = 0;
$inverted_genotyped = 0;
$standard_genotyped = 0;

foreach $A (@archiu2) #1000G
{

	$t++; 
	#print $A;
	chomp $A;
	my @FILE1 = split(/\t/,$A);		
	my $ind1 = $FILE1[0];
	my $BP1 = $FILE1[1];
	my $BP2 = $FILE1[2];	
	#print "$ind1\t$BP1\t$BP2\n";
	#print "$ind1\n";

	# if ($BP1 ne $BP2)
	# {
	# 	$i++;
	# 	#print $A."\t$i\n";
	# }

	# if ($BP1 eq "I")
	# {
	# 	$int++;
	# 	#print $A."\t$i\n";
	# }

	# if ($BP2 eq "I")
	# {
	# 	$int++;
	# 	#print $A."\t$i\n";
	# }

	foreach $B (@archiu1) #Hapmap
	{
		#print $B;
		#chomp $B;
		my @FILE2 = split(/\t/,$B);
		my $ind2 = $FILE2[1];
		#print "$ind2\n";
		#print "$ind1\t$ind2\n";
		if ($ind1 eq $ind2) 
		{
			#print $A."\n";
			$genotyped++;
		}

		if (($ind1 eq $ind2) and ($BP1 ne $BP2)) 
		{
			$SEgenotyped++;
		}

		if (($ind1 eq $ind2) and ($BP1 eq "I"))
		{
			$inverted_genotyped++;
		#print $A."\t$i\n";
		}

		if (($ind1 eq $ind2) and ($BP2 eq "I"))
		{
			$inverted_genotyped++;
		#print $A."\t$i\n";
		}

	}
		
}
$genotyped = $genotyped*2;
$standard_genotyped = $genotyped-$inverted_genotyped;
$frequency = $inverted_genotyped/$genotyped;
$frequency_wo_SE = ($inverted_genotyped-$SEgenotyped)/($genotyped-$SEgenotyped);

print "$file2\t$genotyped\t$SEgenotyped\t$inverted_genotyped\t$standard_genotyped\t$frequency\t$frequency_wo_SE\n";

exit
