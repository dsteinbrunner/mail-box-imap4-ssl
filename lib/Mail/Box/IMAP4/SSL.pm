package Mail::Box::IMAP4::SSL;
use 5.006;
use strict;
use warnings;
use IO::Socket::SSL;

use base 'Mail::Box::IMAP4';
use Mail::Transport::IMAP4;

our $VERSION = '0.01'; 

my $imaps_port = 993; # standard port for IMAP over SSL

#--------------------------------------------------------------------------#
# init
# 
# for errors before we do the normal superclass init, we need to do an 
# emergency init to bootstrap enough initialization for reporting
#--------------------------------------------------------------------------#

sub init {
    my ($self, $args) = @_;

    # if no port is provided, use the default
    $args->{server_port} ||= $imaps_port;

    # giving us a transport argument is an error since our only purpose
    # is to create the right kind of transport object
    if ( $args->{transport} ) {
        $self->Mail::Box::Net::init( { %$args, transport => {}, folder => '/' } );
        $self->log(ERROR => 
            "The 'transport' option is not valid for " . __PACKAGE__
        );
        return;
    }

    # some arguments are required to connect to a server
    for my $req ( qw/ server_name username password/ ) {
        if ( not defined $args->{$req} ) {
            $self->init( { %$args, transport => {}, folder => '/' } );
            $self->log(ERROR =>  
                "The '$req' option is required for " . __PACKAGE__ 
            );
            return;
        }
    }

    # trying to create the transport object

    my $ssl_socket = IO::Socket::SSL->new(  
        Proto    => 'tcp',
        PeerAddr => $args->{server_name},
        PeerPort => $args->{server_port},   
    );
    
    unless ( $ssl_socket ) {
        $self->log(ERROR => 
            "Couldn't connect to '@{[$args->{server_name}]}': " 
            . IO::Socket::SSL::errstr()
        );
        return;
    }

    my $imap = Mail::IMAPClient->new( 
        User     => $args->{username},
        Password => $args->{password},
        Socket   => $args->{server_port},
        Uid      => 1,              # Mail::Transport::IMAP4 does this
        Peek     => 1,              # Mail::Transport::IMAP4 does this
    );
        
    unless ( $imap && $imap->IsAuthenticated ) {
        $self->log( ERROR => 
            "Login rejected for user '@{[$args->{username}]}'"
            . " on server '@{[$args->{server_name}]}'."
        );
        return;
    }

    $args->{transport} = Mail::Transport::IMAP4->new(
        imap_client => $imap,
    );
        
    unless ( $args->{transport} ) {
        $self->log( ERROR => 
            "Error creating Mail::Box::Transport from the SSL connection."
        );
        return;
    }
    
    # now that we have a valid transport argument, let the superclass take over
    return $self->SUPER::init($args); 
}

1; #modules must return true

__END__

#--------------------------------------------------------------------------#
# pod documentation 
#--------------------------------------------------------------------------#

=begin wikidoc

= NAME

Mail::Box::IMAP4::SSL - handle IMAP4 folders over SSL

= VERSION

This documentation describes version %%VERSION%%.

= INHERITANCE

    Mail::Box::IMAP4::SSL
      is a Mail::Box::IMAP4
      is a Mail::Box::Net
      is a Mail::Box
      is a Mail::Reporter

= SYNOPSIS

    use Mail::Box::IMAP4::SSL;
    my $folder = new Mail::Box::IMAP4::SSL(
        username => 'johndoe',
        password => 'x_marks_the_spot',
        server_name => 'imap.example.com',
    );
        
= DESCRIPTION

This is a thin subclass of [Mail::Box::IMAP4] to provide IMAP over SSL (aka
IMAPS).  It hides the complexity of setting up Mail::Box::IMAP4 with
[IO::Socket::SSL], [Mail::IMAPClient] and [Mail::Transport::IMAP4].

In all other respects, it resembles [Mail::Box::IMAP4].  See that module
for documentation.

= METHODS


== {Mail::Box::IMAP4::SSL->new( %options )}

    my $folder = new Mail::Box::IMAP4::SSL(
        username => 'johndoe',
        password => 'x_marks_the_spot',
        server_name => 'imap.example.com',
        %other_options
    );

The {username}, {password} and {server_name} options arguments are required.
See [Mail::Box::IMAP4] for additional options.

Note: It is an error to provide a {transport} options, as this class exists
only to create an SSL-secured {transport} for {Mail::Box::IMAP4}.


= BUGS

Please report any bugs or feature requests using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
[http://rt.cpan.org/Dist/Display.html?Queue=Mail::Box::IMAP4::SSL]

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

Please limit your bug/feature reports to SSL-specific issues.  All other
issues should be directed to the maintainer of {Mail::Box::IMAP4}.

= SEE ALSO

* [Mail::Box]
* [Mail::Box::IMAP4]

= AUTHOR

David A. Golden (DAGOLDEN)

= COPYRIGHT AND LICENSE

Copyright (c) 2007 by David A. Golden

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 
[http://www.apache.org/licenses/LICENSE-2.0]

Files produced as output though the use of this software, shall not be
considered Derivative Works, but shall be considered the original work of the
Licensor.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end wikidoc

=cut