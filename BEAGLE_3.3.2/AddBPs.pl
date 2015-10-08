#!/usr/bin/perl
use Getopt::Long;

GetOptions('BPs_file=s' => \$file2,
);

open(INPUT2, "$file2") or die "Error 1";
	
@archiu2 = <INPUT2>;	

#print "@archiu2";

for ($count = 2; $count >= 0; $count--) 
	{
		unshift (@colsize,$count);
	}	

#print "@colsize";

foreach my $col (@colsize)
	{ 
#print "$col\n";
		my @result = "";
				
		foreach $A (@archiu2) 
		{	
			chomp $A;
#print "$A\n";
			@snp = split(/\t/,$A);
			push (@result,"$snp[$col]\t");

		}
		print "@result\n";	
	}


exit
