#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Llama' ) || print "Bail out!
";
}

diag( "Testing Llama $Llama::VERSION, Perl $], $^X" );
