# SHRUG Paper Replication Repo

These code and data files replicate the results in "Development Research at High Geographic Resolution: An Analysis of Night-Lights, Firms, and Poverty in India Using the SHRUG Open Data Platform" by Sam Asher, Tobias Lunt, Ryu Matsuura and Paul Novosad (2021). The paper can be found [here](https://doi.org/10.1093/wber/lhab003).

--- 
To regenerate the tables and figures from the paper, take the following steps:

1. Download and unzip the replication data package from this Google Drive [folder](https://drive.google.com/drive/folders/1j7BpC_iQPdajdr9F4t-MZdN6PRlv3i6U)
2. To get all the files in CSV format, use this [link](https://drive.google.com/file/d/1faMl8S0WMNYf60FAoL2AI49nL0uJeMRN/view?usp=sharing)

Clone this repo and switch to the code folder.

Open the do file `make_shrug_paper.do`, and set the globals `out`, `repdata`, `tmp`, and `shcode`.

  - `$out` is the target folder for all outputs, such as tables and graphs.
  - `$tmp` is the folder for the data files and temporary data files that will be created during the rebuild.
  - `$repdata` is the folder where you unzipped and saved the replication data package.
  - `$shcode` is the code folder of the clone of the replication repo

Run the do file `make_shrug_paper.do`. This will run through all the other do files to regenerate all of the results.

We have included all the required programs to generate the main results. However, some of the estimation output commands (like estout) may fail if certain Stata packages are missing. These can be replaced by the estimation output commands preferred by the user.

Please note we use globals for pathnames, which will cause errors if filepaths have spaces in them. Please store code and data in paths that can be access without spaces in filenames.

This code was tested using Stata 16.0. 

---
# Data Description on SHRUG panel and SHRUG keys
------

### A)  Data Sources 
The data comes from 1990, 1998, 2005, and 2013 Economic Censuses (3rd through 6th rounds) and 1991, 2001, 2011 Population Censuses and Village/Town Directories reported by the Indian government.

### B) Datasets
 We include two types of datasets in Stata format:

   1) **SHRUG IDs and Cross-Census Keys**: The data are linked across waves through the use of unique **SHRUG** Identifiers (`shrid` in the data). SHRIDs identify consistent units across multiple waves of Indian data. In most cases, the SHRUG id matches directly to a single village or town. In cases where unit boundaries have changed, a single SHRID may match multiple towns or villages. For instance, two villages in the 2001 population census that are merged into one town in the 2011 population census will have the same SHRID.

 The key files are structured such that each file is unique on the census identifier for that file, but not necessarily on the SHRID. This allows users to directly merge in additional data from the Population or Economic Censuses. For instance, `shrug_pc01_village_key.dta` is unique on `pc01_state_id` and `pc01_village_id`, which identify observations in the 2001 Population Census. However, it is **not** unique on SHRID, because multiple 2001 villages may correspond to a single village in a different census round.

To match data across rounds, the datasets must be collapsed to unique SHRID. For instance, multiple villages with the same SHRID should have their populations added to create a single unique unit. Note that when a village becomes a town, a SHRID may correspond to a village in one census year and a town in a future census year.

   The following keys are currently provided:

         shrug_ec05_town_key.dta
         shrug_ec05_village_key.dta
         shrug_ec13_town_key.dta
         shrug_ec13_village_key.dta
         shrug_ec90_town_key.dta
         shrug_ec90_village_key.dta
         shrug_ec98_town_key.dta
         shrug_ec98_village_key.dta
         shrug_pc01_town_key.dta
         shrug_pc01_village_key.dta
         shrug_pc11_town_key.dta
         shrug_pc11_village_key.dta
         shrug_pc91_town_key.dta
         shrug_pc91_village_key.dta

   2) **SHRUG Panel**: `shrug_panel.dta`

This is a panel dataset that is unique on SHID and includes selected data fields from all rounds of the Economic Census, Population Census, and Village/Town Directories. The panel has missing values for location ID values if (1) we cannot match the PC11 observation to any wave for which the panel has missing value or (2) there are multiple towns/villages that are matched to one SHRID. For variable description, please refer to the variable label.

### C) Data coverage

These data were linked through a combination of linked identifiers, fuzzy matching using names, and other linking attributes provided by the Censuses. Every effort has been made to make these links accurate, but there will inevitably be some Type I and Type II errors. The Economic Censuses in particular often contain substantial outliers, which are difficult to verify. Coverage of the linked data is higher for more recent years where the identifiers were better documented. In particular, the match rate for towns in 1990 is quite low.

These data are therefore *not* suitable for describing aggregate (e.g. national or state) trends in population and employment. However, they are suitable for describing those trends in the town and village units that have matched across periods.

The table below shows the data coverage:

      ---------------------------------------------
      Year  Census  Sector  No. of obs.     w/ SHID
      ---------------------------------------------
      1990      EC   Rural       549985      485386  
      1990      EC   Urban         4480        2181  
      ---------------------------------------------
      1991     PCA   Rural       628191      626477  
      1991      VD   Rural       627067      622684  
      1991     PCA   Urban         5947        4999  
      1991      TD   Urban         4615        4475  
      ---------------------------------------------
      1998      EC   Rural       520580      452916  
      1998      EC   Urban         4402        3782  
      ---------------------------------------------
      2001     PCA   Rural       593603      593432  
      2001      VD   Rural       634805      634565  
      2001     PCA   Urban         5217        5207  
      2001      TD   Urban         5178        5168  
      ---------------------------------------------
      2005      EC   Rural       532069      510054  
      2005      EC   Urban         4619        4286  
      ---------------------------------------------
      2011     PCA   Rural       597619      596586  
      2011      VD   Rural       640914      639779  
      2011     PCA   Urban         8067        8067  
      2011      TD   Urban         7948        7948  
      ---------------------------------------------
      2013      EC   Rural       560251      549459  
      2013      EC   Urban         9963        9309  
      ---------------------------------------------

_Note: EC, PCA, VD, and TD indicate Economic Census, Primary Census Abstract, Village Directory, and Town Directory respectively. The PCA, VD, and TD all come from the Population Census._
