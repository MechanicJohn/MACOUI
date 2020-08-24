#!/usr/bin/perl

# MACOUI v1.3
# Created by John Tassano
# john.tassano@centurylink.com
# Wireshark vendor/manufacture database 2015
# process list of mac addresses 
# Search by name or macaddress.

# Wireshark Database https://code.wireshark.org/review/gitweb?p=wireshark.git;a=blob_plain;f=manuf

use strict;
use warnings;
use Data::Dumper;
use Win32::Clipboard;
use Net::MAC::Vendor;
use List::MoreUtils qw(uniq);
use Data::Dumper qw(Dumper);

# Print header
my $VERSION = '1.3';
my $limit = 100;
my $logfile = "MACOUI.txt";
my $clip = Win32::Clipboard::GetText();
my $match_count = 0;
my $input = "";
print "\n MAC address OUI lookup tool v$VERSION\n";

# Check arguments
if ( @ARGV == 0)
{
	$input = &promptUser(" Enter company name, macaddress, or txt file ");
	$ARGV[0] = $input;
	if ( !$input ) 
	{
		print " No Input";
		print " Syntax: macaddress [OUI|MACADDRESS|COMPANY|FILE]\n\n";
		exit 1;
	}
	chomp($ARGV[0]);
}
elsif(	@ARGV > 1)
{
	if ( $ARGV[1] eq "-a" ) {
		$limit = 999999999;
		print " -a switch used showing all entrys\n";
		chomp($ARGV[0]);
	}
	else
	{
		print " Too Many Arguments\n";
		print " Syntax: macaddress [OUI|MACADDRESS|COMPANY|FILE]\n\n";
		exit 1;
	}
}
else{
	chomp($ARGV[0]);
}  


if ( $ARGV[0] =~ /^(.+\.txt)$/i)
{
	my $file = $1;
	ProcessFile($file);
}
else
{
	ProcessMacAddress($ARGV[0]);
}

sub ProcessFile
{
	my $file = shift;
	open my $ouifile, $file or die "Could not find file $file: $!";

	while( my $line = <$ouifile>)  
	{
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
	my $searchtype = 0;
	my @oui_hash = ();
	$match_count = 0;
	
	# Removing seperators from MAC address then uppercase chars
	my $orgin_input = $input;
	$input =~ s/[\.:|\s|-]//g; #normalize mac input
	$input =~ y/a-z/A-Z/; # upper case chars

	# Get OUI from MAC
	# first three octets of a MAC address.
	if ($input =~ /^([0-9a-f]{6})/i) {
	  $OUI = $1;
	  print " Checking OUI: ".$OUI."\n";
	} 
	else 
	{
		#get original input if its not a mac address
		$OUI = $orgin_input;
	}

	my $file = 'OUI.db';
	open(my $ouifile, '<', $file) or die " Could not find Wireshark OUI Database File $file\n";
	while( my $line = <$ouifile>)  
	{
		if ( $line !~ m/^#.+$/i) # Omit lines starting with #
		{
			#if ( $line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i || $line =~ m/^([0-9a-f]{6})\s(.+)$/i) # Separate data Match 2015 database
			if ( $line =~ m/^(.+)\t(.+)\t(.+)$/ || $line =~  m/^(.+)\t(.+)$/ ) # Separate wireshark data with tabs 2018 database 
			{
				my $oui_string = $1; my $company = $2; my $companydetail = $3;
				$oui_string =~ s/[\.:|\s|-]//g; #normalize mac input
				$oui_string = $1 if ($oui_string =~ /^([0-9a-f]{6})/i); # Convert to OUI first 3 mac octets 
				#$company =~ s/\s//g; # remove spaces
				$companydetail = $company if (!$companydetail); 
				if ($OUI eq $oui_string) 
				{
					print " Found OUI: ".$OUI." - ".$companydetail."\n\n";
					$match_count++;
				}
				elsif ( $company =~ m/\Q$orgin_input/i || $companydetail =~ m/\Q$orgin_input/i)
				{
					$match_count++;
					# Create array of hashes for all our results so we can loop through them later.
					my %hash;
					$hash{'oui'} = $oui_string;
					$hash{'company'} = $company;
					$hash{'companydetail'} = $companydetail;
					$companydetail = $company if (!$companydetail); 
					push (@oui_hash, \%hash);
				}
			}	
		}
	}
	close $ouifile;
	
	if (scalar(@oui_hash) > 0)
	{
		my $mutiple = 0;
		my $ouistring = ""; 
		my $company = "";
		my $companystring = "";
		my @companys = ();
		my @OUIs = ();
		foreach my $hash_ref (@oui_hash) 
		{
			foreach (keys %{$hash_ref}) 
			{
				$mutiple++;
				#Limt amount of entrys appended to ouistring
				if ( $mutiple < $limit) {
					# Add all oui results to a single string.
					#$ouistring = $ouistring ." ". $hash_ref->{'oui'} .',';
					push (@OUIs, $hash_ref->{'oui'});
					$company = $hash_ref->{'company'};
					if ( $hash_ref->{'companydetail'} ) {
						$company = $hash_ref->{'companydetail'};
					}
					#$companystring = $companystring . ", " . $company;
					#push companys to array so we can sort them and remove duplicates 
					push (@companys, $company);
				}
			}
		}
		
		#print ( Dumper \@companys );
		
		my @unique_companys = uniq @companys;
		my $first = 1;
		foreach my $cc (@unique_companys)
		{
			if ( $first ) {
				$companystring = $cc;
				$first = 0;
			}
			else {
				$companystring = $companystring . " | " . $cc;
			}
			
			$companystring = $companystring . "\n" if ( length($companystring) > 50 );
		}
		
		my @unique_OUIs = uniq @OUIs;
		$first = 1;
		my $last_length = 0;
		foreach my $cc (@unique_OUIs)
		{
			if ( $first ) {
				$ouistring = ' ' . $cc;
				$first = 0;
			}
			else {
				$ouistring = $ouistring . " " . $cc;
			}
			
			if ( (length($ouistring) - $last_length ) > 70 )
			{
				$ouistring = $ouistring . " \n";
				$last_length = length($ouistring); 
			}
		}
		
		#$ouistring = $ouistring ." ". $hash_ref->{'oui'} .',';
		
		print " $mutiple matches found for $OUI\n";
		print " $companystring\n";
		if ( !$ARGV[1] && $mutiple > 100 )
		{
			print " Only Showing Fist $limit OUI found for $OUI " . "\n" . "$ouistring\n";
		}
		else
		{
			print "$ouistring\n";
		}
	}
	
	# Show if OUI was not found
	print " Could not find OUI matching ".$OUI."\n\n" if ($match_count == 0 );
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
        "    Usage: perl MACOUI.pl <MAC/OUI>\n".
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
        "    Usage: perl MACOUI.pl <MAC/OUI>\n".
        "    MAC Format:\n".
        "       001122334455\n".
        "       00:11:22:33:44:55\n".
        "       00-11-22-33-44-55\n".
        "    OUI Format:\n".
        "       001122\n".
        "       00:11:22\n".
        "       00-11-22\n\n";
}

exit 1;