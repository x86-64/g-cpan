#!/usr/bin/perl 

use File::Slurp;
use Time::ParseDate qw/parsedate/;

my @lines = read_file($ARGV[0]);

my $approve;

foreach my $line (@lines){
	if($line =~ m@(authors/id/.*)\.(meta|readme)$@){
		$approve->{$1} = 1;
		next;
	}
	next unless $line =~ m@(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) ((authors/id/.*)\.(tar\.(gz|bz2|xz|Z)|zip|tgz|tbz2))$@;
	my ($date, $module, $module_short) = (scalar parsedate($1), $2, $3);
	next if $module =~ m@/os2/@;
	next if $module =~ m@/perl-?5\.@;
	next if $module =~ m@/perl542b@;
	next if $module =~ m@/AUTOLIFE/@;
	next if $module =~ m@/MICB/@;
	next if $module =~ m@/flatland2@;
	next if $module =~ m@/(perlMIF|One_Penguin|Chart-0\.99c-pre3|cmmtalk-ye2000)@;
	next unless $approve->{$module_short};
	
	printf "%d %s\n", $date, $module;
}
