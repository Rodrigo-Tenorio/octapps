## Copyright (C) 2010, 2011 Karl Wette
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

## Compute the cumulative density function of the
## non-central chi^2 distribution.
## Syntax:
##   p = ChiSquare_cdf(x, k, lambda)
## where:
##   x      = value of the non-central chi^2 variable
##   k      = number of degrees of freedom
##   lambda = non-centrality parameter

function p = ChiSquare_cdf(x, k, lambda)

  ## check for common size input
  if !exist("lambda")
    lambda = 0;
  endif
  [cserr, x, k, lambda] = common_size(x, k, lambda);
  if cserr > 0
    error("All input arguments must be either of common size or scalars");
  endif

  ## flatten input after saving sizes
  siz = size(x);
  x = x(:)';
  k = k(:)';
  lambda = lambda(:)';

  ## allocate result
  p = zeros(size(x));

  ## for zero lambda, compute the central chi^2 CDF
  ii = (lambda > 0);
  if any(!ii)
    p(!ii) = gsl_chi2cdf(x(!ii), k(!ii));
  endif

  ## otherwise compute the non-central chi^2 PDF
  if any(ii)

    ## series summation error
    err = 1e-6;

    ## half quantities
    hx = hk = hlambda = zeros(size(x));
    hx(ii) = 0.5 .* x(ii);
    hk(ii) = 0.5 .* k(ii);
    hlambda(ii) = 0.5 .* lambda(ii);

    ## starting indexes for summation
    j0 = jp = jm = zeros(size(x));
    j0(ii) = jp(ii) = jm(ii) = round(hlambda(ii));

    ## initial values of Poisson term in series sum
    Pp = Pm = zeros(size(x));
    Pp(ii) = Pm(ii) = poisspdf(j0(ii), hlambda(ii));
    
    ## initial values of chi^2 term in series sum
    Xp = Xm = zeros(size(x));
    Xp(ii) = Xm(ii) = gsl_chi2cdf(x(ii), k(ii) + 2.*j0(ii));

    ## initial values of Poisson adjustments to chi^2 terms
    XPm = XPp = zeros(size(x));
    XPp(ii) = poisspdf(hk(ii) + j0(ii), hx(ii));
    XPm(ii) = XPp(ii) .* (hk(ii) + j0(ii)) ./ hx(ii);

    ## initial series value
    p(ii) = Pp(ii) .* Xp(ii);

    ## add up series expansion of non-central chi^2 distribution
    pnew = zeros(size(p));
    do

      ## adjust positive-index Poisson term
      Pp(ii) .*= hlambda(ii) ./ ( jp(ii) + 1 );

      ## adjust positive-index chi^2 term
      Xp(ii) -= XPp(ii);

      ## adjust Poisson adjustment to positive-index chi^2 term
      XPp(ii) .*= hx(ii) ./ ( hk(ii) + jp(ii) + 1 );

      ## new series term (positive indices)
      pnew(ii) = Pp(ii) .* Xp(ii);
      jp(ii) += 1;

      ## if there are negative indices to sum
      iim = ii & jm > 0;
      if any(iim)

        ## adjust negative-index Poisson term
        Pm(iim) .*= jm(iim) ./ hlambda(iim);

        ## adjust negative-index chi^2 term
        Xm(iim) += XPm(iim);

        ## adjust Poisson adjustment to negative-index chi^2 term
        XPm(iim) .*= (hk(iim) + jm(iim) - 1) ./ hx(iim);

        ## add to new series term (negative indices)
        pnew(iim) += Pm(iim) .* Xm(iim);
        jm(iim) -= 1;

      endif

      ## add new series terms to result
      p(ii) += pnew(ii);

      ## determine which series to continue summing
      ii = ii & (abs(pnew) > err .* abs(p));

      ## continue until no series are left
    until !any(ii)

  endif

  ## reshape result to original size of input
  p = reshape(p, siz);

endfunction

## try to use first GSL to compute the central chi^2 CDF:
## it's a bit slower than the Octave function, but it
## works for large values of x,k > 2000, where the Octave
## function fails. fall back to the Octave function if
## the GSL module is unavailable.
function p = gsl_chi2cdf(x, k)
  try
    gsl_sf_gamma;
    p = gsl_sf_gamma_inc_P(k/2, x/2);
  catch
    p = chi2cdf(x, k);
  end_try_catch
endfunction

## Tests ChiSquare_cdf against values generated by Mathematica using:
##   CDF[NoncentralChiSquareDistribution[k, lambda]][x]
##   NIntegrate[PDF[NoncentralChiSquareDistribution[k, lambda]][y], {y, 0, x}]
## and a Mathematica implementation of the above algorithm,
## with x,k,lambda set to 50-precision numbers. The Mathematica-calculated
## values generally agree to < 10^-5 fractional error.

## Test value x against reference value x0
%!function __test_cdf(x, x0)
%! assert(abs(x - x0) < 1e-9 * abs(x0) | abs(x0) < 1e-140)

## Tests
%!test __test_cdf(ChiSquare_cdf(5.,4.,0.),0.7127025048163542)
%!test __test_cdf(ChiSquare_cdf(5.,4.,15.),0.015699244906430973)
%!test __test_cdf(ChiSquare_cdf(5.,4.,50.),1.0105355110594111e-7)
%!test __test_cdf(ChiSquare_cdf(5.,4.,120.),1.1864322190083836e-19)
%!test __test_cdf(ChiSquare_cdf(5.,4.,400.),2.399493834640724e-72)
%!test __test_cdf(ChiSquare_cdf(5.,10.,0.),0.10882198108584876)
%!test __test_cdf(ChiSquare_cdf(5.,10.,15.),0.0007444674329556936)
%!test __test_cdf(ChiSquare_cdf(5.,10.,50.),1.5289064311270403e-9)
%!test __test_cdf(ChiSquare_cdf(5.,10.,120.),6.362909862598009e-22)
%!test __test_cdf(ChiSquare_cdf(5.,10.,400.),2.625194772380971e-75)
%!test __test_cdf(ChiSquare_cdf(5.,20.,0.),0.00027735209462083604)
%!test __test_cdf(ChiSquare_cdf(5.,20.,15.),7.376350350905591e-7)
%!test __test_cdf(ChiSquare_cdf(5.,20.,50.),4.328674422926527e-13)
%!test __test_cdf(ChiSquare_cdf(5.,20.,120.),4.697583974727663e-26)
%!test __test_cdf(ChiSquare_cdf(5.,20.,400.),1.9504867119479666e-80)
%!test __test_cdf(ChiSquare_cdf(5.,150.,0.),2.397024434306258e-81)
%!test __test_cdf(ChiSquare_cdf(5.,150.,15.),1.695863883652722e-84)
%!test __test_cdf(ChiSquare_cdf(5.,150.,50.),7.540937655658166e-92)
%!test __test_cdf(ChiSquare_cdf(5.,150.,120.),1.4728975173762546e-106)
%!test __test_cdf(ChiSquare_cdf(5.,150.,400.),1.8481736281231183e-165)
%!test __test_cdf(ChiSquare_cdf(5.,500.,0.),7.834778480687875e-395)
%!test __test_cdf(ChiSquare_cdf(5.,500.,15.),4.669327368998337e-398)
%!test __test_cdf(ChiSquare_cdf(5.,500.,50.),1.395558559363579e-405)
%!test __test_cdf(ChiSquare_cdf(5.,500.,120.),1.246175627715284e-420)
%!test __test_cdf(ChiSquare_cdf(5.,500.,400.),7.885709963372185e-481)
%!test __test_cdf(ChiSquare_cdf(10.,4.,0.),0.9595723180054871)
%!test __test_cdf(ChiSquare_cdf(10.,4.,15.),0.12613158885805104)
%!test __test_cdf(ChiSquare_cdf(10.,4.,50.),0.000012185135531341695)
%!test __test_cdf(ChiSquare_cdf(10.,4.,120.),4.757752226564309e-16)
%!test __test_cdf(ChiSquare_cdf(10.,4.,400.),3.922278003570363e-65)
%!test __test_cdf(ChiSquare_cdf(10.,10.,0.),0.5595067149347875)
%!test __test_cdf(ChiSquare_cdf(10.,10.,15.),0.02228745971194175)
%!test __test_cdf(ChiSquare_cdf(10.,10.,50.),6.273033706842392e-7)
%!test __test_cdf(ChiSquare_cdf(10.,10.,120.),8.176344196630852e-18)
%!test __test_cdf(ChiSquare_cdf(10.,10.,400.),1.3008467424472597e-67)
%!test __test_cdf(ChiSquare_cdf(10.,20.,0.),0.03182805730620481)
%!test __test_cdf(ChiSquare_cdf(10.,20.,15.),0.0003266754196765963)
%!test __test_cdf(ChiSquare_cdf(10.,20.,50.),1.9085645385578783e-9)
%!test __test_cdf(ChiSquare_cdf(10.,20.,120.),5.294471960509474e-21)
%!test __test_cdf(ChiSquare_cdf(10.,20.,400.),6.99323575438422e-72)
%!test __test_cdf(ChiSquare_cdf(10.,150.,0.),7.694733240471517e-60)
%!test __test_cdf(ChiSquare_cdf(10.,150.,15.),6.956668946547875e-63)
%!test __test_cdf(ChiSquare_cdf(10.,150.,50.),5.43356566835553e-70)
%!test __test_cdf(ChiSquare_cdf(10.,150.,120.),3.1637181251476596e-84)
%!test __test_cdf(ChiSquare_cdf(10.,150.,400.),2.1579590973338844e-141)
%!test __test_cdf(ChiSquare_cdf(10.,500.,0.),1.175385101854905e-320)
%!test __test_cdf(ChiSquare_cdf(10.,500.,15.),7.547997660893584e-324)
%!test __test_cdf(ChiSquare_cdf(10.,500.,50.),2.684539043436523e-331)
%!test __test_cdf(ChiSquare_cdf(10.,500.,120.),3.390967204007231e-346)
%!test __test_cdf(ChiSquare_cdf(10.,500.,400.),8.472409973844811e-406)
%!test __test_cdf(ChiSquare_cdf(40.,4.,0.),0.9999999567157739)
%!test __test_cdf(ChiSquare_cdf(40.,4.,15.),0.98421692505162)
%!test __test_cdf(ChiSquare_cdf(40.,4.,50.),0.1656323325479984)
%!test __test_cdf(ChiSquare_cdf(40.,4.,120.),7.608191384654475e-7)
%!test __test_cdf(ChiSquare_cdf(40.,4.,400.),1.240217236556717e-43)
%!test __test_cdf(ChiSquare_cdf(40.,10.,0.),0.9999830552560699)
%!test __test_cdf(ChiSquare_cdf(40.,10.,15.),0.9394158853888496)
%!test __test_cdf(ChiSquare_cdf(40.,10.,50.),0.0775662772656693)
%!test __test_cdf(ChiSquare_cdf(40.,10.,120.),1.1972546615644404e-7)
%!test __test_cdf(ChiSquare_cdf(40.,10.,400.),3.57099573827949e-45)
%!test __test_cdf(ChiSquare_cdf(40.,20.,0.),0.9950045876916924)
%!test __test_cdf(ChiSquare_cdf(40.,20.,15.),0.7139045640824745)
%!test __test_cdf(ChiSquare_cdf(40.,20.,50.),0.014989144847017681)
%!test __test_cdf(ChiSquare_cdf(40.,20.,120.),4.147473013071116e-9)
%!test __test_cdf(ChiSquare_cdf(40.,20.,400.),8.249316210739692e-48)
%!test __test_cdf(ChiSquare_cdf(40.,150.,0.),4.252751341829973e-21)
%!test __test_cdf(ChiSquare_cdf(40.,150.,15.),1.6379295606637303e-23)
%!test __test_cdf(ChiSquare_cdf(40.,150.,50.),3.215969081520923e-29)
%!test __test_cdf(ChiSquare_cdf(40.,150.,120.),6.965372096189379e-41)
%!test __test_cdf(ChiSquare_cdf(40.,150.,400.),1.2393294919177327e-89)
%!test __test_cdf(ChiSquare_cdf(40.,500.,0.),1.2533481488425446e-176)
%!test __test_cdf(ChiSquare_cdf(40.,500.,15.),1.258943528670742e-179)
%!test __test_cdf(ChiSquare_cdf(40.,500.,50.),1.2652082031081847e-186)
%!test __test_cdf(ChiSquare_cdf(40.,500.,120.),1.249708755299477e-200)
%!test __test_cdf(ChiSquare_cdf(40.,500.,400.),9.03090035569765e-257)
%!test __test_cdf(ChiSquare_cdf(80.,4.,0.),0.9999999999999998)
%!test __test_cdf(ChiSquare_cdf(80.,4.,15.),0.9999989234984757)
%!test __test_cdf(ChiSquare_cdf(80.,4.,50.),0.9539641241549137)
%!test __test_cdf(ChiSquare_cdf(80.,4.,120.),0.015319281395466426)
%!test __test_cdf(ChiSquare_cdf(80.,4.,400.),3.0232379184333603e-29)
%!test __test_cdf(ChiSquare_cdf(80.,10.,0.),0.999999999999498)
%!test __test_cdf(ChiSquare_cdf(80.,10.,15.),0.999992149514936)
%!test __test_cdf(ChiSquare_cdf(80.,10.,50.),0.9045084903176945)
%!test __test_cdf(ChiSquare_cdf(80.,10.,120.),0.00685200255974378)
%!test __test_cdf(ChiSquare_cdf(80.,10.,400.),2.5169014976137993e-30)
%!test __test_cdf(ChiSquare_cdf(80.,20.,0.),0.9999999960740678)
%!test __test_cdf(ChiSquare_cdf(80.,20.,15.),0.9997798725831025)
%!test __test_cdf(ChiSquare_cdf(80.,20.,50.),0.7521022416849387)
%!test __test_cdf(ChiSquare_cdf(80.,20.,120.),0.0014874117233941227)
%!test __test_cdf(ChiSquare_cdf(80.,20.,400.),3.5745202710349446e-32)
%!test __test_cdf(ChiSquare_cdf(80.,150.,0.),5.084340996560126e-7)
%!test __test_cdf(ChiSquare_cdf(80.,150.,15.),1.2638268739653603e-8)
%!test __test_cdf(ChiSquare_cdf(80.,150.,50.),1.2719279206475188e-12)
%!test __test_cdf(ChiSquare_cdf(80.,150.,120.),2.249233500962962e-21)
%!test __test_cdf(ChiSquare_cdf(80.,150.,400.),1.3286588734176838e-61)
%!test __test_cdf(ChiSquare_cdf(80.,500.,0.),5.11636710024072e-110)
%!test __test_cdf(ChiSquare_cdf(80.,500.,15.),9.31582766394185e-113)
%!test __test_cdf(ChiSquare_cdf(80.,500.,50.),3.691490231802776e-119)
%!test __test_cdf(ChiSquare_cdf(80.,500.,120.),5.320454719316955e-132)
%!test __test_cdf(ChiSquare_cdf(80.,500.,400.),8.478303850956232e-184)
%!test __test_cdf(ChiSquare_cdf(200.,4.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,4.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,4.,50.),0.9999992635505939)
%!test __test_cdf(ChiSquare_cdf(200.,4.,120.),0.9989192237549719)
%!test __test_cdf(ChiSquare_cdf(200.,4.,400.),1.368269306194939e-9)
%!test __test_cdf(ChiSquare_cdf(200.,10.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,10.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,10.,50.),0.9999992635387218)
%!test __test_cdf(ChiSquare_cdf(200.,10.,120.),0.9976488607628722)
%!test __test_cdf(ChiSquare_cdf(200.,10.,400.),4.553687181261618e-10)
%!test __test_cdf(ChiSquare_cdf(200.,20.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,20.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,20.,50.),0.9999992631832745)
%!test __test_cdf(ChiSquare_cdf(200.,20.,120.),0.9923722520637899)
%!test __test_cdf(ChiSquare_cdf(200.,20.,400.),6.791518109396686e-11)
%!test __test_cdf(ChiSquare_cdf(200.,150.,0.),0.9960268140291784)
%!test __test_cdf(ChiSquare_cdf(200.,150.,15.),0.9613423985376754)
%!test __test_cdf(ChiSquare_cdf(200.,150.,50.),0.5142785557024798)
%!test __test_cdf(ChiSquare_cdf(200.,150.,120.),0.003418539794364018)
%!test __test_cdf(ChiSquare_cdf(200.,150.,400.),4.701174535943039e-25)
%!test __test_cdf(ChiSquare_cdf(200.,500.,0.),1.9094894161622827e-36)
%!test __test_cdf(ChiSquare_cdf(200.,500.,15.),2.044329643552851e-38)
%!test __test_cdf(ChiSquare_cdf(200.,500.,50.),4.545711392180851e-43)
%!test __test_cdf(ChiSquare_cdf(200.,500.,120.),1.3903019369311199e-52)
%!test __test_cdf(ChiSquare_cdf(200.,500.,400.),9.732091398284993e-93)
