#!/usr/bin/perl 

use lib '../lib';
use lib 'lib';
use File::Slurp;
use Time::ParseDate qw/parsedate/;
use Gentoo::CPAN::Object;

my @lines = read_file($ARGV[0]);

my $approve;

foreach my $line (@lines){
	if($line =~ m@(authors/id/.*)\.(meta|readme)$@){
		$approve->{$1} = 1;
		next;
	}
	next unless $line =~ m@(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) ((authors/id/.*)\.(tar\.(gz|bz2|xz|Z)|zip|tgz|tbz2))$@;
	my ($date, $package, $package_short) = (scalar parsedate($1), $2, $3);
	
	my $co = Gentoo::CPAN::Object->new({
		src_uri => $package,
	});
	next unless $co->is_authorized;
	
	next if $package =~ m@/os2/@;
	next if $package =~ m@/perl-?5\.@;
	next if $package =~ m@/perl542b@;
	next if $package =~ m@/AUTOLIFE/@;
	next if $package =~ m@/MICB/@;
	next if $package =~ m@/flatland2@;
	next if $package =~ m@/(perlMIF|One_Penguin|Chart-0\.99c-pre3|cmmtalk-ye2000)@;
	next unless $approve->{$package_short};
	
	printf "%d %s\n", $date, $package;
}
