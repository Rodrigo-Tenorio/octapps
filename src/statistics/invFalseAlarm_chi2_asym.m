## Copyright (C) 2011 Karl Wette
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

## Calculate the threshold of a central chi^2 distribution which gives
## a certain false alarm probability. Uses an analytic, asymptotic
## inversion of the chi^2 CDF that is accurate for very small
## false alarm probabilities and very large degrees of freedom.
## Syntax:
##   sa = invFalseAlarm_chi2_asym(pa, k)
## where:
##   sa = threshold
##   pa = false alarm probability
##   k  = degrees of freedom of the chi^2 distribution

function sa = invFalseAlarm_chi2_asym(pa, k)

  ## make input and output the same size
  [err, pa, k] = common_size(pa, k);
  if err > 0
    error("%s: pa and k are not of common size", funcName);
  endif
  assert(all(pa(:) > 0) && all(k > 0));
  sa = zeros(size(pa));

  ## for large false alarm probabilities, fall back on
  ## numerical chi^2 inverse function
  ii = pa < 0.1;
  if any(!ii(:))
    sa(!ii) = invFalseAlarm_chi2(pa(!ii), k(!ii));
  endif

  ## calculate threshold
  if any(ii(:))
    eta0 = eta = zeros(size(sa));
    eta0(ii) = 2 ./ sqrt(k(ii)) .* erfcinv(2*pa(ii));
    eta(ii) = eta0(ii) + 2 ./ (k(ii) .* eta0(ii)) .* log(eta0(ii) ./ (lambdaFunction(eta0(ii)) - 1));
    sa(ii) = k(ii) .* lambdaFunction(eta(ii));
  endif

endfunction

function lambda = lambdaFunction(x)

  ## lambda1 function
  ii = (x <= 4);
  lambda1 = zeros(size(x));
  lambda1(ii) = 1 + x(ii) + x(ii).^2./3 + x(ii).^3./36 - x(ii).^4./270;

  ## lambda2 function
  jj = (2 <= x);
  lambda2 = y = zeros(size(x));
  y(jj) = 1 + x(jj).^2./2;
  lambda2(jj) = y(jj) + (1 + y(jj).^(-1) + y(jj).^(-2)) .* log(y(jj));

  ## lambda function
  lambda = g = zeros(size(x));
  lambda(!jj) = lambda1(!jj);
  lambda(!ii) = lambda2(!ii);
  kk = ii & jj;
  g(kk) = tanh(5.*(x(kk) - 3));
  lambda(kk) = 0.5.*((1 - g(kk)).*lambda1(kk) + (1 + g(kk)).*lambda2(kk));

endfunction