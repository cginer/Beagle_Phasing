#!/usr/bin/perl
use Getopt::Long;

GetOptions('file=s' => \$file,
);

open(INPUT, "$file") or die "Error 1";
	
@archiu = <INPUT>;

$umbral = 0.9;

foreach (@archiu) {
	#chomp $_;
	if ($_ =~ /^rs/) {
		chomp $_;
		@marker2 = split(/\t/,$_);
		if ($marker2[1] < $umbral){
			print $marker2[0]."\n";
		}
		if ($marker2[1] eq "NaN"){
			print $marker2[0]."\n";
		}
	}	
}

exit