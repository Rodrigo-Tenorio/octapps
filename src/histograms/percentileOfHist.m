## Copyright (C) 2010 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Returns the percentile(s) of a histogram.
## Syntax:
##   percentile = percentileOfHist(hgrm, pc, [k = 1])
## where:
##   hgrm = histogram class
##   pc   = percentile, in the range (0, 1)
##   k    = dimension to calculate percentile(s) over

function percentile = percentileOfHist(hgrm, pc, k = 1)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);
  assert(isscalar(pc) && 0 < pc && pc < 1);
  assert(isscalar(k) && 1 <= k && k <= dim);

  ## get probability densities
  prob = histProbs(hgrm, "finite");

  ## multiply by areas of all probability bins
  for i = 1:dim
    dbins = histBinGrids(hgrm, i, "finite", "width");
    prob .*= dbins;
  endfor

  ## calculate cumulative probabilities along dimension k
  siz = size(prob);
  siz(k) += 1;
  cumprob = zeros(siz);
  [subs{1:length(siz)}] = ndgrid(arrayfun(@(n) 1:n, size(prob), "UniformOutput", false){:});
  subs{k} += 1;
  cumprob(sub2ind(siz, subs{:})) = cumsum(prob, k);

  ## calculate normalisation from total probability of dimension k
  [subs{1:length(siz)}] = ndgrid(arrayfun(@(n) 1:n, siz, "UniformOutput", false){:});
  subs{k} = siz(k)*ones(siz);
  norm = cumprob(sub2ind(siz, subs{:}));

  ## normalise probabilities
  cumprob ./= norm;

  ## get lower and upper cumulative probabilities containing pc
  [subs{1:length(siz)}] = ndgrid(arrayfun(@(n) 1:n, ifelse(1:dim == k, 1, siz), "UniformOutput", false){:});
  subs{k} = subsk = sum(cumprob < pc, k);
  cumproblower = cumprob(sub2ind(siz, subs{:}));
  subs{k} += 1;
  cumprobupper = cumprob(sub2ind(siz, subs{:}));

  ## calculate percentile(s)
  [xl, dx] = histBins(hgrm, k, "finite", "lower", "width");
  xlk = reshape(xl(subsk), size(cumproblower));
  dxk = reshape(dx(subsk), size(cumproblower));
  percentile = squeeze(xlk + dxk .* (pc - cumproblower) ./ (cumprobupper - cumproblower));

endfunction
