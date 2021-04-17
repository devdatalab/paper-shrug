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
