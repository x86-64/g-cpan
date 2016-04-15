#!/usr/bin/perl 

use lib '../lib';
use lib 'lib';
use File::Slurp;
use Gentoo::CPAN::Object;
use YAML qw/DumpFile/;

our ($input, $output) = @ARGV;

my $db = {};
my $header = 1;
foreach my $line (read_file($input)){
	chomp $line;
	($header = 0, next) if $line =~ /^$/;
	next unless $header == 0;
	
	my ($module, $version, $package) = split /\s+/, $line;
	
	my $co = Gentoo::CPAN::Object->new({
		src_uri => $package,
	});
	
	$db->{$co->package_name}->{$co->author} = 1;
}

DumpFile($output, $db);
