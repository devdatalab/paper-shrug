/* prepare night light analysis dataset. Consists of night lights and all of their interesting correlates. */

/* start with shrids, cells, and calibrated lights from wide night light data */
use shrid num_cells total_light_cal* using $shrug/shrug_nl_wide, clear
ren total_light_cal_* total_light*

/* bring in employment, services, and manufacturing from all EC rounds */
foreach y in 90 98 05 13 {
  merge 1:1 shrid using $shrug/shrug_ec`y', keepusing(ec`y'_emp_all ec`y'_emp_manuf ec`y'_emp_services) nogen keep(match master)
}

/* bring in total population */
foreach y in 91 01 11 {
  merge 1:1 shrid using $shrug/shrug_pc`y'_pca, keepusing(pc`y'_pca_tot_p) nogen keep(match master)
}

/* get sector in pc11 */
merge 1:1 shrid using $shrug/shrug_pc11_pca, keepusing(pc11_sector) nogen keep(match master)

/* bring in electricity */

/* rural */
foreach y in 91 01 {
  merge 1:1 shrid using $shrug/shrug_pc`y'_vd, keepusing(pc`y'_vd_power_supl) nogen keep(match master)
}
merge 1:1 shrid using $shrug/shrug_pc11_vd, keepusing(pc11_vd_power_all_win pc11_vd_power_all_sum) nogen keep(match master)

/* urban */
merge 1:1 shrid using $shrug/shrug_pc91_td, keepusing(pc91_td_el_dom pc91_td_res_house) nogen keep(match master)
foreach y in 01 11 {
  merge 1:1 shrid using $shrug/shrug_pc`y'_td, keepusing(pc`y'_td_el_dom pc`y'_td_no_hh) nogen keep(match master)
}

/* bring in SECC consumption and poverty rate */
save $tmp/foo, replace
merge 1:1 shrid using $shrug/shrug_secc, keepusing(secc_cons_pc_rural secc_cons_pc_urban secc_pov_rate_urban secc_pov_rate_rural) nogen keep(match master)

/* bring in the district and subdistrict ids */
merge 1:1 shrid using $shrug/keys/shrug_pc11_district_key, keep(master match) keepusing(pc11_district_id pc11_state_id) nogen
merge 1:1 shrid using $shrug/keys/shrug_pc11_subdistrict_key, keep(master match) keepusing(pc11_subdistrict_id) nogen

/* combine 2011 electricity variables and name it the same as the 91/01 vars (even though the meaning and range are different. */
egen pc11_vd_power_supl = rowmean(pc11_vd_power_all_win pc11_vd_power_all_sum)

/* generate urban electrification variables */
ren pc91_td_res_house pc91_td_no_hh
foreach y in 91 01 11 {
  gen pc`y'_td_power_share = pc`y'_td_el_dom/ pc`y'_td_no_hh
  replace pc`y'_td_power_share = 1 if inrange(pc`y'_td_power_share, 1, 1.5)
  replace pc`y'_td_power_share = . if !inrange(pc`y'_td_power_share, 0, 1)
  label var pc`y'_td_power_share "Share of HH with electrical connection (pc`y')"
}

/* shorten some varnames  */
ren *services* *serv*
ren secc_cons_pc_rural cons_rural
ren secc_pov_rate_rural pov_rate_rural
ren secc_cons_pc_urban cons_urban
ren secc_pov_rate_urban pov_rate_urban
ren *vd_power_supl *power

/* combine rural and urban consumption */
gen     consumption = cons_urban
replace consumption = cons_rural if mi(consumption)
gen     pov_rate = pov_rate_urban
replace pov_rate = pov_rate_rural if mi(pov_rate)

/* convert night lights to location averages */
foreach v of varlist total_light* {
  gen mean_`v' = `v' / num_cells
  ren mean_total_light* light*
}

/* create log of continuous variables  */
foreach v of varlist light* ec* *tot_p cons* pc11_power num_cells {
  gen ln_`v' = ln(`v' + 1)
}

/* create district fixed effects */
group pc11_state_id pc11_district_id 
group pc11_state_id pc11_district_id pc11_subdistrict_id 

/* set list of NL correlate vars of interest for the paper */
global avars ln_pc11_pca_tot_p ln_ec13_emp_all ln_ec13_emp_manuf ln_ec13_emp_serv pc11_power pc11_td_power_share consumption

/* create standardized versions of all vars we like */
foreach v of varlist $avars light2012 {
  sum `v', d
  gen z_`v' = (`v' - `r(mean)') / `r(sd)'
}

/* create a sample where we have all the vars of interest */
gen sample = 1
foreach v in $avars {
  replace sample = 0 if mi(`v')
}

/* drop outlier places */
drop if pc11_pca_tot_p < 100

/* save the working combined SHRUG */
label var ln_pc11_pca_tot_p "Log Population"
label var ln_ec13_emp_all "Log Employment"
label var ln_ec13_emp_manuf "Log Manufacturing Employment"
label var ln_ec13_emp_serv "Log Services Employment"
label var pc11_power "Daily Hours of Electricity"
label var ln_pc11_power "Log Daily Hours of Electricity"
label var ln_consumption "Log Annual Consumption"
label var ln_light2012 "Log Luminosity"
label var ln_num_cells "Log number of cells in polygon"

save $tmp/shrug_combined, replace

/*************************************/
/* district and subdistrict collapse */
/*************************************/
foreach dist in subdistrict district {

  foreach spec in rural urban both {
    
    use $tmp/shrug_combined, clear

    /* keep only towns/villages for urban/rural collapses */
    if "`spec'" == "urban" keep if pc11_sector == 1 | pc11_sector == 3
    if "`spec'" == "rural" keep if pc11_sector == 2
    
    /* specify collapse level */
    if "`dist'" == "district" local level pc11_district_id 
    if "`dist'" == "subdistrict" local level pc11_district_id pc11_subdistrict_id
    
    /* collapse to the (sub)district level for x- vs. within- comparison */
    collapse (rawsum) pc*_pca_tot_p ec* num_cells total_light* (mean) pc11_power pc11_td_power_share cons* pov_rate* [aw=pc11_pca_tot_p], by(pc11_state_id `level' sdgroup)
    
    /* recreate logs and normalized vars */
    /* convert night lights to location averages */
    foreach v of varlist total_light* {
      gen mean_`v' = `v' / num_cells
      ren mean_total_light* light*
    }
    
    /* create log of continuous variables  */
    foreach v of varlist light* ec* *tot_p cons* pc11_power num_cells {
      gen ln_`v' = ln(`v' + 1)
    }
    
    foreach v of varlist $avars light2012 {
      sum `v', d
      if `r(N)' > 0 {
        gen z_`v' = (`v' - `r(mean)') / `r(sd)'
      }
    }
    
    label var ln_pc11_pca_tot_p "Log Population"
    label var ln_ec13_emp_all "Log Employment"
    label var ln_ec13_emp_manuf "Log Manufacturing Employment"
    label var ln_ec13_emp_serv "Log Services Employment"
    label var pc11_power "Daily Hours of Electricity"
    label var ln_pc11_power "Log Daily Hours of Electricity"
    label var ln_consumption "Log Annual Consumption"
    label var ln_light2012 "Log Luminosity"
    label var ln_num_cells "Log number of cells in polygon"
    label var pc11_td_power_share "Share of HH with electrical connection (pc11)"
    save $tmp/shrug_combined_`dist'_`spec', replace
  }
}

/*****************************************************************/
/* bootstrap consumption collapse for districts and subdistricts */
/*****************************************************************/

/* create a folder for the bootstrap files */
cap mkdir $tmp/shrugboot

foreach spec in rural urban both {
  
  /* create the bootstrapped rural consumption dataset with only vars of interest */
  use $tmp/shrug_combined, clear

  /* keep only towns/villages for urban/rural collapses */
  if "`spec'" == "urban" keep if pc11_sector == 1 | pc11_sector == 3 
  if "`spec'" == "rural" keep if pc11_sector == 2

  /* merge in consumption variables for bootstrapping */
  keep pc11_sector pc11_state_id pc11_district_id pc11_subdistrict_id shrid total_light2012 num_cells sdgroup sdsgroup pc11_pca_tot_p ec13_emp_all ec13_emp_manuf ec13_emp_serv pc11_power pc11_td_power_share
  merge 1:1 shrid using $shrug/shrug_rural_cons_boot, keepusing(secc_cons_pc_*) keep(match master) nogen
  merge 1:1 shrid using $shrug/shrug_urban_cons_boot, keepusing(secc_cons_pc_*) keep(match master) nogen update
  drop if mi(secc_cons_pc_1)
  save $tmp/shrug_boot_pre_collapse_`spec', replace

  /* loop over bootstraps */
  forval b = 1/1000 {
    
    /* loop over collapse levels */
    foreach dist in subdistrict district {
      
      /* open the precollapse file */
      use $tmp/shrug_boot_pre_collapse_`spec', replace

      /* specify collapse level */
      if "`dist'" == "district" local level pc11_district_id 
      if "`dist'" == "subdistrict" local level pc11_district_id pc11_subdistrict_id
      
      /* set the consumption variable */
      ren secc_cons_pc_`b' cons_pc
      
      /* collapse to the (sub)district level */
      collapse (rawsum) pc*_pca_tot_p ec* num_cells total_light* (mean) pc11_power cons* [aw=pc11_pca_tot_p], by(pc11_state_id `level' sdgroup)

      /* drop any districts missing a var */
      foreach v in pc11_pca_tot_p ec13_emp_all ec13_emp_manuf ec13_emp_serv pc11_power {
        drop if mi(`v')
      }
      
      /* convert night lights to location averages */
      foreach v of varlist total_light* {
        gen mean_`v' = `v' / num_cells
        ren mean_total_light* light*
      }
      
      /* calculate logs */
      gen ln_cons = ln(cons_pc)
      gen ln_light2012 = ln(light2012 + 1)
      gen ln_num_cells = ln(num_cells + 1)
      drop cons_pc light2012 num_cells pc11_pca_tot_p ec13_emp_all ec13_emp_manuf ec13_emp_serv pc11_power
      save $tmp/shrugboot/shrug_cons_`dist'_`spec'_boot_`b', replace
    }
  }
}

/******************************************************************************/
/* CREATE TIME SERIES DATASET WITH EXTRAPOLATED DATA TO ECONOMIC CENSUS YEARS */
/******************************************************************************/

/* interpolate night lights back to 1990 and convert to wide format */
use $shrug/shrug_nl_wide, clear
ren total_light_cal_* light*
gen g = (light2000 / light1994) ^ (1/6)
gen light1990 = light1994  / (g ^ 4)
keep shrid num_cells light*
reshape long light, i(shrid num_cells) j(year)
keep if inlist(year, 1990, 1998, 2005, 2013)
save $tmp/shrug_nl_ec_years, replace

/* reopen the core dataset */
use $tmp/shrug_combined, clear

/* normalize electrification data since the units change over time */
normalize pc91_power, replace
normalize pc01_power, replace
drop pc11_power
normalize ln_pc11_power, gen(pc11_power)
/* we normalize log power from pc11, which works pretty well as an elasticity
   since the SD of the log variable is 1.3 (vs. 7.5 for hours of power) */

/* shorten pop and power varnames */
ren pc91_pca_tot_p pop91
ren pc01_pca_tot_p pop01
ren pc11_pca_tot_p pop11
ren pc*_power power*
ren pc*_td_power_share powert*

/* multiplicatively interpolate population to EC years */
gen g9101 = (pop01 / pop91) ^ (1/10)
gen g0111 = (pop11 / pop01) ^ (1/10)

gen pop90 = pop91 / g9101
gen pop98 = pop91 * (g9101 ^ 7)
gen pop05 = pop01 * (g0111 ^ 4)
gen pop13 = pop11 * (g0111 ^ 2)

/* linear interpolation of rural power to EC years */
gen gp9101 = (power01 - power91) / 10
gen gp0111 = (power11 - power01) / 10

gen power90 = power91 - gp9101
gen power98 = power91 + (gp9101 * 7)
gen power05 = power01 + (gp0111 * 4)
gen power13 = power11 + (gp0111 * 2)

/* linear interpolation of urban power to EC years */
gen gpt9101 = (powert01 - powert91) / 10
gen gpt0111 = (powert11 - powert01) / 10

gen powert90 = powert91 - gpt9101
gen powert98 = powert91 + (gpt9101 * 7)
gen powert05 = powert01 + (gpt0111 * 4)
gen powert13 = power11 + (gpt0111 * 2)

/* rename EC vars for easy reshaping */
ren ec*_emp_all ec_emp_all*
ren ec*_emp_manuf ec_emp_manuf*
ren ec*_emp_serv ec_emp_serv*
drop light* ln_light*

/* reshape to long. use 'string' so 05 works with the leading zero */
keep shrid *90 *98 *05 *13 pc11_sector
reshape long ec_emp_all ec_emp_manuf ec_emp_serv pop power powert, j(year) i(shrid) string
destring year, replace
replace year = year + 1900
replace year = year + 100 if inlist(year, 1905, 1913)

/* merge to night lights data on year */
merge 1:1 shrid year using $tmp/shrug_nl_ec_years, keepusing(light num_cells) keep(match) nogen

/* create logs */
foreach v in ec_emp_all ec_emp_manuf ec_emp_serv pop light {
  gen ln_`v' = ln(`v' + 1)
}

/* drop shrids with zero population in any year */
bys shrid: egen min_pop = min(pop)
drop if min_pop == 0
drop min_pop

/* drop shrids with missing population in any year */
drop if mi(pop)
bys shrid: egen num_pop = count(pop)
keep if num_pop == 4
drop num_pop

/* get districts and create district-year fixed effects */
merge m:1 shrid using $shrug/keys/shrug_pc11_district_key, keep(master match) nogen
group pc11_state_id pc11_district_id
group pc11_state_id pc11_district_id year

/* get subdistricts and subdistrict fixed effects */
merge m:1 shrid using $shrug/keys/shrug_pc11_subdistrict_key, keep(master match) nogen
group pc11_state_id pc11_district_id pc11_subdistrict_id 
group pc11_state_id pc11_district_id pc11_subdistrict_id year

gen ln_num_cells = ln(num_cells)

/* save joint village town time series dataset */
save $tmp/shrug_ts_vt, replace

/* collapse data to district and subdistrict levels */
foreach dist in subdistrict district {

  /* open village time series */
  use $tmp/shrug_ts_vt, clear
  
  /* specify collapse level */
  if "`dist'" == "district" local level pc11_district_id 
  if "`dist'" == "subdistrict" local level pc11_district_id pc11_subdistrict_id

  /* collapse to the (sub)district level for x- vs. within- comparison */
  collapse (rawsum) pop ec* num_cells light* (mean) power [aw=pop], by(pc11_state_id `level' year)

  /* convert night lights to location averages */
  foreach v of varlist light* {
    replace `v' = `v' / num_cells
  }
  
  /* recreate log vars */
  foreach v of varlist light* ec* pop* num_cells {
    gen ln_`v' = ln(`v' + 1)
  }

  /* create fixed effects */
  group pc11_state_id `level'
  group pc11_state_id pc11_district_id year
  
  label var pop "Population"
  label var ec_emp_all "Employment"
  label var ec_emp_manuf "Manufacturing Employment"
  label var ec_emp_serv "Services Employment"
  label var power "Standardized Power"
  label var ln_pop "Log Population"
  label var ln_ec_emp_all "Log Employment"
  label var ln_ec_emp_manuf "Log Manufacturing Employment"
  label var ln_ec_emp_serv "Log Services Employment"
  label var ln_light "Log Luminosity"
  label var ln_num_cells "Log number of cells in polygon"
  save $tmp/shrug_ts_`dist', replace
}

