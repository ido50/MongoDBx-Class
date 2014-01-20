package MongoDBx::Class::EmbeddedDocument;

# ABSTRACT: A MongoDBx::Class embedded (sub-)document role

our $VERSION = "1.040000";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;

with 'MongoDBx::Class::DocumentBase';

=head1 NAME

MongoDBx::Class::EmbeddedDocument - A MongoDBx::Class embedded (sub-)document role

=head1 SYNOPSIS

	# create an embedded document class
	package MyApp::Schema::PersonName;

	use MongoDBx::Class::Moose; # use this instead of Moose
	use namespace::autoclean;
	
	with 'MongoDBx::Class::EmbeddedDocument';

	has 'first_name' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_first_name');
	
	has 'middle_name' => (is => 'ro', isa => 'Str', predicate => 'has_middle_name', writer => 'set_middle_name');

	has 'last_name' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_last_name');

	sub name {
		my $self = shift;

		my $name = $self->first_name;
		$name .= ' '.$self->middle_name.' ' if $self->has_middle_name;
		$name .= $self->last_name;

		return $name;
	}

	__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

MongoDBx::Class::EmbeddedDocument is a L<Moose role|Moose::Role> meant
to be consumed by document classes representing embedded documents. These
are documents that are entirely contained within parent MongoDB documents.

The role provides expanded embedded documents with some common attributes
and useful methods.

=head1 METHODS

The following methods are provided:

=head2 as_hashref()

Returns the embedded document as a hash reference, without the _collection
and _class attributes (if they exist).

=cut

sub as_hashref {
	my ($self, $hash) = (shift, {});

	foreach my $ha (keys %$self) {
		next if $ha eq '_collection' || $ha eq '_class';
		$hash->{$ha} = $self->{$ha};
	}

	return $hash;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::EmbeddedDocument

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

=head1 SEE ALSO

L<MongoDBx::Class::Moose>, L<MongoDBx::Class::Document>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
