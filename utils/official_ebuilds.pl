#!/usr/bin/perl 

use lib 'lib';
use lib '../lib';
use File::Find;
use File::Slurp;
use File::Temp;
use Shell::EnvImporter;
use Gentoo;
use YAML qw/DumpFile/;

our @overlays = (
	"/usr/portage",
	"/var/lib/layman/perl-experimental",
);

our @categories = (
	"dev-perl",
	"perl-core",
	"virtual",
);

our $ebuilds = {};
our $g = Gentoo->new;

sub main {
	foreach my $overlay (@overlays){
		foreach my $category (@categories){
			my $path = sprintf("%s/%s", $overlay, $category);
			
			find({
				wanted => sub {
					my $file = $_;

					return unless $file =~ /\.ebuild/i;
					return if $category eq "virtual" and $file !~ m@/perl-@;
					
					my $ebuild_data = $g->ebuild_read($file);
					ebuild_process($ebuild_data);
				},
				no_chdir => 1,
			}, $path);
			
		}
	}
	
	DumpFile($ARGV[0], $ebuilds);
}

sub ebuild_process {
	my ($ebuild) = @_;
	
	my $version = substr($ebuild->{P}, length($ebuild->{PN}) + 1);
	
	push @{ $ebuilds->{$ebuild->{PN}} }, {
		atom     => $ebuild->{P},
		version  => $version,
		category => $ebuild->{CATEGORY},
		src_uri  => $ebuild->{SRC_URI},
	};
}

main;
