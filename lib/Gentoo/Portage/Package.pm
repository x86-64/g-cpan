package Gentoo::Portage::Package;

use Gentoo::PerlMod::Version qw/gentooize_version/;

sub new {
	my ($class, $opts) = @_;
	
	my $self = bless { %$opts }, $class;
	return $self;
}

sub from_cpan {
	my ($class, $opts) = @_;

	my $cpan_object = delete $opts->{cpan_object}
		or die;
	
	my $is_perl_core = $cpan_object->is_perl_core;
	if( ($is_perl_core || 0) == 1 ){
		$opts->{category} = "dev-lang";
		$opts->{name}     = "perl";
		return $class->new($opts);
	}
	
	$opts->{category} = "dev-perl";
	$opts->{name}     = $cpan_object->package_name;
	$opts->{version}  = gentooize_version($cpan_object->version);
	
	return $class->new($opts);
}

sub category { shift->{category} }
sub name     { shift->{name} }
sub version  { shift->{version} }

sub version_parsed {
	my ($self) = @_;
	
	$self->version =~ /^([>=<]*)(.*)$/;
	return ($1 || ">=", $2 || "0");
}

sub ebuild {
	my ($self) = @_;
	
	return sprintf("%s/%s", $self->category, $self->name);
}

sub atom {
	my ($self) = @_;
	
	my ($v_cond, $v_number) = $self->version_parsed;
	
	return $self->ebuild if $v_number =~ /^[0.]*$/;
	return sprintf("%s%s-%s", $v_cond, $self->ebuild, $v_number);
}

1;
