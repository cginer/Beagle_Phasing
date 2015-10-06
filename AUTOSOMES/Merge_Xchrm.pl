#!/usr/bin/env perl
use Getopt::Long;

GetOptions('genotyped_list=s' => \$file1, #HapMap
'1000G_list=s' => \$file2, #1000G
'BPs_file=s' => \$file4, #BPs_positions
'Population=s' => \$file3,
'Inv=s' => \$file5,
);


open(INPUT1, "$file1") or die "Error 1";
open(INPUT2, "$file2") or die "Error 2";
open(INPUT3, "$file4") or die "Error 3";

# open(OUT1, ">"."./$file5/LISTS/$file3/$file3".".BP.Genotyped.list") or die "Error 4";
# open(OUT2, ">"."./$file5/LISTS/$file3/$file3".".Genotyped.browser.list") or die "Error 5";
open(OUT3, ">"."./$file5/LISTS/$file3/$file3".".BP.ALLPOP.list") or die "Error 6";


@archiu1 = <INPUT1>; #HapMap
@archiu2 = <INPUT2>; #1000G
@archiu3 = <INPUT3>; #BPs_positions


foreach $C (@archiu3) #BPs_positions
{
	chomp $C;
	my @FILE3 = split(/-/,$C);
	my $start = $FILE3[1];
	my $stop = $FILE3[2];		
	print OUT1 "ID\t$start\t$stop\n";	
	print OUT3 "ID\t$start\t$stop\n";	
}
	
foreach $A (@archiu2) #1000G
{
	chomp $A;
	my @FILE1 = split(/\t/,$A);		
	my $ind1 = $FILE1[0];	
	$i  = 0;
		
	foreach $B (@archiu1) #Hapmap
	{
		chomp $B;
		my @FILE2 = split(/\t/,$B);
		my $ind2 = $FILE2[1];
		$genotype = $FILE2[2];
		my $pop = $FILE2[0];
		
		if ($ind1 eq $ind2) 
		{
			$i++;

		### MALES ###	
			if ($genotype eq "S-") 
			{
				$genotype = "0:0.000:-0,-50";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind2\t$genotype\t$genotype\n";
			}

			if ($genotype eq "I-") 
			{
				$genotype = "1:2.000:-50,-0";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind2\t$genotype\t$genotype\n";
			}

		### FEMALES ###
			if ($genotype eq "SS") 
			{
				$genotype = "0|0:0:-0,-50,-50";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind2\t$genotype\t$genotype\n";
			}

			if ($genotype eq "SI") 
			{
				$genotype = "1|0:1:-50,-0,-50";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind2\t$genotype\t$genotype\n";
			}

			if ($genotype eq "II") 
			{
				$genotype = "1|1:2:-50,-50,-0";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind2\t$genotype\t$genotype\n";
			}	

			if ($genotype eq "ND") 
			{
				# $genotype = "1|0:1:-50,-0,-50";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind1\t?|?:?:-0.48,-0.48,-0.48\t?|?:?:-0.48,-0.48,-0.48\n";
			}	

			if ($genotype eq "NA") 
			{
				# $genotype = "1|0:1:-50,-0,-50";
				# print OUT1 "$ind2\t$genotype\t$genotype\n";
				print OUT3 "$ind1\t?|?:?:-0.48,-0.48,-0.48\t?|?:?:-0.48,-0.48,-0.48\n";
			}
		}	
	}
	
	print OUT3 "$ind1\t?:?:-0.48,-0.48\t?:?:-0.48,-0.48\n" if ($i == 0 and ($genotype eq "S-" or $genotype eq "I-")) ;
	print OUT3 "$ind1\t?|?:?:-0.48,-0.48,-0.48\t?|?:?:-0.48,-0.48,-0.48\n" if ($i == 0 and ($genotype eq "SS" or $genotype eq "SI" or $genotype eq "II"));
	# print OUT2 "$ind1," if ($i == 1);
	
}

exit
