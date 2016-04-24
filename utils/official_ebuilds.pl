#!/usr/bin/perl 

use File::Find;
use File::Slurp;
use File::Temp;
use Shell::EnvImporter;
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

our $eclass = "/usr/portage/eclass/perl-module.eclass";
our $ebuilds = {};

sub main {
	foreach my $overlay (@overlays){
		foreach my $category (@categories){
			my $path = sprintf("%s/%s", $overlay, $category);
			
			find({
				wanted => sub {
					my $file = $_;

					return unless $file =~ /\.ebuild/i;
					return if $category eq "virtual" and $file !~ m@/perl-@;
					
					my $ebuild_data = ebuild_read($file);
					ebuild_process($ebuild_data);
				},
				no_chdir => 1,
			}, $path);
			
		}
	}
	
	DumpFile($ARGV[0], $ebuilds);
}

sub ebuild_read {
	my ($filepath) = @_;
	
	my $ebuild = {};
	
	my ($cat, $pn, $p) = ($filepath =~ m@([^/]+)/([^/]+)/([^/]+).ebuild$@i);
	
	my $tmp = File::Temp->new;
	append_file($tmp->filename, qq!
		PN="${pn}"
		P="${p}"
		PF="${p}"
		CATEGORY="${cat}"
	!);
	append_file($tmp->filename, scalar read_file($filepath));
	append_file($tmp->filename, scalar read_file($eclass));
	
	my $env = Shell::EnvImporter->new(
		file          => $tmp->filename,
		shell         => 'bash',
		auto_run      => 1,
		auto_import   => 1,
		import_filter => sub {
			my ($var, $value, $type_of_change) = @_;
			
			$value =~ s/^['"\s]+//;
			$value =~ s/['"\s]+$//;
			
			$ebuild->{$var} = $value;
			return 0;
		},
	);
	$env->shellobj->envcmd('set');
	$env->run;
	
	return $ebuild;
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
