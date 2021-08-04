/**************************/
/* Variance decomposition */
/**************************/

/* prep dataset */
clear
useshrug
get_shrug_var ec13_emp_all ec13_emp_f total_light_cal2013 avg_forest2014 pc11_pca_tot_work_p pc01_sector pc11_pca_p_06 pc11_pca_tot_work_f pc01_vd_area pc01_td_area pc01_pca_tot_p pc11_sector
get_shrug_key pc11_district_id pc11_state_id pc11_subdistrict_id
duplicates drop shrid, force

/* get consumption vars which aren't picked  */
merge 1:1 shrid using $shrug/shrug_secc, keepusing(secc_cons_pc_rural secc_cons_pc_urban) nogen keep(master match)

/* get total light if we didn't */
merge 1:1 shrid using $shrug/shrug_nl_wide, keepusing(total_light_cal_2013) nogen keep(master match)

/* compute area variable */
gen pc01_vd_area_convert = pc01_vd_area / 100
egen pc01_area = rowtotal(pc01_td_area pc01_vd_area_convert), missing
drop pc01_vd_area_convert

/* prepare calculated vars */
gen ec13_emp_f_share = ec13_emp_f / ec13_emp_all 
gen ec13_emp_pc = ec13_emp_all / (pc11_pca_tot_p - (15 * pc11_pca_p_06 / 7))
gen nl_pc = total_light_cal_2013 / pc11_pca_tot_p
gen f_lab_shr = pc11_pca_tot_work_f / pc11_pca_tot_work_p
gen density = pc01_pca_tot_p / pc01_area

/* fix errors in consumption variable */
replace secc_cons_pc_urban = . if secc_cons_pc_urban == 0
replace secc_cons_pc_rural = . if secc_cons_pc_rural == 0

/* combine consumptions */
gen cons_pc = secc_cons_pc_urban
replace cons_pc = secc_cons_pc_rural if mi(cons_pc)

/* set vars for variance assessment */
global varlist cons_pc ec13_emp_f_share ec13_emp_pc nl_pc avg_forest2014 f_lab_shr density

/* prep geogroups */
egen state_id = group(pc11_state_id)
egen dist_id = group(pc11_state_id pc11_district_id)
egen sdist_id = group(pc11_state_id pc11_district_id pc11_subdistrict_id)

/* set output file */
global file $tmp/shrug_anova_results.csv
cap rm $file

/* loop over all anova vars */
foreach var in $varlist {

  /* winsorize var to clean up high end outliers */
  winsorize `var' 0 99, replace centile

  /* loop over geographic level */
  foreach level in state_id dist_id sdist_id {
    
    /* loop over rural vs urban */
    foreach sector in rural urban {

      /* select urban or rural sectors */
      if "`sector'" == "rural" local sector_val = "== 2"
      if "`sector'" == "urban" local sector_val = "!= 2"

      /* regress consumption with state or district fixed effect to decompose variance in consumption */
      areg `var' if pc11_sector `sector_val', absorb(`level')
      insert_into_file using $file, key("`var'_`level'_`sector'") value(`e(r2)') format(%5.3f)
    }
  }
}

/* create table from regressions */
table_from_tpl, t($repdata/paper-shrug/tex/var_decomp_panel.tpl) r($file) o($out/var_decomp_con_panel.tex)
cat $out/var_decomp_con_panel.tex
