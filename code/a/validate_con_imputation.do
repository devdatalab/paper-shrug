/******************************************************************************************/
/* test accuracy of imputation process by dropping additional shrids and seeing how we do */
/******************************************************************************************/
/* design decisions / notes:
- do 2008 con boundaries only
- work with 2001, where we need almost no imputation, so our reference test is damn good.
- values used in SHRUG are in $shrug/intermediate/con_pre_impute_08.
- goal is to compare what we generate to these ones

1. set X% of 2001 populations to missing
2. rerun the imputation to get constituency population totals
3. compare the totals to $shrug/intermediate/con_pre_impute_08.
- mean absolute deviation as a percentage of constituency population

4. graph: share shrids dropped on X axis, mean absolute deviation on Y axis.

*/

/**********************************************************************************************************************/
/* program impute_shrid_pop : Impute population for missing villages based on other villages in the same constituency */
/**********************************************************************************************************************/
cap prog drop impute_shrid_pop
prog def impute_shrid_pop
{
  syntax, group_id(string) base_year(string) target_year(string) [pca_suffix(string)]

  /* example: base_year: 11
            target_year: 01
             pca_suffix: _r  [can be blank for U + R]
  */
  
  
  /* calculate total non-missing constituency population in target year */
  bys `group_id': egen c_pop`target_year'_orig`pca_suffix' = total(pc`target_year'_pca_tot_p`pca_suffix')
  
  /* by constituency, calculate base year population in places with non-missing target year population */
  bys `group_id': egen c_pop`base_year'_found`target_year'`pca_suffix' = total(pc`base_year'_pca_tot_p`pca_suffix' * !mi(pc`target_year'_pca_tot_p`pca_suffix'))
  
  /* these two variables give us an estimate of population growth in this constituency */
  /* we use this to predict target (2001) population from the base (2011) population */
  /* the scaling factor (relative to 2011) is the con 2001 pop divided by the
     con 2011 pop * in the places where 2001 was non-missing* */
  /* same as dividing 2011 pop by the average growth rate from 2001-2011 in this con */
  replace pc`target_year'_pca_tot_p`pca_suffix' = (pc`base_year'_pca_tot_p`pca_suffix') * c_pop`target_year'_orig`pca_suffix' / c_pop`base_year'_found`target_year'`pca_suffix' if mi(pc`target_year'_pca_tot_p`pca_suffix') & mi(pc`target_year'_pca_tot_p)

  /* note the double missing requirement -- e.g. need to be missing
  tot_p_r AND tot_p in order to impute rural population -- otherwise
  this could be a town that became a village or vice versa */

}
end
/* *********** END program impute_shrid_pop ***************************************** */

/* open the shrid-con key, which is unique on shrids */
use $shrug/keys/shrug_con_key_2008, clear

/* limit the sample to places where we observe pc11 population */
get_shrug_var pc11_pca_tot_p 
drop if mi(pc11_pca_tot_p)

/* get shrid populations in all years and state names */
get_shrug_var pc11_pca_tot_p_r pc11_pca_tot_p_u pc01_pca_tot_p pc01_pca_tot_p_r pc01_pca_tot_p_u
get_shrug_key pc11_state_name

save $tmp/pre_impute_test, replace

/*********************/
/* start the testing */
/*********************/

/* write the output file header */
cap erase $tmp/impute_errors.csv
append_to_file using $tmp/impute_errors.csv, s(var,threshold,value)

/* loop over different drop thresholds */
qui forval threshold = .01(.01).30 { 
  noi di "Test: setting `threshold' observations to missing..."
  local threshstr = round(`threshold' * 100)

  use $tmp/pre_impute_test, clear

  /* set a random subset of pc01 populations to missing */
  foreach loc in "_r" "_u" {
    replace pc01_pca_tot_p = . if runiform() < `threshold'
  }

  /* impute missing all missing 2001 populations */
  gen pop_old = pc01_pca_tot_p 
  impute_shrid_pop, group_id(ac08_id) base_year(11) target_year(01) pca_suffix("")

  /* drop intermediate variables used in population imputation */
  keep shrid ac08_id pc* c_overlap_ratio c_misaligned_pop_share c_pop* pop_old
  drop c_pop*found*

  /* compare the result to the original file with no drops */
  ren pc01_pca_tot_p pop01_imputed

  /* merge in the SHRUG version of the data with no missing population */
  merge 1:1 shrid using $shrug/shrug-intermediate/con_pre_impute_08, keepusing(pc01_pca_tot_p)

  /* collapse to the constituency level */
  collapse (sum) pc01_pca_tot_p pop01_imputed, by(ac08_id)

  /* calculate mean error (with sign) and mean absolute deviation (without sign) */
  gen error = (pop01_imputed - pc01_pca_tot_p ) / pc01_pca_tot_p 
  gen mad = abs(pc01_pca_tot_p - pop01_imputed) / pc01_pca_tot_p

  /* store the mad and the error */
  sum error
  insert_into_file using $tmp/impute_errors.csv, key("error,`threshstr'") value(`r(mean)') format("%5.4f")
  sum mad
  insert_into_file using $tmp/impute_errors.csv, key("mad,`threshstr'") value(`r(mean)') format("%5.4f")
}
cat $tmp/impute_errors.csv

/******************/
/* review results */
/******************/
import delimited using $tmp/impute_errors.csv, clear

/* only plot errors up to threshold of 30 */
drop if threshold > 30

/* plot error rate as function of obs dropped */
scatter value threshold if var == "error", ytitle("Average error as share of population") xtitle("% of shrids dropped") xline(25, lpattern(-))
graphout impute_sim_error, pdf

scatter value threshold if var == "mad", ytitle("Mean absolute deviation as share of population") xtitle("% of shrids dropped") xline(25, lpattern(-))
graphout impute_sim_mad, pdf
