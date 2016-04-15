#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use Gentoo::Portage::Package;
use CPANPLUS::Dist::Gentoo::Version;
use YAML::XS qw/LoadFile/;

my $g = Gentoo->new;

(my $data_file = __FILE__) =~ s/\.t$/.yaml/;

my $db = LoadFile($data_file);

foreach my $package (keys %$db){
	my @versions = @{ $db->{$package} } or next;
	my $versions_str = join " ", @versions;
	
	my @gentoo_versions = 
		map { CPANPLUS::Dist::Gentoo::Version->new($_) }
		grep { defined }
		map {
			my $version = $_;
			
			my $co = Gentoo::CPAN::Object->new({
				parent       => $g,
				package_name => $package,
				version      => $version,
			});
			
			my $go = Gentoo::Portage::Package->from_cpan({
				cpan_object => $co,
			});
			$go ? $go->version : undef;
		}
		@versions;
	
	my $gversions_str = join " ", map { "".$_ } @gentoo_versions;
	if(_check_perl_versions(@gentoo_versions)){
		ok("$package success");
	}elsif(Gentoo::CPAN::Object::_version_rewrite->{approve_inconsistent}->{$package}){
		ok("$package approved");
	}else{
		diag($versions_str);
		diag($gversions_str);
		fail("$package versions incorrect");
	}
}

sub _check_perl_versions {
	my (@check) = @_;
	
	my $v1 = shift @check;
	while(my $v2 = shift @check){
		unless($v1 < $v2){
			return 0;
		}
		$v1 = $v2;
	}
	return 1;
}

done_testing();
