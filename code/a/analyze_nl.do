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

/* set output file template */
global g $out/nl_xc.csv
cap erase $g

/* create short varnames for the tpl file */
local short_ln_pc11_pca_tot_p pop
local short_ln_ec13_emp_all emp
local short_ln_ec13_emp_manuf manuf
local short_ln_ec13_emp_serv serv
local short_ln_pc11_power power
local short_pc11_td_power_share power_urb
local short_ln_consumption cons

/* set variable list */
global tvars ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_consumption pc11_td_power_share
global vvars ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_consumption ln_pc11_power 

/* DISTRICT-LEVEL (RURAL & URBAN) */
use $tmp/shrug_combined_district_both, clear
foreach v in $vvars {
  drop if mi(`v')
}

disp_nice "DISTRICT-LEVEL"
foreach v in $vvars {
  quireg `v' ln_light2012 ln_num_cells, robust title(`v')
  qui store_est_tpl using $g, coef(ln_light2012) name(dxc_`short_`v'') all
}

/* SUBDISTRICT-LEVEL (RURAL & URBAN) */
use $tmp/shrug_combined_subdistrict_both, clear
foreach v in $vvars {
  drop if mi(`v')
}
disp_nice "SUBDISTRICT-LEVEL"

foreach v in $vvars {
  quireg `v' ln_light2012 ln_num_cells, robust title(`v') 
  qui store_est_tpl using $g, coef(ln_light2012) name(sdxc_`short_`v'') all
}

/* TOWN-LEVEL (VILLAGES DROPPED) */
use $tmp/shrug_combined, clear
drop if pc11_sector==2
foreach v in $tvars {
  drop if mi(`v')
}
group pc11_state_id 
disp_nice "TOWN-LEVEL (villages dropped, district FE)"

foreach v in $tvars {
  quireg `v' ln_light2012 ln_num_cells, robust title(`v') absorb(sdgroup)
  qui store_est_tpl using $g, coef(ln_light2012) name(txc_d_`short_`v'') all
}

/* VILLAGE-LEVEL (TOWNS DROPPED) */
use $tmp/shrug_combined, clear
foreach v in $vvars {
  drop if mi(`v')
}
keep if pc11_sector==2
disp_nice "VILLAGE-LEVEL (towns dropped, dist FE)"

foreach v in $vvars {
  quireg `v' ln_light2012 ln_num_cells, robust title(`v') absorb(sdgroup)
  qui store_est_tpl using $g, coef(ln_light2012) name(vxc_d_`short_`v'') all
}

disp_nice "VILLAGE-LEVEL (towns dropped, subdist FE)"

foreach v in $vvars {
  quireg `v' ln_light2012 ln_num_cells, robust title(`v') absorb(sdsgroup)
  qui store_est_tpl using $g, coef(ln_light2012) name(vxc_sd_`short_`v'') all
}

/* create the output table */
table_from_tpl, t($shcode/a/nl_xc.tpl) r($g) o($out/nl_xc.tex)
cat $out/nl_xc.tex

/* predict numbers for a within-subdistrict effect of a 50% increase in light */
foreach v in ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_pc11_power ln_consumption {
  qui quireg `v' ln_light2012, absorb(sdsgroup)

  /* exp(.4054) = 1.5, so this is a 50% increase in light */
  qui lincom 0.4054 * ln_light2012
  di "50% increase in light -> " %1.0f ((exp(`r(estimate)') - 1) * 100) "% increase in `v'."
}

/*****************************/
/* CROSS-SECTION BINSCATTERS */
/*****************************/
use $tmp/shrug_combined, clear

/* generate town variable */
generate village = pc11_sector==2 if !mi(pc11_sector)
label define lvillage 0 "Towns" 1 "Villages"
label values village lvillage

/* binscatter the local relationship with district fixed effects for each var */

/* rural only (since pc11_power is only in rural areas) */
foreach v in ln_pc11_power {
  local ylabel: var label `v'
  local xlabel: var label ln_light2012
  binscatter `v' ln_light2012, xtitle("`xlabel'") ytitle("`ylabel'") title("`ylabel'") linetype(none) name("`v'", replace) absorb(sdgroup)
}

/* rural and urban */
foreach v in ln_pc11_pca_tot_p ln_ec13_emp_all ln_consumption {
  local ylabel: var label `v'
  local xlabel: var label ln_light2012
  binscatter `v' ln_light2012, xtitle("`xlabel'") ytitle("`ylabel'") title("`ylabel'") linetype(none) name("`v'", replace) absorb(sdgroup)
}

/* combine graphs */
graph combine ln_pc11_pca_tot_p ln_ec13_emp_all ln_pc11_power ln_consumption
graphout bins_lights_xvars, pdf

/* generate some predicted numbers for a 0.4 change in log light */
foreach v in ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv ln_pc11_power ln_consumption {
  qui quireg `v' ln_light2012 
  qui lincom 0.4 * ln_light2012
  di "50% increase in light -> " %1.0f ((exp(`r(estimate)') - 1) * 100) "% increase in `v'."
}

/******************************/
/* LOCAL BINSCATTERS BY POWER */
/******************************/

use $tmp/shrug_combined, clear
capdrop any_power
gen any_power = pc11_power > 0 if !mi(pc11_power)
replace any_power = pc11_td_power_share > 0 if !mi(pc11_td_power_share)
label var any_power "Any Electricity"
foreach v in ln_pc11_pca_tot_p ln_consumption ln_ec13_emp_manuf ln_ec13_emp_serv {

  /* calculate spots for slope */
  sum `v' if any_power == 1 & inrange(ln_light2012, 2.25, 2.6)
  local y1 = `r(mean)'
  di `y1'
  sum `v' if any_power == 0 & inrange(ln_light2012, 2.5, 3)
  local y2 = `r(mean)' * 0.997
  di `y2'

  /* override some locations */
  if "`v'" == "ln_consumption" local y1 9.825
  if "`v'" == "ln_ec13_emp_serv" local y2 3.3
  if "`v'" == "ln_ec13_emp_manuf" local y2 1.75
  
  /* calculate slopes and y-values for text */
  quireg `v' ln_light2012 if any_power == 1, absorb(sdgroup)
  local s1: di %5.2f `r(b)'
  quireg `v' ln_light2012 if any_power == 0, absorb(sdgroup)
  local s2: di %5.2f `r(b)'
    
  local ylabel: var label `v'
  local xlabel: var label ln_light2012
  binscatter `v' ln_light2012, absorb(sdgroup) xtitle("`xlabel'") ytitle("`ylabel'") title("`ylabel'") ///
      linetype(lfit) by(any_power) name(`v', replace) ///
      legend(lab(1 "Locations without Electricity") lab(2 "Locations with Electricity")) ///
      colors(midblue orange_red) ///
      text(`y1' 2.1 "Slope: `s1'", color(orange_red) size(vsmall)) ///
      text(`y2' 2.75 "Slope: `s2'", color(midblue) size(vsmall))
  graphout bin_power_`v'
}

grc1leg ln_pc11_pca_tot_p  ln_consumption ln_ec13_emp_manuf ln_ec13_emp_serv
graphout bins_lights_xvars_by_power, pdf

/***************************/
/* TIME SERIES REGRESSIONS */
/***************************/

/* create an output file for the time series regressions */
global f $out/nl_ts.csv
cap erase $f

/* create locals with short varnames for store_est_tpl */
local short_ln_pop pop
local short_ln_ec_emp_all emp
local short_ln_ec_emp_manuf manuf
local short_ln_ec_emp_serv serv
local short_power power
local short_powert powert

global tsvvars ln_pop ln_ec_emp_all ln_ec_emp_manuf ln_ec_emp_serv power
global tstvars ln_pop ln_ec_emp_all ln_ec_emp_manuf ln_ec_emp_serv powert 

/* DISTRICTS */
use $tmp/shrug_ts_district, clear
foreach v in $tsvvars {
  drop if mi(`v')
}

disp_nice "DISTRICT-LEVEL"
foreach v in $tsvvars {
  quireg `v' ln_light ln_num_cells, robust title(`v') absorb(sdgroup year) cluster(sdgroup)
  qui store_est_tpl using $f, coef(ln_light) name(dts_`short_`v'') all
}

/* SUBDISTRICTS */
use $tmp/shrug_ts_subdistrict, clear
foreach v in $tsvvars {
  drop if mi(`v')
}
group pc11_state_id pc11_district_id
disp_nice "SUBDISTRICT-LEVEL"
foreach v in $tsvvars {
  quireg `v' ln_light ln_num_cells, robust title(`v') absorb(sdsgroup year) cluster(sdgroup)
  qui store_est_tpl using $f, coef(ln_light) name(sdts_`short_`v'') all
}

/* TOWNS */
use $tmp/shrug_ts_vt, clear
group pc11_state_id year
drop if pc11_sector==2
foreach v in $tstvars {
  drop if mi(`v')
}

disp_nice "TOWN-LEVEL (town, district-year FE)"
foreach v in $tstvars {
  quireg `v' ln_light ln_num_cells, robust title(`v') absorb(shrid sdygroup) cluster(sdgroup)
  qui store_est_tpl using $f, coef(ln_light) name(tts_d_`short_`v'') all
}


/* VILLAGES */
use $tmp/shrug_ts_vt, clear
keep if pc11_sector==2
foreach v in $tsvvars {
  drop if mi(`v')
}

disp_nice "VILLAGE-LEVEL (village, district-year FE)"
foreach v in $tsvvars {
  quireg `v' ln_light ln_num_cells, robust title(`v') absorb(shrid sdygroup) cluster(sdgroup)
  qui store_est_tpl using $f, coef(ln_light) name(vts_d_`short_`v'') all
}

disp_nice "VILLAGE-LEVEL (village, subdistrict-year FE)"
foreach v in $tsvvars {
  quireg `v' ln_light ln_num_cells, robust title(`v') absorb(shrid sdsygroup) cluster(sdgroup)
  qui store_est_tpl using $f, coef(ln_light) name(vts_sd_`short_`v'') all
}

/* create the output table */
table_from_tpl, t($shcode/a/nl_ts.tpl) r($f) o($out/nl_ts.tex)
cat $out/nl_ts.tex

/**************/
/* APPENDICES */
/**************/

/*********************************************************************/
/* App 1. (1-2) Census years 2005 & 2013, (3-4) Population-weighted. */
/*********************************************************************/
global h $out/nl_ts_app1.csv
cap erase $h

/* create locals with short varnames for store_est_tpl */
local short_ln_pop pop
local short_ln_ec_emp_all emp
local short_ln_ec_emp_manuf manuf
local short_ln_ec_emp_serv serv
local short_power power

global tsvars ln_pop ln_ec_emp_all ln_ec_emp_manuf ln_ec_emp_serv power 

/* village-level data only */
use $tmp/shrug_ts_vt, clear
keep if pc11_sector == 2
foreach v in $svars {
  drop if mi(`v')
}

disp_nice "VILLAGE-LEVEL (village, district-year FE)"
foreach v in $tsvars {

  /* 2005-2013 only */
  quireg `v' ln_light ln_num_cells if inrange(year, 2000, 2013), robust title(`v') absorb(shrid sdygroup) cluster(sdgroup)
  qui store_est_tpl using $h, coef(ln_light) name(vts_d20_`short_`v'') all

  /* population-weighted */
  quireg `v' ln_light ln_num_cells [aw=pop], robust title(`v') absorb(shrid sdygroup) cluster(sdgroup)
  qui store_est_tpl using $h, coef(ln_light) name(vts_dwt_`short_`v'') all
}

disp_nice "VILLAGE-LEVEL (village, subdistrict-year FE)"
foreach v in $tsvars {

  /* 2005-2013 only */
  quireg `v' ln_light ln_num_cells if inrange(year, 2000, 2013), robust title(`v') absorb(shrid sdsygroup) cluster(sdgroup)
  qui store_est_tpl using $h, coef(ln_light) name(vts_sd20_`short_`v'') all

  /* pop-weighted */
  quireg `v' ln_light ln_num_cells [aw=pop], robust title(`v') absorb(shrid sdsygroup) cluster(sdgroup)
  qui store_est_tpl using $h, coef(ln_light) name(vts_sdwt_`short_`v'') all
}

/* create the output table */
table_from_tpl, t($shcode/a/nl_ts_app1.tpl) r($h) o($out/nl_ts_app1.tex)
cat $out/nl_ts_app1.tex

