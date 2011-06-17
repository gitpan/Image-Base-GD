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


use FindBin;
use lib::abs "$FindBin::Bin/../..";
use GD;
use Test::Without::GD ();
Test::Without::GD->import('-png');
Test::Without::GD->import('-jpeg');
Test::Without::GD->import('-gif');

GD::Image->newFromGif('/usr/share/xulrunner-1.9.1/res/arrow.gif');
GD::Image->newFromJpeg('/usr/share/doc/imagemagick/images/background.jpg');
GD::Image->newFromPng('/usr/share/xemacs-21.4.22/etc/cbx.png');
GD::Image->newFromPngData('');
