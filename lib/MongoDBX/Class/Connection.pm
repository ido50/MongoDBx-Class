package MongoDBX::Class::Connection;

# ABSTARCT: A connection to a MongoDB server

use Moose;
use namespace::autoclean;

extends 'MongoDB::Connection';

=head1 NAME

MongoDBX::Class::Connection - A connection to a MongoDB server

=cut

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'doc_classes' => (is => 'ro', isa => 'HashRef', required => 1);

has 'safe' => (is => 'rw', isa => 'Bool', default => 0);

override 'get_database' => sub {
	MongoDBX::Class::Database->new(_connection => shift, name => shift);
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
	);

	foreach ($dc->meta->get_all_attributes) {
		# is this a MongoDBX::Class::Reference?
		if ($_->{isa} eq 'MongoDBX::Class::Reference') {
			my $name = $_->name;
			$name =~ s!^_!!;
			
			next unless exists $doc->{$name} &&
				    ref $doc->{$name} eq 'HASH' &&
				    exists $doc->{$name}->{'$ref'} &&
				    exists $doc->{$name}->{'$id'};

			$attrs{$_->name} = MongoDBX::Class::Reference->new(
				_collection => $coll,
				ref_coll => $doc->{$name}->{'$ref'},
				ref_id => $doc->{$name}->{'$id'},
			);
		} elsif ($_->{isa} eq 'ArrayRef[MongoDBX::Class::Reference]') {
			my $name = $_->name;
			$name =~ s!^_!!;

			next unless exists $doc->{$name} &&
				    ref $doc->{$name} eq 'ARRAY';

			foreach my $ref (@{$doc->{$name}}) {
				push(@{$attrs{$_->name}}, MongoDBX::Class::Reference->new(
					_collection => $coll,
					ref_coll => $ref->{'$ref'},
					ref_id => $ref->{'$id'},
				));
			}				
		} elsif ($_->documentation && $_->documentation eq 'MongoDBX::Class::EmbeddedDocument') {
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

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class::Connection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBX::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBX::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBX::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBX::Class/>

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
