/******************************************************************/
/* prepare comparison of consumption between IHDS, NSS, and SHRUG */
/******************************************************************/

/*****************************************/
/* prep SHRUG district consumption data  */
/*****************************************/

/* get SHRUG consumption and district identifiers */
useshrug
get_shrug_var secc_cons_pc_rural secc_cons_pc_urban
get_shrug_key pc01_state_id pc01_district_id 

/* TMP FIX: SECC error: consumption can't be zero */
replace secc_cons_pc_rural = . if secc_cons_pc_rural == 0
replace secc_cons_pc_urban = . if secc_cons_pc_urban == 0
/* END TMP */

/* combine rural and urban consumption */
egen    secc_cons_pc_both = rowtotal(secc_cons_pc_rural secc_cons_pc_urban)
replace secc_cons_pc_both = . if mi(secc_cons_pc_rural) & mi(secc_cons_pc_urban)

/* save SHRUG at village level */
gen source = "shrug"
save $tmp/shrug_cons_village, replace

/* collapse to district level */
collapse (rawsum) pc11_pca_tot_p (mean) secc_cons_pc_both secc_cons_pc_rural secc_cons_pc_urban [aw=pc11_pca_tot_p], by(pc01_state_id pc01_district_id)

/* save SHRUG district-level consumption */
gen source = "shrug"
save $tmp/shrug_cons_dist, replace

/****************************************/
/* prep IHDS district consumption data  */
/****************************************/

/* open IHDS members data just for household size count */
use $repdata/ihds_2011_members, clear

/* collapse to household level */
keep hhid
gen num_members = 1
collapse (sum) num_members, by(hhid)

/* merge to household data */
merge 1:1 hhid using $repdata/ihds_2011_hh, nogen keep(match) keepusing(stateid distid cototal wt psuid district urban2011)
ren urban2011 urban

/* generate per capita consumption */
gen ihds_cons_pc_both = cototal / num_members

/* split rural and urban consumption */
gen ihds_cons_pc_rural = ihds_cons_pc_both if urban == 0
gen ihds_cons_pc_urban = ihds_cons_pc_both if urban == 1

/* generate PSU, village, and neighborhood groups */
group stateid distid psuid

/* generate pop census identifiers */
tostring stateid, gen(pc01_state_id) format(%02.0f)
tostring distid, gen(pc01_district_id) format(%02.0f)

/* save individual-level IHDS with consumption */
save $tmp/ihds_cons_hh, replace

/**********************************************************/
/* collapse IHDS to PSU-level for distribution comparison */
/**********************************************************/

/* create a var to hold number of households in collapsed data */
gen num_hh = 1

/* collapse to PSU and save, where PSU is a village or urban block. */
preserve
collapse (rawsum) wt num_hh (mean) ihds_cons_pc_mean_both = ihds_cons_pc_both ihds_cons_pc_mean_rural = ihds_cons_pc_rural ihds_cons_pc_mean_urban = ihds_cons_pc_urban (p50) ihds_cons_pc_both ihds_cons_pc_rural ihds_cons_pc_urban (firstnm) pc01_state_id pc01_district_id [aw=wt], by(sdpgroup)
gen source = "ihds"
save $tmp/ihds_cons_psu, replace
restore

/* recollapse to district level */
group pc01_state_id pc01_district_id
collapse (rawsum) wt num_hh (mean) ihds_cons_pc_mean_both = ihds_cons_pc_both ihds_cons_pc_mean_rural = ihds_cons_pc_rural ihds_cons_pc_mean_urban = ihds_cons_pc_urban (p50) ihds_cons_pc_both ihds_cons_pc_rural ihds_cons_pc_urban (firstnm) pc01_state_id pc01_district_id [aw=wt], by(sdgroup)

/* save for analysis */
save $tmp/ihds_cons_dist, replace

/*********************************************/
/* prepare district-level NSS for comparison */
/*********************************************/

/* use schedule 10 to create a household -> state/district key for NSS */

/* save urban district ids in a temporary file */
use $repdata/data/nss68/nss_sch10_urban.dta, clear
keep hhid pc01_state_id pc01_district_id
save $tmp/nss_dist_urban, replace

/* append rural district ids */
use $repdata/data/nss68/nss_sch10.dta, clear
keep hhid pc01_state_id pc01_district_id
append using $tmp/nss_dist_urban
duplicates drop
save $tmp/nss_dist_key, replace

/*******************************/
/* calculate NSS68 consumption */
/*******************************/

/* NSS - note use mrp for mixed reference period rather than uniform reference period. mult * 12 for annual */

/* begin w/raw data to build an fsu:hhid key. FSU is village or urban block. */
use $repdata/data/block-1-household, clear
ren *, lower
keep hhid fsu_serial_no
ren fsu_serial_no fsu
ren hhid hhid
save $tmp/nss_fsu_key, replace

/* Use the cleaned NSS data and merge in the FSU ID. */
use $repdata/data/nss-68-01-household, clear
merge 1:1 hhid using $tmp/nss_fsu_key, keep(match) nogen

/* merge in PC district ids */
merge 1:1 hhid using $tmp/nss_dist_key, keep(match) nogen

/* generate consumption and remove zero consumption if any */
drop if mpce_mrp == 0
gen nss_cons_pc_both = mpce_mrp * 12
gen nss_cons_pc_rural = mpce_mrp * 12 if urban == 0
gen nss_cons_pc_urban = mpce_mrp * 12 if urban == 1

/* save household-level NSS consumption dataset */
save $tmp/nss_cons_hh, replace

/* collapse NSS consumption to FSU with weights */
preserve
collapse (rawsum) wt (mean) nss_cons_pc_mean_both = nss_cons_pc_both nss_cons_pc_rural_mean = nss_cons_pc_rural nss_cons_pc_urbanmean = nss_cons_pc_urban (p50) nss_cons_pc_both nss_cons_pc_rural nss_cons_pc_urban (firstnm) pc01_state_id pc01_district_id [aw=wt], by(fsu)
gen source = "nss"
save $tmp/nss_cons_fsu, replace
restore

/* collapse NSS consumption districts with weights */
collapse (rawsum) wt (mean) nss_cons_pc_mean_both = nss_cons_pc_both nss_cons_pc_rural_mean = nss_cons_pc_rural nss_cons_pc_urbanmean = nss_cons_pc_urban (p50) nss_cons_pc_both nss_cons_pc_rural nss_cons_pc_urban [aw=wt], by(pc01_state_id pc01_district_id)
gen source = "nss"
save $tmp/nss_cons_dist, replace

/************************************************/
/* combine SHRUG + IHDS district-level datasets */
/************************************************/

/* open district shrug and merge to district IHDS */
use $tmp/shrug_cons_dist, clear
merge 1:1 pc01_state_id pc01_district_id using $tmp/ihds_cons_dist, keep(match) nogen

/* save prepped IHDS/SHRUG district comparison */
save $tmp/ihds_shrug_dist_cons, replace

/****************************************************/
/* create a list of districts in all three datasets */
/****************************************************/
use pc01_state_id pc01_district_id using $tmp/ihds_cons_dist, clear
merge m:1 pc01_state_id pc01_district_id using $tmp/nss_cons_dist, keep(match) keepusing(pc01_state_id) nogen
merge m:1 pc01_state_id pc01_district_id using $tmp/shrug_cons_dist, keep(match) keepusing(pc01_state_id) nogen
save $tmp/combined_district_list, replace
