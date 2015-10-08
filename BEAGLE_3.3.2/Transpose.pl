#!/usr/bin/perl
use Getopt::Long;

GetOptions('file=s' => \$file,
);

open(INPUT, "$file") or die "Error 1";
	
@archiu = <INPUT>;	


$header = shift(@archiu);
@values = split('\s', $header);
$sample = $#values;
unshift(@archiu,$header);


for ($count = $sample; $count >= 0; $count--) 
{
	unshift (@colsize,$count);
}
		
foreach my $col (@colsize)
{ 
	my @result = "";

	foreach $_ (@archiu) 
	{	
		chomp $_;
		@snp = split(/\s/,$_);
		push (@result,"$snp[$col]\t");


		#print $snp[8]."\n";
	}

	print "@result\n";	
}


exit
