package MongoDBx::Class::Document;

# ABSTRACT: A MongoDBx::Class document role

use Moose::Role;
use namespace::autoclean;

=head1 NAME

MongoDBx::Class::Document - A MongoDBx::Class document role

=head1 SYNOPSIS

	# create a document class
	package MyApp::Schema::Novel;

	use MongoDBx::Class::Moose; # use this instead of Moose;
	use namespace::autoclean;

	with 'MongoDBx::Class::Document';

	has 'title' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_title');

	holds_one 'author' => (is => 'ro', isa => 'MyApp::Schema::PersonName', required => 1, writer => 'set_author');

	has 'year' => (is => 'ro', isa => 'Int', predicate => 'has_year', writer => 'set_year');
	
	holds_many 'tags' => (is => 'ro', isa => 'MyApp::Schema::Tag', predicate => 'has_tags');

	joins_one 'synopsis' => (is => 'ro', isa => 'Synopsis', coll => 'synopsis', ref => 'novel');

	has_many 'related_novels' => (is => 'ro', isa => 'Novel', predicate => 'has_related_novels', writer => 'set_related_novels', clearer => 'clear_related_novels');

	joins_many 'reviews' => (is => 'ro', isa => 'Review', coll => 'reviews', ref => 'novel');

	sub print_related_novels {
		my $self = shift;

		foreach my $other_novel ($self->related_novels) {
			print $other_novel->title, ', ',
			      $other_novel->year, ', ',
			      $other_novel->author->name, "\n";
		}
	}

	around 'reviews' => sub {
		my ($orig, $self) = (shift, shift);

		my $cursor = $self->$orig;
		
		return $cursor->sort([ year => -1, title => 1, 'author.last_name' => 1 ]);
	};

	__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

MongoDBx::Class::Document is a L<Moose role|Moose::Role> meant to be consumed
by document classes. It provides expanded MongoDB documents with some
common attributes, and needed methods for easy updating and deleting of
documents.

=head1 ATTRIBUTES

The following attributes are provided:

=head2 _id

The document's internal ID, represented as a L<MongoDB::OID> object. This
is a required attribute.

=head2 _collection

The L<MongoDBx::Class::Collection> object representing the MongoDB collection
in which the document is stored. This is a required attribute.

=head2 _class

A string. The name of the document class of this document. This is a required
attribute.

=cut

has '_id' => (is => 'ro', isa => 'MongoDB::OID', required => 1);

has '_collection' => (is => 'ro', isa => 'MongoDBx::Class::Collection', required => 1);

has '_class' => (is => 'ro', isa => 'Str', required => 1);

=head1 OBJECT METHODS

The following object methods are provided:

=head2 id()

=head2 oid()

Both methods are equivalent. They are convenience methods that return
the documents internal MongoDB OID in string format.

=cut

sub id {
	shift->_id->to_string;
}

sub oid {
	shift->id;
}

=head2 update( [ \%object, [ \%options ] ] )

Saves a new version of the document to the database. The behavior of this
method is dependant on the existance or non-existance of an object hash-ref:

If an object hash-ref is provided, all of its key-value pairs are collapsed,
and a C<$set> update is performed on them. For example:

	$doc->update({ author => 'Sir Arthur Conan Doyle', year => 1895 }, $options)

Will effectively result in something like this being performed:

	$coll->update({ _id => $doc->_id }, { '$set' => { author => 'Sir Arthur Conan Doyle', year => 1895 } }, $options)

If an object hash-ref isn't provided, the entire document object is collapsed
and an aggresive update is performed (i.e. an entirely new version of the
document, representing the current state of the document's attributes, is
saved to the database. For example:

	my $doc = find_one($id);

	$doc->set_author('Sir Arthur Conan Doyle');
	$doc->set_year(1895);
	$doc->update;

Will effectively result in something like this being performed:

	$coll->update({ _id => $doc->_id }, $collapsed_doc, $options)

You can pass an options hash-ref just like with the C<update()> method
of L<MongoDBx::Class::Collection>, but only if you pass an update object
also.

=cut

sub update {
	my $self = shift;

	if (scalar @_ && ref $_[0] eq 'HASH') {
		foreach (keys %{$_[0]}) {
			$_[0]->{$_} = $self->_connection->collapse($_[0]->{$_});
		}
		$self->_collection->update({ _id => $self->_id }, { '$set' => $_[0] }, $_[1]);
	} else {
		my $new_doc;
		foreach (ref($self)->meta->get_all_attributes) {
			my $name = $_->name;
			next if $name eq '_collection' || $name eq '_class';

			my $newval = $self->_connection->collapse($self->$name);

			$name =~ s/^_// if ($_->{isa} eq 'MongoDBx::Class::CoercedReference' ||
					    $_->{isa} eq 'ArrayOfMongoDBx::Class::CoercedReference' ||
					    ($_->documentation && $_->documentation eq 'MongoDBx::Class::EmbeddedDocument')
					   );

			$new_doc->{$name} = $newval;
		}
		$new_doc->{_class} = $self->_class;
		$self->_collection->update({ _id => $self->_id }, $new_doc, $_[1]);
	}
}

=head2 delete()

=head2 remove()

Both methods are equivalent. They are shortcut methods for invoking the
collection's C<remove()> method on this document only. So, umm, they remove
the document. But note that this operation does not cascade, so documents
which are considered dependant on this document (such as those that reference
it with C<belongs_to>) will not be removed too.

=cut

sub delete {
	my $self = shift;

	$self->_collection->remove({ _id => $self->_id });
}

sub remove {
	shift->delete;
}

=head2 _database()

Convenience method, shortcut for C<<$doc->_collection->_database>>.

=cut

sub _database {
	shift->_collection->_database;
}

=head2 _connection()

Convenience method, shortcut for C<<$doc->_database->_connection>>.

=cut

sub _connection {
	shift->_database->_connection;
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

=head1 SEE ALSO

L<MongoDBx::Class::Moose>, L<MongoDBx::Class::EmbeddedDocument>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
