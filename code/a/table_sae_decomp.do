
/* produce a table comparing mean values of consumption index componetns in IHDS and SECC,
   and the effect they have on the mean consumption difference. */

global f $tmp/sae_decomp.csv
global secc_means $out/secc_asset_means.csv

local ihds_urban_vars ac computer exc_latrine kitchen wash_mac refrig num_room wall_mat_grass wall_mat_mud wall_mat_plastic wall_mat_wood wall_mat_brick wall_mat_gi wall_mat_stone wall_mat_concrete roof_mat_grass roof_mat_tile roof_mat_slate roof_mat_plastic roof_mat_gi roof_mat_brick roof_mat_stone roof_mat_concrete house_own_owned vehicle_two vehicle_four phone_landline_only phone_mobile_only phone_both
local ihds_rural_vars land_own kisan_cc refrig num_room wall_mat_grass wall_mat_mud wall_mat_plastic wall_mat_wood wall_mat_brick wall_mat_gi wall_mat_stone wall_mat_concrete roof_mat_grass roof_mat_tile roof_mat_slate roof_mat_plastic roof_mat_gi roof_mat_brick roof_mat_stone roof_mat_concrete house_own_owned vehicle_two vehicle_four phone_landline_only phone_mobile_only phone_both high_inc_5000_10000 high_inc_more_10000

/* loop over sectors */
foreach sector in urban rural {

  /* copy code from consumption imputation to read the imputation coefficients one line at a time */
  cap file close fh
  file open fh using $secc/consumption/ihds_cons_coefs_`sector'.csv, read text
  
  /* read the header row */
  file read fh line
  local varlist = subinstr("`line'", ",", " ", .)
  cap file close fh
  
  /* get the variable list without the constant */
  local tmp constant
  local imputevars: list varlist - tmp
  
  /********************************************/
  /* open IHDS and prepare for mean reporting */
  /********************************************/
  use $ihds/sae/all_ihds_data, clear
  ren WT wt
  
  if "`sector'" == "urban" keep if URBAN2011 == 1
  if "`sector'" == "rural" keep if URBAN2011 == 0
  
  /* verify no missings are marked negative */
  sum `ihds_`sector'_vars'
  
  /* loop over each IHDS variable */
  foreach v in `ihds_`sector'_vars' {
  
    /* store the weighted mean in a local and a file */
    qui sum `v' [aw=wt], d
    local ihds_`sector'_`v' = `r(mean)'
    insert_into_file using $f, key(ihds_`sector'_`v') value(`r(mean)') format(%5.2f)
  }

  /* convert estimates to a stata file */
  /* note: this is in the sector loop, but b/c we're using insert_into_file above,
           the first pass save is just pointless and the second saves both rural
           and urban parts. */
  import delimited using $f, clear
  ren (v1 v2) (varname mean)
  save $tmp/ihds_ests, replace

  /************************/
  /* calculate SECC means */
  /************************/
  
  /* We don't have collapsed data, so need to do this state by state */
  if "`sector'" == "urban" {
    local path $secc/parsed_draft/dta/urban
    local hhkey draftlistid house_no
    local memkey draftlistid house_no sn
  }
  
  if "`sector'" == "rural" {
    local path $secc/mord/dta/rural
    local hhkey mord_hh_id
    local memkey mord_member_id
  }
  
  /* get the list of state files */
  /* loop over each SECC state */
  local filelist: dir "`path'" files "*_household_clean.dta"
  foreach file in `filelist' {
  
    /* get state name */
    local state_name = substr("`file'", 1, strpos("`file'", "_") - 1)
  
    /* open the household data */
    use `path'/`state_name'_household_clean, clear
  
    /* copy variable creation from imputation program */
    /* generate dummy variables for each wall materials */
    gen wall_mat_grass    = wall_mat == 1 if !mi(wall_mat)
    gen wall_mat_mud      = wall_mat == 3 if !mi(wall_mat)
    gen wall_mat_plastic  = wall_mat == 2 if !mi(wall_mat)
    gen wall_mat_wood     = wall_mat == 4 if !mi(wall_mat)
    gen wall_mat_brick    = wall_mat == 8 if !mi(wall_mat)
    gen wall_mat_gi       = wall_mat == 7 if !mi(wall_mat)
    gen wall_mat_stone    = wall_mat == 5 if !mi(wall_mat)
    replace wall_mat_stone = 1 if wall_mat == 6
    gen wall_mat_concrete = wall_mat == 9 if !mi(wall_mat)
  
    /* generate dummy variables for each roof material */
    gen roof_mat_grass     = roof_mat == 1 if !mi(roof_mat)
    gen roof_mat_tile      = roof_mat == 3 if !mi(roof_mat)
    replace roof_mat_tile = 1 if roof_mat == 4
    gen roof_mat_slate     = roof_mat == 7 if !mi(roof_mat)
    gen roof_mat_plastic   = roof_mat == 2 if !mi(roof_mat)
    gen roof_mat_gi        = roof_mat == 8 if !mi(roof_mat)
    gen roof_mat_brick     = roof_mat == 5 if !mi(roof_mat)
    gen roof_mat_stone     = roof_mat == 6 if !mi(roof_mat)
    gen roof_mat_concrete  = roof_mat == 9 if !mi(roof_mat)
  
    /* generate dummy variables for each house ownership type */
    gen house_own_owned = house_own == 1 if !mi(house_own)
  
    /* generate dummy variables for each vehicle ownership type */
    gen vehicle_two  = vehicle == 1 if !mi(vehicle)
    gen vehicle_four = vehicle == 3 if !mi(vehicle)
  
    /* generate dummy variables for each phone ownership type */
    gen phone_landline_only = phone == 1 if !mi(phone)
    gen phone_mobile_only   = phone == 2 if !mi(phone)
    gen phone_both          = phone == 3 if !mi(phone)
  
    /* generate dummy variables for computer */
    if "`sector'" == "urban" {
      gen computer = 0 if !mi(comp)
      replace computer = 1 if comp == 1 | comp == 2
    }
  
    /* generate dummy variables for high income */
    if "`sector'" == "rural" {
      gen high_inc_less_5000 = high_inc == 1 if !mi(high_inc)
      gen high_inc_5000_10000 = high_inc == 2 if !mi(high_inc)
      gen high_inc_more_10000 = high_inc == 3 if !mi(high_inc)
    }
  
    /* loop over imputation vars */
    foreach v in `imputevars' {
      
      /* store the state mean in an output file */
      qui sum `v'
      if (`r(N)' > 0) {
  
        /* note we use a different file because it is still split by state */
        insert_into_file using $secc_means, key(`state_name',secc_`sector'_`v') value(`r(mean)') format(%5.2f)
      }
    }
  }
}

/* prepare coefficients files to join with estimates */
foreach sector in rural urban {
  import delimited using $secc/consumption/ihds_cons_coefs_`sector'.csv, clear
  drop constant
  keep in 1
  
  /* prepare and execute a reshape */
  ren * coef*
  gen index = 1
  reshape long coef, j(varname) i(index) string
  drop index
  gen sector = "`sector'"  
  save $tmp/cons_coefs_`sector', replace
}
append using $tmp/cons_coefs_rural
save $tmp/cons_coefs, replace

/* combine all the SECC numbers into a population-weighted */
import delimited using $secc_means, clear

ren v1 state
ren v2 varname
ren v3 mean

/* fix the state name */
ren state pc11_state_name
fix_spelling pc11_state_name, src($keys/pc11_state_key) replace

/* get state ids */
get_state_ids, y(11)
replace pc11_state_id = "36" if pc11_state_name == "telangana"

/* get state populations */
merge m:1 pc11_state_id using $pc11/pc11_pca_state_clean, keepusing(pc11_pca_tot_p)
replace pc11_pca_tot_p = 49600000 if pc11_state_name == "andhra pradesh"
replace pc11_pca_tot_p = 35000000 if pc11_state_name == "telangana"
sum pc11_pca_tot_p

/* collapse across states */
collapse (mean) mean [aw=pc11_pca_tot_p ], by(varname)

/* format the mean for the table */
format mean %5.2f

/* combine with IHDS estimates */
append using $tmp/ihds_ests

/* reorder vars so we can merge to the coefficients */
gen source = substr(varname, 1, 4)
gen sector = substr(varname, 6, 5)
replace varname = substr(varname, 12, .)

/* save estimates */
save $tmp/all_ests, replace

merge m:1 varname sector using $tmp/cons_coefs, nogen

/* reshape wide on dataset so this looks like the output table we want */
reshape wide mean, j(source) i(varname sector) string
ren mean* mean_*
gen diff = mean_secc - mean_ihds
gen delta = diff * coef

/* get var labels */
preserve
import delimited using $shcode/a/cons_varlabels.csv, clear delimiters(",")
replace v2 = v2 + "," + v3 if !mi(v3)
drop v3
ren v1 varname
ren v2 label
save $tmp/varlabels, replace
restore

merge m:1 varname using $tmp/varlabels, nogen

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

