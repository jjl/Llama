use MooseX::Declare;

class Llama::Exception::Trace {


#   use Llama::Exception::Trace::Item;
    use Llama::Exception::Trace::DebugItem;
    
    has items => (
        isa => 'ArrayRef',
        is => 'rw',
        builder => '_build_trace',
    );
    
#   has debug => (
#       isa => Bool,
#       default => 0,
#   );
    
    method _build_trace {
        my @trace_items;
        my @item_names = qw(
            package filename line subroutine hasargs wantarray
            evaltext is_require hints bitmask
        );
        {
            package DB;
            use List::MoreUtils qw(zip);
            for (my ($i,@c) = (1);@c=caller($i);$i++,@c) {
                my %items = (zip(@item_names,@c), args => [@DB::args]);
                next if $items{subroutine} =~ /^Llama::Exception/ or $items{package} =~ /^Llama::Exception/;
                push @trace_items, (Llama::Exception::Trace::DebugItem->new(%items));
            }
        }
        [@trace_items];
    }
}
__END__