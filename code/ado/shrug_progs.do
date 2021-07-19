qui {

/*********************************************************************************/
  /* program rebuild_shrug_lists : Rebuild variable and key lists for the SHRUG      */
  /***********************************************************************************/
  /* NOTE: it is essential for each variable to have a leading space so that get_shrug_var and get_shrug_key work properly! */
  cap prog drop rebuild_shrug_lists
  prog def rebuild_shrug_lists
    {
        di "Creating the list of SHRUG variables for get_shrug_var()..."
        preserve
        /* create a list of all the shrug vars */
        qui {
            global  f ~/shrug/output/shrug_varlist.txt
            cap erase $f
            foreach file in ec05 ec13 ec90 ec98 pc01_pca pc01_td pc01_vd pc11_pca pc11_td pc11_vd pc91_pca pc91_td pc91_vd secc nl_wide vcf_wide spatial pmgsy {
                use $shrug/data/shrug_`file', clear
                ds
                append_to_file using $f, s($shrug/data/shrug_`file'.dta, `r(varlist)')
              }
          }

        /* create a list of all the variables in the shrug keys */
        qui {
            global  f ~/shrug/output/shrug_keylist.txt
            cap erase $f
            cap erase
            foreach file in ec05_district ec05r ec05_state ec05_subdistrict ec05u ec13_district ec13r ec13_state ec13_subdistrict ec13u ec90_district ec90r ec90_state ec90_subdistrict ec90u ec98_district ec98r ec98_state ec98_subdistrict ec98u pc01_district pc01r pc01_state pc01_subdistrict pc01u pc11_district pc11r pc11_state pc11_subdistrict pc11u pc91_district pc91r pc91_state pc91_subdistrict pc91u {
                use $shrug/keys/shrug_`file'_key, clear
                ds
                append_to_file using $f, s($shrug/keys/shrug_`file'_key.dta, `r(varlist)')
              }
            use $shrug/keys/shrug_names, clear
            ds
            append_to_file using $f, s($shrug/keys/shrug_names.dta, `r(varlist)')
          }
        restore
      }
    end
  /* *********** END program rebuild_shrug_lists ***************************************** */

/************************************************************************************/
/* program clear_shrug_outliers : This programs drops or flags outliers in the Shrug */
/*
- note that we don't drop, but rather set vars to missing. Because an EC outlier may
  be fine in the PC or other component datasets.

*/

/************************************************************************************/
cap prog drop clear_shrug_outliers
prog def clear_shrug_outliers
{
  
  /*

  Cut outliers based on two things:

  1. A list of shrid-level indicators in $shrug/intermediate, for EC,
     PCA, VDTD shrids that appear to have wonky data. A bad EC90 obs gets
     all EC90 fields set to missing.

  2. Individual TD / VD fields are dropped or winsorized. e.g. we want to
     restrict insane values for number of roads per town, schools per village,
     etc..
  
  */
  qui {
    /* merge data from generate_shrug_outliers.do */
    merge 1:1 shrid using $shrug/data/shrug_outliers, keep(master match) nogen
    
    /* reset fields to missing based on each outlier flag */
  
    /* Economic Censuses */
    foreach y in 90 98 05 13 {
  
      /* if emp_all exists for this year, manage EC outliers for this year */
      cap confirm variable ec`y'_emp_all
      if !_rc {
        foreach v of varlist ec`y'* {
          replace `v' = . if ec`y'_outlier == 1
        }
      }
    }
  
    /* PCAs -- currently operating on joint urban + rural */
    foreach y in 91 01 11 {
  
      /* if pca_tot_p exists for this year, manage PCA outliers for this year */
      cap confirm variable pc`y'_pca_tot_p
      if !_rc {
        foreach v of varlist pc`y'_pca* {
          replace `v' = . if pca`y'_outlier == 1
        }
      }
    }
  
  
  }
  /* VDs and TDs -- nothing here yet -- we can't count on pc01_vd_t_p being present or useful for VD to be useful. We also don't want to cut one VD field
   just because another is missing. So probably need to do something specific here on a field by field basis. For sum fields only. */

  /* FIX / TO DO:
    - winsorize / set to missing unreasonable numbers of VD/TD count fields.

    - for shrid analysis, we also want to drop villages with population
      outside of (100, 5000), maybe big cities. Where to do this?

  */
  
}
end
/* *********** END program clear_shrug_outliers ***************************************** */

/**************************************************************************************/
/* program combine_urban_rural_vals : add up urban and rural pca/ec variable values   */
/*************************************************************************************/

/* there are town-village joint shrug that has both urban and rural values (e.g.
pc91_pca_tot_p for urban and rural) and we would like to summarize these values
into one combined value. we can run the program for pca and ec variables so that rural and urban
pca/ec variable values are combined as shrug pca/ec variable value. note that we have to
separate urban and rural variables before running the program (i.e. change the prefix
from pc11 to pc11u or pc11r

SYNTAX:
combine_urban_rural_vals, year(pc11)
*/

cap prog drop combine_urban_rural_vals
prog def combine_urban_rural_vals
{

  /* define syntax */
  syntax, Year(string)

  /* store the list of variables for pca and ec */
  if strpos("`year'", "pc") qui d `year'u_pca* `year'r_pca*, varl
  if strpos("`year'", "ec") qui d `year'u_* `year'r_*, varl

  /* set local macro to 1 */
  local first = 1

  /* empty local macro */
  local `year'_varlist

  /* store variable list into local macro */
  local varlist `r(varlist)' 
  
  /* loop over the list of variables */
  foreach var in `varlist' {
    
    /* store the variable name that removes u or r from prefix */
    if strpos("`var'", "`year'u") local varname = subinstr("`var'", "`year'u", "`year'", .)
    if strpos("`var'", "`year'r") local varname = subinstr("`var'", "`year'r", "`year'", .)

    /* empty local macro */
    local `varname'_s
  }

  /* loop over the list of variables */
  foreach var in `varlist' {
    
    /* store the variable name that removes u or r from prefix */
    if strpos("`var'", "`year'u") local varname = subinstr("`var'", "`year'u", "`year'", .)
    if strpos("`var'", "`year'r") local varname = subinstr("`var'", "`year'r", "`year'", .)

    /* store the variable name with u or r prefix */
    local `varname'_s ``varname'_s' `var'

    /* for the first variable in the list */
    if "`first'" == "1" {

      /* store the variable names without u or r prefix into local macro */
      local `year'_varlist ``year'_varlist' `varname'
    }

    /* for the non-first variables */
    else {

      /* set count local macro to 0 */
      local count = 0

      /* loop over the list of variable names without u or r prefix */
      foreach x in ``year'_varlist' {

        /* if the variable name exists in the list */
        if "`varname'" == "`x'" local count = `count' + 1
      }

      /* store the variable names without u or r prefix into local macro if not in the macro yet */
      if "`count'" == "0" local `year'_varlist ``year'_varlist' `varname'
    }

    /* update first local macro - it's not 1 anymore */
    local first = `first' + 1
  }

  /* loop over the variable names without u or r prefix */
  foreach var in ``year'_varlist' {

    /* store the number of variables stored into local macro */
    local n: word count ``var'_s'

    /* retain urban and rural variable name */
    local urban_var = subinstr("`var'", "`year'", "`year'u", 1)
    local rural_var = subinstr("`var'", "`year'", "`year'r", 1)

    /* if only urban/rural variable is stored, rename urban/rural variable */
    if `n' == 1 & strpos("``var'_s'", "`year'u") ren `urban_var' `var'
    if `n' == 1 & strpos("``var'_s'", "`year'r") ren `rural_var' `var'

    /* if both urban and rural variables are stored */
    if `n' == 2 {

      /* combine urban and rural values - both missing must be missing */
      egen `var' = rowtotal(`urban_var' `rural_var')
      qui replace `var' = . if mi(`urban_var') & mi(`rural_var')

      /* store label from urban variable and label the combined variable */
      local label: var label `urban_var'
      label var `var' "`label'"

      /* drop urban/rural variables */
      drop `urban_var' `rural_var'
    }
  }
}
end
/* *********** END program combine_urban_rural_vals ***************************************** */

/**********************************************************************************/
/* program label_shrug_ec_vars: label ec variables                                      */
/***********************************************************************************/

cap prog drop label_shrug_ec_vars
prog def label_shrug_ec_vars
{
  foreach year in 90 98 05 13 {

    /* label variable */
    cap label var ec`year'_emp_all "total employment"
    cap label var ec`year'_emp_child "child employment"
    cap label var ec`year'_emp_m "male employment"
    cap label var ec`year'_emp_adult_m "male adult employment"
    cap label var ec`year'_emp_child_m "male child employment"
    cap label var ec`year'_emp_f "female employment"
    cap label var ec`year'_emp_adult_f "female adult employment"
    cap label var ec`year'_emp_child_f "female child employment"
    cap label var ec`year'_emp_hired "employment of hired workers"
    cap label var ec`year'_emp_hired_m "employment of male hired workers"
    cap label var ec`year'_emp_hired_f "employment of female hired workers"
    cap label var ec`year'_emp_size20 "employment in firms with 20+ employees"
    cap label var ec`year'_emp_size50 "employment in firms with 50+ employees"
    cap label var ec`year'_emp_size100 "employment in firms with 100+ employees"
    cap label var ec`year'_emp_size100 "employment in firms with 100+ employees"
    cap label var ec`year'_emp_gov "employment in government owned firms"
    cap label var ec`year'_emp_firm_informal "employment in non-regulated firms"
    cap label var ec`year'_emp_non "employment of non-hired workers"
    cap label var ec`year'_emp_unhired_m "employment of male non-hired workers"
    cap label var ec`year'_emp_unhired_f "employment of female non-hired workers"
    cap label var ec`year'_emp_pub "employment in public firms"
    cap label var ec`year'_emp_priv "employment in private firms"
    cap label var ec`year'_count_all "number of firms"
    cap label var ec`year'_count_size_small "number of firms with 0-19 employees"
    cap label var ec`year'_count_size_medium "number of firms with 20-49 employees"
    cap label var ec`year'_count_size_medlarge "number of firms with 50-99 employees"
    cap label var ec`year'_count_size_large "number of firms with 100+ employees"
    cap label var ec`year'_count_gov "number of government owned firms"
    cap label var ec`year'_count_firm_informal "number of non-regulated firms"
    cap label var ec`year'_count_emp_informal "number of firms with non-hired workers"
    cap label var ec`year'_count_family "number of firms with all non-hired workers from family"
    cap label var ec`year'_count_m "number of firms with male employees"
    cap label var ec`year'_count_f "number of firms with female employees"
    cap label var ec`year'_count_pub "number of public firms"
    cap label var ec`year'_count_priv "number of private firms"
    cap label var ec`year'_emp_pub_banks "employment in public sector banks"
    foreach nic in 7 8 9 12 13 14 15 16 18 {
      cap label var ec`year'_emp_pub_NIC`nic' "employment in public sector mines, NIC`nic'"
    }
    forvalue nic = 1/217 {
      cap label var ec`year'_emp_NIC`nic' "employment in firms, NIC`nic'"
    }
    cap label var ec`year'_emp_all_mean "mean of total employment"
    foreach y in emp count {
      if "`y'" == "emp" local employ employment in firms
      if "`y'" == "count" local employ number of firms
      cap label var ec`year'_`y'_power_animal "`employ' with animal power"
      cap label var ec`year'_`y'_power_coal "`employ' with coal power"
      cap label var ec`year'_`y'_power_elec "`employ' with electric power"
      cap label var ec`year'_`y'_power_gas "`employ' with gas power"
      cap label var ec`year'_`y'_power_non_convent "`employ' with non-conventional power"
      cap label var ec`year'_`y'_power_none "`employ' without any power"
      cap label var ec`year'_`y'_power_other "`employ' with other power"
      cap label var ec`year'_`y'_power_petrol "`employ' with petrol power"
      cap label var ec`year'_`y'_power_wood "`employ' with wood power"
      cap label var ec`year'_`y'_st "`employ' with ST owner"
      cap label var ec`year'_`y'_sc "`employ' with SC owner"
      cap label var ec`year'_`y'_gen "`employ' with general class owner"
      cap label var ec`year'_`y'_obc "`employ' with OBC owner"
      cap label var ec`year'_`y'_hindu "`employ' with Hindu owner"
      cap label var ec`year'_`y'_muslim "`employ' with Muslim owner"
      cap label var ec`year'_`y'_christ "`employ' with Christian owner"
      cap label var ec`year'_`y'_social_other "`employ' with owner from other social group"
      cap label var ec`year'_`y'_m_owner "`employ' with male owner"
      cap label var ec`year'_`y'_f_owner "`employ' with female owner"
      cap label var ec`year'_`y'_fin_bank "`employ' with financial source from bank"
      cap label var ec`year'_`y'_fin_gov "`employ' with financial source from government"
      cap label var ec`year'_`y'_fin_informal "`employ' with informal financial source"
      cap label var ec`year'_`y'_fin_none_self "`employ' with self financing"
      cap label var ec`year'_`y'_fin_other "`employ' with financial source from other"
      forvalue i = 1/23 {
        if "`i'" == "1" local act agricultural
        if "`i'" == "2" local act livestock
        if "`i'" == "3" local act forestry and loggin
        if "`i'" == "4" local act finishing and aquafarming
        if "`i'" == "5" local act mining and quarrying 
        if "`i'" == "6" local act manufacturing
        if "`i'" == "7" local act electricity, gas, steam, and air conditioning supply
        if "`i'" == "8" local act water supply, sewerage, and waste management
        if "`i'" == "9" local act construction
        if "`i'" == "10" local act motor vehicles and motor cyles whole sale trade, retail trade, and repair
        if "`i'" == "11" local act whole sale trade
        if "`i'" == "12" local act retail trade
        if "`i'" == "13" local act transportation and storage
        if "`i'" == "14" local act accommodation and food service
        if "`i'" == "15" local act information and communication
        if "`i'" == "16" local act financial and insurance
        if "`i'" == "17" local act real estate
        if "`i'" == "18" local act professional, scientific, and technical
        if "`i'" == "19" local act administrative and support service
        if "`i'" == "20" local act education
        if "`i'" == "21" local act human health and social work
        if "`i'" == "22" local act arts, entertainment, sports, and amusement
        if "`i'" == "23" local act other service
        cap label var ec`year'_`y'_act`i' "`employ' with `act' activity"
        foreach x in sc st obc gen {
          local owner = upper("`x'")
          if "`x'" != "gen" cap label var ec`year'_`y'_act`i'_`x' "`employ' with `act' activity and `owner' owner"
          if "`x'" == "gen" cap label var ec`year'_`y'_act`i'_`x' "`employ' with `act' activity and general class owner"
        }
      }
      cap label var ec`year'_`y'_act99 "`employ' other activity" 
      foreach x in sc st obc gen {
        local owner = upper("`x'")
        if "`x'" != "gen" cap label var ec`year'_`y'_act99_`x' "`employ' with other activity and `owner' owner"
        if "`x'" == "gen" cap label var ec`year'_`y'_act99_`x' "`employ' with other activity and general class owner"
      }
    }
  }
}
end
/* *********** END program label_shrug_ec_vars ***************************************** */

/******************************************************************************************************/
/* program label_shrug_pc_vars : This monstrous program labels all variables in all PC SHRUG datasets */
/******************************************************************************************************/
cap prog drop label_shrug_pc_vars
prog def label_shrug_pc_vars
{
  foreach year in 91 01 11 {

    /* PCA joint urban/rural variables */
    cap label var pc`year'_pca_no_hh "number of households"
    cap label var pc`year'_pca_area  "area"
    cap label var pc`year'_pca_res_house  "number of occupied residential houses"
    
    /* loop over total, male, and female */
    foreach s in p m f {

      /* store total, male, or female */
      if "`s'" == "p" local sex total 
      if "`s'" == "m" local sex male
      if "`s'" == "f" local sex female
    
      /* PCA joint urban/rural variables */
      cap label var pc`year'_pca_tot_`s' "`sex' population"
      cap label var pc`year'_pca_`s'_06  "`sex' population (0-6 years old)"
      cap label var pc`year'_pca_`s'_sc  "`sex' scheduled castes population"
      cap label var pc`year'_pca_`s'_st  "`sex' scheduled tribes population"
      cap label var pc`year'_pca_`s'_lit "`sex' literate population"
      cap label var pc`year'_pca_`s'_ill "`sex' illiterate population"
      cap label var pc`year'_pca_tot_work_`s' "`sex' workers"
      cap label var pc`year'_pca_mainwork_`s' "`sex' main workers"
      cap label var pc`year'_pca_main_cl_`s'  "`sex' cultivators"
      cap label var pc`year'_pca_main_al_`s'  "`sex' agricultural labourers"
      cap label var pc`year'_pca_main_hh_`s'  "`sex' household industries workers"
      cap label var pc`year'_pca_main_liv_`s' "`sex' livestock workers"
      cap label var pc`year'_pca_main_min_`s' "`sex' mining and quarrying workers"
      cap label var pc`year'_pca_main_man_`s' "`sex' non-household industries workers"
      cap label var pc`year'_pca_main_con_`s' "`sex' construction workers"
      cap label var pc`year'_pca_main_trade_`s' "`sex' trade and commerce workers"
      cap label var pc`year'_pca_main_trans_`s' "`sex' transport workers"
      cap label var pc`year'_pca_main_ot_`s'  "`sex' other serices workers"
      cap label var pc`year'_pca_margwork_`s' "`sex' marginal workers"
      cap label var pc`year'_pca_marg_cl_`s'  "`sex' marginal cultivators"
      cap label var pc`year'_pca_marg_al_`s'  "`sex' marginal agricultural labourers"
      cap label var pc`year'_pca_marg_hh_`s'  "`sex' marginal household industries workers"
      cap label var pc`year'_pca_marg_ot_`s'  "`sex' marginal other services workers"
      cap label var pc`year'_pca_non_work_`s' "`sex' non-workers"
      cap label var pc`year'_pca_margwork36_`s' "`sex' marginal workers (3-6 months)"
      cap label var pc`year'_pca_marg_cl36_`s'  "`sex' marginal cultivators (3-6 months)"
      cap label var pc`year'_pca_marg_al36_`s'  "`sex' marginal agricultural labourers (3-6 months)"
      cap label var pc`year'_pca_marg_hh36_`s'  "`sex' marginal household industries workers (3-6 months)"
      cap label var pc`year'_pca_marg_ot36_`s'  "`sex' marginal other services workers (3-6 months)"
      cap label var pc`year'_pca_margwork03_`s' "`sex' marginal workers (0-3 months)"
      cap label var pc`year'_pca_marg_cl03_`s'  "`sex' marginal cultivators (0-3 months)"
      cap label var pc`year'_pca_marg_al03_`s'  "`sex' marginal agricultural labourers (0-3 months)"
      cap label var pc`year'_pca_marg_hh03_`s'  "`sex' marginal household industries workers (0-3 months)"
      cap label var pc`year'_pca_marg_ot03_`s'  "`sex' marginal other services workers (0-3 months)"
    }

    /* PCA urban/rural separated variables */
    /* loop over urban and rural */
    foreach loc in u r {
    
      /* store either urban or rural */
      if "`loc'" == "u" local sector urban
      if "`loc'" == "r" local sector rural
    
      /* label variables */
      cap label var pc`year'_pca_tot_p_`loc' "`sector' total population"
      cap label var pc`year'_pca_no_hh_`loc' "`sector' number of households"
      cap label var pc`year'_pca_tot_m_`loc' "`sector' male population"
      cap label var pc`year'_pca_tot_f_`loc' "`sector' female population"
      cap label var pc`year'_pca_p_sc_`loc' "`sector' total scheduled castes population"
      cap label var pc`year'_pca_p_st_`loc' "`sector' total scheduled tribes population"
    }
    
    /* VD variables */
    cap label var pc`year'_vd_p_sch "number of primary schools"
    cap label var pc`year'_vd_m_sch "number of middle schools"
    cap label var pc`year'_vd_s_sch "number of secondary schools"
    cap label var pc`year'_vd_s_s_sch "number of senior secondary schools"
    cap label var pc`year'_vd_college "number of colleges"
    cap label var pc`year'_vd_app_pr "accessibility by paved road"
    cap label var pc`year'_vd_app_mr "accessibility by mud road"

    /* TD variables */
    cap label var pc`year'_td_area "area in square km"
    cap label var pc`year'_td_primary "number of primary schools"
    cap label var pc`year'_td_middle "number of middle schools"
    cap label var pc`year'_td_secondary "number of secondary schools"
    cap label var pc`year'_td_s_sec "number of senior secondary schools"
    cap label var pc`year'_td_college "number of colleges"

    /* Assign some ANA value labels */
    cap label define ana 0 "not available" 1 "available"
    cap label values pc`year'_vd_app_pr ana
    cap label values pc`year'_vd_app_mr ana
  }

  /* VD variables that only appear in 2011 */
  cap label var pc11_vd_power_dom_win "power supply for domestic use in winter (October-March) per day (in hours)"
  cap label var pc11_vd_power_dom_sum "power supply for domestic use in summer (April-September) per day (in hours)"
  cap label var pc11_vd_power_agr_win "power supply for agricultural use in winter (October-March) per day (in hours)"
  cap label var pc11_vd_power_agr_sum "power supply for agricultural use in summer (April-September) per day (in hours)"
  cap label var pc11_vd_power_com_win "power supply for commercial use in winter (October-March) per day (in hours)"
  cap label var pc11_vd_power_com_sum "power supply for commercial use in summer (April-September) per day (in hours)"
  cap label var pc11_vd_power_all_win "power supply for all uses in winter (October-March) per day (in hours)"
  cap label var pc11_vd_power_all_sum "power supply for all uses in summer (April-September) per day (in hours)"
}
end
/* *********** END program label_shrug_pc_vars ***************************************** */

/******************************************************************************************************/
/* program label_shrug_vcf_vars : This program labels all variables in all VCF SHRUG variables          */
/******************************************************************************************************/
cap prog drop label_shrug_vcf_vars
prog def label_shrug_vcf_vars
{

  /* label vcf variables */
  cap label var num_cells    "number of grid cells in this shrid" 
  cap label var total_forest "sum of forest cover (0-100) in all grid cells in this shrid"
  cap label var max_forest   "maximum forest cover (0-100) in this shrid"
  cap label var forest_loss  "value of forest loss since 2000 in this shrid"  
  cap label var avg_forest   "average forest cover (0-100) in this shrid"
  cap label var poly_type    "polygon source type"
}
end
/* *********** END program label_shrug_vcf_vars ***************************************** */
/**********************************************************************************/
/* program label_id_vars: label pc/ec location id variables                        */
/***********************************************************************************/
cap prog drop label_id_vars
prog def label_id_vars
{

  /* label variable */
  cap label var pc91_state_id "1991 state id"
  cap label var pc91_district_id "1991 district id"
  cap label var pc91_subdistrict_id "1991 subdistrict id"
  cap label var pc91_town_id "1991 town id"
  cap label var pc91_village_id "1991 village id"
  cap label var pc01_state_id "2001 state id"
  cap label var pc01_district_id "2001 district id"
  cap label var pc01_subdistrict_id "2001 subdistrict id"
  cap label var pc01_town_id "2001 town id"
  cap label var pc01_village_id "2001 village id"
  cap label var pc11_state_id "2011 state id"
  cap label var pc11_district_id "2011 district id"
  cap label var pc11_subdistrict_id "2011 subdistrict id"
  cap label var pc11_town_id "2011 town id"
  cap label var pc11_village_id "2011 village id"
  cap label var ec90_state_id "1990 state id"
  cap label var ec90_district_id "1990 district id"
  cap label var ec90_subdistrict_id "1990 subdistrict id"
  cap label var ec90_town_id "1990 town id"
  cap label var ec90_village_id "1990 village id"
  cap label var ec98_state_id "1998 state id"
  cap label var ec98_district_id "1998 district id"
  cap label var ec98_subdistrict_id "1998 subdistrict id"
  cap label var ec98_town_id "1998 town id"
  cap label var ec98_village_id "1998 village id"
  cap label var ec05_state_id "2005 state id"
  cap label var ec05_district_id "2005 district id"
  cap label var ec05_subdistrict_id "2005 subdistrict id"
  cap label var ec05_town_id "2005 town id"
  cap label var ec05_village_id "2005 village id"
  cap label var ec13_state_id "2013 state id"
  cap label var ec13_district_id "2013 district id"
  cap label var ec13_subdistrict_id "2013 subdistrict id"
  cap label var ec13_town_id "2013 town id"
  cap label var ec13_village_id "2013 village id"
  cap label var shrid "SHRUG Identifier"
}
end
/* *********** END program label_id_vars ***************************************** */
  
/**********************************************************************************/
/* program label_merge_source: label merge source variables                       */
/***********************************************************************************/
cap prog drop label_merge_source
prog def label_merge_source
{

  /* define syntax */
  syntax varname, Year(string)

  /* store variable name */
  tokenize `varlist'

  /* define value label */
  if "`year'" == "pc0111" label define pc0111 1 "01 town - 11 town" 2 "01 village - 11 town" 3 "01 village - 11 village", replace 
  if "`year'" == "pc9101" label define pc9101 1 "91 town - 01 town" 2 "91 village - 01 town" 3 "91 village - 01 village" 4 "91 town - 01 village", replace
  if "`year'" == "ec13pc11" label define ec13pc11 1 "13 town - 11 town" 2 "13 village - 11 village", replace 
  if "`year'" == "ec05pc01" label define ec05pc01 1 "05 town - 01 town" 2 "05 village - 01 village", replace
  if "`year'" == "ec98pc" label define ec98pc 1 "98 town - 01 town" 2 "98 village - 91 village", replace
  if "`year'" == "ec90pc91" label define ec90pc91 1 "90 town - 91 town" 2 "90 village - 91 village", replace 

  /* assing value label to variable */
  label value `1' `year'
}
end
/* *********** END program label_merge_source ***************************************** */

/**********************************************************************************/
/* program label_sector_var: label sector variable                                */
/***********************************************************************************/

cap prog drop label_sector_var
prog def label_sector_var
{

  /* define syntax */
  syntax varname

  /* store variable name */
  local name = "`1'"

  /* define value label */
  label define shrug_sector 1 "town" 2 "village" 3 "town & village", replace 

  /* assing value label to variable */
  label value `name' shrug_sector
}
end
/* *********** END program label_sector_var ***************************************** */

/*****************************************************************************************************************************/
/* program identify_big_cities: create indicators that identify locations that SHRUG aggregates to state or district level   */
/*****************************************************************************************************************************/

/* This program tags observations in the locations that we are aggregating to the state or the district level.
   Currently this is:
  - (pc01, ec05, pc11, ec13) mumbai/mumbai suburban or (ec90, pc91, ec98) greater bombay -- This is greater mumbai in the town list
  - (ec90, pc91, pc01, ec05, pc11, ec13) bangalore or (ec98) bangalore urban -- bbmp in the town list
  - rangareddi/hyderabad/medak -- hyderabad in the town list
  - ahmadabad -- ahmadabad in the town list
  - (pc11, ec13) surat/tapi or (ec90, pc91, ec98, pc01, ec05) surat -- surat in the town list

  identify_big_cities, year(11) cityvar(city) [drop]
  - This creates tagvar if it doesn't exist, and updates it to 1 for all matched locations if it does.
  - Specify "drop" option to drop big cities
*/
  
cap prog drop identify_big_cities
prog def identify_big_cities
{
  syntax, Year(string) [CITYvar(string) drop]

  /* default cityvar to city_name */
  if mi("`cityvar'") local cityvar city_name
  
  /* create the city name variable if it doesn't exist yet */
  cap gen `cityvar' = ""
  
  /* set a local indicating whether this is a PC or EC year */
  if inlist("`year'", "91", "01", "11") local census pc
  if inlist("`year'", "90", "98", "05", "13") local census ec

  /* set city for delhi and chandigarh, which are states */
  replace `cityvar' = "delhi" if inlist("`year'", "90", "91", "98") & `census'`year'_state_id == "31"
  replace `cityvar' = "delhi" if inlist("`year'", "01", "05", "11", "13") & `census'`year'_state_id == "07"
  replace `cityvar' = "chandigarh" if inlist("`year'", "90", "91", "98") & `census'`year'_state_id == "28"
  replace `cityvar' = "chandigarh" if inlist("`year'", "01", "05", "11", "13") & `census'`year'_state_id == "04"
  
  /* identify greater mumbai */
  replace `cityvar' = "mumbai" if  inlist("`year'", "90", "91", "98")  & (`census'`year'_state_id == "14" & `census'`year'_district_id == "01")
  replace `cityvar' = "mumbai" if  "`year'" == "01"                    & (`census'`year'_state_id == "27" & (`census'`year'_district_id == "23" | `census'`year'_district_id == "22"))
  replace `cityvar' = "mumbai" if  inlist("`year'", "05", "13")        & (`census'`year'_state_id == "27" & (`census'`year'_district_id == "22" | `census'`year'_district_id == "23"))
  replace `cityvar' = "mumbai" if  "`year'" == "11"                    & (`census'`year'_state_id == "27" & (`census'`year'_district_id == "518" | `census'`year'_district_id == "519"))

  /* update for bangalore/bangalore urban */
  replace `cityvar' = "bbmp" if inlist("`year'", "90", "91", "98") & (`census'`year'_state_id == "11" & `census'`year'_district_id == "01")
  replace `cityvar' = "bbmp" if inlist("`year'", "01", "05")       & (`census'`year'_state_id == "29" & `census'`year'_district_id == "20")
  replace `cityvar' = "bbmp" if "`year'" == "11"                   & (`census'`year'_state_id == "29" & `census'`year'_district_id == "572")
  replace `cityvar' = "bbmp" if "`year'" == "13"                   & (`census'`year'_state_id == "29" & `census'`year'_district_id == "18")

  /* update for rangareddi/hyderabad/medak */
  replace `cityvar' = "hyderabad" if inlist("`year'", "90", "91", "98")  & (`census'`year'_state_id == "02" & inlist(`census'`year'_district_id, "15", "16", "17"))
  replace `cityvar' = "hyderabad" if inlist("`year'", "01", "05")  & (`census'`year'_state_id == "28" & inlist(`census'`year'_district_id, "04", "05", "06"))
  replace `cityvar' = "hyderabad" if "`year'" == "11"  & (`census'`year'_state_id == "28" & inlist(`census'`year'_district_id, "535", "536", "537"))
  replace `cityvar' = "hyderabad" if "`year'" == "13"  & (`census'`year'_state_id == "36" & inlist(`census'`year'_district_id, "04", "05", "06"))

  /* update for ahmadabad */
  replace `cityvar' = "ahmadabad" if inlist("`year'", "90", "91")  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "12")
  replace `cityvar' = "ahmadabad" if "`year'" == "98"  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "14")
  replace `cityvar' = "ahmadabad" if inlist("`year'", "01", "05", "13")  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "07")
  replace `cityvar' = "ahmadabad" if "`year'" == "11"  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "474")

  /* update for surat */
  replace `cityvar' = "surat" if inlist("`year'", "90", "91")  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "17")
  replace `cityvar' = "surat" if "`year'" == "98"  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "22")
  replace `cityvar' = "surat" if inlist("`year'", "01", "05")  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "22")
  replace `cityvar' = "surat" if "`year'" == "11"  & (`census'`year'_state_id == "24" & (`census'`year'_district_id == "492" | `census'`year'_district_id == "493"))
  replace `cityvar' = "surat" if "`year'" == "13"  & (`census'`year'_state_id == "24" & (`census'`year'_district_id == "25" | `census'`year'_district_id == "26"))

  /* These ahmedabad lines use "capture" because some of the town data doesn't have subdistricts. This subdistrict has rural places only. */
  /* update for ahmadabad - for dehgam subdistrict */
  noi cap replace `cityvar' = "ahmadabad" if "`year'" == "98"  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "13" & `census'`year'_subdistrict_id == "002")
  noi cap replace `cityvar' = "ahmadabad" if inlist("`year'", "01", "05")  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "06" & `census'`year'_subdistrict_id == "0004")
  noi cap replace `cityvar' = "ahmadabad" if "`year'" == "11"  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "473" & `census'`year'_subdistrict_id == "03776")
  noi cap replace `cityvar' = "ahmadabad" if "`year'" == "13"  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "06" & `census'`year'_subdistrict_id == "004")

  /* update for ahmadabad - for dehgam town */
  noi cap replace `cityvar' = "ahmadabad" if "`year'" == "98"  & (`census'`year'_state_id == "07" & `census'`year'_district_id == "13" & `census'`year'_town_id == "02")
  noi cap replace `cityvar' = "ahmadabad" if "`year'" == "05"  & (`census'`year'_state_id == "24" & `census'`year'_district_id == "06" & `census'`year'_town_id == "05")

  /* if "drop" is specified, drop these vars and kill the cityvar variable */
  if !mi("`drop'") {
    drop if !mi(`cityvar')
    drop `cityvar'
  }
  
}
end

/* *********** END program identify_big_cities ***************************************** */

/**********************************************************************************/
/* program label_shrug_vars : Label a SHRUG var using the external data dictionary */
/**********************************************************************************/
cap prog drop label_shrug_vars
prog def label_shrug_vars
{
  /* preserve while we manipulate the data dictionary */
  preserve
  
  /* download the data dictionary */
  global dict_file $tmp/shrug_data_dict.csv
  global dict_doc_id 1ZD0dAJ4Q6soJJOmjg91CRkfmLYE8P8_kFfDFUZA2YwE
  global curl_cmd curl -s -d /dev/null https://docs.google.com/spreadsheets/d/${dict_doc_id}/export?exportFormat=csv >$tmp/dict_tmp.csv
  shell $curl_cmd

  /* get variable labels from the downloaded file */
  /* strip the top line (with human-readable variable descriptions) */
  shell tail -n+2 $tmp/dict_tmp.csv  >$dict_file

  /* simplify the dictionary file to the fields we care about */
  import delimited $dict_file, clear varnames(1)
  keep varname desc

  /* drop sequence fields */
  drop if strpos(varname, "[")
  
  /* write it out without headers, which is how it gets used below. */
  export delimited using $tmp/labels.csv, replace novarnames

  /* restore to the file that we want to label */
  restore
  
  /* read the same file in using file read */
  cap file close fh
  file open fh using $tmp/labels.csv, read
  file read fh line
  while r(eof) == 0 {

    /* trim whitespace */
    local l = strtrim("`line'")

    tokenize "`l'", parse(",")
    label var `1' "`3'"
    
    file read fh line
  }
  cap file close fh

  /* TO DO: UPDATE THIS TO GET VARS LIKE EC_s7 or light_[2000-2014] */
  
}
end
/* *********** END program label_shrug_vars ***************************************** */

/*****************************************************************************************/
/* program download_shrug_data_dict : Download the Google Sheet with the data dictionary */
/*                                    and expand all wildcards. Next time, do this in
                                      python.                                            */
/*****************************************************************************************/
cap prog drop download_shrug_data_dict
prog def download_shrug_data_dict
{
  syntax, [maxrows(real -1)]
  qui {
    /* download the data dictionary */
  global dict_varlist varname collapse_type pc_ref_year location desc release packet
  global dict_file $tmp/shrug_data_dict.csv
  global dict_doc_id 18Sgl-hTRF5iKIERc_uE3z5CWyhprZjo2ddNH2ZrPjfM

  /* use download_gsheet from tools.do */
  download_gsheet $tmp/dict_tmp.csv, key($dict_doc_id)
        
  /* strip the top line (with human-readable variable descriptions) */
  shell tail -n+2 $tmp/dict_tmp.csv  >$tmp/shrug_data_dict_unclean.csv

  /* simplify the dictionary file to the fields we care about */
  import delimited $tmp/shrug_data_dict_unclean.csv, clear varnames(1)
  keep  $dict_varlist
  order $dict_varlist
  replace collapse_type = lower(collapse_type)
  replace pc_ref_year = lower(pc_ref_year)
  drop if mi(varname) | substr(varname, 1, 1) == "#"
  
  /* drop rows after STOP flag for temporary work */
  gen row_number = _n
  sum row_number if varname == "STOP"
  if `r(N)' == 1 {
    drop if row_number >= `r(mean)'
  }
  if (`maxrows' > 0) {
    drop if row_number >= `maxrows'
  }

  /* expand rows with wildcard sequences */
  gen wildcard = strpos(varname, "[")
  egen seq = seq() if wildcard != 0 & !mi(wildcard)
  drop wildcard
 
  /* loop over each wildcard field */
  sum seq
  local nseq = "`r(max)'"
  if mi("`nseq'") local nseq 0
  forval i = 1/`nseq' {

    /* Get the row number matching this sequence. Stata is the worst. */
    gen row = _n if seq == `i'
    sum row
    local row `r(mean)'
    drop row
    
    /* get the wildcard variable name */
    local wildcard = varname[`row']
    local ref_year = pc_ref_year[`row']
    
    /* get the low and high value for the sequence */
    local charstart = strpos("`wildcard'", "[")
    local chardash = strpos("`wildcard'", "-")
    local charend = strpos("`wildcard'", "]")
    local low = substr("`wildcard'", `charstart' + 1, `chardash'-`charstart' - 1)
    local high = substr("`wildcard'", `chardash' + 1, `charend'-`chardash' - 1)
    di "`charstart'"
    di "`chardash' "
    di "`charend'  "
    di "`low'  "
    di "`high'  "
    /* get the variable stub */
    local varstub = substr("`wildcard'", 1, `charstart' - 1)
    
    /* create new rows in the dataset for this expansion */
    local new_obs_count = `high' - `low'
    expand `new_obs_count' if seq == `i', gen(new)

    /* create a counter for all new observations and the one original one */
    egen new_count = seq() if seq == `i'
    replace new_count = new_count + `low' - 1
    
    /* assign the new variable names */
    replace varname = "`varstub'" + string(new_count) if seq == `i'
    
    /* if it's a variable reference, change pc_ref_year based on the year value */
    if "`ref_year'" == "year" {
      replace pc_ref_year = "pc91" if new_count <= 2000 & seq == `i'
      replace pc_ref_year = "pc01" if inrange(new_count, 2001, 2010) & seq == `i'
      replace pc_ref_year = "pc11" if new_count >= 2011 & !mi(new_count) & seq == `i'
    }
    drop new new_count

    /* recombine all of these variables in the order list */
    sort varname
  }

  /* drop the wildcard indicator */
  drop seq

  /* write it out without headers, which is how it gets used below. */
  order $dict_varlist 
  keep $dict_varlist
  export delimited using $dict_file, replace 
  }
  di "Data dictionary downloaded to $dict_file."
}
end
/* *********** END program download_shrug_data_dict ***************************************** */


/*****************************************************************************************/
/* program merge_percentage_to_local : simple merge efficiency for unit testing.         */
/*****************************************************************************************/

/* set a post-merge helper function */
cap prog drop merge_percentage_to_local
prog def merge_percentage_to_local, rclass
{
  /* get merge categories - matched, and unmatched from master  */
  qui count if _merge == 3
  local merged = `r(N)'
  qui count if _merge == 1
  local unmerged = `r(N)'

  /* define merge percentage of master dataset */
  local merge_percentage = `merged' / (`merged' + `unmerged')
  return local merge_percentage `merge_percentage'
}
end
/* *********** END program merge_percentage_to_local ***************************************** */


}
