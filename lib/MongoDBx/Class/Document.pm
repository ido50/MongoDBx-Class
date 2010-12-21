package MongoDBx::Class::Document;

# ABSTRACT: A MongoDBx::Class document role

use Moose::Role;
use namespace::autoclean;

=head1 NAME

MongoDBx::Class::Document - A MongoDBx::Class document role

=cut

has '_id' => (is => 'ro', isa => 'MongoDB::OID', required => 1);

has '_collection' => (is => 'ro', isa => 'MongoDBx::Class::Collection', required => 1);

sub id {
	shift->_id->to_string;
}

sub oid {
	shift->id;
}

sub update {
	my $self = shift;

	if (scalar @_) {
		$self->_collection->update({ _id => $self->_id }, { '$set' => $_[0] }, $_[1]);
	} else {
		my $new_doc;
		foreach (ref($self)->meta->get_all_attributes) {
			my $name = $_->name;
			next if $name eq '_collection';
			$new_doc->{$name} = $self->$name;
		}
		$self->_collection->update({ _id => $self->_id }, $new_doc, $_[1]);
	}
}

sub delete {
	my $self = shift;

	$self->_collection->remove({ _id => $self->_id });
}

sub remove {
	shift->delete;
}

sub _database {
	shift->_collection->_database;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Document

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

1;
