use MooseX::Declare;

class Llama::Exception::Trace {

    use Llama::Exception::Trace::DebugItem;

#   use Llama::Exception::Trace::Item;
#   has debug => (
#       isa => Bool,
#       default => 0,
#   );

    has skip_levels => (
	isa => 'Int',
	is => 'ro',
	default => 0,
    );
    
    has items => (
        isa => 'ArrayRef',
        is => 'rw',
        builder => '_build_trace',
    );
    
    
    method _build_trace {
        my @trace_items;
        my @item_names = qw(
            package filename line subroutine hasargs wantarray
            evaltext is_require hints bitmask hinthash
        );
        {
	    
	    use List::MoreUtils 'zip';
	    
	    my $caller_hash = sub {
		my ($level) = @_;
		my @c = caller($level);
		return unless @c;
		# return a hash of caller items
                return zip(@item_names,@c);
	    };

	    my $get_extra_info = sub {

		package DB;
		
		use PadWalker qw(peek_my peek_our);
		use List::MoreUtils 'zip';
		my ($level) = @_;
		#
		my %c = $caller_hash->($level);
		return unless %c;
		return (
		    %c,
                    args => [@DB::args],
                    my_vars => peek_my($level),
                    our_vars => peek_our($level),
                );
	    };

	    #Our loop variable, shared across 3 loops
	    my $level = 1;

	    #Cast out things inside of this tree
	    for ( ; my %next = $caller_hash->($level) ; $level++) {
		next if
		    $next{subroutine} =~ /^Llama::Exception/ ||
		    $next{package} =~ /^Llama::Exception/;
		last;
	    }

	    #Cast out any 'skip' levels
	    for (my $skip = ($self->skip_levels) ; $skip ; $skip--) {
	    }

	    #The main loop, keep travelling up the call stack
	    for ( ; my %items = $get_extra_info->($level) ; $level++ ) {
		push @trace_items, (
		    Llama::Exception::Trace::DebugItem->new(%items)
		);
	    }

        }
	#Phew, we made it
        [@trace_items];
    }
}
__END__
