#!/usr/bin/perl 

use lib '../lib';
use lib 'lib';
use File::Slurp;
use Time::ParseDate qw/parsedate/;
use Gentoo;
use Gentoo::CPAN::Object;

my @lines = read_file($ARGV[0]);

our $g = Gentoo->new;
my $approve;

foreach my $line (@lines){
	if($line =~ m@(authors/id/.*)\.(meta|readme)$@){
		$approve->{$1} = 1;
		next;
	}
	next unless $line =~ m@(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) ((authors/id/.*)\.(tar\.(gz|bz2|xz|Z)|zip|tgz|tbz2))$@;
	my ($date, $package, $package_short) = (scalar parsedate($1), $2, $3);
	
	my $co = Gentoo::CPAN::Object->new({
		parent  => $g,
		src_uri => $package,
	});
	next unless $co->is_authorized;
	next unless delete $approve->{$package_short};
	
	printf "%d %s\n", $date, $package;
}
