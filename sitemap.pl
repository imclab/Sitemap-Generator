#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use URI;
use DateTime;

my $mech = WWW::Mechanize->new();
my $base_url = $ARGV[0];

my %scanned_urls = ();
my @crawl_urls = ();

my $current_url = $base_url;
$scanned_urls{$current_url} = 1;

open SITEMAP_FILE, "> sitemap.xml" or die "Could not create sitemap file\n";
print SITEMAP_FILE '<urlset>';

while ($current_url)
{
  my $response = $mech->get($current_url);

  if ($response->content_type eq 'text/html')
  {
    my $datetime = DateTime->from_epoch(epoch => time());

    if ($response->last_modified)
    {
      $datetime = DateTime->from_epoch(epoch => $response->last_modified);
    }

    my @links = $mech->links();

    for my $link (@links)
    {
      my $abs_url = URI->new_abs($link->url, $current_url)->canonical;

      if ($abs_url =~ m/$base_url/ && !exists($scanned_urls{$abs_url}))
      {
        push(@crawl_urls, $abs_url);
        $scanned_urls{$abs_url} = 1;
      }
    }

    print "$current_url\n";
    print SITEMAP_FILE '<url><loc>' . $current_url . '</loc><lastmod>' . $datetime->ymd . '</lastmod></url>' . "\n";
  }

  sleep 1;

  $current_url = pop(@crawl_urls);
}

print SITEMAP_FILE '</urlset>';
close SITEMAP_FILE;