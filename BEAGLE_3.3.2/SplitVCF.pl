#!/usr/bin/perl
use Getopt::Long;

GetOptions('vcf=s' => \$file1,
'desired_individuals=s' => \$file2);
die("Usage Error perl linecall.pl -vcf -desired_individuals \n") if(!$file1 | !$file2);

open(FILE1,"$file1") or die "Error 1";
open(FILE2,"$file2") or die "Error 2";
@vcf = <FILE1>;
@invind = <FILE2>;	

	
foreach my $row (@invind) {
	$i = 0;
	@individual = "";
	foreach $line (@vcf)
	{ 
		$i++;
		#push (@individual,$i."\t".$line) if ($line eq $row);
		push (@individual,$i.",") if ($line eq $row);
	}    	

#chomp @individual;
print "@individual";

}

exit
