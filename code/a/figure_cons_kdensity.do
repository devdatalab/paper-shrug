/*************************************************************/
/* store full dataset consumption mean from shrug, ihds, nss */
/*************************************************************/
qui foreach sector in both urban rural {

  noi disp_nice "consumption in sector: `sector'"
  
  /* loop over NSS and IHDS which have the same structure. SHRUG is village-level so different. */
  foreach ds in ihds nss {

    /* get `DS' means */
    use $tmp/`ds'_cons_hh, clear

    /* store mean and median dataset-wide consumption in locals */
    sum `ds'_cons_pc_`sector' [aw=wt], d
    global `ds'_cons_median_`sector' = `r(p50)'
    global `ds'_cons_mean_`sector' = `r(mean)'
    
    /* report them for use in the paper */
    noi di "`ds' consumption median: " %10.0f (`r(p50)')
    noi di "`ds' consumption mean:   " %10.0f (`r(mean)')
  }

  /* repeat for shrug */
  use $tmp/shrug_cons_village, clear

  sum secc_cons_pc_`sector' [aw=pc11_pca_tot_p], d
  
  global shrug_cons_median_`sector' = `r(p50)'
  global shrug_cons_mean_`sector' = `r(mean)'
    
  /* report them for use in the paper */
  noi di "shrug consumption median: " %10.0f (`r(p50)')
  noi di "shrug consumption mean:   " %10.0f (`r(mean)')
}

/*********************************/
/* kdensity plots of consumption */
/*********************************/

/* combine shrug/nss/ihds without restricting to matched districts */
use $tmp/shrug_cons_village, replace
gen wt = 1
append using $tmp/ihds_cons_psu
append using $tmp/nss_cons_fsu

/* generate the kdensity */
foreach sector in rural urban both {
  twoway ///
      (kdensity secc_cons_pc_`sector' [aw=wt], lcolor(ebblue)   range(5000 50000))  ///
      (kdensity nss_cons_pc_`sector'  [aw=wt],  lcolor(orange)           range(5000 50000))  ///
      (kdensity ihds_cons_pc_`sector' [aw=wt], lcolor(gs4)              range(5000 50000))  ///
      , ytitle("Kernel Density") xtitle("Per Capita Consumption (Rs)") legend(ring(0) pos(2) label(1 "SHRUG") label(2 "NSS") label(3 "IHDS") size(medium) rows(3))
  
  graphout cons_compare_kdensity_`sector', pdf
}
