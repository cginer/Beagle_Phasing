#!/usr/bin/perl
use Getopt::Long;

GetOptions('BPs=s' => \$file1,
'Genotyped=s' => \$file2);
die("Usage Error perl linecall.pl -BPs -Genotyped \n") if(!$file1 | !$file2);

open(FILE1,"$file1") or die "Error 1";
open(FILE2,"$file2") or die "Error 2";
@bp = <FILE1>;
@genotyped = <FILE2>;	
shift @bp;
shift @bp;
	
foreach my $A (@genotyped) {
	$i = 9;
	@individual = "";
	my @FILE1 = split(/\t/,$A);		
	my $g_individual = $FILE1[1];
#print $g_individual."\n";

	foreach $B (@bp)
	{ 
		$i++;
		my @FILE2 = split(/\t/,$B);
		my $SE_individual = $FILE2[0];
		my $BP1 = $FILE2[1];
		my $BP2 = $FILE2[2];

		push (@individual,$i.",") if (($g_individual eq $SE_individual) and ($BP1 eq $BP2));
	}    	

#chomp @individual;
print "@individual";

}

exit
