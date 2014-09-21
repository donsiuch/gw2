#!/usr/bin/perl -w

use DBI; # DBI (The Perl Database Interface Model)
use DBD::mysql; # DBD is a Perl module that works with the DBI	to access Oracle DBs
#use Path::Class; # module for manipulation of file and directory specifications
use JSON;
use Data::Dumper; # Dumper(): dumps everything
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

sub openFileForAppend {
	my $filename = shift;
	open(my $fh, '>>', "$filename") or die "Can't open $filename";
	return $fh;
}

sub openFileForWrite {
	my $filename = shift;
	open(my $fh, '>', "$filename") or die "Can't open $filename";
	return $fh;
}

sub closeFile {
	my $fh = shift;
	close ($fh);
}

# Writes to the open file.
sub writeToFile {
	my $fh = shift;
	my $content = shift;
	print $fh $content;
}

# Get the html from a web page and store in the contentAddr variable
sub getHTML {
	my $URL = shift @_;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 (X11; Linux x86_64)'); # Prevent user-agent blocking
	my $can_accept = HTTP::Message::decodable; # Accept gzip
	my $response = $ua->get("$URL", 'Accept-Encoding' => $can_accept,); 
	return $response->decoded_content; # Store in 
}

# Returns a connection to database
sub connectToMysql {
	$host = $_[0];
	$user = $_[1];
	$pw = $_[2];
	$db = $_[3];
	return DBI->connect("dbi:mysql:$db;$host", $user, $pw);
}

# Executes query and reports errors.
# [in] $mysql
# [in] $query
sub executeQuery {
	$mysql = $_[0];
	$query = $_[1];
	my $statement = $mysql->prepare($query)
							or die "MySQL: Couldn't prepare: " . $mysql->errstr . "\n";
	$statement->execute()
			or die "MySQL: Couldn't execute: " . $statement->errstr . "\n";
	my @tuples;
   @tuples = $statement->fetchrow_array();
	#printf $tuples[3] . "\n";
	$statement->finish(); # Release statement handle
	return $tuples[3];
}

sub dumpObject {
	my $objectToDump = shift @_;	
	print Data::Dumper($objectToDump);
}

########
# MAIN #
########

# Establish connectin with database
#my $mysql = connectToMysql($host, $user, $password, $database);

my $content = getHTML("https://api.guildwars2.com/v1/items.json");

# Returns a reference to a hash
$content = decode_json($content);

# $content == a hard reference to a hash
# %$content == %{$content} == $content-> ==  dereferenced the hash reference
# @{$content}{'items'}: _{$content}{'items'} ==> deref. hash and query key
#	@{$content}{'items'} ==> deref. hash and query key then treat as an array
# ${@{$content}{'items'}}[0] == $content->{'items'}[0] == get the first index of the array
#print ${@{$content}{'items'}}[0] .

# @{$content}{'items'} == Get the reference and treat it as an array reference. 
# @{...} == Dereference the array reference and treat it as an array
@itemsArray = @{@{$content}{'items'}};

my @typesCache;
my $counter = 0;
for my $item (@itemsArray){
	$content = getHTML("https://api.guildwars2.com/v1/item_details.json?item_id=$item");
	$content = decode_json($content);
	#print Dumper($content);
	my %typesCacheHash = map {$_ => 1} @typesCache;
	if (not exists($typesCacheHash{${$content}{'type'}})){
		print "Adding to cache : " . ${$content}{'type'} . "\n";
		push (@typesCache, ${$content}{'type'});
		my $fh = openFileForAppend("output.txt");
		my $outputFormatted = Dumper($content);
		writeToFile($fh, $outputFormatted . "\n");
		closeFile($fh);
	}
	print "	Fetch $counter/" . scalar @itemsArray . "\n";
	$counter += 1;
}

