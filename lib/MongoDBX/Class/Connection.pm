package MongoDBX::Class::Connection;

use Moose;
use namespace::autoclean;

extends 'MongoDB::Connection';

has 'doc_classes' => (is => 'ro', isa => 'HashRef', required => 1);

override 'get_database' => sub {
	MongoDBX::Class::Database->new(_connection => shift, name => shift);
};

sub expand {
	my ($self, $coll_ns, $doc) = @_;

	return unless $coll_ns && $doc && ref $doc eq 'HASH';

	my ($db_name, $coll_name) = ($coll_ns =~ m/^([^.]+)\.(.+)$/);

	my $coll = $self->get_database($db_name)->get_collection($coll_name);

	return $doc unless exists $doc->{_class} && exists $self->doc_classes->{$doc->{_class}};

	my $dc = $self->doc_classes->{$doc->{_class}};

	my %attrs = (
		_collection => $coll,
	);

	foreach ($dc->meta->get_all_attributes) {
		# is this a MongoDBX::Class::Reference?
		if ($_->{isa} eq 'MongoDBX::Class::Reference') {
			my $name = $_->name;
			$name =~ s!^_!!;
			
			next unless $doc->{$name};

			$attrs{$_->name} = MongoDBX::Class::Reference->new(
				_collection => $coll,
				ref_coll => $doc->{$name}->{'$ref'},
				ref_id => $doc->{$name}->{'$id'},
			);
		} else {
			next unless $doc->{$_->name};
			$attrs{$_->name} = $doc->{$_->name};
		}
	}

	return $dc->new(%attrs);
}

__PACKAGE__->meta->make_immutable;
