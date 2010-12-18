package MongoDBX::Class::Moose;

# ABSTRACT: Extends Moose with common relationships for MongoDBX::Class documents

use Moose ();
use Moose::Exporter;

=head1 NAME

MongoDBX::Class::Moose - Extends Moose with common relationships for MongoDBX::Class documents

=head1 RELATIONSHIPS

=head2 belongs_to

Specifies that the document has an attribute which references another,
supposedly parent, document. The reference is in the form documented by
L<MongoDBX::Class::Reference>.

=head2 has_one

Specifies that the document has an attribute which references another
document. The reference is in the form documented by L<MongoDBX::Class::Reference>.
This is entirely equivalent to L</belongs_to>, the two are provided merely
for convenience.

=head2 has_many

Specifies that the document has an attribute which holds a list (array)
of references to other documents. These references are in the form
documented by L<MongoDBX::Class::Reference>. 

=head2 holds_one

Specifies that the document has an attribute which holds an embedded
document (a.k.a sub-document) in its entirety. The embedded document
is represented by a class that C<does> L<MongoDBX::Class::EmbeddedDocument>.

=head2 holds_many

Specifies that the document has an attribute which holds a list (array)
of embedded documents (a.k.a sub-documents) in their entirety. These
embedded documents are represented by a class that C<does>
L<MongoDBX::Class::EmbeddedDocument>.

=head2 joins_one

Specifies that the document is referenced by one other document. The reference
in the other document to this document is in the form documented by
L<MongoDBX::Class::Reference>.

=head2 joins_many

Specifies that the document is referenced by other documents. The references
in the other document to this document are in the form documented by
L<MongoDBX::Class::Reference>.

=cut

Moose::Exporter->setup_import_methods(
	with_meta => [ 'belongs_to', 'has_one', 'has_many', 'holds_one', 'holds_many', 'joins_one', 'joins_many' ],
	also      => 'Moose',
);

sub belongs_to {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = 'MongoDBX::Class::Reference';

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;
		return $self->$attr->load;
	});
}

sub has_one {
	belongs_to(@_);
}

sub has_many {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = "ArrayRef[MongoDBX::Class::Reference]";

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;

		my @docs;
		foreach (@{$self->$attr || []}) {
			push(@docs, $_->load);
		}
		return @docs;
	});
}

sub holds_one {
	my ($meta, $name, %opts) = @_;

	$opts{does} = 'MongoDBX::Class::EmbeddedDocument';

	$meta->add_attribute($name => %opts);
}

sub holds_many {
	my ($meta, $name, %opts) = @_;

	my $type = delete $opts{isa};
	$opts{isa} = "ArrayRef[$type]";
	$opts{does} = 'MongoDBX::Class::EmbeddedDocument';

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;

		return @{$self->$attr || []};
	});
}

sub joins_one {
	my ($meta, $name, %opts) = @_;

	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBX::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_method($name => sub {
		my $self = shift;

		my $coll_name = $coll eq '<same>' ? $self->_collection->name : $coll;

		return $self->_collection->_database->get_collection($coll_name)->find_one({ $ref.'.$id' => $self->_id });
	});
}

sub joins_many {
	my ($meta, $name, %opts) = @_;

	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBX::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_method($name => sub {
		my $self = shift;

		my $coll_name = $coll eq '<same>' ? $self->_collection->name : $coll;

		return $self->_collection->_database->get_collection($coll_name)->find({ $ref.'.$id' => $self->_id });
	});
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class::Moose

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

1;
