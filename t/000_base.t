#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Cwd;
use Path::Class qw/dir/;
use Test::More tests => 6;

BEGIN {
  unshift @::INC, "$FindBin::Bin/lib";
};

use MyHttpServer;

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
  $pid = MyHTTPServer->new(8080)->background();
}

# Checking command
my $cmd="../download_files --outdir ".$outdir->stringify." --recompress yes";
my $out=`$cmd`;
ok($? == 0,"Checking download with recompression");
ok((-f $outdir->stringify."/Test-Simple-1.001014.tar.bz2"), "Checking downloaded file exists"); 

# Checking file content
my $tar = "tar tf ".$outdir->stringify."/Test-Simple-1.001014.tar.bz2";
`$tar`;
ok($? == 0,"Checking extraction $tar");
ok((-f $outdir->stringify."/patch1.diff"),"Checking patch1");
ok((-f $outdir->stringify."/patch2.diff"),"Checking patch2");

# checking cleanup
my @fl = $outdir->children();
ok(@fl == 3,"Checking cleanup");

# cleanup
$outdir->rmtree;
kill 15, $pid;
waitpid $pid, 0;
chdir $dir;

exit 0;
