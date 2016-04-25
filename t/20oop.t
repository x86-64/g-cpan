#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use Gentoo::Portage::Package;

plan tests => 17;

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
test_atom("Scalar::Util", "virtual/perl-Scalar-List-Utils");
test_atom("Sub::Util", "virtual/perl-Scalar-List-Utils");
test_atom("Carp", "virtual/perl-Carp");
test_atom("File::Path", "virtual/perl-File-Path");

test_atom("Data::Dumper", "virtual/perl-Data-Dumper");

test_atom("File::Path", ">=virtual/perl-File-Path-1.100", { version => "1.1" });
test_atom("Sub::Util", ">=virtual/perl-Scalar-List-Utils-1.100", { version => "1.1" });

test_atom("Rstats", "dev-perl/Rstats");

test_atom("ExtUtils::MakeMaker", "virtual/perl-ExtUtils-MakeMaker");

test_atom("R/RJ/RJBS/PathTools-3.62.tar.gz", "virtual/perl-File-Spec");
test_atom("Cwd", "virtual/perl-File-Spec");

test_atom("strict", "dev-lang/perl");
test_atom("warnings", "dev-lang/perl");
test_atom("utf8", "dev-lang/perl");
