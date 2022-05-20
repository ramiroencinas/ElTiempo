unit module GetURL;

sub get-url ($url) is export {

    grammar URL {

        token TOP              { <protocol> <host> <resource-path>? }
        token protocol         { 'https://' }
        token host             { <[ a..z 0..9 _ . - ]> ** 5..40 }
        token resource-path    { '/' <[ a..z 0..9 / ? = & _ . - ]> ** 1..255 }
    }

    unless my $m = URL.parse($url) { return 'Bad URL'; }

    my $remote-port  = 443;
    my $http-version = 'HTTP/1.0';

    use IO::Socket::Async::SSL;
    my $conn = await IO::Socket::Async::SSL.connect($m.<host>, $remote-port);
    $conn.print: "GET $m.<resource-path> $http-version\r\nHost: $m.<host>\r\n\r\n";

    my $result = '';

    react {
        whenever $conn -> $buffer {
            $result ~= $buffer;
        }
    }

    $conn.close;

    return $result;
}