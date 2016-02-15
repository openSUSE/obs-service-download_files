#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Cwd;

use Path::Class qw/dir/;
use Test::More tests => 5;

{
package MyWebServer;
use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use Path::Class qw/file/;
use base qw(HTTP::Server::Simple::CGI);
use File::Type;

my $document_root = $FindBin::Bin;

my %dispatch = (
);

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

}

my $dir     = getcwd();
my $outdir  = dir($FindBin::Bin,"tmp");

dir($outdir)->rmtree;
mkdir $outdir;
chdir $FindBin::Bin || die;

my $pid;

{
  local *STDOUT;
  my $out="";
  open(STDOUT,'>',\$out);
  $pid = MyWebServer->new(8080)->background();
}



# Checking command
my $cmd="../download_files --outdir ".$outdir->stringify." --recompress yes";
`$cmd`;
ok($? == 0,"Checking download with recompression");

# Checking file content
my $tar = "tar tvjf ".$outdir->stringify."/Test-Simple-1.001014.tar.bz2";
`$tar`;
ok($? == 0,"Checking extraction");

ok((-f $outdir->stringify."/patch1.diff"),"Checking patch1");
ok((-f $outdir->stringify."/patch2.diff"),"Checking patch2");

# checking cleanup
my @fl = $outdir->children();
ok(@fl == 3,"Checking cleanup");

# cleanup
$outdir->rmtree;
kill 15, $pid;

chdir $dir;

exit 0;
