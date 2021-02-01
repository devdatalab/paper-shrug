/* This makefile runs all the analysis files for results in the  SHRUG paper */
global out /scratch/sharma/shrug_test/out
global repdata /scratch/sharma/shrug_test
global tmp /scratch/sharma/shrug_test/tmp
global shcode ~/ddl/core/shrug

/* redirect several directories used in the code to $repdata */
global shdata $repdata
global shrug $repdata

/* display an error if any of the globals are empty or set to old values*/
if "$out" == "" | regexm("$out", "iec|ddl") ///
    display  "error: Global out not set properly. See instructions in README"

if "$repdata" == "" | regexm("$repdata", "iec|ddl") ///
    display  "error: Global repdata not set properly. See instructions in README"

if "$shcode" == "" | regexm("$shcode", "iec") ///
    display  "error: Global shcode not set properly. See instructions in README"

if "$tmp" == "" | regexm("$tmp", "iec|ddl") ///
    display  "error: Global tmp not set properly. See instructions in README"

/* set the makefile to crash immediately if globals aren't set properly  */
if "$out" == "" | regexm("$out", "iec|ddl") ///
    | "$repdata" == "" | regexm("$repdata", "iec|ddl") ///
    | "$tmp" == "" | regexm("$tmp", "iec|ddl") ///
    | "$shcode" == "" | regexm("$shcode", "iec") ///
    exit 1

/***************/
/* preparation */
/***************/

/* prepare dataset used in SHRUG paper analysis */
do $shcode/b/prep_shrug_paper_data.do

/* prepare comparable consumption measures in IHDS, NSS, SHRUG */
do $shcode/b/prep_cons_comparison.do

/************/
/* analysis */
/************/

/* anova table */
do $shcode/a/anova.do

/* table of SECC and IHDS small-area-estimate asset comparison */

do $shcode/a/table_sae_decomp.do

/* consumption comparison of IHDS, NSS, SHRUG */
do $shcode/a/figure_cons_kdensity.do

/* scatterplot of IHDS vs. SHRUG */
do $shcode/a/ihds_shrug_dist_cons_scatter.do

/* graphs / tables for distribution of manuf/services firms across space */
do $shcode/a/analyze_firms.do

/* poverty analysis */
do $shcode/a/analyze_poverty.do

/* night lights analysis */
do $shcode/a/analyze_nl.do

/* repeat with bootstrapped consumption */
do $shcode/a/analyze_nl_boot.do

/* appendix: simulate dropping shrids to check con impute */
do $shcode/a/validate_con_imputation.do