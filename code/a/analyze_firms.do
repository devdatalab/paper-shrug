/********************************************************************/
/* GOAL: study the distribution of manufacturing and services firms */
/* across villages within the country and within each district      */
/********************************************************************/

/************************************************************/
/* program urank : Rank a location, weighting by population */
/* i.e. rank on the varlist, but gaps between ranks depend on location size,
so 25% of people live in places with rank below 25. */
/* debugging locals:
     local varlist emp_manuf
     local gen manuf_rank
     local by sdgroup
*/
/************************************************************/

cap prog drop urank
prog def urank
  syntax varlist [if], [gen(string) by(string)]
  tokenize `varlist'
  capdrop __max __by __cum_pop __total_pop

  qui {
    /* point `gen' to the variable to generate */
    if mi("`gen'") local gen `1'_rank

    /* if by() is not specified, create a single group, so we can assume `by' exists  */
    if mi("`by'") {
      gen __by = 1 `if'
      local by __by
    }
    
    /* sort by the rank variable within by groups  */
    sort `by' `1'

    /* calculate the cumulative population in each by group */
    by `by': gen __cum_pop = sum(pc11_pca_tot_p) `if'

    /* calculate the total population in each by group */
    bys `by': egen __total_pop = max(__cum_pop) `if'

    /* calculate the rank within location group */
    gen `gen' = (1 - (__cum_pop / __total_pop)) * 100 `if'
    
    capdrop __max __by __cum_pop __total_pop
  }
end
/* *********** END program urank********* */

/**********************************************************************************/
/* program rbin : standard rank bin graph */
/* debugging info:
rbin ln_manuf_pc if sector == 2, title("Manufacturing Jobs Across Villages") ylabel(0(2)8) n(manuf_pc_v) rerank ytitle("Manufacturing jobs per 1000 people") xtitle("Percentile rank (`village_count' villages)")
local varlist ln_manuf_pc
local if if sector == 1
local title title("Manufacturing Jobs Across Towns")
local ylabel ylabel(0(2)8)
local n manuf_pc_t
local rerank rerank
local yitle ytitle("Manufacturing jobs per 1000 people")
local xtitle xtitle("Percentile rank (8000 towns)")
*/
/***********************************************************************************/
cap prog drop rbin
prog def rbin
  syntax varlist [if], n(string) [by(passthru) title(passthru) control(passthru) yscale(passthru) xlabel(passthru) ylabel(passthru) xtitle(passthru) ytitle(passthru) xscale(passthru) rerank]
  tokenize `varlist'

  /* regenerate ranks if called for */
  if !mi("`rerank'") {
    urank `1' `if', gen(__rank) `by'
    local 2 __rank
  }

  /* create uniform xbins */
  egen __xcut = cut(`2'), at(0(1)100)
  replace __xcut = __xcut + 1
  
  binscatter `1' `2' `if', linetype(none) name(`n', replace) ///
      `control' `xscale' `yscale' `xlabel' `ylabel' `xtitle' `ytitle' `title' xq(__xcut)
  graphout `n'
  capdrop __rank __xcut
end
/* *********** END program rbin ***************************************** */


/* prepare analysis dataset */

/* get pop, manuf and service employment from shrug  */
use $shrug/data/shrug_ec13, clear
keep ec13_emp_manuf ec13_emp_serv shrid ec13_sector

/* get population and district ids */
merge 1:1 shrid using $shrug/data/shrug_pc11_pca, keepusing(pc11_pca_tot_p) keep(match) nogen
merge 1:1 shrid using $shrug/keys/shrug_pc11_district_key, keepusing(pc11_state_id pc11_district_id) nogen keep(match master)

/* drop missings */
drop if mi(pc11_pca_tot_p)
drop if mi(ec13_emp_manuf) | mi(ec13_emp_serv)
drop if mi(pc11_state_id) | mi(pc11_district_id)

/* drop weirdos -- 1 million people living in villages < 100 people */
drop if pc11_pca_tot_p < 100

/* create jobs per 1000 ppl vars */
gen manuf_pc = ec13_emp_manuf / pc11_pca_tot_p * 1000
gen serv_pc = ec13_emp_serv / pc11_pca_tot_p * 1000

/* create log vars of interest */
gen ln_pop = ln(pc11_pca_tot_p)
gen ln_manuf = ln(ec13_emp_manuf + 1)
gen ln_serv = ln(ec13_emp_serv + 1)
gen ln_manuf_pc = ln(manuf_pc + 1)
gen ln_serv_pc = ln(serv_pc + 1)

/* shorten services varnames */
ren *services* *serv*
ren ec13_* *

save $tmp/shr, replace

/* begin analysis */
use $tmp/shr, clear
count if !mi(ln_manuf_pc) & sector == 1
local town_count `r(N)'
count if !mi(ln_manuf_pc) & sector == 2
local village_count `r(N)'
rbin ln_manuf_pc if sector == 1, title("Manufacturing Jobs Across Towns") ylabel(0(2)8) n(manuf_pc_t) rerank ytitle("Manufacturing jobs per 1000 people") xtitle("Percentile rank (`town_count' towns)") 
rbin ln_manuf_pc if sector == 2, title("Manufacturing Jobs Across Villages") ylabel(0(2)8) n(manuf_pc_v) rerank ytitle("Manufacturing jobs per 1000 people") xtitle("Percentile rank (`village_count' villages)")

rbin ln_serv_pc if sector == 1, title("Services Jobs Across Towns") ylabel(0(2)8) n(serv_pc_t) rerank ytitle("Services jobs per 1000 people") xtitle("Percentile rank (`town_count' towns)") 
rbin ln_serv_pc if sector == 2, title("Services Jobs Across Villages") ylabel(0(2)8) n(serv_pc_v) rerank ytitle("Services jobs per 1000 people") xtitle("Percentile rank (`village_count' villages)")

graph combine manuf_pc_t manuf_pc_v serv_pc_t serv_pc_v
graphout granular_job_distribution, pdf

/* now repeat within district */
group pc11_state_id pc11_district_id 
rbin ln_manuf_pc if sector == 1, by(sdgroup) title("Manufacturing Jobs Across Towns") ylabel(0(2)8) n(manuf_pc_t) rerank ytitle("Manufacturing jobs per 1000 people") xtitle("Percentile rank (7200 towns)") 
rbin ln_manuf_pc if sector == 2, by(sdgroup) title("Manufacturing Jobs Across Villages") ylabel(0(2)8) n(manuf_pc_v) rerank ytitle("Manufacturing jobs per 1000 people") xtitle("Percentile rank (534000 villages)")

rbin ln_serv_pc if sector == 1, by(sdgroup) title("Services Jobs Across Towns") ylabel(0(2)8) n(serv_pc_t) rerank ytitle("Services jobs per 1000 people") xtitle("Percentile rank (7200 towns)") 
rbin ln_serv_pc if sector == 2, by(sdgroup) title("Services Jobs Across Villages") ylabel(0(2)8) n(serv_pc_v) rerank ytitle("Services jobs per 1000 people") xtitle("Percentile rank (534000 villages)")

graph combine manuf_pc_t manuf_pc_v serv_pc_t serv_pc_v
graphout granular_job_distribution_dist, pdf


/* calculate interquartile slope of this function */
cap prog drop get_slope
prog def get_slope, rclass
  syntax varlist [if], [passthru by(passthru) gen(string)]

  capdrop __rank
  tokenize `varlist'
  urank `1' `if', gen(__rank) `by'

  noi quireg `1' __rank if inrange(__rank, 10, 90)
  return local b = `r(b)'
  if !mi("`gen'") {
    ren __rank `gen'
  }
  else {
    capdrop __rank
  }
end

use $tmp/shr, clear

group pc11_state_id pc11_district_id

/* review/store mean vs. median and other stats */
global f $out/firm_variation_stats.csv
cap erase $f

foreach s in manuf serv {
  foreach loc in 1 2 {
    local locname1 town
    local locname2 village

    local rankvar rank_`s'_`locname`loc''
    qui get_slope ln_`s'_pc if sector == `loc', gen(`rankvar')
    local b: di %4.3f `r(b)'
    qui get_slope ln_`s'_pc if sector == `loc', by(sdgroup)
    local bd: di %4.3f `r(b)'
    
    /* get the mean */
    qui sum `s'_pc [aw=pc11_pca_tot_p] if sector == `loc', d
    local mean: di %2.1f `r(mean)'

    /* get the 20th, 50th, 80th percentiles */
    foreach i in 20 50 80 {
      qui sum `s'_pc if inrange(`rankvar', `i' - .5, `i' + .5)
      local p`i': di %2.1f `r(mean)'
    }
    
    di %30s "`locname`loc''-`s'.... p20,50,80: " ///
        %2.1f `p20' ", " ///
        %2.1f `p50' ", " ///
        %2.1f `p80'      ///
        ",  mean: " %2.1f `mean' ///
        ", slope: " %4.3f (`b')  ///
        ", within-dist slope: " %4.3f (`bd')

    /* append stats to an output file */
    foreach v in p20 p50 p80 {
      append_to_file using $f, s("`locname`loc''_`s'_`v',``v''")
    }
    append_to_file using $f, s("`locname`loc''_`s'_mean,`mean'")
    append_to_file using $f, s("`locname`loc''_`s'_beta,`b'")
    append_to_file using $f, s("`locname`loc''_`s'_betadist,`bd'")
  }
}
cat $f

table_from_tpl, t($shcode/a/firm_variation_table.tpl) r($f) o($out/emp_concentration.tex)
