#!/usr/bin/perl -w

use DBI; # DBI (The Perl Database Interface Model)
use DBD::mysql; # DBD is a Perl module that works with the DBI	to access Oracle DBs
#use Path::Class; # module for manipulation of file and directory specifications
use JSON;
use Data::Dumper;
use LWP::UserAgent; # HTTP client 
use Compress::Zlib; # bzip decoder (some webpages)
use autodie; # Replace functions with ones that succeed or die with lexical scope
use warnings; # Pragma to control optional warnings
use diagnostics; # More detailed warning messages

# MySQL connection information
my $host = 'localhost';
my $user ='donnie';
my $password = '';
my $database = 'gw2';

# Get the html from a web page and store in the contentAddr variable
sub getHTML {
	my $URL = shift @_;
	my $contentAddr = shift @_;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 (X11; Linux x86_64)'); # Prevent user-agent blocking
	my $can_accept = HTTP::Message::decodable; # Accept gzip
	my $response = $ua->get("$URL", 'Accept-Encoding' => $can_accept,); 
	${$contentAddr} = $response->decoded_content; # Store in 
}

# Returns a connection to database
sub connectToMysql {
	$host = $_[0];
	$user = $_[1];
	$pw = $_[2];
	$db = $_[3];
	return DBI->connect("dbi:mysql:$db;$host", $user, $password);
}

# Executes query and reports errors.
# [in] $mysql
# [in] $query
sub executeQuery {
	$mysql = $_[0];
	$query = $_[1];
	my $statement = $_[0]->prepare($_[1])
							or die "MySQL: Couldn't prepare: " . $mysql->errstr . "\n";
	$statement->execute()
			or die "MySQL: Couldn't execute: " . $statement->errstr . "\n";
	my @tuples;
   @tuples = $statement->fetchrow_array();
	#printf $tuples[3] . "\n";
	$statement->finish(); # Release statement handle
	return $tuples[3];
}

# Establish connectin with database
#my $mysql = connectToMysql($host, $user, $password, $database);

my $content = '';

getHTML("https://api.guildwars2.com/v1/items.json", \$content);

$content = decode_json($content);

print Dumper($content);
