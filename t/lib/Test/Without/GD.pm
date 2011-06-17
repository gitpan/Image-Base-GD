#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-GD is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.


package Test::Without::GD;
use strict;
use Carp;
use Sub::Delete;
use GD;

# uncomment this to run the ### lines
#use Smart::Comments;

sub import {
  my $class = shift;
  foreach (@_) {
    if (/^-/) {
      my $method = 'without_' . substr($_,1);
      $class->can($method)
        or croak 'Unrecognised Test::Without::GD option: ',$_;
      $class->$method;      
    } else {
      croak 'Unrecognised Test::Without::GD option: ',$_;
    }
  }
}

my %replaced;

sub unimport {
  foreach my $name (keys %replaced) {
    local $^W = 0;
    *$name = delete $replaced{$name};
  }
}

sub without_jpeg {
  _without_func('GD::Image::_newFromJpeg');
  _without_func('GD::Image::newFromJpegData');
  _without_func('GD::Image::jpeg');
}
sub without_png {
  _without_func('GD::Image::_newFromPng');
  _without_func('GD::Image::newFromPngData');
  _without_func('GD::Image::png');
  if (my $coderef = GD::Image->can('png')) {
    die "Oops, GD::Image->png() still true: $coderef";
  }
}
sub without_gif {
  _without_func('GD::Image::_newFromGif');
  _without_func('GD::Image::newFromGifData');
  _without_func('GD::Image::gif');
}

sub without_gifanim {
  _change_func('GD::Image::gifanimbegin', \&_no__gifanim);
  _change_func('GD::Image::gifanimadd',   \&_no__gifanim);
  _change_func('GD::Image::gifanimend',   \&_no__gifanim);
}
sub _no__gifanim {
  die "libgd 2.0.33 or higher required for animated GIF support";
}

sub without_xpm {
  _change_func('GD::Image::newFromXpm', \&_no__newFromXpm);
}
sub _no__newFromXpm ($$) {
  $@ = "libgd was not built with xpm support\n";
  return;
}

sub _without_func {
  my ($name) = @_;
  unless ($replaced{$name}) {
    ### remove: $name
    $replaced{$name} = \&$name;
    Sub::Delete::delete_sub($name);
  }
}
sub _change_func {
  my ($name, $new_coderef) = @_;
  unless ($replaced{$name}) {
    $replaced{$name} = \&$name;
    no strict 'refs';
    local $^W = 0;
    *$name = $new_coderef;
  }
}

1;
__END__
