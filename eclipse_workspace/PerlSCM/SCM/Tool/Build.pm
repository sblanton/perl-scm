
package SCM::Tool::Build;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    use SCM::Tool;

    #-- Inherits exporter functions to export functions
    @ISA = qw( SCM::Tool );

    #-- You must export any new functions here:
    @EXPORT = qw(

      $DL
      $eDL
      $insensitive

    );

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors

#use Carp;    #-- helps for debugging
use Log::Log4perl qw( get_logger );
use Cwd;

my $DL;        #-- the delimiter, or 'slash'
my $eDL;       #-- the escaped version of the delimiter, useful for regexp
my $insensitive;

if ( $^O =~ /os2|win/i ) {

    # Win-like
    $DL = $eDL = '\\';
    $eDL =~ s/(\W)/\\$1/g;
    $insensitive = 1;    # define insensitive
}
else {

    # Assume UNIX-like
    $DL = $eDL = '/';
    $eDL =~ s/(\W)/\\$1/g;
    $insensitive = 0;
}

my $logger = get_logger('SCM.Tool.Build');

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#####################################################
# OBJECT METHODS
#####################################################

# Context constructor

sub new {

    my $proto = shift;

    my $class = ref($proto) || $proto;
    my $self = {};

    my $logger = get_logger('Harvest::Context');

    my %ctx = @_;    # form a context hash

    foreach ( keys %ctx ) {
        $self->{$_} = $ctx{$_};

    }

    $logger->debug("New instance created.");

    # instantiate and return the reference

    bless( $self, $class );
    return $self;

}

1;

