#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use Gentoo::Portage::Package;

plan tests => 10;

my $g = Gentoo->new;

my $co = Gentoo::CPAN::Object->new({
	parent => $g,
	name   => "Module::Build",
});
ok($co->package_name eq "Module-Build", "correct name");
ok($co->package_version,                "has version");

sub test_atom {
	my ($name, $atom, $opts) = @_;

	my $co = Gentoo::CPAN::Object->new({
		parent => $g,
		name   => $name,
		version => 0,
		%{ $opts || {} },
	});
	my $gp = Gentoo::Portage::Package->from_cpan({
		parent      => $g,
		cpan_object => $co,
	});
	
	ok($gp->atom eq $atom, 
		sprintf(
			"correct portage name: should be '%s', but provided '%s'",
			$atom,
			$gp->atom,
		)
	);
}

test_atom("L/LE/LEONT/Module-Build-0.4216.tar.gz", "dev-perl/Module-Build");
test_atom("Scalar::Util", "dev-perl/Scalar-List-Utils");
test_atom("Sub::Util", "dev-perl/Scalar-List-Utils");
test_atom("Carp", "dev-lang/perl");
test_atom("File::Path", "dev-lang/perl");

test_atom("Data::Dumper", "perl-core/Data-Dumper");

test_atom("File::Path", ">=perl-core/File-Path-1.100", { version => "1.1" });
test_atom("Sub::Util", ">=dev-perl/Scalar-List-Utils-1.100", { version => "1.1" });

