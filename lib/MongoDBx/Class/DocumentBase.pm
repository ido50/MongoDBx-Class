package MongoDBx::Class::DocumentBase;

# ABSTRACT: A MongoDBx::Class document role

our $VERSION = "1.03";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;
use Carp;
use Scalar::Util qw/blessed/;

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

	has 'added' => (is => 'ro', isa => 'DateTime', traits => ['Parsed'], required => 1);

	has 'review_count' => (is => 'rw', isa => 'Int', traits => ['Transient'], builder => '_build_review_count');
	
	holds_many 'tags' => (is => 'ro', isa => 'MyApp::Schema::Tag', predicate => 'has_tags');

	joins_one 'synopsis' => (is => 'ro', isa => 'Synopsis', coll => 'synopsis', ref => 'novel');

	has_many 'related_novels' => (is => 'ro', isa => 'Novel', predicate => 'has_related_novels', writer => 'set_related_novels', clearer => 'clear_related_novels');

	joins_many 'reviews' => (is => 'ro', isa => 'Review', coll => 'reviews', ref => 'novel');

	sub _build_review_count { shift->reviews->count }

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

=head2 _collection

The L<MongoDBx::Class::Collection> object representing the MongoDB collection
in which the document is stored. This is a required attribute.

=head2 _class

A string. The name of the document class of this document. This is a required
attribute.

=cut

has '_collection' => (is => 'ro', isa => 'MongoDBx::Class::Collection', required => 1);

has '_class' => (is => 'ro', isa => 'Str', required => 1);

=head1 OBJECT METHODS

The following object methods are provided:

=cut

sub TO_JSON {
	my $self = shift;

	my %json = map { $_ => $self->_jsonify_val($self->$_) } $self->_attributes;

	%json = map { $_ => $json{$_} } grep { defined $json{$_} } keys %json;

	return \%json;
}

sub _jsonify_val {
	my ($self, $val) = @_;

	if (blessed $val) {
		if (blessed $val eq 'DateTime') {
			return DateTime::Format::W3CDTF->format_datetime($val);
		} else {
			return $val->TO_JSON;
		}
	} elsif (ref $val && ref $val eq 'ARRAY') {
		my @array;
		foreach my $item (@$val) {
			push(@array, $self->_jsonify_val($item));
		}
		return \@array;
	} elsif (ref $val && ref $val eq 'HASH') {
		my $hash = {};
		foreach my $key (keys %$val) {
			$hash->{$_} = $self->_jsonify_val($val->{$key});
		}
		return $hash;
	}

	return $val;
}

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 _database()

Convenience method, shortcut for C<< $doc->_collection->_database >>.

=cut

sub _database {
	shift->_collection->_database;
}

=head2 _connection()

Convenience method, shortcut for C<< $doc->_database->_connection >>.

=cut

sub _connection {
	shift->_database->_connection;
}

=head2 _attributes()

Returns a list of names of all attributes the document object has, minus
'_collection' and '_class', sorted alphabetically.

=cut

sub _attributes {
	my @names;
	foreach (shift->meta->get_all_attributes) {
		next if $_->name =~ m/^_(class|collection)$/;
		if ($_->{isa} =~ m/MongoDBx::Class::CoercedReference/ || ($_->documentation && $_->documentation eq 'MongoDBx::Class::EmbeddedDocument')) {
			my $name = $_->name;
			$name =~ s/^_//;
			push(@names, $name);
		} else {
			push(@names, $_->name);
		}
	}

	return sort @names;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::DocumentBase

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

Copyright 2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
