#!/usr/bin/perl


# MACOUI v1.1
# Created by John Tassano
# john.tassano@centurylink.com
# Wireshark vendor/manufacture database 2015
# process list of mac addresses 
# Search by name or macaddress. 

use strict;
use warnings;
use Data::Dumper;

# Print header
my $VERSION = '1.1';
my $limit = 30;
my $logfile = "MACOUI.txt";

print "\n  MAC address OUI lookup tool v$VERSION\n";

print "T " .  @ARGV;

# Check arguments
if(	@ARGV > 1){
	if ( $ARGV[1] eq "-a" ) {
		$limit = 99999999;
		print "-a used showing all entrys\n";
		chomp($ARGV[0]);
	}
	else
	{
		print "  Too Many Arguments\n";
		print "  Usage: $0 [MACADDRESS]\n";
		print "  Syntax: macaddress [MACADDRESS]\n\n";
		exit;
	}
}
elsif ( @ARGV == 0)
{
	my($input) = &promptUser("  Enter company name, macaddress, or txt file ");
	$ARGV[0] = $input;
	chomp($ARGV[0]);
}
else{
	chomp($ARGV[0]);
}  


if ( $ARGV[0] =~ /^(.+\.txt)$/i)
{
	my $file = $1;
	#print "This is a text file\n";
	ProcessFile($file);
}
else{
	ProcessMacAddress($ARGV[0]);
}

sub ProcessFile
{
	my $file = shift;
	open my $ouifile, $file or die "Could not find file $file: $!";

	while( my $line = <$ouifile>)  {
		if ( $line !~ m/^#.+$/i)
		{
			ProcessMacAddress($line);
		}
	}
	
	close $ouifile;
}


sub ProcessMacAddress
{
	my $input = shift;
	my $OUI;
	my $match = 0;
	my $mcount = 0;
	my $searchtype = 0;
	my @info = ();
	my $hash_ref = {};
	
	# Removing seperators from MAC address and uppercase chars
	$input =~ s/[:|\s|-]//g;
	$input =~ y/a-z/A-Z/;

	# Get OUI from MAC
	# first three octets of a MAC address.
	if ($input =~ /^([0-9a-f]{6})/i) {
	  $OUI = $1;
	  print "  Checking OUI: ".$OUI."\n";
	} else {
	
	$OUI = $input;
	  #&error($input);
	  #return;
	}


	
	my $file = 'OUI.txt';
	open my $ouifile, $file or die "Could not open $file: $!";

	while( my $line = <$ouifile>)  {
		if ( $line !~ m/^#.+$/i)
		{
			if ( $line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i ||
			$line =~ m/^([0-9a-f]{6})\s(.+)$/i)
			{
				my $checkoui = $1; my $company = $2; my $companydetail = $3;
				$company =~ s/\s//g; my $reg = $company; quotemeta $reg;
				#$reg = qr/$company/; #$reg = /\Q$company\E/i;
				#print "$checkoui . $company . $companydetail . $OUI\n"; 
				if ($OUI eq $checkoui) {
					$companydetail = $company if (!$companydetail); 
					print "  Found OUI: ".$OUI." - ".$companydetail."\n\n";
					$match = 1;
					$mcount++;
				}
				elsif ( $OUI =~ m/\Q$reg/i )
				{
					#print "  Found Company: ".$company." $checkoui \n\n";
					$match = 1;
					$mcount++;
					#push @OUIArray, $company;
					#push @infohash, \%reg;
					#push @info, { 'oui' => $checkoui, 'company' => $company, 'companydetail' => $companydetail};
					my %hash;
					$hash{'oui'} = $checkoui;
					$hash{'company'} = $company;
					$hash{'companydetail'} = $companydetail;
					push (@info, \%hash);
				}
			}
			#Well-known addresses.
			#01-80-C2-00-00-45	TRILL-End-Stations
			else 
			{
				#if ( $line eq m/^$OUI/i) {
				#$line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i;
				#	print $line."\n";
				#$line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i
			}
				
		}
	}
	close $ouifile;
	
	
	if (@info) 
	{
		my $mutiple = 0;
		my $ouistring; 
		my $companystring;
		foreach my $hash_ref (@info) {
			foreach (keys %{$hash_ref}) {
				$mutiple++;
				#Limt amount of entrys appended to ouistring and companystring
				if ( $mutiple < $limit) {
					$ouistring = $ouistring . " " . $hash_ref->{'oui'};
					my $string = $hash_ref->{'company'};
					if ( $hash_ref->{'companydetail'} )
					{
						$string = $hash_ref->{'companydetail'};
					}
					$companystring = $companystring . " " . $string;
				}
			}
		}
		
		#print "OUIS $ouistring\n"; 
		print "$mutiple matches found for $OUI\n";
		print "Only Showing Fist $limit OUI found for $OUI: $ouistring\n";
		
	}
	
	# Show if OUI was not found
	
	print "  Could not find OUI: ".$OUI."\n\n" if ($match == 0 );
}


sub promptUser 
{
	our $promptString;
	local($promptString) = @_;
	print $promptString, ": ";
	$| = 1;               # force a flush after our print
	$_ = <STDIN>;         # get the input from STDIN (presumably the keyboard)
	chomp;
	return $_;
}

# Error messages
sub syntax
{
  print "  Usage: macaddress <maccaddress>.\n".
        "    Usage: perl OUI_lookup.pl <MAC/OUI>\n".
        "    MAC Format:\n".
        "       001122334455\n".
        "       00:11:22:33:44:55\n".
        "       00-11-22-33-44-55\n".
        "    OUI Format:\n".
        "       001122\n".
        "       00:11:22\n".
        "       00-11-22\n\n";
  exit;
}

sub error 
{
	my $input = shift;
  print "  Error: No MAC address or OUI specified or invalid for $input.\n".
        "    Usage: perl OUI_lookup.pl <MAC/OUI>\n".
        "    MAC Format:\n".
        "       001122334455\n".
        "       00:11:22:33:44:55\n".
        "       00-11-22-33-44-55\n".
        "    OUI Format:\n".
        "       001122\n".
        "       00:11:22\n".
        "       00-11-22\n\n";
}


1;
exit 0;