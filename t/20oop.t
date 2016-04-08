#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;

plan tests => 7;

my $g = Gentoo->new;

my $co = Gentoo::CPAN::Object->new({
	parent => $g,
	name   => "Module::Build",
});
ok($co->portage_name eq "Module-Build", "correct name");
ok($co->portage_version,                "has version");

sub test_portage_name {
	my ($name, $portage_name) = @_;

	my $co = Gentoo::CPAN::Object->new({
		parent => $g,
		name   => $name,
	});
	ok($co->portage_name eq $portage_name, 
		sprintf(
			"correct portage name: should be '%s', but provided '%s'",
			$portage_name,
			$co->portage_name,
		)
	);
}

test_portage_name("L/LE/LEONT/Module-Build-0.4216.tar.gz", "Module-Build");
test_portage_name("Scalar::Util", "Scalar-List-Utils");
test_portage_name("Sub::Util", "Scalar-List-Utils");
test_portage_name("Carp", "perl");
test_portage_name("File::Path", "perl");

