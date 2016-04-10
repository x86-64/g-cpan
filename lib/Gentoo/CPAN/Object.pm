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

sub package_name {
	my ($self) = @_;
	
	return $self->parent->transformCPAN($self->src_uri, 'n');
}

sub package_version {
	my ($self) = @_;

	return $self->parent->transformCPAN($self->src_uri, 'v');
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

1;
