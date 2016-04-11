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
		my $name = $self->name;
		
		$self->parent->getCPANInfo($name);
		
		return $self->parent->{cpan}{lc $name};
	}->();
}

sub type    { shift->cpan_info->{type} }
sub src_uri { shift->cpan_info->{src_uri} }
sub version { shift->{version} || "0" }
sub description { shift->cpan_info->{description} }

sub src_filename {
	my ($self) = @_;
	
	return basename($self->src_uri);
}

sub _src_uri_parse {
	my ($self) = @_;
	
	return $self->{_src_uri_parse} //= sub {
		my $filename  = $self->src_filename;
		my $extension = $self->extension;
		$filename = substr($filename, 0, -length($extension)-1);
		$filename =~ s/[._-]+$//g;
		
		# special cases
		$filename =~ s/-undef//g;
		$filename =~ s/\+d//g;
		$filename =~ s/\+NWrap/./g; # SHLOMIF
		$filename =~ s/-Perl\d\.\d$/./g; # GLENSMALL
		$filename =~ s/[._-]?(gnuplot_required|withoutworldwriteables|no-world-writable|changelog_in_manifest|fixedmanifest)$//;
		
		my @r;
		
		if(
			($filename =~ /[a-f0-9]{32,40}/i) ||  # f5019eed24b24c4cb8de55c5db3384aa9d251f09
			($filename =~ /^([\d.]+)$/)           # 1.0.2
		){
			@r = (undef, undef);
		}elsif(($filename !~ /\d/)){
			@r = ($filename, undef);
		}elsif(($filename =~ /^(
			metaperl-dbix-dbh |
			Mica |
			Spreadsheet-WriteExcel-WebPivot2 |
			Win32GUI |
			Net-SMS-WAY2SMS |
			Ipv4_networks |
			Geo-GoogleEarth-Document |
			Device-Velleman-K8055-Client |
			Model3D-Poser-GetStringRes |
			Bundle-FinalTest2
		)/xi)){
			@r = ($1, undef)
		}elsif(
			(@r = ($filename =~ /^
				(
					PGForth|
					Win32-TaskScheduler|
					TimeConvert|
					WWW-TMDB-API|
					ESplit|
					XMS-MotifSet|
					Text-Format|
					v6|
					Class-CompiledC
				)
				v?
				([\d.]+)
			/ix)) ||
			(@r = ($filename =~ /(.*?)[-_.]v?([\d._]+[-_]?[[:alnum:]_]*)$/i)) ||
			(@r = ($filename =~ /(.*?)\.([\d.]+[[:alpha:]]*)$/))             ||
			(@r = ($filename =~ /(.*?)\.([\d.]+[[:alpha:]]\d+)$/))           || # 0.1b2
			(@r = ($filename =~ /(.*?)-([ab]\d)$/))                          || # author MICB: Something-b2, -b3
			(@r = ($filename =~ /(.*?)\.(\d+_\d+)$/))
		){
		}else{
			warn $self->src_uri;
			...;
		}
		my ($package, $version) = @r;
		
		return {
			package   => $package,
			version   => $version,
		};
	}->();
}

sub package_name      { shift->_src_uri_parse->{package}   }
sub package_version   { shift->_src_uri_parse->{version}   }

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

1;
