package MongoDBx::Class::Cursor;

# ABSTRACT: A MongoDBx::Class cursor/iterator object for query results

use Moose;
use namespace::autoclean;

extends 'MongoDB::Cursor';

=head1 NAME

MongoDBx::Class::Cursor - A MongoDBx::Class cursor/iterator object for query results

=cut

around 'next' => sub {
	my ($orig, $self) = (shift, shift);

	my $doc = $self->$orig || return;

	return $self->_connection->expand($self->_ns, $doc);
};

around 'sort' => sub {
	my ($orig, $self, $rules) = @_;

	if (ref $rules eq 'ARRAY') {
		return $self->$orig(Tie::IxHash->new(@$rules));
	} else {
		return $self->$orig($rules);
	}
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Cursor

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
