#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Gentoo;
use Gentoo::CPAN::Object;
use Gentoo::PerlMod::Version qw/:all/; 
use CPANPLUS::Dist::Gentoo::Version;
use YAML::XS qw/LoadFile/;
use List::MoreUtils qw/all/;
use version 0.77;

my $g = Gentoo->new;

(my $data_file = __FILE__) =~ s/\.t$/.yaml/;

my $db = LoadFile($data_file);

my ($all, $float, $dotted, $mixed);
foreach my $package (keys %$db){
	my $array_ref = $db->{$package};
	my $uniq_date = {};
	my @array =
		grep { $_ }
		map { $_->{v} }
		sort { 
			$a->{d} cmp $b->{d} ||
			$a->{v} cmp $b->{v}
		}
		grep { my $r = not defined $uniq_date->{$_}; $uniq_date->{$_} = 1; $r } # FIXME
		@$array_ref;
	
	my $float_re = qr/^\d+(\.\d+)?$/;
	my $dotted_re = qr/^\d+\.\d+(\.\d+)+$/;

	$all++;
	if(all { $_ =~ $float_re } @array){
		$float++;
		if(_check_perl_versions(@array)){
			ok("simple float");
			
		}elsif(_check_perl_versions(map { "${_}.0" } @array)){
			diag("version rescue for $package");
			ok("non float 0.x");
		}else{
	#		fail("fail")
		}
		
	}elsif(all { $_ =~ $dotted_re } @array){
		$dotted++;
	
		if(_check_perl_versions(@array)){
			ok("dotted");
		}else{
	#		fail("fail")
		}

	}elsif(all { $_ =~ $float_re || $_ =~ $dotted_re } @array){
		$mixed++;
		next;
	}else{
		#diag(join(" ", @array));
		next;
	}
	
	next;
	my @versions;
	foreach my $version (@array){
		
		next;
		$version =~ s/[-_]+/./g;
		$version =~ s/([[:alpha:]])/".".ord($1)."."/ige;
		$version =~ s/\.\././g;
		$version =~ s/\.*$//g;

		$version =~ s/\./DOT/;
		$version =~ s/\./0/g;
		$version =~ s/DOT/\./;
		
		my $gpv_version;
		eval { $gpv_version = gentooize_version($version, { lax => 2 }) };
		if($@){
			diag("GPV failed: $version");
		}
		
		push @versions, $version;
	}
	
}
diag("all: $all float: $float dotted: $dotted mixed: $mixed");

sub _check_perl_versions {
	my (@versions) = @_;
	
	my @check = grep { defined } map { eval { version->parse($_) } } @versions;

	my $v1 = shift @check;
	while(my $v2 = shift @check){
		unless($v1 <= $v2){
			return 0;
			last;
		}
		$v1 = $v2;
	}
	return 1;
}

done_testing();
