/****************************************************************/
/* XC REGRESSIONS FROM analyze_nl.do WITH CONSUMPTION BOOTSTRAP */
/****************************************************************/

/*****************************/
/* CROSS-SECTION REGRESSIONS */
/*****************************/

/* bivariate correlation tables.
 Column 1. District (no FE)
 Column 2. Subdistrict (no FE)
 Column 3. Town (within district)
 Column 4. shrid (within district)
 Column 5. shrid (within subdistrict)
*/

/* set number of bootstraps */
global nboot 1000

/* keep full variable list since it affects what we will drop */
global tvars ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_consumption pc11_td_power_share
global vvars ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_consumption ln_pc11_power 

/* prepare the estimates file */
global tmpfile $tmp/nlxc_ests.csv
cap erase $tmpfile
append_to_file using $tmpfile, s(b,se,p,n,var,boot)

/*********************************************/
/* district and subdistrict-level bootstraps */
/*********************************************/
di "Bootstrapping dist / subdistricts..."
qui forval b = 1/$nboot {
  noi di `b'
  use $tmp/shrugboot/shrug_cons_district_both_boot_`b'.dta, clear
  quireg ln_cons ln_light2012 ln_num_cells, robust 
  append_est_to_file using $tmpfile, b(ln_light2012) s(dxc_cons,`b') 

  use $tmp/shrugboot/shrug_cons_subdistrict_both_boot_`b'.dta, clear
  quireg ln_cons ln_light2012 ln_num_cells, robust 
  append_est_to_file using $tmpfile, b(ln_light2012) s(sdxc_cons,`b') 
}

/********************/
/* town-level stats */
/********************/

/* open shrid data */
use $tmp/shrug_combined, clear
group pc11_state_id
drop if pc11_sector == 2
foreach v in $tvars {
  drop if mi(`v')
}

/* keep only the vars we use for the regs */
keep shrid ln_light2012 ln_num_cells sdgroup ln_consumption

/* replace consumption data with bootstrap data B */
merge 1:1 shrid using $secc/parsed_draft/dta/ancillary/shrug_urban_cons_boot, keepusing(secc_cons_pc_*) keep(match) nogen

/* loop over bootstraps */
di "Bootstrapping towns..."
qui forval b = 1/$nboot {

  noi di `b'
  
  /* set consumption to the current bootstrap value */
  replace ln_consumption = ln(secc_cons_pc_`b')
  
  /* run the regressions and store the bootstrap coef */
  quireg ln_consumption ln_light2012 ln_num_cells, robust title(ln_consumption) absorb(sdgroup)
  append_est_to_file using $tmpfile, b(ln_light2012) s(txc_d_cons,`b') 

}

/***********************/
/* village-level stats */
/***********************/

/* open shrid data */
use $tmp/shrug_combined, clear
keep if pc11_sector == 2
foreach v in $vvars {
  drop if mi(`v')
}

/* keep only the vars we use for the regs */
keep shrid ln_light2012 ln_num_cells sdgroup sdsgroup ln_consumption

/* replace consumption data with bootstrap data B */
merge 1:1 shrid using $secc/mord/dta/ancillary/shrug_rural_cons_boot, keepusing(secc_cons_pc_*) keep(match) nogen

/* loop over bootstraps */
di "Bootstrapping villages..."
qui forval b = 1/$nboot {

  noi di `b'
  
  /* set consumption to the current bootstrap value */
  replace ln_consumption = ln(secc_cons_pc_`b')
  
  /* run the regressions and store the bootstrap coef */
  quireg ln_consumption ln_light2012 ln_num_cells, robust title(ln_consumption) absorb(sdgroup)
  append_est_to_file using $tmpfile, b(ln_light2012) s(vxc_d_cons,`b') 

  quireg ln_consumption ln_light2012 ln_num_cells, robust title(ln_consumption) absorb(sdsgroup)
  append_est_to_file using $tmpfile, b(ln_light2012) s(vxc_sd_cons,`b')
}

/* get the mean and standard deviation from the bootstrapped data */
import delimited using $tmpfile, clear

/* copy the template file from the non-boot regression */
global output_csv $out/nl_xc_boot.csv
shell cp $out/nl_xc.csv $output_csv

/* store the stats for each measure */
foreach stat in vxc_d vxc_sd txc_d {
  sum b if var == "`stat'_cons"
  local beta: di %5.3f `r(mean)'
  local se: di %5.3f `r(sd)'
  local t = `beta' / `se'
  local p = 2 * (1 - normal(`t'))
  count_stars, p(`p')
  local stars `r(stars)'
  local starbeta `beta'`stars'
  
  /* insert the stats into the output file */
  insert_into_file using $output_csv, key(`stat'_cons_starbeta) val("`starbeta'")
  insert_into_file using $output_csv, key(`stat'_cons_se) val(`se')
}

shell diff $out/nl_xc.csv $output_csv

/* create the output table */
table_from_tpl, t($shcode/a/nl_xc.tpl) r($output_csv) o($out/nl_xc_boot.tex)
cat $out/nl_xc_boot.tex
