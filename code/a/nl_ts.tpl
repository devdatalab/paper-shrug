\begin{tabular}{lccccc}
  \hline\hline
 & (1) & (2) & (3) & (4) & (5) \\
 & District & Subdistrict & Town & Village & Village \\
  
  \hline
Log Population & $$dts_pop_starbeta$$ & $$sdts_pop_starbeta$$ & $$tts_d_pop_starbeta$$ & $$vts_d_pop_starbeta$$ & $$vts_sd_pop_starbeta$$ \\
               & ($$dts_pop_se$$)     & ($$sdts_pop_se$$)     & ($$tts_d_pop_se$$)     & ($$vts_d_pop_se$$)     & ($$vts_sd_pop_se$$)     \\

Log Non-Farm Employment  & $$dts_emp_starbeta$$ & $$sdts_emp_starbeta$$ & $$tts_d_emp_starbeta$$ & $$vts_d_emp_starbeta$$ & $$vts_sd_emp_starbeta$$ \\
    & ($$dts_emp_se$$)     & ($$sdts_emp_se$$)     & ($$tts_d_emp_se$$)     & ($$vts_d_emp_se$$)     & ($$vts_sd_emp_se$$)     \\

Log Manufacturing Employment & $$dts_manuf_starbeta$$ & $$sdts_manuf_starbeta$$ & $$tts_d_manuf_starbeta$$ & $$vts_d_manuf_starbeta$$ & $$vts_sd_manuf_starbeta$$ \\
         & ($$dts_manuf_se$$)     & ($$sdts_manuf_se$$)     & ($$tts_d_manuf_se$$)     & ($$vts_d_manuf_se$$)     & ($$vts_sd_manuf_se$$)     \\

Log Services Employment & $$dts_serv_starbeta$$ & $$sdts_serv_starbeta$$ & $$tts_d_serv_starbeta$$ & $$vts_d_serv_starbeta$$ & $$vts_sd_serv_starbeta$$ \\
    & ($$dts_serv_se$$)     & ($$sdts_serv_se$$)     & ($$tts_d_serv_se$$)     & ($$vts_d_serv_se$$)     & ($$vts_sd_serv_se$$)     \\

Electricity (Rural) & $$dts_power_starbeta$$ & $$sdts_power_starbeta$$ & & $$vts_d_power_starbeta$$ & $$vts_sd_power_starbeta$$ \\
      & ($$dts_power_se$$)     & ($$sdts_power_se$$)     & & ($$vts_d_power_se$$)     & ($$vts_sd_power_se$$)     \\

Electricity (Urban) &  &  & $$tts_d_powert_starbeta$$ & & \\
      &  &  & ($$tts_d_powert_se$$)     & & \\

\hline
N         & $$dts_pop_n$$       & $$sdts_pop_n$$     & $$tts_d_pop_n$$    & $$vts_d_pop_n$$     & $$vts_sd_pop_n$$                          \\

Fixed Effects & District, & Subdistrict, & Town,        & Village,        & Village,           \\
              & Year      & Year         & District * Year & District * Year & Subdistrict * Year \\

\hline
\multicolumn{6}{l}{$^{*}p<0.10, ^{**}p<0.05, ^{***}p<0.01$} \\
\end{tabular}
