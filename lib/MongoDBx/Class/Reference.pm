package MongoDBx::Class::Reference;

# ABSTRACT: An embedded document representing a reference to a different document (thus establishing a relationship)

use Moose;
use namespace::autoclean;

=head1 NAME

MongoDBx::Class::Reference - An embedded document representing a reference to a different document (thus establishing a relationship)

=cut

with 'MongoDBx::Class::EmbeddedDocument';

has 'ref_coll' => (is => 'rw', isa => 'Str', required => 1);

has 'ref_id' => (is => 'rw', isa => 'MongoDB::OID', required => 1);

sub load {
	my $self = shift;

	return $self->_collection->_database->get_collection($self->ref_coll)->find_one($self->ref_id);
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Reference

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
