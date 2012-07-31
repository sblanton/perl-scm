
package SCM;

BEGIN {

 use vars qw($VERSION @ISA @EXPORT );

 #-- Inherits exporter functions to export functions
 @ISA=qw(Exporter);

 @EXPORT = qw( $DL $eDL $insensitive );
 
 $VERSION = 0.0.0;

}

use strict;  #-- helps to find syntax errors

my $DL;  #-- the delimiter, or 'slash'
my $eDL; #-- the escaped version of the delimiter, useful for regexp
my $insensitive; #-- whether or not the os is case insensitive

#####################################################
# DEFINE CONSTANTS
#####################################################

if($^O =~ /os2|win/i) {
 # Win-like
 $DL  = $eDL = '\\';
 $eDL =~ s/(\W)/\\$1/g;
 $insensitive = 1;  # define insensitive
} else {
 # Assume UNIX-like
 $DL  = $eDL = '/';
 $eDL =~ s/(\W)/\\$1/g;
 $insensitive = 0;
}

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#####################################################
# PUBLIC OBJECT METHODS
#####################################################

#####################################################
# PRIVATE OBJECT METHODS
#####################################################

#####################################################
# SYNONYMS
#####################################################

1;

