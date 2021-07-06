/* merge district shrug and ihds */
use $tmp/ihds_cons_dist, clear

merge 1:1 pc01_state_id pc01_district_id using $tmp/shrug_cons_dist, nogen keep(match)

binscatter ihds_cons_pc_mean_rural secc_cons_pc_rural, xtitle("SHRUG Consumption (Rs.)") ytitle("IHDS Consumption (Rs.)")
graphout shrug_ihds_cons_comp_rural, pdf

binscatter ihds_cons_pc_mean_urban secc_cons_pc_urban, xtitle("SHRUG Consumption (Rs.)") ytitle("IHDS Consumption (Rs.)")
graphout shrug_ihds_cons_comp_urban, pdf


