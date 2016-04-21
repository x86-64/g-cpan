package Gentoo::Portage::Package;

sub new {
	my ($class, $opts) = @_;
	
	my $self = bless { %$opts }, $class;
	return $self;
}

sub from_cpan {
	my ($class, $opts) = @_;

	my $cpan_object = delete $opts->{cpan_object}
		or die "cpan_object not specified";
	
	my $version = $cpan_object->version
		or return undef;
	
	if($version =~ /^[0.]+$/ && ($cpan_object->is_perl_core || 0) == 1){
		$opts->{category} = "dev-lang";
		$opts->{name}     = "perl";
		return $class->new($opts);
	}

	$opts->{category} = "dev-perl";
	$opts->{name}     = $cpan_object->package_name
		or return undef;
	
	if($version =~ /^v(.*)$/){ # dotted
		$opts->{version} = $1;
		
	}elsif($version =~ /^(\d+)\.(\d+)$/){ # float
		$opts->{version} = sprintf(
			"%d.%s",
			$1,
			(
				join ".",
				grep { length($_) == 3 }
				split /(...)/, "${2}00"
			),
		);
	
	}else{
		warn "Unsupported version $version";
		...;
	}
	
	return $class->new($opts);
}

sub parent   { shift->{parent} }
sub category { shift->{category} }
sub name     { shift->{name} }
sub version  { shift->{version} }

sub version_parsed {
	my ($self) = @_;
	
	$self->version =~ /^([>=<]*)(.*)$/;
	return ($1 || ">=", $2 || "0");
}

sub version_condition {
	my ($self) = @_;
	
	my ($v_cond, $v_number) = $self->version_parsed;
	return $v_cond;
}

sub version_digits {
	my ($self) = @_;

	my ($v_cond, $v_number) = $self->version_parsed;
	return $v_number;
}

sub ebuild {
	my ($self) = @_;
	
	return sprintf("%s/%s", $self->category, $self->name);
}

sub atom {
	my ($self) = @_;
	
	return $self->ebuild if $self->version_digits =~ /^[0.]*$/;
	return sprintf("%s%s-%s", $self->version_condition, $self->ebuild, $self->version_digits);
}

sub ebuild_filepath {
	my ($self) = @_;
	
	return sprintf("%s-%s.ebuild", $self->ebuild, $self->version_digits);
}

1;
