#!/usr/bin/perl 

use lib '../lib';
use lib 'lib';
use Gentoo;
use Gentoo::CPAN::Object;
use YAML qw/LoadFile DumpFile/;
use Data::Dumper;

our $g = Gentoo->new;

our ($official_ebuilds_filepath, $output_filepath) = @ARGV;

our $official_ebuilds = LoadFile($official_ebuilds_filepath);

my $rules = {};

$rules->{PathTools} = {                 # no ebuilds that point to PathTools-x.tar.gz
	category => "virtual",
	name     => "perl-File-Spec",
};
$rules->{perl} = {
	category => "dev-lang",
};

foreach my $pn (keys %$official_ebuilds){
	foreach my $package (@{ $official_ebuilds->{$pn} }){
		if($package->{category} eq "virtual"){
			(my $short_name = $pn) =~ s/^perl-//;
			
			$rules->{$short_name}->{category} = "virtual";
			$rules->{$short_name}->{name} = $pn;
			next;
		}

		next unless $package->{src_uri} =~ m@authors/id/(.*)$@;
		my $src_uri = $1;
		
		my $co = Gentoo::CPAN::Object->new({
			parent  => $g,
			src_uri => $src_uri,
		});
		next unless $co->package_name;
		
		unless($co->package_name eq $pn){
			$rules->{$co->package_name}->{name} //= $pn;
		}
		unless($package->{category} eq "dev-perl"){
			$rules->{$co->package_name}->{category} //= $package->{category};
		}
	}
}

DumpFile($output_filepath, $rules);
