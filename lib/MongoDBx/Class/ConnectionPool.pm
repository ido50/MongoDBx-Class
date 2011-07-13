package MongoDBx::Class::ConnectionPool;

# ABSTARCT: A simple connection pool for MongoDBx::Class

our $VERSION = "0.9";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Time::HiRes qw/time/;
use Carp;

has 'max_conns' => (
	is => 'ro',
	isa => 'Int',
	default => 100,
);

has 'when_full' => (
	is => 'ro',
	isa => 'Str',
	default => 'wait',
);

has 'timeout' => (
	is => 'ro',
	isa => 'Int',
	default => 10,
);

has 'pool' => (
	is => 'ro',
	isa => 'ArrayRef[MongoDBx::Class::Connection]',
	writer => '_set_pool',
	default => sub { [] },
);

has 'num_used' => (
	is => 'ro',
	isa => 'Int',
	writer => '_set_used',
	default => 0,
);

has 'params' => (
	is => 'ro',
	isa => 'HashRef',
	required => 1,
);

around BUILDARGS => sub {
	my ($orig, $class, %opts) = @_;

	croak "Illegal 'when_full' option, must either be 'wait' or 'fail'."
		if %opts && exists $opts{when_full} && $opts{when_full} ne 'wait' && $opts{when_full} ne 'fail';

	return $class->$orig(%opts);
};

sub get_conn {
	my $self = shift;

	# are there available connections in the pool?
	if (scalar @{$self->pool}) {
		return $self->_take_from_pool;
	}

	# there aren't any, can we create a new connection?
	if ($self->num_used < $self->max_conns) {
		# yes we can, let's create it
		return $self->_get_new_conn;
	}

	# we can't, should we return failure?
	if ($self->when_full eq 'fail') {
		croak 'No available connections to MongoDB server.';
	} else {
		my $time = time;
		do {
			$self->_wait(1); # wait 1 second
			# check again
			if (scalar @{$self->pool}) {
				return $self->_take_from_pool;
			} elsif ($self->num_used < $self->max_conns) {
				return $self->_get_new_conn;
			}
		} while (time - $time <= $self->timeout);
		
		# timeout reached, croak
		croak 'No available connections to MongoDB server and timeout reached.';
	}
}

sub return_conn {
	my ($self, $conn) = @_;

	# only add connection if pool isn't full, otherwise discard it
	if (scalar @{$self->pool} + $self->num_used - 1 < $self->max_conns) {
		$self->_add_to_pool($conn);
		$self->_inc_used(-1);
	} else {
		undef $conn;
	}
}

sub _take_from_pool {
	my $self = shift;

	my $pool = $self->pool;
	my $conn = shift @$pool;
	$self->_set_pool($pool);
	$self->_inc_used;
	return $conn;
}

sub _get_new_conn {
	my $self = shift;

	my $conn = MongoDBx::Class::Connection->new(%{$self->params});
	$self->_inc_used;
	return $conn;
}

sub _inc_used {
	my ($self, $int) = @_;

	$int ||= 1;
	$self->_set_used($self->num_used + $int);
}

sub _add_to_pool {
	my ($self, $conn) = @_;

	my $pool = $self->pool;
	push(@$pool, $conn);
	$self->_set_pool($pool);
}

sub _wait {
	my ($self, $sec) = @_;

	my $time = time;
	while (time - $time < $sec) {
		# do squat
	}

	return;
}

__PACKAGE__->meta->make_immutable;
