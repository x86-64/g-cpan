#!/usr/bin/perl 

use lib 'lib';
use Data::Dumper;
#use YAML qw/LoadFile DumpFile/;
use YAML qw/DumpFile/;
use YAML::XS qw/LoadFile/;
use Gentoo::CPAN::Object;
use List::MoreUtils qw/all/;

my $rules_filepath = Gentoo::CPAN::Object::_rules_filepath();
my $versions_filepath = "t/22versiongentoo.yaml";

my $db = LoadFile($versions_filepath);
my $rules = {};

foreach my $package (keys %$db){
	my $array_ref = $db->{$package};
	my $uniq_date = {};
	my @versions =
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

	if(all { $_ =~ $float_re } @versions){
		if(_check_perl_versions(@versions)){
			# simple float 0.1 0.2 0.22 0.3
			
		}elsif(_check_perl_versions(map { "${_}.0" } @versions)){
			# broken float, eg. 0.8 0.9 0.10 0.11  (0.10 is 0.1, which is less than 0.9)
			$rules->{force_dotted}->{$package} = 1;

		}else{
			print STDERR Dumper { $package => \@versions, error => "incorrect float version" };
		}
		
	}elsif(all { $_ =~ $dotted_re } @versions){
		if(_check_perl_versions(@versions)){
			# simple dotted version 0.0.1 0.0.2
		}else{
	#		print STDERR Dumper { $package => \@versions, error => "incorrect dotted version" };
		}

	}elsif(all { $_ =~ $float_re || $_ =~ $dotted_re } @versions){
		$mixed++;
		next;
	}else{
		#diag(join(" ", @versions));
		next;
	}
	
	next;
	$version =~ s/[-_]+/./g;
	$version =~ s/([[:alpha:]])/".".ord($1)."."/ige;
	$version =~ s/\.\././g;
	$version =~ s/\.*$//g;

	$version =~ s/\./DOT/;
	$version =~ s/\./0/g;
	$version =~ s/DOT/\./;
	
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


