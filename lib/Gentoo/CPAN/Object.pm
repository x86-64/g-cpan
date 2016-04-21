package Gentoo::CPAN::Object;

use Config;
use File::Basename;

sub new {
	my ($class, $opts) = @_;

	my $self = bless { %$opts }, $class;
	
	$self->parent(delete $self->{parent}) if $self->{parent};
	
	return $self;
}

sub name { shift->{name} }

sub parent {
	my ($self, $value) = @_;
	
	$self->{_parent} = $value if @_ >= 2;
	$self->{_parent};
}

sub cpan_info {
	my ($self) = @_;
	
	return $self->{_cpan_info} //= sub {
		my $name = $self->name
			or return {};
		
		$self->parent->getCPANInfo($name);
		
		return $self->parent->{cpan}{lc $name};
	}->();
}

sub type         {
	my ($self) = @_;

	return $self->{type} // $self->cpan_info->{type}
}

sub src_uri      {
	my ($self) = @_;
	
	return $self->{src_uri} // $self->cpan_info->{src_uri};
}

sub description  {
	my ($self) = @_;
	
	return $self->{description} // $self->cpan_info->{description};
}

sub version      {
	my ($self) = @_;
	
	return $self->_fix_version($self->{version} // $self->package_version // "0");
}

sub src_filename {
	my ($self) = @_;
	
	return basename($self->src_uri);
}

sub _src_uri_parse {
	my ($self) = @_;
	
	return $self->{_src_uri_parse} //= sub {
		my $src_uri   = $self->src_uri;
		my $filename  = $self->src_filename;
		my $extension = $self->extension;
		$filename = substr($filename, 0, -length($extension)-1);
		$filename =~ s/[._-]+$//g;
		
		# special cases
		$filename =~ s/-undef//g;
		$filename =~ s/\+d//g;
		$filename =~ s/\+NWrap/./g; # SHLOMIF
		$filename =~ s/-woldrich//g; # WOLDRICH
		$filename =~ s/-Perl\d\.\d$/./g; # GLENSMALL
		$filename =~ s/-bsdtar$/.b/g; # Tk-Wizard
		$filename =~ s/_win32_.*/.w/g; # Tk-Wizard
		$filename =~ s/-(ms)?win32//gi; # HTML-EP
		$filename =~ s/-OpenSource$//g; # NewsClipper 
		$filename =~ s/-bin-.*//g; # TWEGNER
		$filename =~ s/@.*//g; # RSPIER
		$filename =~ s/\.v\.(\d)/.v\1/g;
		$filename =~ s/[._-]?(gnuplot_required|withoutworldwriteables|no-world-writable|changelog_in_manifest|fixedmanifest|remove_blib)$/.1/;
		$filename =~ s/-withoutworldwriteables.*$//;
		$filename =~ s/\.full$//; # SRPATT/Printer
		$filename =~ s/-win32-bin-/-/; # TOSTI
		$filename =~ s/-winnt//; # CDONLEY
		$filename =~ s/-SOPM-OPM-FORMAT$//; # ROHITBASU
		$filename =~ s/\+$//; # JSMYSER
		$filename =~ s/(rc\d)-TRIAL/\1/; # KMCGRAIL
		$filename =~ s/-v$//; # KCOWGILL, ACID, MONGODB
		$filename =~ s/-v-(\d)/-v\1/; # PERLANCAR

		my @r;
		my $package_version_rules = $self->parent->_package_version_rules;
		
		my $matching_rules = {};
		while(my ($type, $rules) = each %$package_version_rules){
			foreach my $rule (
				sort { length($b) <=> length($a) }
				keys %$rules
			){
				if($filename =~ /($rule)/ or $src_uri =~ /($rule)/){
					$matching_rules->{$type} = $1;

					if($type eq "no_sep"){
						$filename =~ s/($rule)/\1-/g;
					}
				}
			}
		}
		
		if($matching_rules->{no_package}){
			@r = (undef, undef);
			
		}elsif(($filename !~ /\d/)){
			@r = ($filename, undef);
			
		}elsif(my $package = $matching_rules->{no_version}){
			@r = ($package, undef);
			
		}elsif(
			(@r = ($filename =~ /(.*?)[-_.]v?([\d._]+[-_]?[[:alnum:]_]*)$/i)) ||
			(@r = ($filename =~ /(.*?)\.([\d.]+[[:alpha:]]*)$/))             ||
			(@r = ($filename =~ /(.*?)\.([\d.]+[[:alpha:]]\d+)$/))           || # 0.1b2
			(@r = ($filename =~ /(.*?)-([ab]\d)$/))                          || # author MICB: Something-b2, -b3
			(@r = ($filename =~ /(.*?)_([a-z]\d)$/))                         || # author AUTOLIFE: Something_t3 
			(@r = ($filename =~ /(.*?)\.(\d+_\d+)$/))
		){
		}else{
			warn $self->src_uri;
			#...;
		}
		my ($package, $version) = @r;

		my $version_rewrite = $self->parent->_version_rewrite;
		if(exists $version_rewrite->{rewrite}->{$package}->{$version // ""}){
			$version = $version_rewrite->{rewrite}->{$package}->{$version // ""};
		}
		
		return {
			package   => $package,
			version   => $version,
		};
	}->();
}

sub package_name {
	my ($self) = @_;
	
	return $self->{package_name} // $self->_src_uri_parse->{package};
}
sub package_version {
	my ($self) = @_;
	
	return $self->{package_version} // $self->_src_uri_parse->{version};
}

sub author {
	my ($self) = @_;
	
	my $dirname = dirname($self->src_uri);
	return (split m@/@, $dirname)[-1];
}

sub extension {
	my ($self) = @_;
	
	return (
		($self->src_uri =~ /\.(tar\.(gz|bz2|xz|Z)|zip|tgz|gz|tbz2)$/i)[0] //
		($self->src_uri =~ /\.([^.]+)$/)[0]
	);
}

sub filepath {
	my ($self) = @_;
	
	return undef unless $self->type eq "CPAN::Module";
	
	(my $module_file = $self->name.".pm") =~ s@::@/@g;
	return $self->{_filepath} //= (
		grep { -e $_ }
		map { sprintf("%s/%s", $_, $module_file) }
		@INC
	)[0];
}

sub is_perl_core {
	my ($self) = @_;
	
	my $filepath = $self->filepath
		or return undef;
	
	my $folders_in = { 
		map { $_ => 1 } 
		grep { index($filepath, $Config::Config{$_}) == 0 } 
		qw/archlibexp privlibexp sitelibexp vendorlibexp/
	};  
	my $is_core = ($folders_in->{archlibexp} or $folders_in->{privlibexp}) ? 1 : 0;
	
	return $is_core;
}

sub unpack {
	my ($self) = @_;
	
	$self->parent->unpackModule($self->name);
	delete $self->{_cpan_info};
	return $self->cpan_info;
}

sub is_authorized {
	my ($self) = @_;
	
	return defined $self->parent->_package_authors->{$self->package_name}->{$self->author} ? 1 : 0;
}

sub _fix_version {
	my ($self, $version) = @_;
	
	my $package = $self->package_name;
	my $rules   = $self->parent->_version_rules;
	
	if($rules->{float2dotted}->{$package}){
		$version = sprintf("v%s.0", $version);
		
	}elsif($rules->{ignore}->{$package}){
		$version = undef;
	
	}elsif($version =~ /^v?(\d+\.\d+(\.\d+)+)$/i){ # dotted
		$version = sprintf("v%s", $1);
		
	}elsif($version =~ /^(\d+)(\.(\d+))?$/){ # float
		$version = sprintf("%s.%s", $1, $3 || "0");
		
	}else{
		warn "Incorrect version $version";
		$version = undef;
	}
	
	return $version;
}

1;
