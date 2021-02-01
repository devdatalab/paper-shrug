---------------------------------------------------------------------------
Socioeconomic High-resolution Rural-Urban Geographic Data for India (SHRUG)
---------------------------------------------------------------------------
Version 1.0, 2018/12/17  (Preliminary)
---------------------------------------------------------------------------

This dataset is an early release of time series high geographic
resolution socioeconomic data on India spanning the period 1990 to the
present, presently named the Socioeconomic High-resolution
Rural-Urban Geographic Data for India.

The current data series links together the location identifiers from
three rounds of the Indian Population Census and four rounds of the
Indian Economic Census. The main contribution of this dataset is to
link the village and town identifiers across datasets and over time.
The keys to link the various censuses are stored in separate files,
one for each source of raw data.

We also include a village and town panel with consistent locations for
the entire sample period.  The dataset does not contain the full set
of fields from the Population and Economic Censuses; we include a very
small subset of fields -- total population, total employment, and
several public goods -- for verification purposes only. Anyone
interested in conducting village- or town-level analysis using a
broader set of fields from the Economic or Population Censuses should
purchase or download the raw data series from the original sources,
and then use the keys provided here to link the datasets together.
The Economic Census is available for purchase from the Ministry of
Statistics, Planning and Information. The Population Census is
available in various formats from the Office of the Registrar General
& Census Commissioner of India.

If you use these data, please use the following reference:

Asher, Sam and Paul Novosad. "Socioeconomic High-resolution
Rural-Urban Geographic Data for India." Version 1.0 (2018).

---------------------------------------------------------------------------
Data Description on SHRUG panel and SHRUG keys
---------------------------------------------------------------------------

A) Data Sources 
   The data comes from 1990, 1998, 2005, and 2013
   Economic Censuses (3rd through 6th rounds) and 1991, 2001, 2011
   Population Censuses and Village/Town Directories reported by the
   Indian government.

B) Datasets
   We include two types of datasets in Stata format:

   1) SHRUG IDs and Cross-Census Keys:

     The data are linked across waves through the use of unique SHRUG
     Identifiers (SHID in the data). SHRUG ids identify consistent
     units across multiple waves of Indian data. In most cases, the
     SHRUG id matches directly to a single village or town. In cases
     where unit boundaries have changed, a single SHID may match
     multiple towns or villages. For instance, two villages in the
     2001 population census that are merged into one town in the 2011
     population census will have the same SHID.

     The key files are structured such that each file is unique on the
     census identifier for that file, but not necessarily on the
     SHID. This allows users to directly merge in additional data from
     the Population or Economic Censuses. For instance,
     shrug_pc01_village_key.dta is unique on pc01_state_id and
     pc01_village_id, which identify observations in the 2001
     Population Census. However, it is *not* unique on SHID, because
     multiple 2001 villages may correspond to a single village in a
     different census round.

     To match data across rounds, the datasets must be collapsed to
     unique SHID. For instance, multiple villages with the same SHID
     should have their populations added to create a single unique unit.

     Note that when a village becomes a town, a shrug id may
     correspond to a village in one census year and a town in a future
     census year.

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

   2) SHRUG Panel: shrug_panel.dta
   
      This is a panel dataset that is unique on SHID and includes
      selected data fields from all rounds of the 
      Economic Census, Population Census, and Village/Town Directories.
      The panel has missing values for location ID values if (1) we cannot
      match the PC11 observation to any wave for which the panel has missing
      value or (2) there are multiple towns/villages that are matched to one
      SHID. For variable description, please refer to the variable label.

C) Data coverage

      These data were linked through a combination of linked
      identifiers, fuzzy matching using names, and other linking
      attributes provided by the Censuses. Every effort has been made
      to make these links accurate, but there will inevitably be some
      Type I and Type II errors. The Economic Censuses in particular
      often contain substantial outliers, which are difficult to
      verify. Coverage of the linked data is higher for more recent
      years where the identifiers were better documented. In
      particular, the match rate for towns in 1990 is quite low.

      These data are therefore *not* suitable for describing aggregate
      (e.g. national or state) trends in population and
      employment. However, they are suitable for describing those
      trends in the town and village units that have matched across
      periods.

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
      
      Note: EC, PCA, VD, and TD indicate Economic Census, Primary
      Census Abstract, Village Directory, and Town Directory
      respectively. The PCA, VD, and TD all come from the
      Population Census.

----------------------------------------------------------------
Notes on Preliminary Release
----------------------------------------------------------------

This is a preliminary release. We are continuing to improve the
quality of matches where towns/villages are merged or split across
censuses. The current panel dataset may not accurately reflect all
changes in town boundaries where villages in one period have been
absorbed by towns in the following period. We are in the process of
identifying these towns and villages. A future version of this dataset
will also include aggregates at the level of legislative
constituencies, as well as various satellite based measures of
development. For feedback, suggestions or errors, please email Sam
Asher (sasher@worldbank.org) and Paul Novosad
(paul.novosad@dartmouth.edu).


