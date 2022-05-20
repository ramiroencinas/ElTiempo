use lib 'lib';
use GetURL;

my $url = 'https://open-meteo.com/en/docs';
my $url-content = get-url($url);

grammar OPTION-CITIES {

    token TOP {
        <option-open> <latitude> <longitude> <data-asl> <city> <option-close>
    }
    token option-open {
        \s* ['<option ' | '<option selected ']
    }
    token latitude       { <latitude-name> <latitude-value> }
    token latitude-name  { 'data-latitude="' }
    token latitude-value { <number> }
    token number {
        \-?\d+ [\. \d+]?
    }
    token longitude       { <longitude-name> <longitude-value> }
    token longitude-name  { '" data-longitude="' }
    token longitude-value { <number> }
    token data-asl {
        '" data-asl="'<number>'">'
    }
    token city { <[ a..z A..Z \s ]> ** 3..40 }
    token option-close { '</option>' }
}

my %cities-lat-lon = gather for $url-content.lines -> $line {

    next unless my $match = OPTION-CITIES.parse($line);

    take $match.<city> => {
        'latitude'  => $match.<latitude><latitude-value>,
        'longitude' => $match.<longitude><longitude-value>
    }
}

my $menu        = "\n";
my $menu-cols   = 4;
my $last-col    = $menu-cols;
my $city-number = 1;

my %cities-lat-lon-sorted = gather for %cities-lat-lon.sort(*.key)>>.kv -> ($city, $data) {

    take $city-number => {
        'city'      => $city,
        'latitude'  => $data.<latitude>,
        'longitude' => $data.<longitude>
    }

    $menu ~= sprintf "%2s %-17s", $city-number, $city;

    if $city-number == $last-col {
        $menu ~= "\n";
        $last-col += $menu-cols;
    }

    $city-number++;
}

shell 'clear';
$menu.say;

my $prompt-message = "\nEnter city number to show the current temperature. Another number = exit: ";
my $op = prompt $prompt-message;

# menu loop
while $op >= 1 and $op <= %cities-lat-lon-sorted.elems {

    my $city      = %cities-lat-lon-sorted{$op}<city>;
    my $latitude  = %cities-lat-lon-sorted{$op}<latitude>;
    my $longitude = %cities-lat-lon-sorted{$op}<longitude>;

    my $url-temperature = "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true";

    my $temperature = get-url($url-temperature) ~~ /\"temperature\"\:<( \-? \d+ [\. \d+]? )>/;

    shell 'clear';
    "$menu\n".say;

    "       City: $op $city".say;
    "Temperature: $temperature °C".say;

    $op = prompt $prompt-message;
}