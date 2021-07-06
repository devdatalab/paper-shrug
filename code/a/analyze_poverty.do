/* GOAL: Create SHRUG rural poverty analysis dataset */

/* get rural poverty rate and consumption level */
use shrid secc_pov_rate_tend_rural using $shrug/data/shrug_secc, clear
ren secc_pov_rate_tend_rural secc_pov_rate_rural

/* get district and subdistrict ids */
merge 1:1 shrid using $shrug/keys/shrug_pc11_district_key, keepusing(pc11_state_id pc11_district_id) nogen keep(match master)
merge 1:m shrid using $shrug/keys/shrug_pc11_subdistrict_key, keepusing(pc11_subdistrict_id) nogen keep(match master)

/* drop shrids that cross subdistrict lines */
ddrop shrid

/* drop places where we can't measure the poverty rate */
drop if mi(secc_pov_rate_rural)

/* get population */
merge 1:1 shrid using $shrug/data/shrug_pc11_pca, keepusing(pc11_pca_tot_p) keep(match) nogen
drop if mi(pc11_pca_tot_p) | mi(pc11_district_id) | mi(pc11_subdistrict_id)

/* create dist and subdist groups and tags */
group pc11_state_id
group pc11_district_id
group pc11_district_id pc11_subdistrict_id 
tag pc11_district_id pc11_subdistrict_id 

/* generate average poverty rate in each district and subdistrict */
egen pov_rate_state = wtmean(secc_pov_rate_rural), by(sgroup) weight(pc11_pca_tot_p)
egen pov_rate_dist = wtmean(secc_pov_rate_rural), by(dgroup) weight(pc11_pca_tot_p)
egen pov_rate_subdist = wtmean(secc_pov_rate_rural), by(dsgroup) weight(pc11_pca_tot_p)
ren secc_pov_rate_rural pov_rate_vill

/* generate village poverty rank */
egen pov_rank_vill = rank(pov_rate_vill), unique
sum pov_rank_vill
replace pov_rank_vill = ((`r(max)' - pov_rank_vill + 1) / `r(max)') * 100

/* generate subdistrict poverty rank */
egen tmp = rank(pov_rate_subdist) if dstag, unique
bys dsgroup:  egen pov_rank_subdist = max(tmp)
sum pov_rank_subdist
replace pov_rank_subdist = ((`r(max)' - pov_rank_subdist + 1) / `r(max)') * 100
drop tmp

/* generate district poverty rank */
tag dgroup
egen tmp = rank(pov_rate_dist) if dtag, unique
bys dgroup:  egen pov_rank_dist = max(tmp)
sum pov_rank_dist
replace pov_rank_dist = ((`r(max)' - pov_rank_dist + 1) / `r(max)') * 100
drop tmp

/* generate state poverty rank */
tag sgroup
egen tmp = rank(pov_rate_state) if stag, unique
bys sgroup:  egen pov_rank_state = max(tmp)
sum pov_rank_state
replace pov_rank_state = ((`r(max)' - pov_rank_state + 1) / `r(max)') * 100
drop tmp

/* calculate total population in each state / district / subdistrict */
bys sgroup: egen pop_state = total(pc11_pca_tot_p)
bys dgroup: egen pop_dist = total(pc11_pca_tot_p)
bys dsgroup: egen pop_subdist = total(pc11_pca_tot_p)
ren pc11_pca_tot_p pop_vill

/* store total dataset population in memory */
sum pop_vill
global total_pop = `r(N)' * `r(mean)'

/* rank is correlated with population. If we want the bottom 25% of people based on village, that is not rank < 25, we need to calculate actual percentiles with a running sum */
sort pov_rank_vill
gen running_pop_vill = sum(pop_vill)
gen rank_vill = running_pop_vill / $total_pop * 100

/* repeat for state */
sort pov_rank_state
gen running_pop_state = sum(pop_state) if stag
gen tmp = running_pop_state / $total_pop * 100
bys sgroup: egen rank_state = max(tmp)
drop tmp

/* repeat for dist */
sort pov_rank_dist
gen running_pop_dist = sum(pop_dist) if dtag
gen tmp = running_pop_dist / $total_pop * 100
bys dgroup: egen rank_dist = max(tmp)
drop tmp

/* repeat for subdist */
sort pov_rank_subdist
gen running_pop_subdist = sum(pop_subdist) if dstag
gen tmp = running_pop_subdist / $total_pop * 100
bys dsgroup: egen rank_subdist = max(tmp)
drop tmp

save $tmp/secc_pov_rates_ranks, replace

/* create a tagged population that we can collapse on at different levels */
gen pop_tag_vill = pop_vill
gen pop_tag_state = pop_state if stag
gen pop_tag_dist = pop_dist if dtag
gen pop_tag_subdist = pop_subdist if dstag

/* collapse to granular percentile bins for quicker graphing */
foreach v in vill dist subdist state {
  preserve

  /* create an integer rank to collapse on */
  gen rank_`v'_int = floor(rank_`v') + 1
  replace rank_`v'_int = 100 if rank_`v'_int == 101

  /* collapse to integer ranks */
  collapse (rawsum) pop_tag_`v' (mean) pov_rate_`v' [aw=pop_tag_`v'], by(rank_`v'_int)
  ren rank_`v'_int rank
  save $tmp/collapsed_`v', replace
  restore
}

use $tmp/collapsed_vill, clear
merge 1:1 rank using $tmp/collapsed_state, nogen
merge 1:1 rank using $tmp/collapsed_dist, nogen
merge 1:1 rank using $tmp/collapsed_subdist, nogen
ren pop_tag* pop*

/* fill in state poverty rates to get a step function */
sort rank
replace pov_rate_state = pov_rate_state[_n-1] if mi(pov_rate_state)

save $tmp/pov_ranks, replace

/************/
/* ANALYSIS */
/************/
use $tmp/pov_ranks, clear

/* graph share poor at each rank */
sort rank
twoway ///
    (line pov_rate_vill    rank, lwidth(medthick)) ///
    (line pov_rate_subdist rank, lwidth(medthick) lpattern(-)) ///
    (line pov_rate_dist    rank, lwidth(medthick) lpattern(.-)) ///
    (line pov_rate_state    rank, lwidth(medthick) lpattern(.)) ///
    , xlabel(0(20)100) ylabel(0(.2).8) legend(region(lcolor(black)) lab(1 "Village") lab(2 "Subdistrict") lab(3 "District") lab(4 "State") ring(0) pos(7)) ///
    xtitle("Location poverty rank") ytitle("Poverty rate at this location percentile")
graphout pov_rate_perc_loc, pdf

/* describe mean poverty rate at 5th percentile village, subdist, district */
/* [actually this is wrong b/c you don't have the populations] */
sum pov_rate_vill pov_rate_subdist pov_rate_dist pov_rate_state if rank == 5

/* count population in the bottom 25% of places and top 25% of places  */
foreach loc in vill dist subdist state {
  local loclongvill village
  local loclongsubdist subdistrict
  local loclongdist district
  local loclongstate state
  
  qui sum pop_`loc' if rank <= 25
  local c_pop_poor`loc' = `r(N)' * `r(mean)'
  qui sum pop_`loc' if rank > 25
  local c_pop_rich`loc' = `r(N)' * `r(mean)'
  
  /* count poor people in the same places */
  qui sum pov_rate_`loc' [aw=pop_`loc'] if rank <= 25
  local c_poorpop_poor`loc' = `c_pop_poor`loc'' * `r(mean)'
  qui sum pov_rate_`loc' [aw=pop_`loc'] if rank > 25
  local c_poorpop_rich`loc' = `c_pop_rich`loc'' * `r(mean)'
}

/* report population stats */
foreach loc in vill subdist dist state {
  di %15.0fc (`c_pop_poor`loc'') " people live in bottom 25% `loclong`loc''s, or " %5.2f (`c_pop_poor`loc''/(`c_pop_poor`loc''+`c_pop_rich`loc'')*100) "% of the rural population."
}

/* report poverty stats */
foreach loc in vill subdist dist state {
  di "Targeting the 25% poorest `loclong`loc''s will cover " %5.2f (`c_poorpop_poor`loc''/(`c_poorpop_poor`loc''+`c_poorpop_rich`loc'')*100) "% of the rural poor."
}

