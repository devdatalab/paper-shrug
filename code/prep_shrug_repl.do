/****************************************************************************/
/* PREPARE A PACKET OF ALL REPLICATION CODE/DATA FOR SHRUG REPLICATION REPO */
/****************************************************************************/

/***** TABLE OF CONTENTS *****/
/* 1. set global paths, make replication repo folder structure */
/* 2. move build + analysis files to the replication repo */
/* 3. copy the READ-ME for front page of repo */
/* 4. move data files to public google drive  */

/***************************************************************/
/* 1. set global paths, make replication repo folder structure */
/***************************************************************/

/* set global to shrug project repo */
global shcode ~/ddl/shrug

/* set global to shrug project data folder */
global shdata ~/iec1/shrug

/* set global to the shrug replication repo */
global shrug_dir ~/ddl/paper-shrug

/* make the replication code directory plus subfolder structure, if they don't exist */
cap mkdir $shrug_dir
cap mkdir $shrug_dir/code/
cap mkdir $shrug_dir/code/ado
cap mkdir $shrug_dir/code/a
cap mkdir $shrug_dir/code/b

cap mkdir $shrug_dir/tex

cap mkdir $shrug_dir/data

/* set global to the shrug replication data on Google Drive */
global repdata ~/secc/frozen_data/paper-shrug

/* make the replication data directory structure */
cap mkdir $repdata/data
cap mkdir $repdata/csv
cap mkdir $repdata/intermediate
cap mkdir $repdata/keys
cap mkdir $repdata/out
cap mkdir $repdata/tmp
cap mkdir $repdata/tmp/shrugboot


/**********************************************************/
/* 2. move build + analysis files to the replication repo */
/**********************************************************/

// /* copy the necessary programs to the ado folder  */
// copy $shcode/shrug_progs.do $shrug_dir/code/ado/ , replace
// copy ~/ddl/tools/do/tools.do $shrug_dir/code/ado/ , replace
//
// /* copy the make file to the packet folder */
// copy $shcode/make_shrug_paper.do $shrug_dir/code/ , replace
//
// /* Copy SHRUG build files into the packet folder */
// copy $shcode/b/prep_shrug_paper_data.do $shrug_dir/code/b/ , replace
// copy $shcode/b/prep_cons_comparison.do $shrug_dir/code/b/ , replace
//
//
// /* copy all the main analysis do files into packet folder */
// copy $shcode/a/anova.do $shrug_dir/code/a/ , replace 							//ANOVA Table
// copy $shcode/a/table_sae_decomp.do $shrug_dir/code/a/ , replace 					//table of SECC and IHDS small-area-estimate asset comparison
// copy $shcode/a/figure_cons_kdensity.do $shrug_dir/code/a/ , replace 				//consumption comparison of IHDS, NSS, SHRUG
// copy $shcode/a/ihds_shrug_dist_cons_scatter.do $shrug_dir/code/a/ , replace		//scatterplot of IHDS vs. SHRUG
// copy $shcode/a/analyze_firms.do $shrug_dir/code/a/ , replace 					//graphs / tables for distribution of manuf/services firms
// copy $shcode/a/analyze_poverty.do $shrug_dir/code/a/ , replace					//poverty analysis
// copy $shcode/a/analyze_nl.do $shrug_dir/code/a/ , replace						//night lights analysis
// copy $shcode/a/analyze_nl_boot.do $shrug_dir/code/a/ , replace					//repeat with bootstrapped consumption
// copy $shcode/a/validate_con_imputation.do $shrug_dir/code/a/ , replace			//simulate dropping shrids to check con imput (appendix)

/* ZIP CODE FILES AND COPY */

// /* zip code packet with internal folder structure */
// cd $shrug_dir/code
// shell zip -r shrug-code.zip *
// 
// /* copy code packet to replication repo */
// shell mv shrug-code.zip $shrug_dir

/**********************************************/
/* 4. move data files to public google drive  */
/**********************************************/

/* note: this also converts any .dta files to CSV and stores them in $repdata/csv/ */

/* MOVE .DTA FILES */

global dta "shrug_pcec shrug_rural_cons_imputed_all shrug_nl shrug_pc11_vd shrug_vcf shrug_pc01_vd shrug_nl_wide shrug_ancillary shrug_ec13 shrug_pc11_pca shrug_ec05 shrug_ec98 shrug_ec90 shrug_pc01_pca shrug_pc91_pca shrug_pc91_vd shrug_vcf_wide shrug_spatial shrug_quality shrug_secc shrug_pmgsy shrug_pc11_td shrug_elevation shrug_outliers shrug_pc01_td con_shrug_2008_nl con_shrug_2007_nl con_shrug_2008 shrug_pc91_td con_shrug_2007 con_shrug_2008_vcf con_shrug_2007_vcf con_shrug_2008_nl_wide con_shrug_2007_nl_wide con_shrug_2008_vcf_wide con_shrug_2007_vcf_wide shrug_rural_cons"

foreach i in $dta {
use $shdata/data/`i', clear
save $repdata/data/`i', replace
export delimited using $repdata/csv/`i' , replace
}

/* IHDS */
global dta "ihds_2011_members ihds_2011_hh"
foreach i in $dta {
use "~/iec1/ihds/`i'", clear
save $repdata/data/`i', replace
export delimited using $repdata/csv/`i' , replace
}

use "~/iec1/ihds/sae/all_ihds_data", clear
save "$repdata/data/all_ihds_data", replace
export delimited using $repdata/csv/all_ihds_data , replace

/* NSS */
global dta "nss_sch10 nss_sch10_urban"
foreach i in $dta {
use ~/iec1/misc_data/nss68/`i', clear
save $repdata/data/`i', replace
export delimited using $repdata/csv/`i' , replace
}

use ~/iec1/nss/clean/nss-68-01-household, clear
save $repdata/data/nss-68-01-household, replace
export delimited using $repdata/csv/nss-68-01-household , replace

use ~/iec1/nss/nss-68/1.0/block-1-household, clear
save $repdata/data/block-1-household, replace
export delimited using $repdata/csv/block-1-household, replace

/* SECC */

/* urban consumption bootstraps */
use ~/iec2/secc/parsed_draft/dta/ancillary/shrug_urban_cons_boot
save $repdata/data/shrug_urban_cons_boot, replace
export delimited using $repdata/csv/shrug_urban_cons_boot, eplace

/* rural consumption bootstraps */
use ~/iec2/secc/mord/dta/ancillary/shrug_rural_cons_boot
save $repdata/data/shrug_urban_cons_boot, replace
export delimited using $repdata/csv/shrug_rural_cons_boot, eplace


global keys "shrug_names shrug_con_key_2008 shrug_pc01_subdistrict_key shrug_pc11_subdistrict_key shrug_pc91_subdistrict_key shrug_con_key_2007 shrug_ec05_subdistrict_key shrug_ec98_subdistrict_key shrug_pc91_district_key shrug_pc01_district_key shrug_pc11_district_key shrug_ec13_subdistrict_key shrug_ec13_district_key shrug_ec90_subdistrict_key shrug_ec05_district_key shrug_ec98_district_key shrug_ec90_district_key shrug_pc91_state_key shrug_pc01_state_key shrug_pc11_state_key shrug_ec13_state_key shrug_ec05_state_key shrug_ec90_state_key shrug_pc01r_key shrug_ec98_state_key shrug_pc11r_key shrug_pc91r_key shrug_ec90r_key shrug_ec13r_key shrug_ec05r_key shrug_ec98r_key shrug_pc11u_key shrug_ec13u_key shrug_pc01u_key shrug_pc91u_key shrug_ec05u_key shrug_ec98u_key shrug_ec90u_key shric_descriptions shric_NIC87_key shric_NIC04_key shric_NIC08_3d_key"

foreach i in $keys {
use $shdata/keys/`i', clear
save $repdata/keys/`i', replace
export delimited using $repdata/csv/`i' , replace
}

global intermediate "con_pre_impute_08"

foreach i in $intermediate {
use $shdata/intermediate/`i', clear
save $repdata/intermediate/`i', replace
export delimited using $repdata/csv/`i' , replace
}

/* Compile SECC means */
do $shcode/b/prep_table_sae_decomp.do
save $repdata/intermediate/table_sae_decomp, replace

/* ZIP DATA PACKET */
cd $repdata/data
shell zip -r shrug-dta.zip *.dta
shell mv *.zip $repdata

cd $repdata/csv
shell zip -r shrug-csv.zip *.csv
shell mv *.zip $repdata

cd $repdata/keys
shell zip -r shrug-keys.zip *.dta
shell mv *.zip $repdata

cd $repdata/intermediate
shell zip -r shrug-intermediate *.dta
shell mv *.zip $repdata


/* move the data packet to google drive with rclone */

/* note 1: to use the rclone commands, you must make a remote called shrug_repl
(follow instructions in rclone wiki in ~ddl/tools/ */

/* note 2: the GDrive folder is in ddl_full/data/public-repos/data-shrug */
shell rclone copy $repdata/shrug-dta.zip  my_drive:data/public-repos/data-shrug
shell rclone copy $repdata/shrug-csv.zip  my_drive:data/public-repos/data-shrug
shell rclone copy $repdata/shrug-keys.zip  my_drive:data/public-repos/data-shrug
shell rclone copy $repdata/shrug-intermediate.zip  my_drive:data/public-repos/data-shrug
