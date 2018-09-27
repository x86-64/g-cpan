package Gentoo::Portage::Package;

use strict;
use warnings;

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
	
	$opts->{version}  = $opts->{parent}->cpan_version_convert($version);
	$opts->{category} = "dev-perl";
	$opts->{name}     = $cpan_object->package_name
		or return undef;
	
	my $package_rules = $opts->{parent}->_package_rules;	
	if(my $rule = $package_rules->{$opts->{name}}){
		$opts = {
			%$opts,
			%$rule,
		};
	}
	
	$opts->{cpan_object} = $cpan_object;

	$opts->{name} =~ s/[^[:alnum:]+-]+/-/g;
	if($opts->{name} =~ /-\d+$/){ # package name can't end with "-1234", portage confused
		$opts->{name} .= "-perl";
	}
	
	return $class->new($opts);
}

sub parent   { shift->{parent} }
sub category { shift->{category} }
sub name     { shift->{name} }
sub version  { shift->{version} // "" }

sub dependencies {
	my ($self) = @_;
	
	if(defined $self->{dependencies}){
		return $self->{dependencies};
	}
	
	if(my $cpan_object = $self->{cpan_object}){
		my $uniq = {};
		
		my $deps = $cpan_object->dependencies;
		foreach my $type (qw/requires test_requires configure_requires build_requires/){
			my $deps_curr = $deps->{$type};
			
			$self->{dependencies}->{$type} = [
				sort { $a->ebuild cmp $b->ebuild }
				grep { my $r = not defined $uniq->{$_->ebuild}; $uniq->{$_->ebuild} = 1; $r }
				grep { defined }
				map {
					my $p = Gentoo::Portage::Package->from_cpan({
						parent      => $self->parent,
						cpan_object => $_,
					});
					warn "no package for ".$_->name if not $p;

					# drop versions for virtual/* packages - requires particular
					# perl version to be installed
					$p->{version} = "0" if $p->category eq "virtual";

					$p; 
				}
				@$deps_curr
			];
		}

		return $self->{dependencies};
	}
	
	return {};
}

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
	
	return $self->{ebuild_filepath} // 
		sprintf("%s/%s-%s.ebuild", $self->ebuild, $self->name, $self->version_digits);
}

sub ebuild_content {
	my ($self) = @_;
	
	return $self->parent->ebuild_read($self->ebuild_filepath);
}

sub is_valid {
	my ($self) = @_;
	
	return ($self->name && $self->version) ? 1 : 0;
}

1;
