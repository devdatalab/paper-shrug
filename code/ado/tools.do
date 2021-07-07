qui {

  /* DDL STATA TOOLS */
  
   /***************************************************************************************************/
  /* program table_from_tpl : Create a table from a stored estimates file and a .tex table template  */
  /***************************************************************************************************/
  cap prog drop table_from_tpl
  prog def table_from_tpl
    {
        syntax, Template(string) Replacement(string) Output(string) [Verbose addstars dropstars]

        /* set up verbose flag */
        if !mi("`verbose'") {
              local v "-v"
          }
        else {
              local v
          }

        /* set path for python code to the tools folder in this repo */
        local path $shcode/py

        /* check python file existence */
        cap confirm file `path'/table_from_tpl.py
        if _rc {
              display as error "ERROR: table_from_tpl.py not found. Put in current folder or folder defined by global \$PYTHONPATH"
              error -1
          }

        /* deal with addstars/dropstars parameters */
        if "`addstars'" == "addstars" {
            local star_param "--add-stars"
          }
        if "`dropstars'" == "dropstars" {
            local star_param "--drop-stars"
          }

        local pycommand `path'/table_from_tpl.py -t `template' -r `replacement' -o `output' `v' `star_param'
        if !mi("`verbose'") {
              di `"Running `pycommand' "'
          }

        shell python `pycommand'
        cap confirm file `output'
        if !_rc {
            display "Created `output'."
          }
        else {
            display "Could not create `output'."
            error 1
          }

        /* clean up the temporary file if star/nostar specified */
        if !mi("`stars'") {
            !rm $tmp/tpl_sed_tmp.tex
          }
      }
    end
  /* *********** END program table_from_tpl ***************************************** */

  /**********************************************************************************/
  /* program insert_into_file : Insert a key-value pair into a file                 */
  /*
  Assume "using" csv file take a key, value format, e.g.:
  est1,3.544
  est2,3.234***
  ...
  "est1" is the key. "3.544" is the value.
  Example:
  insert_into_file using $tmp/estimates.csv, key(est1) value(3.54493) format(%5.2f)
  - if "est1" is not already in estimates file, it will be appended
  - if "est1" is already in estimates file, its value will be replaced with the passed in parameter
  - estimates file will be created if it does not already exist
  */

  /***********************************************************************************/
  cap prog drop insert_into_file
  prog def insert_into_file
    {
        syntax using/, Key(string) Value(string) [Format(string) verbose]

        /* set default format if not specified */
        if mi("`format'") local format "%6.3f"

        /* get value in correct format (unless it's a string) */
        if !mi(real("`value'")) {
            local value : di `format' `value'
          }
        else {
            local value `value'
          }

        /* confirm file handles are closed */
        cap file close fout
        cap file close fin

        /* create a temporary file for writing */
        tempfile tempfile
        qui file open fout using `tempfile', write replace

        /* if input file doesn't exist, display a notification that we will create the file */
        cap confirm file `using'
        if _rc {
            if !mi("`verbose'") {
                di "Creating new file `using'..."
              }

            /* set found to zero so the line gets appended at the end */
            local found 0
          }

        /* else, open the input file and read the first line */
        else {
            file open fin using `using', read

            /* read the first line */
            file read fin line

            /* store a flag indicating whether we found the line or not */
            local found 0

            /* loop over all lines of the file */
            while r(eof) == 0 {

                /* check if line matches the current key */
                if regexm("`line'", "^`key',") {

                    /* if verbose, show what we're replacing  */
                    if !mi("`verbose'") {
                        di `"Replacing "`line'" with "`key',`value'"..."'
                      }
                    local found 1

                    /* replace the line with key,value */
                    local line `key',`value'
                  }

                /* write the line to the output file */
                file write fout "`line'" _n

                /* read the next line */
                file read fin line
              }
          }

        /* if we didn't find this key, append it to the end */
        if `found' == 0 {
            file write fout "`key',`value'" _n
          }

        /* close input and output files */
        cap file close fin
        file close fout

        /* copy the temporary file to the `using` filename */
        copy `tempfile' `using', replace
      }
    end
  /* *********** END program insert_into_file ***************************************** */

  /**************************************************************************************************/
  /* program app : short form of append_to_file: app $f, s(foo) == append_to_file using $f, s(foo) */
  /**************************************************************************************************/
  cap prog drop app
  prog def app
  {
    syntax anything, s(passthru) [format(passthru) erase(passthru)]
    append_to_file using `anything', `s' `format' `erase'
  }
  end
  /* *********** END program app ***************************************** */
  
  /**********************************************************************************/
  /* program append_est_to_file : Appends a regression estimate to a csv file       */
  /**********************************************************************************/
  cap prog drop append_est_to_file
  prog def append_est_to_file
  {
    syntax using/, b(string) Suffix(string)
  
    /* get number of observations */
    qui count if e(sample)
    local n = r(N)
  
    /* get b and se from estimate */
    local beta = _b["`b'"]
    local se   = _se["`b'"]
  
    /* get p value */
    qui test `b' = 0
    local p = `r(p)'
    if "`p'" == "." {
      local p = 1
      local beta = 0
      local se = 0
    }
    append_to_file using `using', s("`beta',`se',`p',`n',`suffix'")
  }
  end
  /* *********** END program append_est_to_file ***************************************** */
  
  **********************************************************************************/
  /* program append_to_file : Append a passed in string to a file                   */
  /**********************************************************************************/
  cap prog drop append_to_file
  prog def append_to_file
  {
    syntax using/, String(string) [format(string) erase]
  
    tempname fh
    
    cap file close `fh'
  
    if !mi("`erase'") cap erase `using'
  
    file open `fh' using `using', write append
    file write `fh'  `"`string'"'  _n
    file close `fh'
  }
  end
  /* *********** END program append_to_file ***************************************** */
  
  /**********************************************************************************/
  /* program capdrop : Drop a bunch of variables without errors if they don't exist */
  /**********************************************************************************/
  cap prog drop capdrop
  prog def capdrop
  {
    syntax anything
    foreach v in `anything' {
      cap drop `v'
    }
  }
  end
  /* *********** END program capdrop ***************************************** */
  
  /**********************************************************************************/
  /* program count_stars : return a string with the right number of stars           */
 /**********************************************************************************/
   cap prog drop count_stars
   prog def count_stars, rclass
     {
       syntax, p(real)
       local star = ""
       if `p' <= 0.1  local star = "*"
       if `p' <= 0.05 local star = "**"
       if `p' <= 0.01 local star = "***"
       return local stars = "`star'"
     }
   end
   /* *********** END program count_stars ***************************************** */
   
   /*********************************************************************************************************/
  /* program ddrop : drop any observations that are duplicated - not to be confused with "duplicates drop" */
  /*********************************************************************************************************/
  cap prog drop ddrop
  cap prog def ddrop
  {
    syntax varlist(min=1) [if]

    /* do nothing if no observations */
    if _N == 0 exit
    
    /* `0' contains the `if', so don't need to do anything special here */
    duplicates tag `0', gen(ddrop_dups)
    drop if ddrop_dups > 0 & !mi(ddrop_dups) 
    drop ddrop_dups
  }
end
  /* *********** END program ddrop ***************************************** */
  
  /**********************************************************************************/
  /* program disp_nice : Insert a nice title in stata window */
  /***********************************************************************************/
  cap prog drop disp_nice
  prog def disp_nice
  {
    di _n "+--------------------------------------------------------------------------------------" _n `"| `1'"' _n  "+--------------------------------------------------------------------------------------"
  }
  end
  /* *********** END program disp_nice ***************************************** */
  
  /**********************************************************************************/
  /* program dtag : shortcut duplicates tag */
  /***********************************************************************************/
  cap prog drop dtag
  prog def dtag
    {
      syntax varlist [if]
      duplicates tag `varlist' `if', gen(dup)
      sort `varlist'
      tab dup
    }
  end
 /* *********** END program dtag ***************************************** */
 
 /****************************************************************/
/* program get_state_ids : merge in state_ids using state_names */
/****************************************************************/
/* get state ids ( y(91) if want 1991 ids ) */
cap prog drop get_state_ids
prog def get_state_ids
  {
    syntax , [Year(string)]

    /* default is 2001 */
    if mi("`year'") {
      local year 01
    }

    /* merge to the state key on state name */
    merge m:1 pc`year'_state_name using $keys/pc`year'_state_key, gen(_gsn_merge) update replace

    /* display state names that did not match the key */
    di "unmatched names: "
    cap noi table pc`year'_state_name if _gsn_merge == 1

    /* drop places that were only in the key */
    drop if _gsn_merge == 2
    drop _gsn_merge

  }
end


  /**********************************************************************************/
  /* program graphout : Export graph to public_html/png and pdf form                */
  /* defaults:
     - on Dartmouth RC, exports a .png to ~/public_html/png/ only
     - on MacOS, exports a pdf to $tmp
*/
  
  /* options:
     - pdf: export a pdf to $out
     - pdfout(path): specifies an alternate filename or path for the pdf
                     i.e.:  mv file.pdf `pdfout'
*/
  /**********************************************************************************/
  cap prog drop gt
  prog def gt
  {
    syntax anything, [pdf pdfout(passthru)]
    graphout `1', `pdf' `pdfout'
  }
  end

  cap prog drop graphout
  prog def graphout
    
    syntax anything, [small png pdf pdfout(string) QUIet rescale(real 100)]

    /* strip space from anything */
    local anything = subinstr(`"`anything'"', " ", "", .)

    /* break if pdf is specified but not $out not defined */
    if mi("$out") & !mi("`pdf'") {
      disp as error "graphout FAILED: global \$out must be defined if 'out' is specified."
      exit 123
    }

    /* make everything quiet from here */
    qui {

      /* always start with an eps file to $tmp */
      graph export `"$tmp/`anything'.eps"', replace 
      local linkpath `"$tmp/`anything'.eps"'

      /* if small is specified, specify size */
      if "`small'" == "small" {
        local size 480x480
      }

      if "`small'" == ""{
        local size 960x960
      }
      
      /* if "pdf" is specified, send a PDF to $out */
      if "`pdf'" == "pdf" {

        /* convert the eps to pdf in the $tmp folder */
        // noi di "Converting EPS to PDF..."
        shell epstopdf $tmp/`anything'.eps

        /* now move it to its destination, which is $out or `pdfout' */
        if mi("`pdfout'")  local out $out
        if !mi("`pdfout'") local out `pdfout'
        shell mv $tmp/`anything'.pdf `out'
          
        /* set output path for link */
        local linkpath `out'/`anything'.pdf
      }

      /* if on a mac, convert to a pdf in $tmp and kill the eps */
      if ("$macos" == "1") {
        shell epstopdf $tmp/`anything'.eps
        cap erase $tmp/`anything'.eps
        if mi("`pdf'") local linkpath $tmp/`anything'.pdf
      }
        
      /* if we are not on macos (i.e. we are on RC), export a png file to ~/public_html */
      if ("$macos" != "1") {

        /* create a large png and move to public_html/png */
        shell convert -size `size' -resize `size' -density 300 $tmp/`anything'.eps $tmp/`anything'.png

        /* if png is specified, save png to out folder */
        if ("`png'" != "") {
          cap erase $out/`anything'.png
          shell convert $tmp/`anything'.png -resize `rescale'% $out/`anything'.png
        }
        
        /* if public_html/png folder exists, move it there */
        cap confirm file ~/public_html/png
        if !_rc {
          shell mv $tmp/`anything'.png ~/public_html/png/`anything'.png
        }
        local linkpath "http://caligari.dartmouth.edu/~`c(username)'/png/`anything'.png"
        if ("$tmp" == "/scratch/pn") local linkpath "http://rcweb.dartmouth.edu/~`c(username)'/png/`anything'.png"
        

      }
        
      /* output a link to the image destination path */
      if mi("`quiet'") {
        shell echo "View graph at `linkpath'"
      }
    }

  end
  /* *********** END program graphout ***************************************** */
  
  /**********************************************************************************/
  /* program group : Fast way to use egen group()                  */
  /**********************************************************************************/
  cap prog drop regroup
  prog def regroup
    syntax anything [if]
    group `anything' `if', drop
  end
  
  cap prog drop group
  prog def group
  {
    syntax anything [if], [drop]
  
    tokenize "`anything'"
  
    local x = ""
    while !mi("`1'") {
  
      if regexm("`1'", "pc[0-9][0-9][ru]?_") {
        local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
      }
      else {
        local x = "`x'" + substr("`1'", 1, 1)
      }
      mac shift
    }
  
    if ~mi("`drop'") cap drop `x'group
  
    display `"RUNNING: egen int `x'group = group(`anything')" `if''
    egen int `x'group = group(`anything') `if'
  }
  end
  /* *********** END program group ***************************************** */
  
  /**********************************************************************************/
  /* program lf : Better version of lf */
  /***********************************************************************************/
  cap prog drop lf
  prog def lf
  {
    syntax anything
    d *`1'*, f
  }
  end
  /* *********** END program lf ***************************************** */
  
   /**********************************************************************************/
   /* program normalize: demean and scale by standard deviation */
   /***********************************************************************************/
   cap prog drop normalize
   prog def normalize
     {
       syntax varname, [REPLace GENerate(name)]
       tokenize `varlist'
   
       /* require generate or replace [sum of existence must equal 1] */
       if ((!mi("`generate'") + !mi("`replace'")) != 1) {
         display as error "normalize: generate or replace must be specified, not both"
         exit 1
       }
   
       tempvar tmp
   
       cap drop __mean __sd
       egen __mean = mean(`1')
       egen __sd = sd(`1')
       gen `tmp' = (`1' - __mean) / __sd
       drop __mean __sd
   
       /* assign created variable based on replace or generate option */
       if "`replace'" == "replace" {
         replace `1' = `tmp'
       }
       else {
         gen `generate' = `tmp'
       }
     }
   end
   /* *********** END program normalize ***************************************** */
   
   /**********************************************************************************************/
  /* program quireg : display a name, beta coefficient and p value from a regression in one line */
  /***********************************************************************************************/
  cap prog drop quireg
  prog def quireg, rclass
  {
    syntax varlist(fv ts) [pweight aweight] [if], [cluster(varlist) title(string) vce(passthru) noconstant s(real 40) absorb(varlist) disponly robust]
    tokenize `varlist'
    local depvar = "`1'"
    local xvar = subinstr("`2'", ",", "", .)
  
    if "`cluster'" != "" {
      local cluster_string = "cluster(`cluster')"
    }
  
    if mi("`disponly'") {
      if mi("`absorb'") {
        cap qui reg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' `constant' robust
        if _rc == 1 {
          di "User pressed break."
        }
        else if _rc {
          display "`title': Reg failed"
          exit
        }
      }
      else {
        /* if absorb has a space (i.e. more than one var), use reghdfe */
        if strpos("`absorb'", " ") {
          cap qui reghdfe `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' absorb(`absorb') `constant' 
        }
        else {
          cap qui areg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' absorb(`absorb') `constant' robust
        }
        if _rc == 1 {
          di "User pressed break."
        }
        else if _rc {
          display "`title': Reg failed"
          exit
        }
      }
    }
    local n = `e(N)'
    local b = _b[`xvar']
    local se = _se[`xvar']
  
    quietly test `xvar' = 0
    local star = ""
    if r(p) < 0.10 {
      local star = "*"
    }
    if r(p) < 0.05 {
      local star = "**"
    }
    if r(p) < 0.01 {
      local star = "***"
    }
    di %`s's "`title' `xvar': " %10.5f `b' " (" %10.5f `se' ")  (p=" %5.2f r(p) ") (n=" %6.0f `n' ")`star'"
    return local b = `b'
    return local se = `se'
    return local n = `n'
    return local p = r(p)
  }
  end
  /* *********** END program quireg**********************************************************************************************/
  
  
  /*********************************************************************************/
  /* program winsorize: replace variables outside of a range(min,max) with min,max */
  /*********************************************************************************/
  cap prog drop winsorize
  prog def winsorize
  {
    syntax anything,  [REPLace GENerate(name) centile]
  
    tokenize "`anything'"
  
    /* require generate or replace [sum of existence must equal 1] */
    if (!mi("`generate'") + !mi("`replace'") != 1) {
      display as error "winsorize: generate or replace must be specified, not both"
      exit 1
    }
  
    if ("`1'" == "" | "`2'" == "" | "`3'" == "" | "`4'" != "") {
      di "syntax: winsorize varname [minvalue] [maxvalue], [replace generate] [centile]"
      exit
    }
    if !mi("`replace'") {
      local generate = "`1'"
    }
    tempvar x
    gen `x' = `1'
  
  
    /* reset bounds to centiles if requested */
    if !mi("`centile'") {
  
      centile `x', c(`2')
      local 2 `r(c_1)'
  
      centile `x', c(`3')
      local 3 `r(c_1)'
    }
  
    di "replace `generate' = `2' if `1' < `2'  "
    replace `x' = `2' if `x' < `2'
    di "replace `generate' = `3' if `1' > `3' & !mi(`1')"
    replace `x' = `3' if `x' > `3' & !mi(`x')
  
    if !mi("`replace'") {
      replace `1' = `x'
    }
    else {
      generate `generate' = `x'
    }
  }
  end
  /* *********** END program winsorize ***************************************** */
  
  /**************************************************************************************************/
  /* program rd : produce a nice RD graph, using polynomial (quartic default) for fits         */
  /**************************************************************************************************/
  global rd_start -250
  global rd_end 250
  cap prog drop rd
  prog def rd
  {
    syntax varlist(min=2 max=2) [aweight pweight] [if], [degree(real 4) name(string) Bins(real 100) Start(real -9999) End(real -9999) MSize(string) YLabel(string) NODRAW bw xtitle(passthru) title(passthru) ytitle(passthru) xlabel(passthru) xline(passthru) absorb(string) control(string) xq(varname) cluster(passthru) xsc(passthru) fysize(passthru) fxsize(passthru) note(passthru) nofit]
  
    tokenize `varlist'
    local xvar `2'
  
    preserve

    /* Create convenient weight local */
    if ("`weight'"!="") local wt [`weight'`exp']

    /* get the weight variable itself by removing other elements of the expression */
    local wtvar "`wt'"
    foreach i in "=" "aweight" "pweight" "]" "[" " " {
      local wtvar = subinstr("`wtvar'", "`i'", "", .)
    }

    /* set start/end to global defaults (from include) if unspecified */
    if `start' == -9999 & `end' == -9999 {
      local start $rd_start
      local end   $rd_end
    }

    if "`msize'" == "" {
      local msize small
    }
  
    if "`ylabel'" == "" {
      local ylabel ""
    }
    else {
      local ylabel "ylabel(`ylabel') "
    }
  
    if "`name'" == "" {
      local name `1'_rd
    }
  
    /* set colors */
    if mi("`bw'") {
      local color_b "red"
      local color_se "blue"
    }
    else {
      local color_b "black"
      local color_se "gs8"
    }
  
    if "`se'" == "nose" {
      local color_se "white"
    }
  
    capdrop pos_rank neg_rank xvar_index xvar_group_mean rd_bin_mean rd_tag mm2 mm3 mm4 l_hat r_hat l_se l_up l_down r_se r_up r_down total_weight rd_resid tot_mean
    qui {

      /* restrict sample to specified range */
      if !mi("`if'") {
        keep `if'
      }
      keep if inrange(`xvar', `start', `end')
  
      /* get residuals of yvar on absorbed variables */
      if !mi("`absorb'")  | !mi("`control'") {
        if !mi("`absorb'") {
        reghdfe `1' `control' `wt' `if', absorb(`absorb') resid
        }
        else {
          reg `1' `control' `wt' `if'
        }
        predict rd_resid, resid
        local 1 rd_resid
      }
  
      /* GOAL: cut into `bins' equally sized groups, with no groups crossing zero, to create the data points in the graph */
      if mi("`xq'") {
  
        /* count the number of observations with margin and dependent var, to know how to cut into 100 */
        count if !mi(`xvar') & !mi(`1')
        local group_size = floor(`r(N)' / `bins')
  
        /* create ranked list of margins on + and - side of zero */
        egen pos_rank = rank(`xvar') if `xvar' > 0 & !mi(`xvar'), unique
        egen neg_rank = rank(-`xvar') if `xvar' < 0 & !mi(`xvar'), unique
  
        /* hack: multiply bins by two so this works */
        local bins = `bins' * 2
  
        /* index `bins' margin groups of size `group_size' */
        /* note this conservatively creates too many groups since 0 may not lie in the middle of the distribution */
        gen xvar_index = .
        forval i = 0/`bins' {
          local cut_start = `i' * `group_size'
          local cut_end = (`i' + 1) * `group_size'
  
          replace xvar_index = (`i' + 1) if inrange(pos_rank, `cut_start', `cut_end')
          replace xvar_index = -(`i' + 1) if inrange(neg_rank, `cut_start', `cut_end')
        }
      }
      /* on the other hand, if xq was specified, just use xq for bins */
      else {
        gen xvar_index = `xq'
      }
  
      /* generate mean value in each margin group */
      bys xvar_index: egen xvar_group_mean = mean(`xvar') if !mi(xvar_index)
  
      /* generate value of depvar in each X variable group */
      if mi("`weight'") {
        bys xvar_index: egen rd_bin_mean = mean(`1')
      }
      if "`weight'" != "" {
        bys xvar_index: egen total_weight = total(`wtvar') if !mi(`wtvar')
        bys xvar_index: egen rd_bin_mean = total(`wtvar' * `1')
        replace rd_bin_mean = (rd_bin_mean / total_weight)
      }

      /* generate a tag to plot one observation per bin */
      egen rd_tag = tag(xvar_index)
  
      /* run polynomial regression for each side of plot */
      gen mm2 = `xvar' ^ 2
      gen mm3 = `xvar' ^ 3
      gen mm4 = `xvar' ^ 4
  
      /* set covariates according to degree specified */
      if "`degree'" == "4" {
        local mpoly mm2 mm3 mm4
      }
      if "`degree'" == "3" {
        local mpoly mm2 mm3
      }
      if "`degree'" == "2" {
        local mpoly mm2
      }
      if "`degree'" == "1" {
        local mpoly
      }

      reg `1' `xvar' `mpoly' `wt' if `xvar' < 0, `cluster'
      predict l_hat
      predict l_se, stdp
      gen l_up = l_hat + 1.65 * l_se
      gen l_down = l_hat - 1.65 * l_se
  
      reg `1' `xvar' `mpoly' `wt' if `xvar' > 0, `cluster'
      predict r_hat
      predict r_se, stdp
      gen r_up = r_hat + 1.65 * r_se
      gen r_down = r_hat - 1.65 * r_se
    }
  
    if "`fit'" == "nofit" {
      local color_b white
      local color_se white
    }
    
    /* fit polynomial to the full data, but draw the points at the mean of each bin */
    sort `xvar'
    twoway ///
      (line r_hat  `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_b') msize(vtiny)) ///
      (line l_hat  `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_b') msize(vtiny)) ///
      (line l_up   `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
      (line l_down `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
      (line r_up   `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
      (line r_down `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
      (scatter rd_bin_mean xvar_group_mean if rd_tag == 1 & inrange(`xvar', `start', `end'), xline(0, lcolor(black)) msize(`msize') color(black)),  `ylabel'  name(`name', replace) legend(off) `title' `xline' `xlabel' `ytitle' `xtitle' `nodraw' `xsc' `fysize' `fxsize' `note' graphregion(color(white))
    restore
  }
  end
  /* *********** END program rd ***************************************** */
  
  /**********************************************************************************/
  /* program tag : Fast way to run egen tag(), using first letter of var for tag    */
  /**********************************************************************************/
  cap prog drop tag
  prog def tag
  {
    syntax anything [if]
  
    tokenize "`anything'"
  
    local x = ""
    while !mi("`1'") {
  
      if regexm("`1'", "pc[0-9][0-9][ru]?_") {
        local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
      }
      else {
        local x = "`x'" + substr("`1'", 1, 1)
      }
      mac shift
    }
  
    display `"RUNNING: egen `x'tag = tag(`anything') `if'"'
    egen `x'tag = tag(`anything') `if'
  }
  end
  /* *********** END program tag ***************************************** */
  
  /**********************************************************************************/
  /* program useshrug : Rapidly open the shrug */
  /***********************************************************************************/
  cap prog drop useshrug
  prog def useshrug
  {
    use shrid pc11_pca_tot_p using $shrug/data/shrug_pc11_pca, clear
  }
  end
  /* *********** END program useshrug ***************************************** */
  
  /**********************************************************************************/
/* program get_shrug_var : automagically gets a variable from the shrug           */
/* Example:
  - get_shrug_var pc11_pca_tot_p ec13_emp_all ec05_emp_all ec13_emp_obc           */
/**********************************************************************************/
cap prog drop get_shrug_var
prog def get_shrug_var
{
  syntax anything, [verbose]
  qui {

    /* create tempfiles for the desired varlist and sourcefile list */
    tempfile list
    tempfile tmp
    
    /* Create a temporary file with the requested variable list, which expands wildcards like [1-22] */
    shell python $PYPATH/get_vars.py --varlist "`anything'" --output_path `list'

    /* read the expanded variable list one line at a time: `line' contains a variable */
    cap file close fl
    file open fl using `list', read
    file read fl line
    while r(eof) == 0 {

      /* skip the variable if it already exists */
      cap confirm variable `line'
      if !_rc {
        noi di "WARNING: Ignoring request for `line', which is already in current dataset"
        file read fl line
        continue
      }
    
      /* use grep to get the file name with this string in it */
      shell grep "[ ]`line'" $repdata/shrug_varlist.txt | cut -f 1 -d "," >`tmp'

      /* read the filename into a stata variable */
      file open gsv_fh using `tmp', read
      file read gsv_fh filename
      file close gsv_fh

      /* if nothing was found, warn and loop */
      if mi(trim("`filename'")) {
        noi di "WARNING: Could not find `line'"
        file read fl line
        continue
      }
      if !mi("`verbose'") {
        noi di `"merge m:1 shrid using `filename', keepusing(`line') keep(master match) nogen update"'
      }
      merge m:1 shrid using `filename', keepusing(`line') keep(master match) nogen update
      count if mi(`line')
      if `r(N)' > 0 {
        noi di %6.0f `r(N)' " observations do not have `line'"
      }
      file read fl line
    }
    file close fl
  }
}
end
/* *********** END program get_shrug_var ***************************************** */

/*************************************************************************************************/
/* program get_shrug_key : automagically get a variable from a shrug key -- like pc91_state_name */
/*************************************************************************************************/
cap prog drop get_shrug_key
prog def get_shrug_key
{
  syntax anything, [verbose]
  qui {
    tokenize `anything'
    tempfile tmp

    while !mi("`1'") {
      
      /* get the file name with this string in it */
      shell grep "[ ]`1'" $repdata/shrug_keylist.txt | cut -f 1 -d "," >`tmp'

      /* read the filename into a stata variable */
      file open gsk_fh using `tmp', read
      file read gsk_fh filename
      file close gsk_fh

      /* if nothing was found, warn and loop */
      if mi(trim("`filename'")) {
        noi di "WARNING: Could not find `1'"
        mac shift
        continue
      }

      /* merge to the shrug key. Note that unlike get_shrug_var this is 1:m, requires unique shrid in master, b/c keys not unique on shrids */
      if !mi("`verbose'") {
        noi di `"merge 1:m shrid using `filename', keepusing(`1') keep(master match) nogen update"'
      }

      /* count # observations before merge */
      count
      local n_before_merge `r(N)'
      merge 1:m shrid using `filename', keepusing(`1') keep(master match) nogen update
      count if mi(`1')
      if `r(N)' > 0 {
        noi di %6.0f `r(N)' " observations do not have `1'"
      }
      count
      if `r(N)' > `n_before_merge' {
        noi di "Warning: Dataset is not unique on shrids anymore.  " %1.0f `r(N)' " new observations were added due to 1:m key."
      }
      mac shift
    }
  }
  
}
end
/* *********** END program get_shrug_key ***************************************** */
  
 }
