package MongoDBx::Class::Connection;

# ABSTARCT: A connection to a MongoDB server

use Moose;
use namespace::autoclean;
use Scalar::Util qw/blessed/;

extends 'MongoDB::Connection';

=head1 NAME

MongoDBx::Class::Connection - A connection to a MongoDB server

=cut

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'doc_classes' => (is => 'ro', isa => 'HashRef', required => 1);

has 'safe' => (is => 'rw', isa => 'Bool', default => 0);

override 'get_database' => sub {
	MongoDBx::Class::Database->new(_connection => shift, name => shift);
};

sub expand {
	my ($self, $coll_ns, $doc) = @_;

	return unless $coll_ns && $doc && ref $doc eq 'HASH';

	my ($db_name, $coll_name) = ($coll_ns =~ m/^([^.]+)\.(.+)$/);

	my $coll = $self->get_database($db_name)->get_collection($coll_name);

	return $doc unless exists $doc->{_class} && exists $self->doc_classes->{$doc->{_class}};

	my $dc_name = $doc->{_class};
	my $ns = $self->namespace;
	$dc_name =~ s/^${ns}:://;

	my $dc = $self->doc_classes->{$dc_name};

	my %attrs = (
		_collection => $coll,
		_class => $doc->{_class},
	);

	foreach ($dc->meta->get_all_attributes) {
		# is this a MongoDBx::Class::Reference?
		if ($_->{isa} eq 'MongoDBx::Class::CoercedReference') {
			my $name = $_->name;
			$name =~ s!^_!!;
			
			next unless exists $doc->{$name} &&
				    ref $doc->{$name} eq 'HASH' &&
				    exists $doc->{$name}->{'$ref'} &&
				    exists $doc->{$name}->{'$id'};

			$attrs{$_->name} = MongoDBx::Class::Reference->new(
				_collection => $coll,
				_class => 'MongoDBx::Class::Reference',
				ref_coll => $doc->{$name}->{'$ref'},
				ref_id => $doc->{$name}->{'$id'},
			);
		} elsif ($_->{isa} eq 'ArrayOfMongoDBx::Class::CoercedReference') {
			my $name = $_->name;
			$name =~ s!^_!!;

			next unless exists $doc->{$name} &&
				    ref $doc->{$name} eq 'ARRAY';

			foreach my $ref (@{$doc->{$name}}) {
				push(@{$attrs{$_->name}}, MongoDBx::Class::Reference->new(
					_collection => $coll,
					_class => 'MongoDBx::Class::Reference',
					ref_coll => $ref->{'$ref'},
					ref_id => $ref->{'$id'},
				));
			}				
		} elsif ($_->documentation && $_->documentation eq 'MongoDBx::Class::EmbeddedDocument') {
			my $edc_name = $_->{isa};
			$edc_name =~ s/^${ns}:://;
			if ($_->{isa} =~ m/^ArrayRef/) {
				my $name = $_->name;
				$name =~ s!^_!!;

				next unless exists $doc->{$name} &&
					    ref $doc->{$name} eq 'ARRAY';

				foreach my $a (@{$doc->{$name}}) {
					$a->{_class} = $edc_name;
					push(@{$attrs{$_->name}}, $self->expand($coll_ns, $a));
				}
			} else {
				next unless exists $doc->{$_->name};
				$doc->{$_->name}->{_class} = $edc_name;
				$attrs{$_->name} = $self->expand($coll_ns, $doc->{$_->name});
			}
		} else {
			next unless exists $doc->{$_->name};
			$attrs{$_->name} = $doc->{$_->name};
		}
	}

	return $dc->new(%attrs);
}

sub collapse {
	my ($self, $val) = @_;

	if (ref $val eq 'ARRAY') {
		my @arr;
		foreach (@$val) {
			if (blessed $_ && $_->isa('MongoDBx::Class::Reference')) {
				push(@arr, { '$ref' => $_->ref_coll, '$id' => $_->ref_id });
			} elsif (blessed $_ && $_->does('MongoDBx::Class::Document')) {
				push(@arr, { '$ref' => $_->_collection->name, '$id' => $_->_id });
			} elsif (blessed $_ && $_->does('MongoDBx::Class::EmbeddedDocument')) {
				my $hash = {};
				foreach my $ha (keys %$_) {
					next if $ha eq '_collection';
					$hash->{$ha} = $_->{$ha};
				}
				push(@arr, $hash);
			} else {
				push(@arr, $_);
			}
		}
		return \@arr;
	} elsif (blessed $val && $val->isa('MongoDBx::Class::Reference')) {
		return { '$ref' => $val->ref_coll, '$id' => $val->ref_id };
	} elsif (blessed $val && $val->does('MongoDBx::Class::Document')) {
		return { '$ref' => $val->_collection->name, '$id' => $val->_id };
	} elsif (blessed $val && $val->does('MongoDBx::Class::EmbeddedDocument')) {
		my $hash = {};
		foreach my $ha (keys %$val) {
			next if $ha eq '_collection';
			$hash->{$ha} = $val->{$ha};
		}
		return $hash;
	}

	return $val;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Connection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
