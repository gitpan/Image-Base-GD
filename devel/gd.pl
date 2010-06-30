#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;

use Smart::Comments;

{
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (100,100, 1);

#   my $index1 = $gd->colorAllocate(1,2,3);
#   print "$index1\n";

  my $index_t = $gd->colorAllocateAlpha(1,2,3, 1);
  printf "index_t %X\n", $index_t;

  my $index2 = $gd->colorAllocate(0xFF,0xAA,0xAA);
  printf "index2  %X\n", $index2;

  $gd->alphaBlending(0);
  $gd->setPixel (20, 20, $index2);
  $gd->setPixel (20, 20, $index_t);
  my $got = $gd->getPixel(20, 20);
  printf "got %X\n", $got;
  exit 0;
}

{
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (100,100);
  foreach my $i (1 .. 259) {
    print $gd->colorAllocate(0,0,0),"\n";
  }
  exit 0;
}
{
  require Image::Base::GD;
  my $gd = Image::Base::GD->new (-width => 10, -height => 10);
  $gd->rectangle (0,0, 9,9, 'black');
  $gd->rectangle (3,3, 7,7, 'white');

#   my $newgd = $gd->new_from_image($newgd);
#   $pixmap->save ('/tmp/x.xpm');
#   print keys %$pixmap;

  exit 0;
}

{
  require Image::Base::GD;
  require Image::Xpm;
  my $gd = Image::Base::GD->new (-width => 10, -height => 10);
  $gd->rectangle (0,0, 9,9, 'black');
  $gd->rectangle (3,3, 7,7, 'white');

  my $pixmap = $gd->new_from_image('Image::Xpm');
  $pixmap->save ('/tmp/x.xpm');
  print keys %$pixmap;

  exit 0;
}


{
  require GD;
  # print gdTransparent();
  print GD::gdTransparent();
  exit 0;
}

