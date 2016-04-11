#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use File::Slurp;

my $g = Gentoo->new;

(my $data_file = __FILE__) =~ s/\.t$//;

foreach my $package_file (map { read_file($_) } glob("${data_file}*.txt") ){
	chomp($package_file);
	
	my $co = Gentoo::CPAN::Object->new({
		parent => $g,
		_cpan_info => {
			src_uri => $package_file,
		},
	});
	
	my ($p, $v) = ($co->package_name, $co->package_version);
	$p //= ""; $v //= "";
	
	unless(
		($p eq "" and $v eq "") ||
		$p =~ /[[:alpha:]]$/ ||
		index($package_file, "${p}-${v}") >= 0 ||
		index($package_file, "${p}_${v}") >= 0 ||
		index($package_file, "${p}-v${v}") >= 0 ||
		($p =~ /Sendmail_M4/ && index($package_file, "${p}.${v}") >= 0) ||
		($p =~ /Bundle-FinalTest|WebPivot2/ && index($package_file, "${p}${v}") >= 0)
	){
		diag($co->src_uri);
		diag($co->package_name);
		diag($co->package_version);
		fail("incorrect");
	}else{
		ok($package_file);
	}
}

done_testing();
