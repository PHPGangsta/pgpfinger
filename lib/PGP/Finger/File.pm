package PGP::Finger::File;

use Moose;

extends 'PGP::Finger::Source';

# ABSTRACT: gpgfinger source for local file input
# VERSION

use PGP::Finger::Result;
use PGP::Finger::Key;

use IO::File;
use IO::Handle;

has 'input' => ( is => 'ro', isa => 'Str', required => 1 );

has 'format' => ( is => 'ro', isa => 'Str', default => 'armored' );

has '_data' => ( is => 'ro', lazy_build => 1 );

sub _build__data {
	my $self = shift;
	my $fh;
	my $buf;
	my $data = '';

	if( $self->input eq '-' ) {
		$fh = IO::Handle->new_from_fd(fileno(STDIN),'r');
	} else {
		$fh = IO::File->new($self->input,'r');
	}
	if( ! defined $fh ) {
		die('unable to open '.$self->input.': '.$!);
	}

	while( $fh->read( $buf, 1024 ) ) {
		$data .= $buf;
	}

	$fh->close;

	return $data;
}

sub fetch {
	my ( $self, $addr ) = @_;
	my $result = PGP::Finger::Result->new;
	my $key;

	if( $self->format eq 'armored' ) {
		$key = PGP::Finger::Key->new_armored(
			mail => $addr,
			data => $self->_data,
		);
	} elsif ( $self->format eq 'binary' ) {
		$key = PGP::Finger::Key->new(
			mail => $addr,
			data => $self->_data,
		);
	} else {
		die('unknown input format: '.$self->format);
	}
	$key->set_attr( source => 'local file input' );
	$key->set_attr( input => $self->input );

	$result->add_key( $key );
	return $result;
}

1;

