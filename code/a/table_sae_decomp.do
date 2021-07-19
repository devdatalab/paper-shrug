
/* produce a table comparing mean values of consumption index componetns in IHDS and SECC,
   and the effect they have on the mean consumption difference. */

use $repdata/out/table_sae_decomp, clear

/* manually write the table -- too many coefficients for stata-tex */
sort sector varname
foreach sector in urban rural {
  cap file close fh
  file open fh using $out/sae_decomp_`sector'.tex, write replace

  /* write table headers */
  file write fh "\begin{tabular}{lccccc}" _n
  file write fh "\hline\hline & (1) & (2) & (3) & (4) & (5) \\" _n
  file write fh " & IHDS & SECC & Difference & Coefficient & Delta \\" _n
  file write fh "\hline" _n

  /* loop over the variables */
  count
  forval i = 1/`r(N)' {
    if sector[`i'] != "`sector'" continue
    di label[`i']
    file write fh     %20s (label[`i'])          " & " %10.2f (mean_ihds[`i'])
    di label[`i']
    file write fh " & " %10.2f (mean_secc[`i'])    " & " %10.2f (diff[`i'])
    file write fh " & " %10.2f (coef[`i']) " & " %10.2f (delta[`i']) " \\" _n
  }
  file write fh "\hline" _n
  file write fh "\end{tabular}" _n
  file close fh
}
cat $out/sae_decomp_rural.tex
cat $out/sae_decomp_urban.tex

