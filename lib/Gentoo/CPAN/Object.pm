package Gentoo::CPAN::Object;

use Config;
use File::Basename;
use File::ShareDir ':ALL';
use YAML qw/LoadFile/;

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
		$filename =~ s/[._-]?(gnuplot_required|withoutworldwriteables|no-world-writable|changelog_in_manifest|fixedmanifest|remove_blib)$//;
		$filename =~ s/-withoutworldwriteables.*$//;
		$filename =~ s/\.full$//; # SRPATT/Printer
		$filename =~ s/-win32-bin-/-/; # TOSTI
		$filename =~ s/-SOPM-OPM-FORMAT$//; # ROHITBASU
		$filename =~ s/\+$//; # JSMYSER
		$filename =~ s/(rc\d)-TRIAL/\1/; # KMCGRAIL
		
		my @r;
		
		if(
			($filename =~ /[a-f0-9]{32,40}/i) ||  # f5019eed24b24c4cb8de55c5db3384aa9d251f09
			($filename =~ /^v?([\d.]+)$/)     ||  # 1.0.2
			($src_uri =~ m@(
				/os2/|
				perl-?5\.|
				perl542b|
				/AUTOLIFE/|
				/MICB/|
				flatland2|
				perlMIF|
				One_Penguin|
				Chart-0\.99c-pre3|
				20120109-NoSQL_and_MongoDB|
				Data-Fault-z668|
				cmmtalk-ye2000
			)@x)
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
			Win32-API-Prototype|
			Win32-Daemon|
			Win32-EventLog-Message|
			ChemCanvas|
			Net-SSH2-Simple|
			Pod2html|
			Win32-MSI-SummaryInfo|
			TML-EP-MSWin32|
			Apache-AxKit-Language-Svg2AnyFormat|
			txt2slides|
			5foldCV|
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
					Class-CompiledC|
					netldapapi|
					TinyMake|
					karma|
					perltk|
					zfilter|
					cvspragma|
					Tk|
					Jeeves|
					ngstatistics|
					etext|
					File-NCopy|
					File-Remove|
					man2html|
					makehomeidx|
					htmltoc|
					perlanim|
					bperlexe|
					swig|
					p9p|
					Tk-TableMatrix|
					perl|
					PerlCRT
				)
				[-v]?
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
	
	return defined $self->_package_authors->{$self->package_name}->{$self->author} ? 1 : 0;
}

sub _rules_filepath {
	my $folder = eval { dist_dir("g-cpan") } || "share";
	
	return sprintf("%s/version_rules.yaml", $folder);
}

our $rules;
sub _rules {
	$rules //= sub {
		return LoadFile(_rules_filepath());
	}->();
}

sub _fix_version {
	my ($self, $version) = @_;
	
	my $package = $self->package_name;
	my $rules   = $self->_rules;
	
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
		...;
	}
	
	return $version;
}

our $package_authors;
sub _package_authors_filepath {
	my $folder = eval { dist_dir("g-cpan") };
	$folder //= "share" if -e "share";
	$folder //= "../share" if -e "../share";
	
	return sprintf("%s/package_authors.yaml", $folder);
}

sub _package_authors {
	$rules //= sub {
		return LoadFile(_package_authors_filepath());
	}->();
}

1;
