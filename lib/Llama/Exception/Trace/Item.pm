use MooseX::Declare;

class Llama::Exception::Trace::Item {

    has package => (
        is => 'ro',
        required => 1,
    );
    has filename => (
        is => 'ro',
        required => 1,
    );
    has line => (
        is => 'ro',
        required => 1,
    );
    has subroutine => (
        is => 'ro',
        required => 1,
    );
}