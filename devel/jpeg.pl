#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use GD;

# uncomment this to run the ### lines
use Devel::Comments;


{
  my $gd = GD::Image->new(1,1) || die;
  my $white = $gd->colorAllocate(255,255,255);
  my $black = $gd->colorAllocate(0,0,0);
  $gd->rectangle(0,0,1,1,$white);
  $gd->rectangle(1,0,1,1,$black);
  ### bytes: $gd->gif
  open my $fh, '>', 't/GD-gif.gif' or die;
  print $fh $gd->gif or die;
  close $fh or die;
  exit 0;
}
{
  my $gd = GD::Image->new(1,1) || die;
  my $white = $gd->colorAllocate(255,255,255);
  $gd->rectangle(0,0,1,1,$white);
  ### bytes: $gd->jpeg
  open my $fh, '>', 't/GD-jpeg.jpg' or die;
  print $fh $gd->jpeg or die;
  close $fh or die;
  exit 0;
}
{
  require Gtk2;
  my $pixbuf = Gtk2::Gdk::Pixbuf->new('rgb',0,8,1,1);
  $pixbuf->save('/dev/stdout','jpeg');
  exit 0;
}

