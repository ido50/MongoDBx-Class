package MongoDBX::Class::Database;

# ABSTRACT: A MongoDBX::Class database object

use Moose;
use namespace::autoclean;

extends 'MongoDB::Database';

=head1 NAME

MongoDBX::Class::Database - A MongoDBX::Class database object

=cut

override 'get_collection' => sub {
	MongoDBX::Class::Collection->new(_database => shift, name => shift);
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-MongoDBX::Class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX::Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class::Database

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
