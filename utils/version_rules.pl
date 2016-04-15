#!/usr/bin/perl 

use lib '../lib';
use lib 'lib';
use Data::Dumper;
use YAML qw/LoadFile DumpFile/;
use Gentoo::CPAN::Object;
use List::MoreUtils qw/all/;

my $versions_filepath = $ARGV[0];
my $rules_filepath    = $ARGV[1] // Gentoo::CPAN::Object::_rules_filepath();

my $db = LoadFile($versions_filepath);
my $rules = {};

foreach my $package (keys %$db){
	my @versions = @{ $db->{$package} } or next;
	my $versions_str = join " ", @versions;
	
	my $float_re = qr/^\d+(\.\d+)?$/;
	my $dotted_re = qr/^\d+\.\d+(\.\d+)+$/;

	if(all { $_ =~ $float_re } @versions){
		if(_check_perl_versions(@versions)){
			# simple float 0.1 0.2 0.22 0.3
			
		}elsif(_check_perl_versions(map { "${_}.0" } @versions)){
			# broken float, eg. 0.8 0.9 0.10 0.11  (0.10 is 0.1, which is less than 0.9)
			$rules->{float2dotted}->{$package} = 1;

		}else{
			$rules->{ignore}->{$package} = "incorrect float version: $versions_str";
		}
		
	}elsif(all { $_ =~ $dotted_re } @versions){
		if(_check_perl_versions(@versions)){
			# simple dotted version 0.0.1 0.0.2
		}else{
			$rules->{ignore}->{$package} = "incorrect dotted version: $versions_str";
		}

	}elsif(all { $_ =~ $float_re || $_ =~ $dotted_re } @versions){
		$rules->{ignore}->{$package} = "mixed version style: $versions_str";
	}else{
		$rules->{ignore}->{$package} = "unknown version style: $versions_str";
	}
}

DumpFile($rules_filepath, $rules);

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


