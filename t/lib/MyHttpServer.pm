package MyHTTPServer;
use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use Path::Class qw/file/;
use base qw(HTTP::Server::Simple::CGI);
use File::Type;

my $document_root = "$FindBin::Bin";

my %dispatch = ();

sub handle_request {
   my $self = shift;
   my $cgi  = shift;

   my $path = $cgi->path_info();
   my $handler = $dispatch{$path};
   my $file = file($document_root,$path);

   if (ref($handler) eq "CODE") {
       print "HTTP/1.0 200 OK\r\n";
       $handler->($path);
   } elsif ( -f $file->stringify ) {
       print "HTTP/1.0 200 OK\r\n";
       file_handler($file);
   } else {
       print "HTTP/1.0 404 Not found\r\n";
       print $cgi->header,
             $cgi->start_html('Not found'),
             $cgi->h1('Not found'),
             $cgi->end_html;
   }
}

sub file_handler {
  my $f   = shift;

  my $fc  = $f->slurp();
  my $l   = length($fc);
  my $ct  = File::Type->new()->checktype_filename($f);

  print "Content-Type: $ct\r\n";
  print "Content-Length: $l\r\n\r\n";
  print $fc;

}

1;
