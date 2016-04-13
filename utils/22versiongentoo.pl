#!/usr/bin/perl 

use lib '../lib';
use File::Slurp;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use YAML::XS qw/DumpFile/;

our ($input, $output) = @ARGV;

our $g = Gentoo->new;
our $db = {};

foreach my $line (read_file($input)){
	chomp $line;
	my ($mtime, $name) = split / /, $line;
	
	my $co = Gentoo::CPAN::Object->new({
		parent => $g,
		_cpan_info => {
			src_uri => $name,
		},
	});
	
	push @{ $db->{$co->package_name} }, {
		d => $mtime,
		v => $co->package_version,
	};
}

foreach my $package (keys %$db){
	$db->{$package} = [
		grep { defined }
		map { $_->{v} }
		sort { $a->{d} <=> $b->{d} }
		@{ $db->{$package} }
	];
}

DumpFile($output, $db);
