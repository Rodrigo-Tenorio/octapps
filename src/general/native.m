## Copyright (C) 2014 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Converts its arguments from foreign objects (e.g. SWIG-wrapped objects)
## to native Octave objects, if possible. Native objects are passed though.
## Usage:
##   [x1, x2, ...] = native(x1, x2, ...)

function varargout = native(varargin)

  ## assume no conversion by default
  varargout = varargin;

  for i = 1:length(varargin)

    ## ignore non-SWIG objects
    if !strcmp(class(varargin{i}), "swig_ref")
      continue
    endif

    ## try extracting data from a 'data field'
    try
      data = varargin{i}.data;
      varargout{i} = reshape(data(:), size(data));
      continue
    end_try_catch

    ## give up
    error("%s: could not convert argument #%i", funcName, i)

  endfor

endfunction
