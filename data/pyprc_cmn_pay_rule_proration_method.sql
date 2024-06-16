  
/**********************************************************************************************/  
/* procedure      pyprc_cmn_pay_rule_proration_method                                         */  
/* description    To compute employee's salary based on proration method       */  
/*                                                                                            */  
/**********************************************************************************************/  
/* project        NGP                                                                         */  
/* version        1 0 00                                                                      */  
/* rule version   1 0 00                                                                      */  
/**********************************************************************************************/  
/* referenced  epin_employee, tmscd_emp_rota_schd_map, tmscd_attENDance_param,    */  
/* tables/views   , pyprc_cmn_rule_leave_exclude, hrcompn_flexibenft_auth_brkupvw     */  
/*     hros_compensation_conv_factor, ladm_leave_breakup_dtl,       */  
/*     tmscd_rota_sch_gre_caldr ,  tmgif_shift_hdr         */  
/**********************************************************************************************/  
/* development history                                                                        */  
/* author           : Pradeep Balaji . B                                                      */  
/* date             : 29-Jan-2018                                                             */  
/**********************************************************************************************/  
/* modified by                                                                                */  
/* date                                                                     */  
/* description                      */  
/**********************************************************************************************/  
  
----------------------------------Do not Delete or alter this line-------------------------------  
--$versionnumber$::$$$47$$$$  Please dont delete this line$$$$$$$$$$$$$$$$$$$  
----------------------------------Do not Delete or alter this line-------------------------------  
  
create  procedure pyprc_cmn_pay_rule_proration_method  
 @rule_type   hrcd,   
 @pay_elt_cd   hrcd,  
 @payroll_ou_cd  hrouinstance,   
 @payroll_cd   hrcd,   
 @paySET_cd   hrcd,     
 @prcprd_cd   hrint, --hrcd, --code added and commented by Arthi R V on 15-sep-2021 HRP-4972 for removal of int conversion  
 @process_number  hrint,   
 @pprd_FROM_date  DATETIME,  
 @pprd_to_date  DATETIME,  
 @progressive_flag hrcd  
As  
BEGIN  
  
 SET NOCOUNT ON  
   
 EXEC pyprc_cmn_pprd_validation_sp --code added by Arthi R V on 15-sep-2021 HRP-4972 for removal of int conversion  
  
 --CIM Declaration  
 DECLARE @empin_ou  hrouinstance  
 DECLARE @empng_ou  hrouinstance  
 DECLARE @lvdef_ou  hrouinstance  
 DECLARE @pydef_ou  hrouinstance  
 DECLARE @cal_days  hrint  
 DECLARE @pay_cal_code hrcode  
  
 --For salary convertion  
 DECLARE @payset_currency  hrcurrency  
 DECLARE @comcode    hrcurrency  
 DECLARE @erate_ou    hrouinstance  
 DECLARE @pyset_ou    hrouinstance  
 DECLARE @pyelt_ou    hrouinstance  
 DECLARE @exratetype    description ='~BR~'  
 DECLARE @exchange_date   DATETIME  
 DECLARE @count_ou    hrint  
 DECLARE @getdate    DATETIME  
 DECLARE @login_language   ctxt_language  
 DECLARE @pay_frequency          hrquickcode --Code added by Sharmila J on 10-Jan-2019   
 --DECLARE @called_for    hrquickcode --RULE -SA0002--Code added by Sharmila J on 19-Mar-2019 for the defect id HC-3284  
  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 DECLARE @tmgif_ou    hrouinstance  
 DECLARE @assn_no    hrassgnno   
 --DECLARE @emp_cd     hrempcode   --RULE -SA0002  
 --DECLARE @amount     hrsalary --RULE -SA0002  
 --DECLARE @std_amount    hrsalary--RULE -SA0002  
 DECLARE @sys_param_lopctc  hrflag  
 DECLARE @syspr_ou    hrouinstance  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
 DECLARE @empmvou    hrouinstance--Code added by Sharmila J for HRP-2401 on 10-Mar-2021  
 DECLARE @payroll_type   hrtext100--code added by Arthi R V on 31-May-2021 for the defect id HRP-3338  
 --DECLARE @arrears_set_cd         hrcd    /* code commented from HRPS-6299 */  
        --DECLARE @arrears_mode           hrdesc40  /* code commented from HRPS-6299 */  
  
    select @assn_no = 1 --Added for SGIH-150  
 --Code commented by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <Begin>  
 --Temp tables has been changed to permanent table to enhances the performance  
 /*   
 The below temp tables are changed to permanent table respectively  
 #wrk_tmp     - pyprc_cmn_ctc_rule_wrk_tmp  
 #week_begins    - pyprc_cmn_ctc_rule_week_begins  
 #gre_cal_tmp    - pyprc_cmn_ctc_rule_gre_cal_tmp  
 #CTC_tmp     - pyprc_cmn_ctc_rule_comp_tmp  
 #emp_gre_cal    - pyprc_cmn_ctc_rule_emp_gre_cal  
 #hour_conv_freq_tmp   - pyprc_cmn_hour_conv_freq_tmp  
  
 --Code added and commented by Sharmila J on 14-Feb-2019 for the defect id HC-3077 <Begin>  
 --Temporary table declaration   
 CREATE TABLE #wrk_tmp   
 (   
  master_ou     INT,  
  emp_ou      INT,   
  employee_code    NVARCHAR(60),  
  pror_type     NVARCHAR(10),  
  paid_wrking_days   NUMERIC(28,8),--NUMERIC(15,4),--Code changed by Sharmila J for the defect id HC-3293 on 15-Mar-2019  
  sch_days     NUMERIC(28,8),--NUMERIC(15,4),  
  sch_hrs      NUMERIC(28,8),--NUMERIC(15,4),  
  per_day_sal     NUMERIC(28,8),  
  per_hr_sal     NUMERIC(28,8),  
  mon_sal      NUMERIC(28,8),  
  opted_amount    NUMERIC(28,8),--NUMERIC(15,4),  
  lop_days     NUMERIC(8,2),  
  lop_hours     NUMERIC(8,2),  
  lop_days_amount    NUMERIC(28,8),  
  lop_hours_amount   NUMERIC(28,8),  
  paid_week_off    NVARCHAR(10),  
  employment_flag    NVARCHAR(6),  
  employment_date    DATETIME,  
  separation_flag    NVARCHAR(6),  
  separation_date    DATETIME,  
  effective_from    DATETIME,  
  effective_to    DATETIME,  
  rota_schedule_code   NVARCHAR(20),  
  ctc_exchange_type   NVARCHAR(10),  
  ctc_exchange_date   DATETIME,  
  ctc_exchange_rate   NUMERIC(28,8),  
  proration_applicable_for NVARCHAR(10),  
  salary_change_flag   NVARCHAR(6)  
  --code added and commented by Vidya A for the defect id HSH-32 on 22-May-2020 <starts>  
  ,std_hrs_per_day   NUMERIC(15,4),  
  --,std_hrs_per_day   NUMERIC(5,4),  
  --code added and commented by Vidya A for the defect id HSH-32 on 22-May-2020 <ends>  
  hour_conv_freq    NVARCHAR(20),  
  ctc_frequency    NVARCHAR(10)--SJ  
  ,full_month_lop    NVARCHAR(10)--SJ  
  ,tot_paid_days    NUMERIC(28,8)--Code added by Sharmila J on 12-Mar-2020  
  ,std_amt_flag    NVARCHAR(10)-- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121  
  ,assignment_no    INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,mid_prd_prora_based_on  NVARCHAR(20)--HRPS-1824  
  ,fixed_days     NUMERIC(15,4)--NOIH-129  
 )  
   
 CREATE INDEX ix_wrk_tmp ON #wrk_tmp (employee_code)  
  
 CREATE TABLE #week_begins   
 (  
  master_ou   INT,  
  employment_ou  INT,  
  emp_code   NVARCHAR(60),  
  rota_plan_code  NVARCHAR(20),  
  rota_schedule_code NVARCHAR(20),  
  week_begin_day  NVARCHAR(160),  
  week_start_date  DATETIME,  
  week_end_date  DATETIME,  
  pprd_END_date  DATETIME,  
  effective_from  DATETIME,  
  effective_to  DATETIME  
  ,assignment_no  INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 )  
   
 CREATE INDEX ix_week_begins ON #week_begins (emp_code)  
  
 CREATE TABLE #gre_cal_tmp   
 (  
  master_ou   INT,  
  emp_ou    INT,  
  --assign_no   NVARCHAR(10),--Code commented by Sharmila J on 05-Feb-2021 for HRP-837  
  sno     NVARCHAR(20),  
  emp_code   NVARCHAR(60),  
  pprd_days   INT,  
  schedule_date  DATETIME,  
  rota_schedule_code NVARCHAR(20),  
  shift_code   NVARCHAR(20),  
  week_tot_hrs  NUMERIC(15,4),  
        break_hrs           NUMERIC(15,4), --ORH-1161 --  
  mon_tot_hrs   NUMERIC(15,4),  
  mid_join_hrs  NUMERIC(15,4),  
  holiday_qc   NVARCHAR(10),  
  weeklyoff_qc  NVARCHAR(10),  
  offday_qc   NVARCHAR(10),  
  Effective_from  DATETIME,  
  Effective_to  DATETIME  
  ,assignment_no  INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 )  
   
 CREATE INDEX ix_gre_cal_tmp ON #gre_cal_tmp (emp_code)  
  
 CREATE TABLE #CTC_tmp   
 (  
  master_ou_code   INT,  
  empin_ou    INT,  
  employee_code   NVARCHAR(60),  
  effective_from   DATETIME,  
  effective_to   DATETIME,  
  payelement_code   NVARCHAR(20),  
  opted_amount   NUMERIC(28,8),--NUMERIC(15,4),  
  pyelt_exchange_type  NVARCHAR(10),  
  pyset_currency_code  NVARCHAR(10),  
  pyelt_currency_code  NVARCHAR(10),  
  frequency_code   NVARCHAR(10),  
  ctc_exchange_rate  NUMERIC(28,8)  
  ,assignment_no    INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 )  
  
 CREATE INDEX ix_CTC_tmp ON #CTC_tmp (employee_code)  
  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 CREATE TABLE #hour_conv_freq_tmp  
 (  
  employee_code    NVARCHAR(60),  
  process_period_code   INT,  
  period_from_date   DATETIME,  
  period_to_date    DATETIME,  
  effective_from_date   DATETIME,  
  effective_to_date   DATETIME,  
  --code added and commented by Vidya A for the defect id HSH-32 <starts>  
  stdhrsperday    NUMERIC(15,4),  
  --stdhrsperday    NUMERIC(5,4),  
  --code added and commented by Vidya A for the defect id HSH-32 <ends>  
  rota_plan_code    NVARCHAR(160),  
  rota_schedule_code   NVARCHAR(160),  
  proration_method   NVARCHAR(10),  
  hourly_rate_conversion  NVARCHAR(10)  
  ,assignment_no    INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 )  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
 CREATE TABLE #emp_gre_cal    
 (    
  master_ou    INT,    
  employment_ou   INT,    
  employee_code   NVARCHAR(60),    
  original_shift_code  NVARCHAR(20),    
  shift_code    NVARCHAR(20),    
  schedule_date   DATETIME,    
  holiday_qc    NVARCHAR(10),    
  shift_devn_qc   NVARCHAR(10),    
  offday_qc    NVARCHAR(10)    
  ,assignment_no   INT--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 )  
   
 CREATE INDEX ix_emp_gre_cal ON #emp_gre_cal (employee_code)  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
 */  
 --Code commented by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <End>  
  
/*  
 --Temporary table declaration   
 DECLARE @wrk_tmp table  
 (   
  master_ou   hrouinstance,  
  emp_ou    hrouinstance,   
  employee_code  hrempcode ,  
  pror_type   hrquickcode ,  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
  paid_wrking_days hrsalary ,  
  --paid_wrking_days hrint  ,  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
  sch_days   hrsalary ,  
  sch_hrs    hrsalary ,  
  per_day_sal   amount ,  
  per_hr_sal   amount ,  
  mon_sal    amount ,  
  opted_amount  hrsalary  ,  
  lop_days   hrleaveunits ,  
  lop_hours   hrleaveunits ,  
  --Code added by Senthil Arasu B on 17-Oct-2018 for the defect id HC-2634 <Begin>   
  lop_days_amount  amount ,  
  lop_hours_amount amount ,  
  --Code added by Senthil Arasu B  on 17-Oct-2018 for the defect id HC-2634 <End>   
  paid_week_off  hrquickcode ,  
  employment_flag  hrflag  ,  
  employment_date  datetime ,  
  separation_flag  hrflag  ,  
  separation_date  datetime ,  
  effective_from  datetime ,  
  effective_to  datetime ,  
  rota_schedule_code hrcd  ,  
  ctc_exchange_type hrquickcode ,  
  ctc_exchange_date DATETIME ,  
  ctc_exchange_rate fin_exchangerate,  
  proration_applicable_for hrcode --Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  ,salary_change_flag hrflag  --Code added by Senthil Arasu B on 30-Nov-2018 for the defect id HC-2667  
 )  
  
 DECLARE @week_begins table  
 (  
  master_ou   hrouinstance,  
  employment_ou  hrouinstance,  
  emp_code   hrempcode,  
  rota_plan_code  hrcd,  
  rota_schedule_code hrcd,  
  week_begin_day  hrdesc40,  
  week_start_date  datetime,  
  week_end_date  datetime,  
  pprd_END_date  datetime,  
  effective_from  datetime,  
  effective_to  datetime  
 )  
  
 DECLARE @gre_cal_tmp table  
 (  
 master_ou   hrouinstance,  
 emp_ou    hrouinstance,  
 assign_no   hrquickcode,  
 sno     hrcd,  
 emp_code   hrempcode,  
 pprd_days   hrint ,  
 schedule_date  datetime,  
 rota_schedule_code hrcd,  
 shift_code   hrcd,  
 week_tot_hrs  hrsalary,  
 mon_tot_hrs   hrsalary,  
 mid_join_hrs  hrsalary,  
 holiday_qc   hrquickcode,  
 weeklyoff_qc  hrquickcode,  
 offday_qc   hrquickcode,  
 Effective_from  datetime,  
 Effective_to  datetime  
 )  
   
 DECLARE @CTC_tmp Table  
 (  
 master_ou_code   hrouinstance,  
 empin_ou    hrouid,  
 employee_code   hrempcode,  
 effective_from   datetime,  
 effective_to   datetime,  
 payelement_code   hrcd,  
 opted_amount   hrsalary,  
 pyelt_exchange_type  hrquickcode ,  
 pyset_currency_code  hrcode ,  
 pyelt_currency_code  hrcode ,  
 frequency_code   hrquickcode,  
 ctc_exchange_rate  fin_exchangerate  
 )  
*/  
 --Code added and commented by Sharmila J on 14-Feb-2019 for the defect id HC-3077 <End>  
  
 --Finding the employment ou code    
 SELECT @empin_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)   
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'  
 AND  target_component = 'HRMSEMPIN'  
  
 --Finding the Master definition ou        
 SELECT @empng_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)  
 WHERE source_ou_code  = @empin_ou  
 AND  source_component = 'HRMSEMPIN'  
 AND  target_component = 'HRMSEMPNG'  
  
 --Code added by Sharmila J for HRP-2401 on 10-Mar-2021 <Begin>  
 --Finding the employee movements ou code  
 SELECT @empmvou   = target_ou_code        
    FROM hrcmn_cim_view WITH(NOLOCK)       
 WHERE source_ou_code  = @empin_ou   
 AND  source_component = 'HRMSEMPIN'    
 AND  target_component = 'HRMSEMPMV'   
 --Code added by Sharmila J for HRP-2401 on 10-Mar-2021 <End>  
  
 --Code added and commented by Sharmila J for the defect id SMH-135 on 16-Oct-2019 <Begin>  
 --Finding the leave definition ou   
 SELECT @lvdef_ou   = source_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)  
 where source_component = 'HRMSLVDEF'  
 and  target_ou_code  = @empin_ou  
 and  target_component = 'HRMSEMPIN'  
  
/* SELECT @lvdef_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)  
 where source_component = 'HRMSLVDEF'  
 and  source_ou_code  = @empin_ou  
 and  target_component = 'HRMSEMPIN'  
*/  
 --Code added and commented by Sharmila J for the defect id SMH-135 on 16-Oct-2019 <End>  
  
 --Code added and commented by Sharmila J on 25-Oct-2021 for HRP-3338<Begin>  
 -- query to fetch payroll definition unit  
 SELECT @pydef_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)--Rule SA0021  
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'   
 AND  target_component = 'HRMSPYDEF'  
 /*  
 --Finding the payroll definition ou   
 SELECT @pydef_ou   = target_ou_code          
 FROM hrcmn_cim_view WITH (NOLOCK)        
 WHERE source_component = 'HRMSPYRPT'          
 AND  source_ou_code  = @empin_ou          
 AND  target_component = 'HRMSPYDEF'  
 */  
 --Code added and commented by Sharmila J on 25-Oct-2021 for HRP-3338 <End>  
  
 --Finding the payroll Calender Code   
 SELECT @pay_cal_code  = payroll_calendar_code  
 FROM hrpydef_pyrl_def_hdr hdr WITH (NOLOCK)  
 WHERE hdr.master_ou  = @pydef_ou  
 AND  hdr.payroll_code = @payroll_cd  
   
 --Finding the Calender Days  
 SELECT @cal_days   = DATEDIFF(dd,@pprd_FROM_date,@pprd_to_date)+1   
   
 -- for multicurrency conversion   
 SELECT @getdate  = dbo.RES_Getdate(@payroll_ou_cd)--Code Modified for Time Zone Changes - Defect ID -HRMS20_GEN_00507  
 SELECT @exchange_date = CASE WHEN @getdate > @pprd_to_date THEN @pprd_to_date ELSE @getdate END  
  
 -- Finding Exchange Rate definition ou  
 SELECT @erate_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH (NOLOCK)  
 WHERE source_ou_code  = @payroll_ou_cd  
 AND  source_component = 'HRMSPYACT'  
 AND  target_component = 'ERATE'  
  
 --Finding the Payset definition ou        
 SELECT @pyset_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'   
 AND  target_component = 'HRMSPYSET'  
  
 --Code added and commented by Sharmila J for the defect id COH-152 on 20-Apr-2020 <Begin>  
 --Finding the Pay element definition ou        
 SELECT @pyelt_ou   = source_ou_code   
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE target_ou_code  = @pydef_ou   
 AND  target_component = 'HRMSPYDEF'  
 AND  source_component = 'HRMSPYELT'   
 /*  
 --Finding the Payset definition ou        
 SELECT @pyelt_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'   
 AND  target_component = 'HRMSPYELT'  
 */  
 --Code added and commented by Sharmila J for the defect id COH-152 on 20-Apr-2020 <End>  
  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 --Finding the Time Management definition ou        
  SELECT @tmgif_ou   = source_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE target_ou_code  = @empin_ou  
 AND  target_component = 'HRMSEMPIN'  
 AND  source_component = 'HRMSTMGIF'  
  
 --Finding the System parameter ou  
 SELECt @syspr_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @empin_ou  
 AND  source_component = 'HRMSEMPIN'   
 AND  target_component = 'HRMSSYSPR'  
  
 --System parameter flag - LOP deduction through CTC  
 SELECT @sys_param_lopctc   = system_param_value  
 FROM hrsp_sysparam_values WITH (NOLOCK)         
 WHERE master_ou_code    = @syspr_ou  
 AND  UPPER(system_param_code) = 'LOPCTC'  
 AND  quick_code_flag    = 'Y'    
   
 SELECT @sys_param_lopctc = ISNULL(@sys_param_lopctc,'N')  
  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
  
 --code added by Arthi R V on 31- May-2021 for the defect id HRP-3338<Begin>  
 SELECT @payroll_type  = createdby   
 FROM pyprc_pre_payroll WITH (NOLOCK)  
 WHERE process_number  = @process_number  
 --code added by Arthi R V on 31- May-2021 for the defect id HRP-3338<End>  
  
 --Finding the login language   
 --code added by Arthi R V on 31- May-2021 for the defect id HRP-3338<Begin>  
 IF @payroll_type = 'ARREAR'  
 BEGIN  
  /*Code modified by HARI for Language code passed NULL while do manual arrear and payroll process on 30-mar-2023 SAIH-1077 <BEGIN>  */   
  
  --SELECT @login_language  = login_language      
  --FROM hrpyprc_payset_ready_cnt WITH (NOLOCK)      
  --WHERE master_ou   = @pydef_ou  
  --AND  process_number  = @process_number   
  
     --SELECT @arrears_set_cd      = arrears_set_cd, /* code commented from HRPS-6299 */  
     --@arrears_mode        = arrears_set_desc  
    --FROM   hrpyars_arrears_set_hdr WITH (NOLOCK)   
    --WHERE  payroll_master_ou    = @payroll_ou_cd  
    --AND    arrear_payroll_code  = @payroll_cd  
    --AND    arrears_payset_code  = @payset_cd  
    --AND    @prcprd_cd           BETWEEN CONVERT(INT, arrear_from_pprd_code) AND CONVERT(INT, arrear_to_pprd_code)  
      
    SELECT @login_language      = prc.login_language  
    FROM   hrpyars_arrears_prc_cnt prc (nolock)        
    WHERE  prc.process_number   = @process_number        
    --AND    prc.arrears_set_cd   = CASE WHEN @arrears_set_cd = '*' THEN prc.arrears_set_cd ELSE @arrears_set_cd END  /* code commented from HRPS-6299 */  
  
 /* SAIH-1077 <END>*/  
 END  
 ELSE  
 BEGIN  
 --code added by Arthi R V on 31- May-2021 for the defect id HRP-3338<End>  
  SELECT @login_language  = login_language      
  FROM hrpyprc_pyrol_process_cnt WITH (NOLOCK)      
  WHERE master_ou   = @pydef_ou  
  AND  process_number  = @process_number       
 END--code added by Arthi R V on 31- May-2021 for the defect id HRP-3338  
  
 IF @erate_ou IS NULL  
 BEGIN   
  SELECT @erate_ou = @payroll_ou_cd  
 END  
  
 IF EXISTS ( SELECT 'X'  
    FROM erate_exrate_mst exc WITH (NOLOCK)  
    WHERE exc.ou_id = @erate_ou)  
 BEGIN   
  SELECT @erate_ou = @erate_ou  
 END   
 ELSE   
 BEGIN  
  SELECT @count_ou = COUNT(DISTINCT (ou_id))  
  FROM erate_exrate_mst WITH (NOLOCK)  
    
  IF @count_ou = 1  
  BEGIN  
   SELECT  @erate_ou = ou_id  
   FROM erate_exrate_mst WITH (NOLOCK)  
  END  
  ELSE  
  BEGIN  
   SELECT @erate_ou = NULL  
  END  
 END   
   
 --Finding the Payset Currency  
 SELECT @payset_currency = LTRIM(RTRIM(currency))   
 FROM hrpyset_payset_hdr WITH (NOLOCK)        
 WHERE master_ou   = @pyset_ou  
 AND  payset_code   = @payset_cd   
 AND  payroll_master_ou = @pydef_ou  
 AND  payroll_code  = @payroll_cd   
  
 SELECT @comcode   = company_code    
 FROM hrcmn_company_ou_map_view WITH (NOLOCK)   
 WHERE ou_code    = @payroll_ou_cd   
    
 SELECT @exratetype   = parameter_code  
 FROM fbp_setfn_eratetype_wrap_vw WITH (NOLOCK)         
 WHERE ou_id    = @erate_ou --CHECK CIM   
 AND     company_code  = @comcode  
 AND  language_id   = isnull(@login_language,1) --MCIH-435  
   
 --Code added by Sharmila J on 06-sep-2022 <Begin>  
 -- to get the actual working days   
 DECLARE @stdhrs_per_day  hrsalary  
  
 SELECT @stdhrs_per_day  = stdhrs_per_day  
 FROM ldef_leave_parameters WITH (NOLOCK)  
 WHERE master_ou_code  = @lvdef_ou  
 --Code added by Sharmila J on 06-sep-2022 <End>  
   
 -- to get employee's details from interim process table  
 INSERT INTO pyprc_cmn_ctc_rule_wrk_tmp  
   (   
    master_ou,  
    emp_ou,  
    employee_code,  
    pror_type,  
    paid_wrking_days,  
    paid_week_off,  
    sch_days ,   
    sch_hrs  ,   
    per_day_sal ,   
    per_hr_sal ,   
    mon_sal  ,   
    lop_days  ,  
    employment_flag,   
    employment_date,  
    Separation_flag,  
    Separation_date,  
    effective_from ,  
    effective_to ,  
    rota_schedule_code,  
    proration_applicable_for--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
    ,salary_change_flag -- code added by senthil arasu b on 30-Nov-2018 for the defect id HC-2667  
    ,hour_conv_freq  --Code added by Sharmila J for the defect id HST-7014   
    ,std_amt_flag -- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121  
    ,assignment_no --Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    ,process_number   --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    ,mid_prd_prora_based_on --HRPS-1824  
    ,fixed_days --NOIH-129  
    ,row_num --Code added by Sharmila J for HRP-5723 on 25-Nov-2021  
   )  
 SELECT master_ou_code,  
   employment_ou,  
   employee_code,  
   proration_method,  
   --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
   CASE WHEN proration_method IN ( 'FD','FCD') THEN fixed_days  
   --CASE WHEN proration_method = 'FD' THEN fixed_days  
   --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
        WHEN proration_method = 'CD' THEN @cal_days   
     ELSE 0  
   END,  
   paid_week_off,  
   0,  
   0,  
   0,  
   0,  
   0,  
   0,  
   null,  
   null,  
   'N',  
   null,  
   effective_from ,  
   effective_to ,  
   null,  
   proration_applicable_for--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
   ,'N' -- code added by senthil arasu b on 30-Nov-2018  
   ,hour_conv_freq --Code added by Sharmila J for the defect id HST-7014  
   ,'L' -- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121 To Default latest salary  
   ,assignment_no --Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,@process_number   --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   ,mid_prd_prora_based_on --HRPS-1824  
   ,fixed_days --NOIH-129  
   ,row_num --Code added by Sharmila J for HRP-5723 on 25-Nov-2021  
 FROM pyprc_cmn_rule_emp_process_tmp tmp WITH (NOLOCK)  
 WHERE tmp.master_ou_code  = @payroll_ou_cd      
 AND  tmp.rule_type   = @rule_type  
 AND  tmp.pay_element_code = @pay_elt_cd  
 AND  tmp.payroll_code  = @payroll_cd  
 AND  tmp.paySET_code   = @paySET_cd   
 AND  tmp.process_period_code = @prcprd_cd   
 AND  tmp.process_number  = @process_number  
  
 -- to find whether employee is mid month joiner  
 --Code added by Sharmila J for HRP-2401 on 10-Mar-2021 <Begin>  
 --Rehire logic  
 UPDATE tmp  
 SET  tmp.employment_flag    = CASE WHEN reh.rehire_date >= @pprd_from_date THEN 'Y' ELSE 'N' END,  
   tmp.employment_date    = reh.rehire_date  
 FROM hrmv_emp_rehire_dtl    reh WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp  tmp --WITH (NOLOCK)  
 WHERE reh.master_ou_code    = @empng_ou  
 AND  reh.employee_code    = tmp.employee_code  
 AND  reh.empmv_ou_code    = @empmvou  
 AND  reh.rehire_status    = 'A'  
 AND  reh.assignment_defined_ou_code = @empin_ou  
 AND  CONVERT(DATE, reh.rehire_date) BETWEEN tmp.effective_from AND tmp.effective_to  
 AND  tmp.emp_ou      = @empin_ou  
 AND  tmp.process_number    = @process_number  
 --Code added by Sharmila J for HRP-2401 on 10-Mar-2021 <End>  
  
 UPDATE tmp  
 --Code commented and added by Sharmila J on 16-July-2018 for the defect id HC-2097 <Begin>  
 --code changed by sundar for MCIH-923 on 16-July-2018 (To enable the flag as 'Y' when the employmenyt start date fall on the start date of month) <Begin>  
  SET  employment_flag   = CASE WHEN employment_start_date > @pprd_FROM_date THEN 'Y' ELSE 'N' END,  
 --SET  employment_flag   = CASE WHEN employment_start_date >= @pprd_FROM_date THEN 'Y' ELSE 'N' END,  
 --code changed by sundar for MCIH-923 on 16-July-2018 (To enable the flag as 'Y' when the employmenyt start date fall on the start date of month) <End>  
 --Code commented and added by Sharmila J on 16-July-2018 for the defect id HC-2097 <End>  
   employment_date   = employment_start_date  
 FROM epin_employee  epin WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp   tmp  
 Where epin.master_ou_code  = @empng_ou   
 AND  epin.employee_code  = tmp.employee_code  
 AND  tmp.emp_ou    = @empin_ou  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.employment_date  IS NULL--Code added by Sharmila J for HRP-2401 on 10-Mar-2021  
  
 -- to find whether employee is mid month Separater  
 UPDATE tmp  
 --code changed by sundar for MCIH-923 (To enable the flag as 'N' when the employmenyt end date fall on the last date of month) <Begin>  
  --SET  Separation_flag  = 'Y',  
  SET  Separation_flag = CASE WHEN hdr.last_available_date=@pprd_to_date then 'N' else 'Y' end,  
    --code changed by sundar for MCIH-923 (To enable the flag as 'N' when the employmenyt end date fall on the last date of month) <End>  
   Separation_date  = hdr.last_available_date  
 FROM hrmv_emp_sep_hdr hdr WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp   tmp  
 WHERE hdr.master_ou_code = @empng_ou   
 AND  tmp.emp_ou   = @empin_ou  
 -- code commented and added by senthil arasu b on 12-Jul-2018 for defect id HC-2061<begins>  
 -- to update the separtion flage for the speration period only.  
 AND hdr.last_available_date Between @pprd_FROM_date and @pprd_to_date --Uncommented for HIIH-192  
 --AND  CONVERT(date, hdr.last_available_date) BETWEEN effective_from AND effective_to --Commented for HIIH-192  
 -- code commented and added by senthil arasu b on 12-Jul-2018 for defect id HC-2061<ends>  
 AND  hdr.employee_code = tmp.employee_code  
 AND  separation_status = 'A'  
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 update tmp  
 set  rota_schedule_code = map.rota_schedule_code  
   ,rota_plan_code  = map.rota_plan_code--Code added by Sharmila J on 02-Aug-2022 for HRP-8576  
 from pyprc_cmn_ctc_rule_wrk_tmp   tmp,  
   tmscd_emp_rota_schd_map map WITH (NOLOCK)  
 Where map.master_ou  = tmp.master_ou  
 AND  map.employment_ou = tmp.emp_ou  
 AND  map.emp_code  = tmp.employee_code  
 --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837<Begin>  
 AND  map.assignment_no = tmp.assignment_no  
 --AND  map.assignment_no = 1  
 --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837<End>  
 AND  tmp.effective_to between map.eff_FROM_date and isnull(map.eff_to_date,tmp.effective_to)     
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   
 --Code moved from below by Sharmila J on 26-Aug-2022 for HRPS-4125 <Begin>  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
 --Get employee's gre calendar data into the temp table pyprc_cmn_ctc_rule_emp_gre_cal  
 INSERT INTO pyprc_cmn_ctc_rule_emp_gre_cal     
 (   
  master_ou,    employment_ou,   employee_code,    original_shift_code,     
  shift_code,    schedule_date,   holiday_qc,     shift_devn_qc,    
  offday_qc       
  ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,process_number     --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  ,rota_plan_code,  rota_schedule_code--Code added by Sharmila J on 02-Aug-2022 for HRP-8576    
 )    
 SELECT    
  gre.master_ou,   gre.employment_ou,  gre.employee_code,   gre.original_shift_code,     
  gre.shift_code,   gre.schedule_date,  gre.holiday_qc,    gre.shift_devn_qc,    
  gre.offday_qc       
  ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,@process_number    --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542   
  ,gre.rota_plan_code, gre.rota_schedule_code--Code added by Sharmila J on 02-Aug-2022 for HRP-8576    
 FROM tmscd_emp_gre_calendar gre WITH (NOLOCK)    
 JOIN (  
    SELECT DISTINCT  
      master_ou, --Code added by Sharmila.J on 09-Jun-2020 for the defect id JSPH-188  
      emp_ou,  
      employee_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    -- code added and commented by senthil arasu b on 02-Dec-2022 for HRPS-5160 <start>  
    FROM pyprc_cmn_ctc_rule_wrk_tmp WITH(NOLOCK)  
    WHERE master_ou   = @payroll_ou_cd   
    AND  emp_ou    = @empin_ou   
    AND  process_number  = @process_number  
    /**AHLPI-149**/  
    AND  pror_type   NOT IN ('CD', 'FCD')   
    --AND  pror_type   IN ('WH','AWH','WD','AWD','FD')  -- Code 'FD' is handled for HRPS-5637 by HARI   
    /**AHLPI-149**/  
    --FROM pyprc_cmn_ctc_rule_wrk_tmp  
    -- code added and commented by senthil arasu b on 02-Dec-2022 for HRPS-5160 <end>  
      
   )tmp  
 ON  tmp.master_ou  = gre.master_ou --Code added by Sharmila.J on 09-Jun-2020 for the defect id JSPH-188  
 AND  tmp.emp_ou   = gre.employment_ou  
 AND  tmp.employee_code = gre.employee_code  
 AND  tmp.assignment_no = gre.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837      
 --Code added and commented by Sharmila J for the defect id HBM-1843 on 25-Sep-2020 <Begin>  
 WHERE gre.master_ou  = @tmgif_ou   
    AND  gre.employment_ou = @empin_ou --Code added by Sharmila J for the defect id COH-134 on 08-Apr-2020  
    --WHERE gre.employment_ou = @empin_ou --Code added by Sharmila J for the defect id COH-134 on 08-Apr-2020  
 --Code added and commented by Sharmila J for the defect id HBM-1843 on 25-Sep-2020 <End>  
 AND  gre.schedule_date BETWEEN @pprd_from_date AND @pprd_to_date  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
  
 --Fetching Week Begin Data  
 INSERT INTO pyprc_cmn_ctc_rule_week_begins  
   (  
   master_ou  ,  
   employment_ou ,  
   emp_code  ,  
   rota_plan_code,  
   rota_schedule_code,  
   week_begin_day ,  
   week_start_date ,  
   week_end_date ,  
   pprd_END_date ,  
   effective_from ,  
   effective_to  
   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   )   
 SELECT map.master_ou ,  
   map.employment_ou,  
   map.emp_code,  
   map.rota_plan_code,  
   map.rota_schedule_code,  
   par.Week_begins_qc,  
   CASE WHEN par.Week_begins_qc = 'SUN' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'MON' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'TUE' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'WED' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'THUR'THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'FRI' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-6  
              END  
     WHEN par.Week_begins_qc = 'SAT' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'saturday' THEN @pprd_FROM_date  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'sunday'  THEN @pprd_FROM_date-1  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'monday'  THEN @pprd_FROM_date-2  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'tuesday' THEN @pprd_FROM_date-3  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'wednesday' THEN @pprd_FROM_date-4  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'thursday' THEN @pprd_FROM_date-5  
                 WHEN DATENAME(WEEKDAY,@pprd_FROM_date) = 'friday'  THEN @pprd_FROM_date-6  
              END  
   END ,  
   CASE WHEN par.Week_begins_qc = 'SUN' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'MON' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'TUE' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'WED' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'THUR'THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'FRI' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date  
              END  
     WHEN par.Week_begins_qc = 'SAT' THEN   
              CASE  WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'saturday'  THEN @pprd_to_date+6  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'sunday'  THEN @pprd_to_date+5  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'monday'  THEN @pprd_to_date+4  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'tuesday'  THEN @pprd_to_date+3  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'wednesday' THEN @pprd_to_date+2  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'thursday'  THEN @pprd_to_date+1  
                 WHEN DATENAME(WEEKDAY,@pprd_to_date) = 'friday'  THEN @pprd_to_date  
              END  
   END ,  
   @pprd_to_date,  
   tmp.effective_from,  
   tmp.effective_to  
   ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 FROM tmscd_emp_rota_schd_map map WITH (NOLOCK),  
   tmscd_attENDance_param par WITH (NOLOCK),  
   pyprc_cmn_rule_emp_process_tmp tmp WITH (NOLOCK)  
 WHERE tmp.master_ou_code  = @payroll_ou_cd              
 AND  tmp.rule_type   = @rule_type  
 AND  tmp.pay_element_code = @pay_elt_cd  
 AND  tmp.payroll_code  = @payroll_cd                                 
 AND  tmp.paySET_code   = @paySET_cd                                   
 AND  tmp.process_period_code = @prcprd_cd    
 AND  tmp.process_number  = @process_number                          
 AND  map.rota_plan_code  = par.rota_plan_code  
 AND  map.master_ou   = par.master_ou  
 AND  map.employment_ou  = par.employment_ou  
 AND  map.employment_ou  = tmp.employment_ou  
 AND  par.master_ou   = tmp.master_ou_code  
 AND  map.assignment_no  = tmp.assignment_no  
 AND  map.emp_code   = tmp.employee_code  
 --AND  @pprd_to_date BETWEEN par.effective_FROM and isnull(par.effective_to,@pprd_to_date)  
 --AND  @pprd_to_date BETWEEN map.eff_FROM_date and isnull(map.eff_to_date,@pprd_to_date)  
 --AND  @pprd_to_date BETWEEN tmp.effective_from  and isnull(tmp.effective_to,@pprd_to_date)  
 AND  par.effective_FROM <= @pprd_to_date     
 AND  isnull(par.effective_to,@pprd_from_date) >= @pprd_from_date   
 AND  map.eff_FROM_date <= @pprd_to_date     
 AND  isnull(map.eff_to_date,@pprd_from_date) >= @pprd_from_date   
 AND  tmp.effective_FROM <= @pprd_to_date     
 AND  isnull(tmp.effective_to,@pprd_from_date) >= @pprd_from_date    
  And  tmp.effective_from Between map.eff_FROM_date and isnull(map.eff_to_date,tmp.effective_from)   
 /**AHLPI-149**/  
 AND  tmp.proration_method NOT IN ('CD', 'FCD')--MALLIKA--  
 --IN ('WH','AWH','WD','AWD','FD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  --Code 'FD' is handled for HRPS-5637 by HARI  
 /**AHLPI-149**/  
 --Fetching schedule date,rota schedule AND shift code for the employees  
 INSERT INTO pyprc_cmn_ctc_rule_gre_cal_tmp  
   (  
   master_ou ,  
   emp_ou  ,  
   assignment_no,--assign_no ,--Code changed by Sharmila J on 05-Feb-2021 for HRP-837  
   emp_code ,   
   pprd_days ,   
   schedule_date,  
   rota_schedule_code,   
   shift_code ,   
   week_tot_hrs,  
            break_hrs, --ORH-1161  
   sno   ,  
   holiday_qc ,  
   weeklyoff_qc,  
   offday_qc ,  
   effective_from ,  
   effective_to  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542   
   )           
           --Code modified for ORH-1161 STARTS  
    --Code commented for DHPH-214 starts  
 /*  SELECT DISTINCT   
                     gre.master_ou,  
                     gre.employment_ou,  
                     gre.assignment_no,  
                     tmp.emp_code,  
                     gre.day,  
                     gre.schedule_date,  
                     gre.rota_schedule_code,  
                     ISNULL(gre.shift_code, gre.original_shift_code),  
                     datediff(mi,(gre.schedule_date+hdr.shift_start_time),(dateadd(dd,hdr.shift_spill_over,gre.schedule_date)+ hdr.shift_END_time))/60.0,  
            ISNULL(hdr.total_break_time_hrs, 0.00),  --ORH-1161    
                     CASE WHEN gre.schedule_date <= dateadd(dd,6,tmp.week_start_date ) THEN 1   
                            WHEN gre.schedule_date >= dateadd(dd,7,tmp.week_start_date )  AND gre.schedule_date <= dateadd(dd,13,tmp.week_start_date ) THEN 2   
                            WHEN gre.schedule_date >= dateadd(dd,14,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,20,tmp.week_start_date ) THEN 3  
                           WHEN gre.schedule_date >= dateadd(dd,21,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,27,tmp.week_start_date ) THEN 4  
                           WHEN gre.schedule_date >= dateadd(dd,28,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,34,tmp.week_start_date ) THEN 5  
                           WHEN gre.schedule_date >= dateadd(dd,35,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,41,tmp.week_start_date ) THEN 6  
                     END,  
                     gre.holiday_qc,  
                     null,  
                     null,  
                     tmp.effective_from,  
                     tmp.effective_to       
     ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
       FROM   pyprc_cmn_ctc_rule_week_begins                      tmp,  
                     tmscd_emp_gre_calendar            gre LEFT OUTER JOIN  
                     tmgif_shift_hdr hdr WITH (NOLOCK)  
       on            hdr.master_ou              = gre.master_ou  
       AND           hdr.shift_code                    = ISNULL(gre.shift_code, gre.original_shift_code)  
       WHERE  gre.master_ou              = tmp.master_ou  
       AND           gre.employment_ou          = tmp.employment_ou  
       AND           gre.employee_code          = tmp.emp_code  
       AND           gre.rota_plan_code         = tmp.rota_plan_code  
       AND           gre.rota_schedule_code     = tmp.rota_schedule_code  
       AND           gre.schedule_date          BETWEEN       tmp.week_start_date  AND       tmp.week_end_date  
       --Code modified for ORH-1161 ENDS  
       */--Code commented for DHPH-214 ends  
      -- /*Code commented for ORH-1161 STARTS  
      --Code uncommented for DHPH-214 starts  
        SELECT distinct gre.master_ou,  
   gre.employment_ou,  
   rota.assignment_no,  
   tmp.emp_code,  
   gre.day,  
   gre.schedule_date,  
   gre.rota_schedule_code,  
   gre.shift_code,  
   --datediff(mi,(gre.schedule_date+hdr.shift_start_time),(dateadd(dd,hdr.shift_spill_over,gre.schedule_date)+ hdr.shift_END_time))/60.0,  
    (datediff(mi,(gre.schedule_date+hdr.shift_start_time),(dateadd(dd,hdr.shift_spill_over,gre.schedule_date)+ hdr.shift_END_time))/60.0) - ISNULL(total_break_time_hrs, 0.00), /*Code added by HARI for SGIH-1325*/  
            ISNULL(total_break_time_hrs, 0.00),  --ORH-1161    
   CASE WHEN gre.schedule_date <= dateadd(dd,6,tmp.week_start_date ) THEN 1   
     WHEN gre.schedule_date >= dateadd(dd,7,tmp.week_start_date )  AND gre.schedule_date <= dateadd(dd,13,tmp.week_start_date ) THEN 2   
     WHEN gre.schedule_date >= dateadd(dd,14,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,20,tmp.week_start_date ) THEN 3  
     WHEN gre.schedule_date >= dateadd(dd,21,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,27,tmp.week_start_date ) THEN 4  
     WHEN gre.schedule_date >= dateadd(dd,28,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,34,tmp.week_start_date ) THEN 5  
     WHEN gre.schedule_date >= dateadd(dd,35,tmp.week_start_date ) AND gre.schedule_date <= dateadd(dd,41,tmp.week_start_date ) THEN 6  
   END,  
   gre.holiday_flag  ,  
   null ,  
   null ,  
   tmp.effective_from ,  
   tmp.effective_to   
            ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542   
 FROM pyprc_cmn_ctc_rule_week_begins tmp,  
   tmscd_emp_rota_schd_map   rota WITH (NOLOCK),  
   tmscd_rota_sch_gre_caldr gre WITH (NOLOCK)  
   left outer join  
   tmgif_shift_hdr hdr WITH (NOLOCK)  
 on  hdr.master_ou  = gre.master_ou  
 AND  hdr.shift_code  = gre.shift_code  
 WHERE gre.master_ou  = rota.master_ou  
 AND  rota.master_ou  = tmp.master_ou  
 AND  gre.master_ou  = tmp.master_ou  
 AND  gre.employment_ou = tmp.employment_ou  
 AND  gre.employment_ou = rota.employment_ou  
 AND  rota.employment_ou = tmp.employment_ou  
 AND  rota.emp_code  = tmp.emp_code  
 AND  tmp.emp_code  = rota.emp_code  
 AND  rota.assignment_no = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.rota_plan_code = gre.rota_plan_code  
 AND  tmp.rota_schedule_code= gre.rota_schedule_code  
 AND  gre.schedule_date BETWEEN tmp.week_start_date AND tmp.week_end_date  
 --And  @pprd_to_date  BETWEEN rota.eff_FROM_date  AND rota.eff_to_date  
 --AND  @pprd_to_date  BETWEEN tmp.effective_from  AND tmp.effective_to   
 AND  rota.eff_FROM_date <= @pprd_to_date     
 AND  isnull(rota.eff_to_date,@pprd_from_date) >= @pprd_from_date   
 --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <Begin>  
 --Code commented and uncommented by Senthil Arasu B on 22-Jan-2019 for the defect id HC-2854 <Begin>  
 --AND  gre.schedule_date BETWEEN tmp.effective_from AND  tmp.effective_to  
 AND  tmp.effective_from <= @pprd_to_date     
 AND  isnull(tmp.effective_to,@pprd_from_date) >= @pprd_from_date   
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --Code commented and uncommented by Senthil Arasu B on 22-Jan-2019 for the defect id HC-2854 <End>  
 --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <End>  
       --Code uncommented for DHPH-214 ends  
  
 --Code added by Sharmila J on 26-Aug-2022 for HRPS-4125 <Begin>  
 UPDATE rota  
 SET  rota.shift_code = emp.shift_code  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp rota   
 JOIN pyprc_cmn_ctc_rule_emp_gre_cal emp WITH (NOLOCK)  
 ON  emp.master_ou  = rota.master_ou    
 AND  emp.employment_ou = rota.emp_ou    
 AND  emp.employee_code = rota.emp_code   
 AND  emp.assignment_no = rota.assignment_no  
 AND  emp.schedule_date = rota.schedule_date    
 WHERE emp.shift_devn_qc = 'Y'  
 AND  emp.process_number = @process_number  
 AND  rota.process_number = @process_number   
 --Code added by Sharmila J on 26-Aug-2022 for HRPS-4125 <End>  
 --Code added for ORH-1161 STARTS  
 update pyprc_cmn_ctc_rule_gre_cal_tmp   
 set week_tot_hrs = isnull(week_tot_hrs,0.00)   - isnull(break_hrs,0.00)  
 from tmgif_shift_dtl dtl WITH (NOLOCK)  
  where  dtl.master_ou = pyprc_cmn_ctc_rule_gre_cal_tmp.master_ou  
 and   dtl.shift_code = pyprc_cmn_ctc_rule_gre_cal_tmp.shift_code   
and  dtl.time_type_qc =   'BKTI'  
 and   dtl.brk_type = 'UPAD'  
 AND pyprc_cmn_ctc_rule_gre_cal_tmp.process_number = @process_number--Code added by Sharmila J on 18-Apr-2022 for HRP-7239  
  --Code added for ORH-1161 ENDS       
   
 --Code commented by Sharmila J on 02-Aug-2022 for HRP-8576 <Begin>  
 /*  
 --populating average week hours in OFF days if paid week off is "OFF"(Off Day)  
 UPDATE tmp  
 SET  week_tot_hrs = t.avg  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
   pyprc_cmn_ctc_rule_wrk_tmp temp WITH (NOLOCK),  
   (  
    SELECT emp_code,  
      sum(week_tot_hrs)/count('X') as avg,  
      sno  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp WITH (NOLOCK)  
    Where week_tot_hrs is not null  
    AND  process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by sno,emp_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )t  
 Where tmp.emp_code  = t.emp_code  
 AND  tmp.sno    = t.sno  
 AND  temp.employee_code = t.emp_code  
 AND  temp.employee_code = tmp.emp_code  
 AND  tmp.assignment_no = temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  temp.assignment_no = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  week_tot_hrs  is null  
 AND  shift_code   = 'OFF'  
 --Code added and commented by Sharmila J on 18-Mar-2020 for the defect id COH-121<Begin>   
 AND  paid_week_off  = 'OD'  
-- AND  paid_week_off  = 'OFF'  
--Code added and commented by Sharmila J on 18-Mar-2020 for the defect id COH-121<End>  
 AND  temp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.process_number = tmp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.pror_type  IN ('WH','AWH','WD','AWD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
  
 --populating average week hours in Rest days if paid week off is "RD"(Rest Day)  
 UPDATE tmp  
 SET  week_tot_hrs = t.avg  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
   pyprc_cmn_ctc_rule_wrk_tmp temp WITH (NOLOCK),  
   (  
    SELECT emp_code,  
      sum(week_tot_hrs)/count('X') as avg,  
      sno  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp WITH (NOLOCK)  
    Where week_tot_hrs is not null  
    AND  process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by sno,emp_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )t  
 Where tmp.emp_code  = t.emp_code  
 AND  tmp.sno    = t.sno  
 AND  temp.employee_code = t.emp_code  
 AND  temp.employee_code = tmp.emp_code  
 AND  tmp.assignment_no = temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  temp.assignment_no = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  week_tot_hrs  is null  
 AND  paid_week_off  = 'RD'  
 AND  shift_code   = 'WOFF'   
 AND  temp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.process_number = tmp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.pror_type  IN ('WH','AWH','WD','AWD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
   
 --populating average week hours in both off days AND Rest days if paid week off is "BD"(Both Days)  
 UPDATE tmp  
 SET  week_tot_hrs = t.avg  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
   pyprc_cmn_ctc_rule_wrk_tmp temp WITH (NOLOCK),  
   (  
    SELECT emp_code,  
      sum(week_tot_hrs)/count('X') as avg,  
      sno,  
      rota_schedule_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp WITH (NOLOCK)  
    Where week_tot_hrs is not null  
    AND  process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by rota_schedule_code,sno,emp_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )t  
 Where tmp.emp_code  = t.emp_code  
 AND  tmp.sno    = t.sno  
 AND  temp.employee_code = t.emp_code  
 AND  temp.employee_code = tmp.emp_code  
 AND  tmp.assignment_no = temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  temp.assignment_no = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 And  tmp.rota_schedule_code= t.rota_schedule_code  
 AND  week_tot_hrs  is null  
 AND  shift_code   in( 'OFF','WOFF')   
 AND  paid_week_off  =  'BD'  
 AND  temp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.process_number = tmp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  temp.pror_type  IN ('WH','AWH','WD','AWD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
 --Computing Scheduled hours for the mid join employees  
 */  
 --Code commented by Sharmila J on 02-Aug-2022 for HRP-8576 <End>  
  
 -- code added and commented by senthil arasu b on 28-Nov-2018 to remove gre calendar table reference <starts>  
  
 Update tmp  
 SET  sch_hrs   = t.tot  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    SELECT sum(week_tot_hrs) AS TOT,emp_code,rota_schedule_code,effective_from  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp WITH (NOLOCK)  
    Where schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date   
    AND  process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542   
    group by emp_code,rota_schedule_code,effective_from  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ) t  
 Where tmp.employee_code=t.emp_code  
 AND  tmp.employment_flag  = 'N'  
 AND  tmp.employee_code  = t.emp_code  
 AND  tmp.assignment_no  = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 And  tmp.rota_schedule_code = t.rota_schedule_code  
 And  tmp.effective_from  = t.effective_from  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 /**AHLPI-149**/  
 AND  tmp.pror_type  NOT IN ('CD', 'FCD')  
 --MALLIKA--IN ('WH','AWH','WD','AWD','FD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160 --Code 'FD' is handled for HRPS-5637 by HARI  
 /**AHLPI-149**/  
 /*  
 Update tmp  
 SET  sch_hrs   = t.tot  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   pyprc_cmn_ctc_rule_gre_cal_tmp temp,  
   (  
    SELECT sum(week_tot_hrs) AS TOT,emp_code,rota_schedule_code,effective_from  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp  
    --Where schedule_date BETWEEN Effective_from AND effective_to  
    Where schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date    
    group by emp_code,rota_schedule_code,effective_from  
   )T  
 Where tmp.employee_code=t.emp_code  
 AND  tmp.employment_flag = 'N'  
 AND  tmp.employee_code = temp.emp_code  
 And  t.rota_schedule_code = tmp.rota_schedule_code  
 And  t.effective_from  = tmp.effective_from  
 */  
 -- code added and commented by senthil arasu b on 28-Nov-2018 to remove gre calendar table reference <ends>  
  
 --Computing Scheduled hours for the non-mid join employees  
 Update tmp  
 SET  sch_hrs   = t.tot  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    SELECT sum(week_tot_hrs) AS TOT,emp_code,rota_schedule_code,effective_from  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp WITH (NOLOCK)  
    Where schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    AND  process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by emp_code,rota_schedule_code,effective_from  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )T  
 Where tmp.employee_code=t.emp_code  
 AND  t.assignment_no   = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.employment_flag = 'Y'  
 And  t.rota_schedule_code = tmp.rota_schedule_code  
 And  t.effective_from  = tmp.effective_from  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 /**AHLPI-149**/  
 AND  tmp.pror_type  NOT IN ('CD', 'FCD')   
 --AND  tmp.pror_type  IN ('WH','AWH','WD','AWD','FD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  --Code 'FD' is handled for HRPS-5637 by HARI  
 /**AHLPI-149**/  
 --Code added by Sharmila J on 23-FEB-2022 for HRP-6691 <Begin>  
 --Update Scheduled hours with fixed value  
 Update tmp  
 SET  sch_hrs   = tmp.fixed_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp   Where tmp.process_number = @process_number  
 --Code added and commented by Sharmila J on 14-Mar-2022 for HRP-6864 <Begin>  
 AND  tmp.pror_type  IN ( 'WH', 'AWH')  
 --AND  tmp.pror_type  = 'WH'  
 --Code added and commented by Sharmila J on 14-Mar-2022 for HRP-6864 <End>  
 AND  tmp.fixed_days  IS NOT NULL  
 --Code added by Sharmila J on 23-FEB-2022 for HRP-6691 <End>  
   
 --Code commented by Sharmila J on 02-Aug-2022 for HRP-8576 <Begin>  
 /*  
 --Computing mid join hours for the mid join employees  
 -- code added and commented by senthil arasu b on 13-Jul-2018 for new joinee with mid month salary change for the defect id HC-2071 <starts>  
 UPDATE tmp  
 SET  mid_join_hrs  = t.tot  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
   (  
    SELECT tmp.Effective_from,  
      sum(isnull(temp.week_tot_hrs,0)) AS TOT,emp_code  
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp temp WITH (NOLOCK),  
      pyprc_cmn_ctc_rule_wrk_tmp  tmp WITH (NOLOCK)  
    Where schedule_date BETWEEN tmp.Effective_from AND tmp.effective_to  
    AND  temp.Effective_from = tmp.Effective_from  
    AND  temp.master_ou  = tmp.master_ou  
    AND  temp.emp_ou   = tmp.emp_ou  
    AND  temp.emp_code  = tmp.employee_code   
    AND  tmp.employment_flag = 'Y'  
    AND  tmp.assignment_no = temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.process_number = temp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by emp_code, tmp.Effective_from  
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )T  
 Where tmp.emp_code=t.emp_code  
 AND  tmp.assignment_no  = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.Effective_from = t.Effective_from  
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 */  
 --Code commented by Sharmila J on 02-Aug-2022 for HRP-8576 <End>  
  
 /*  
 UPDATE tmp  
 SET  mid_join_hrs  = t.tot  
 FROM pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
   (  
    SELECT sum(isnull(temp.week_tot_hrs,0)) AS TOT,emp_code  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp temp,  
      pyprc_cmn_ctc_rule_wrk_tmp  tmp  
    Where schedule_date BETWEEN tmp.Effective_from AND tmp.effective_to  
    AND  temp.master_ou  = tmp.master_ou  
    AND  temp.emp_ou   = tmp.emp_ou  
    AND  temp.emp_code  = tmp.employee_code   
    AND  tmp.employment_flag = 'Y'  
    group by emp_code  
   )T  
 Where tmp.emp_code=t.emp_code  
 */  
 -- code added and commented by senthil arasu b on 13-Jul-2018 for new joinee with mid month salary change for the defect id HC-2071 <ends>  
  
 --Computing total Working Days for the given process period  
 UPDATE tmp  
 SET  paid_wrking_days  = a.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <Begin>  
    --SELECT count(cal.schedule_date)as sch_days,cal.emp_code,emp_ou  
    SELECT count(cal.schedule_date)as sch_days,cal.emp_code,emp_ou,effective_from   
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <End>  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal WITH (NOLOCK)  
    WHERE cal.master_ou   = @payroll_ou_cd                                 
    --Code commented by Sharmila J for the defect id RGSH-99 on 18-Oct-2019 <Begin>  
    --AND  cal.holiday_qc   = 'N'  
    --Code commented by Sharmila J for the defect id RGSH-99 on 18-Oct-2019 <End>  
    AND  cal.shift_code not in ('WOFF','OFF')  
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <Begin>  
    --AND  schedule_date BETWEEN Effective_from AND effective_to  
    --Group by emp_code,emp_ou  
    AND  schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    AND  cal.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    Group by emp_code,emp_ou,effective_from   
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <End>  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )a  
 Where a.emp_code   = tmp.employee_code  
 AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  a.emp_ou   = tmp.emp_ou  
 AND  tmp.pror_type  IN ('WD','AWD') --= 'WD'--Code changed by Sharmila J for the defect id HST-7024 on 21-Jan-2020  
 AND  a.effective_from = tmp.effective_from --Code added by Sharmila J for the defect id HC-3141 in 20-Feb-2019   
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --AND  tmp.pror_type  IN ('WH','AWH','WD','AWD','FD') -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  --Code commented by HARI for HRPS-5637  
  
 --Computing total Calendar Days for the given process period for the scheduled employees  
 --Code commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <Begin>  
 /*   
 UPDATE tmp  
 SET  paid_wrking_days   = a.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   ldef_leave_parameters lv WITH (NOLOCK),  
   (   
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <Begin>  
    --SELECT count(cal.schedule_date)as sch_days,cal.emp_code,emp_ou  
    SELECT count(cal.schedule_date)as sch_days,cal.emp_code,emp_ou,effective_from   
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <End>  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal  
    WHERE cal.master_ou   = @payroll_ou_cd     
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <Begin>                              
    --AND  schedule_date BETWEEN Effective_from AND effective_to    
    --Group by emp_code,emp_ou  
    AND  schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    Group by emp_code,emp_ou,effective_from  
    --Code commented and added by Sharmila J on 26-July-2018 for the defect id HC-2152 <End>  
   )a  
 Where a.emp_code   = tmp.employee_code  
 AND  a.emp_ou   = tmp.emp_ou  
 AND  lv.master_ou_code = a.emp_ou  
 AND  lv.master_ou_code = tmp.emp_ou  
 AND  tmp.pror_type  = 'CD'  
 AND  lv.time_mgmt_intgn_flag ='FULL'  
 AND  a.effective_from = tmp.effective_from --Code added by Sharmila J for the defect id HC-3141 in 20-Feb-2019   
 */  
 --Code commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <End>  
  
 --Code added by Sharmila J on 04-May-2022 for HRPS-7395 <Begin>  
 EXEC pyprc_cmn_pay_rule_proration_hook_sp @rule_type   ,   
             @pay_elt_cd   ,  
             @payroll_ou_cd  ,   
             @payroll_cd   ,   
             @paySET_cd   ,     
             @prcprd_cd   ,   
             @process_number  ,   
             @pprd_FROM_date  ,  
             @pprd_to_date  ,  
             @progressive_flag ,  
             'PWD' --to overwrite the paid working days   
 --Code added by Sharmila J on 04-May-2022 for HRPS-7395 <End>  
  
 --Computing opted amount for earnings, deductions and other allowance elements  
 INSERT INTO pyprc_cmn_ctc_rule_comp_tmp  
  (  
   master_ou_code ,  
   empin_ou  ,  
   employee_code ,  
   effective_from ,  
   effective_to ,  
   payelement_code ,  
   opted_amount ,  
                        pyelt_exchange_type,--MCIH-77   
   pyset_currency_code,  --for salary convertion  
   pyelt_currency_code,  --for salary convertion  
   frequency_code   
   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  )  
 /*****CODE MODIFIED FOR SAIH-1176 *****/  
  
 SELECT DISTINCT  
  
 /*****CODE MODIFIED FOR SAIH-1176 *****/  
 vw.master_ou_code ,  
   fhdr.empin_ou,--vw.empin_ou ,--Code changed by Sharmila J on 05-Feb-2021 for HRP-837  
   vw.employee_code ,  
   vw.effective_from ,  
   fhdr.effective_to,-- vw.effective_to,--Code changed by Sharmila J on 05-Feb-2021 for HRP-837  
   vw.payelement_code ,  
   vw.opted_amount  ,  
                        @exratetype,--MCIH-77    
   @payset_currency ,  
   vw.currency_code ,  
   vw.frequency_code  
   ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837 <Begin>  
 FROM hrcompn_empflexibenft_auth_brkup vw WITH (NOLOCK),  
   hrcompn_empflexibenft_auth_hdr fhdr WITH (NOLOCK),   
   pyprc_cmn_ctc_rule_wrk_tmp      tmp  
 WHERE vw.master_ou_code  = @empng_ou  
 AND  fhdr.master_ou_code  = @empng_ou  
 AND  fhdr.empin_ou   = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  fhdr.empin_ou   = tmp.emp_ou  
 AND  fhdr.master_ou_code  = vw.master_ou_code  
 AND  vw.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = vw.employee_code                  
 AND  tmp.assignment_no  =   vw.assign_no  
 AND  fhdr.assign_no   =   vw.assign_no  
 AND  vw.payelement_code = @pay_elt_cd  
 AND  vw.effective_from  = fhdr.effective_from  
 AND  fhdr.effective_from <= @pprd_to_date     
 AND  isnull(fhdr.effective_to,@pprd_from_date) >= @pprd_from_date                           
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 /*  
 FROM hrcompn_flexibenft_auth_brkupvw vw WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp      tmp  
 WHERE vw.master_ou_code  = @empng_ou  
 AND  vw.empin_ou    = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  vw.empin_ou    = tmp.emp_ou  
 AND  vw.employee_code  = tmp.employee_code                  
 AND  vw.payelement_code  = @pay_elt_cd   
 AND  vw.effective_from <= @pprd_to_date     
 AND  isnull(vw.effective_to,@pprd_from_date) >= @pprd_from_date                          
 */  
 --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837 <End>  
  
 -- code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <starts>  
 INSERT pyprc_cmn_ctc_rule_comp_tmp  
 (  
   master_ou_code ,  
   empin_ou  ,  
   employee_code ,  
   effective_from ,  
   effective_to ,  
   payelement_code ,  
   opted_amount ,  
                        pyelt_exchange_type,--MCIH-77    
   pyset_currency_code,  --for salary convertion  
   pyelt_currency_code,  --for salary convertion  
   frequency_code   
   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 )  
 -- UNION  
 --code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <ends>  
 SELECT fhdr.master_ou_code ,  
   fhdr.empin_ou   ,  
   fhdr.employee_code ,  
   fhdr.effective_from ,  
   fhdr.effective_to  ,  
   fbrk.payelement_code ,  
   fbrk.opted_amount  ,  
                        @exratetype,--MCIH-77    
   @payset_currency  ,  
   fbrk.currency_code  ,  
   fbrk.frequency_code  
   ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837   
   ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 FROM hrcompn_empflexibenft_auth_ded fbrk WITH (NOLOCK),  
   hrcompn_empflexibenft_auth_hdr fhdr WITH (NOLOCK),   
   pyprc_cmn_ctc_rule_wrk_tmp      tmp  
 WHERE fbrk.master_ou_code  = @empng_ou  
 AND  fhdr.master_ou_code  = @empng_ou  
 AND  fhdr.empin_ou   = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  fhdr.empin_ou   = tmp.emp_ou  
 AND  fhdr.master_ou_code  = fbrk.master_ou_code  
 AND  fbrk.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = fbrk.employee_code                  
 AND  tmp.assignment_no  =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fhdr.assign_no   =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fbrk.payelement_code = @pay_elt_cd  
 AND  fbrk.effective_from  = fhdr.effective_from  
 AND  fhdr.effective_from <= @pprd_to_date     
 AND  isnull(fhdr.effective_to,@pprd_from_date) >= @pprd_from_date                           
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 -- code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <starts>  
 INSERT pyprc_cmn_ctc_rule_comp_tmp  
 (  
   master_ou_code ,  
   empin_ou  ,  
   employee_code ,  
   effective_from ,  
   effective_to ,  
   payelement_code ,  
   opted_amount ,  
                        pyelt_exchange_type,--MCIH-77    
   pyset_currency_code,  --for salary convertion  
   pyelt_currency_code,  --for salary convertion  
   frequency_code   
   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 )  
 -- UNION  
 --code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <ends>  
 SELECT fhdr.master_ou_code  ,  
   fhdr.empin_ou   ,  
   fhdr.employee_code  ,  
   fhdr.effective_from  ,  
   fhdr.effective_to  ,  
   fbrk.payelement_code ,  
   fbrk.hr_opted_amount ,  
                        @exratetype,--MCIH-77    
   @payset_currency  ,  
   fbrk.currency_code  ,  
   fbrk.element_periodicity  
   ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 FROM hrcompn_empflexibenft_auth_oca fbrk WITH (NOLOCK),  
   hrcompn_empflexibenft_auth_hdr fhdr WITH (NOLOCK),   
   pyprc_cmn_ctc_rule_wrk_tmp      tmp  
 WHERE fbrk.master_ou_code  = @empng_ou  
 AND  fhdr.master_ou_code  = @empng_ou  
 AND  fhdr.empin_ou   = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  fhdr.empin_ou   = tmp.emp_ou  
 AND  fhdr.master_ou_code  = fbrk.master_ou_code  
 AND  fbrk.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = tmp.employee_code  
 AND  fbrk.employee_code  = fhdr.employee_code                  
 AND  tmp.assignment_no  =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fhdr.assign_no   =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fbrk.payelement_code = @pay_elt_cd  
 AND  fbrk.effective_from  = fhdr.effective_from  
 AND  fhdr.effective_from <= @pprd_to_date     
 AND  isnull(fhdr.effective_to,@pprd_from_date) >= @pprd_from_date                          
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                      
 --Code added by Senthil Arasu B on 27-Nov-2018 for the defect id HC-2667<starts>  
  
 -- code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <starts>  
 INSERT INTO pyprc_cmn_ctc_rule_comp_tmp  
  (  
   master_ou_code ,  
   empin_ou  ,  
   employee_code ,  
   effective_from ,  
   effective_to ,  
   payelement_code ,  
   opted_amount ,  
                        pyelt_exchange_type,--MCIH-77   
   pyset_currency_code,  --for salary convertion  
   pyelt_currency_code,  --for salary convertion  
   frequency_code   
   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  )  
 -- UNION  
 --code added and commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <ends>  
 SELECT fhdr.master_ou_code  ,  
   fhdr.empin_ou   ,  
   fhdr.employee_code  ,  
   fhdr.effective_from  ,  
   fhdr.effective_to  ,  
   fbrk.payelement_code ,  
   fbrk.opted_amount  ,  
                        @exratetype,--MCIH-77   
   @payset_currency  ,  
   fbrk.currency_code  ,  
   fbrk.periodicity  
   ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 FROM hrcompn_empflexibenft_auth_optn fbrk WITH (NOLOCK),  
   hrcompn_empflexibenft_auth_hdr fhdr WITH (NOLOCK),   
   pyprc_cmn_ctc_rule_wrk_tmp      tmp  
 WHERE fbrk.master_ou_code  = @empng_ou  
 AND  fhdr.master_ou_code  = @empng_ou  
 AND  fhdr.empin_ou   = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  fhdr.empin_ou   = tmp.emp_ou  
 AND  fhdr.master_ou_code  = fbrk.master_ou_code  
 AND  fbrk.employee_code  = tmp.employee_code  
 AND  fhdr.employee_code  = tmp.employee_code  
 AND  fbrk.employee_code  = fhdr.employee_code                  
 AND  tmp.assignment_no  =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fhdr.assign_no   =   fbrk.assign_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fbrk.payelement_code = @pay_elt_cd  
 AND  fbrk.effective_from  = fhdr.effective_from  
 AND  fhdr.effective_from <= @pprd_to_date     
 AND  isnull(fhdr.effective_to,@pprd_from_date) >= @pprd_from_date                          
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                     
 --Code added by Senthil Arasu B on 27-Nov-2018 for the defect id HC-2667<ends>  
  
   
 -- to update the pay element level exchange type defined against each pay element  
 -- code commented as exchange_type column not moved as part of CU23, system will take default exchange rate type  
 -- code uncommented by Arthi R V on 30-Nov-2020 for the defect id HRP-205<starts>  
 --/*  
 UPDATE tmp  
 SET  tmp.pyelt_exchange_type  = elt.exchange_type  
 FROM pyprc_cmn_ctc_rule_comp_tmp     tmp,  
   hrpyset_payset_pe_map  elt WITH(NOLOCK)  
 WHERE elt.master_ou    = @pyset_ou   
 AND  elt.payset_code    = @payset_cd   
 AND  elt.payroll_master_ou  = @pydef_ou   
 AND  elt.payroll_code   = @payroll_cd   
 AND  elt.pay_element_master_ou = @pyelt_ou   
 AND  elt.pay_element_code  = tmp.payelement_code  
 AND  @prcprd_cd BETWEEN elt.effective_from_pprd_code AND ISNULL(elt.effective_to_pprd_code,@prcprd_cd)  
 AND  elt.exchange_type   IS NOT NULL--Code added by Sharmila J on 03-Mar-2021  
 --/*  
 -- code uncommented by Arthi R V on 30-Nov-2020 for the defect id HRP-205<ends>  
  
 -- to default the exchange type which is defined in the finance, when it is not defined at pay element level  
  
 -- code commented by senthil arasu b on 12-Mar-2020 for defect id AIIH-98 <starts>  
 /*  
 UPDATE tmp  
 SET  tmp.pyelt_exchange_type = @exratetype  
 FROM pyprc_cmn_ctc_rule_comp_tmp tmp   
 WHERE tmp.pyelt_exchange_type IS NULL  
 */  
 -- code commented by senthil arasu b on 12-mar-2020 for defect id AIIH-98 <ends>  
  
 UPDATE vw  
 -- code added and commented by senthil arasu b on 12-mar-2020 for defect id AIIH-98 <starts>  
 SET  vw.ctc_exchange_type =  ISNULL(tmp.pyelt_exchange_type, @exratetype),  
 --SET vw.ctc_exchange_type =  tmp.pyelt_exchange_type,  
 -- code added and commented by senthil arasu b on 12-mar-2020 for defect id AIIH-98 <ends>  
   vw.ctc_exchange_date = @exchange_date  
   ,vw.ctc_frequency  = tmp.frequency_code --Code added by Sharmila J for the defect id HST-7014  
 FROM pyprc_cmn_ctc_rule_comp_tmp    tmp WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp    vw  
 WHERE tmp.master_ou_code  = @empng_ou  
 AND  tmp.empin_ou   = @empin_ou  
 AND  vw.master_ou   = @empin_ou  
 AND  vw.emp_ou    = @empin_ou  
 AND  tmp.empin_ou   = vw.emp_ou  
 AND  vw.employee_code  = tmp.employee_code  
 AND  tmp.assignment_no  = vw.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.payelement_code  = @pay_elt_cd  
 AND  vw.effective_FROM  BETWEEN tmp.effective_FROM and isnull(tmp.effective_to ,vw.effective_to)     
 AND  vw.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  vw.process_number  = tmp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
                
 -- to recalculate the opted amount with corresponding exchange rate of the pay element if payset & pay eleemnt currency differs  
 UPDATE tmp  
 SET  tmp.opted_amount  = ISNULL( tmp.opted_amount, 0.0) * ISNULL(exchange_rate,1),  
   tmp.ctc_exchange_rate = exchange_rate  
 FROM pyprc_cmn_ctc_rule_comp_tmp tmp,  
   erate_exrate_mst  exr WITH (NOLOCK)  
 WHERE exr.ou_id    = @erate_ou --check cim   
 --Code added and commented by Sharmila J for HRP-205 <Begin>  
 AND  exr.exchrate_type  = tmp.pyelt_exchange_type  
 --AND  exr.exchrate_type  = ISNULL(tmp.pyelt_exchange_type, @exratetype)  
 --Code added and commented by Sharmila J for HRP-205 <End>  
 AND  exr.from_currency  = ISNULL(tmp.pyelt_currency_code, tmp.pyset_currency_code)  
 AND  exr.to_currency   = tmp.pyset_currency_code  
 AND  ISNULL(tmp.pyelt_currency_code, tmp.pyset_currency_code) <> tmp.pyset_currency_code     
 AND  @exchange_date   BETWEEN exr.start_date AND ISNULL(exr.end_date, @exchange_date)  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Code commented and added by Sharmila J on 10-Jan-2019 for the defect id HC-2761  <Begin>  
 /*  
 --checking whether the ctc frequency and payroll frequency are same  
 IF EXISTS (   
    SELECT 'X'   
    FROM hrpydef_paycal_hdr hdr WITH (NOLOCK),  
      pyprc_cmn_ctc_rule_comp_tmp   vw   
    WHERE hdr.master_ou    = @pydef_ou  
    AND  vw.master_ou_code   = @empng_ou  
    AND  vw.empin_ou     = @empin_ou  
    AND  hdr.payroll_calendar_code = @pay_cal_code  
   -- AND  hdr.period_unit_code  = vw.frequency_code  
   --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <Begin>  
   -- AND  fac.to_frequency  = hdr.period_unit_code    
    AND  vw.frequency_code  = CASE WHEN hdr.payment_freq_qc  = 1  THEN 'H'   
              WHEN hdr.payment_freq_qc  = 2  THEN 'D'   
              WHEN hdr.payment_freq_qc  = 3  THEN 'W'   
              WHEN hdr.payment_freq_qc  = 4  THEN 'BW'   
              WHEN hdr.payment_freq_qc  = 6  THEN 'M'   
              WHEN hdr.payment_freq_qc  = 9  THEN 'Y'   
             END  
   --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <End>  
    AND  vw.payelement_code   = @pay_elt_cd                          
    AND  vw.effective_from   <= @pprd_to_date     
    AND  isnull(vw.effective_to,@pprd_from_date) >= @pprd_from_date  
    )   
 BEGIN   
    SELECT @payroll_ou_cd = @payroll_ou_cd  
 END  
 ELSE --Converting the ctc frequency into payroll frequency if both the frequencies are different  
 BEGIN  
    
  UPDATE vw  
  SET  opted_amount   =  (ISNULL(vw.opted_amount,0.00) / ISNULL(fac.dividing_value,1.00)) * ISNULL(fac.multi_value,1.00)   
  FROM pyprc_cmn_ctc_rule_comp_tmp      vw,  
    pyprc_cmn_ctc_rule_wrk_tmp      tmp,  
    hros_compensation_conv_factor fac WITH (NOLOCK),  
    hrpydef_paycal_hdr    hdr WITH (NOLOCK)  
  WHERE vw.master_ou_code  = @empng_ou  
  AND  vw.empin_ou    = @empin_ou  
  AND  tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  AND  fac.master_ou   = @empng_ou   
  AND  fac.empin_ou   = @empin_ou  
  AND  hdr.master_ou   = @pydef_ou  
  AND  vw.empin_ou    = tmp.emp_ou  
  AND  fac.master_ou   = vw.master_ou_code  
  AND  fac.empin_ou   = vw.empin_ou  
  AND  vw.employee_code  = tmp.employee_code  
  AND  hdr.payroll_calendar_code = @pay_cal_code                  
  AND  fac.rule_type   = @rule_type  
  AND  fac.pay_element_code = @pay_elt_cd  
  AND  vw.payelement_code  = @pay_elt_cd  
  AND  fac.pay_element_code = vw.payelement_code  
  AND  fac.FROM_frequency  = vw.frequency_code  
  --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <Begin>  
 -- AND  fac.to_frequency  = hdr.period_unit_code    
  AND  fac.to_frequency  = CASE WHEN hdr.payment_freq_qc  = 1  THEN 'H'   
            WHEN hdr.payment_freq_qc  = 2  THEN 'D'   
            WHEN hdr.payment_freq_qc  = 3  THEN 'W'   
            WHEN hdr.payment_freq_qc  = 4  THEN 'BW'   
            WHEN hdr.payment_freq_qc = 6  THEN 'M'   
            WHEN hdr.payment_freq_qc  = 9  THEN 'Y'   
          END  
  --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <End>  
  AND  tmp.effective_FROM  BETWEEN vw.effective_FROM and isnull(vw.effective_to ,tmp.effective_to)                  
  AND  @pprd_to_date   BETWEEN fac.effective_FROM AND isnull(fac.effective_to,@pprd_to_date)  
 END  
 */  
  
 SELECT @pay_frequency = CASE WHEN hdr.payment_freq_qc  = 1  THEN 'H'   
          WHEN hdr.payment_freq_qc  = 2  THEN 'D'   
          WHEN hdr.payment_freq_qc  = 3  THEN 'W'   
         --Code added and commented by Sharmila J on 26-May-2020 for the defect id HSH-36 <Begin>  
         WHEN hdr.payment_freq_qc  IN( 4,10)  THEN 'BW'  
         -- WHEN hdr.payment_freq_qc  = 4  THEN 'BW'   
         --Code added and commented by Sharmila J on 26-May-2020 for the defect id HSH-36 <End>  
          WHEN hdr.payment_freq_qc  = 6  THEN 'M'   
          WHEN hdr.payment_freq_qc  = 9  THEN 'Y'   
         WHEN hdr.payment_freq_qc  = 5  THEN 'Bmnth' --Code added by Sharmila J for the defect id HC-3883 on 04-Sep-2019  
        END  
 FROM hrpydef_paycal_hdr hdr WITH (NOLOCK)  
 WHERE hdr.master_ou    = @pydef_ou  
 AND  hdr.payroll_calendar_code = @pay_cal_code  
     
 UPDATE vw  
 SET  opted_amount   =  (ISNULL(vw.opted_amount,0.00) / ISNULL(fac.dividing_value,1.00)) * ISNULL(fac.multi_value,1.00)   
 FROM pyprc_cmn_ctc_rule_comp_tmp      vw,  
   pyprc_cmn_ctc_rule_wrk_tmp      tmp WITH (NOLOCK),  
   hros_compensation_conv_factor fac WITH (NOLOCK)  
 WHERE vw.master_ou_code  = @empng_ou  
 AND  vw.empin_ou    = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  fac.master_ou   = @empng_ou   
 AND  fac.empin_ou   = @empin_ou  
 AND  vw.empin_ou    = tmp.emp_ou  
 AND  fac.master_ou   = vw.master_ou_code  
 AND  fac.empin_ou   = vw.empin_ou  
 AND  vw.employee_code  = tmp.employee_code  
 AND  tmp.assignment_no  = vw.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  fac.rule_type   = @rule_type  
 AND  fac.pay_element_code = @pay_elt_cd  
 AND  vw.payelement_code  = @pay_elt_cd  
 AND  fac.pay_element_code = vw.payelement_code  
 AND  fac.from_frequency  <> 'D' -- code added by senthil arasu b on 16-Oct-2019 for defect id HST-7246  
 AND  fac.from_frequency  = vw.frequency_code  
 AND  fac.to_frequency  = @pay_frequency  
 AND  vw.frequency_code  <> @pay_frequency  
 AND  tmp.effective_FROM  BETWEEN vw.effective_from and isnull(vw.effective_to ,tmp.effective_to)                  
 AND  @pprd_to_date   BETWEEN fac.effective_from AND isnull(fac.effective_to,@pprd_to_date)  
 AND  vw.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  vw.process_number  = tmp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --Code commented and added by Sharmila J on 10-Jan-2019 for the defect id HC-2761 <End>  
   
 -- code added by senthil arasu b on 16-Oct-2019 for defect id HST-7246 <starts>  
 --UPDATE ctc  
 --SET  ctc.opted_amount  = (ISNULL(ctc.opted_amount,0.00) * ISNULL(tmp.paid_wrking_days,0.00))  
 --FROM pyprc_cmn_ctc_rule_comp_tmp ctc,  
 --  pyprc_cmn_ctc_rule_wrk_tmp tmp  
 --WHERE ctc.empin_ou   = tmp.emp_ou  
 --AND  ctc.employee_code  = tmp.employee_code  
 --AND  ctc.frequency_code  = 'D'  
 --AND  ctc.frequency_code  <> @pay_frequency  
 --AND  tmp.effective_FROM  BETWEEN ctc.effective_from AND ISNULL(ctc.effective_to ,tmp.effective_to)                  
 -- code added by senthil arasu b on 16-Oct-2019 for defect id HST-7246 <ends>  
  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 UPDATE ctc  
 SET  ctc.opted_amount  = (ISNULL(ctc.opted_amount,0.00) * ISNULL(tmp.paid_wrking_days,0.00))  
 FROM pyprc_cmn_ctc_rule_comp_tmp ctc,  
   pyprc_cmn_ctc_rule_wrk_tmp tmp WITH (NOLOCK)  
 WHERE ctc.empin_ou   = tmp.emp_ou  
 AND  ctc.employee_code  = tmp.employee_code  
 AND  ctc.frequency_code  = 'D'  
 AND  ctc.frequency_code  <> @pay_frequency  
 AND  tmp.effective_FROM  BETWEEN ctc.effective_from AND ISNULL(ctc.effective_to ,tmp.effective_to)    
 AND  tmp.pror_type   NOT IN ('WH','AWH')  
 AND  tmp.assignment_no  = ctc.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = ctc.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 INSERT INTO  pyprc_cmn_hour_conv_freq_tmp  
 (  
  employee_code,    process_period_code,  period_from_date,  period_to_date,  
  effective_from_date,  effective_to_date,   proration_method,  hourly_rate_conversion  
  ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 )  
 SELECT  
  --code commented and added by Arthi R V on 15-sep-2021 HRP-4972 for removal of int conversion<Begin>  
  --employee_code,   CONVERT(INT,@prcprd_cd), @pprd_from_date,  @pprd_to_date,  
  employee_code,    @prcprd_cd,     @pprd_from_date,  @pprd_to_date,  
  --code commented and added by Arthi R V on 15-sep-2021 HRP-4972 for removal of int conversion<End>  
  effective_from,    effective_to,    pror_type,    hour_conv_freq      
  ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,@process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542     
 FROM   pyprc_cmn_ctc_rule_wrk_tmp  WITH (NOLOCK)  
 WHERE process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --To compute the standard hours per day based on the hour conversion frequency  
 --Code added and commented by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <Begin>  
 EXEC pyprc_cmn_hourly_conv_freq_sp @empng_ou, @empin_ou, 'CTC',@process_number  
 -- EXEC pyprc_cmn_hourly_conv_freq_sp @empng_ou, @empin_ou, 'CTC'   
 --Code added and commented by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <End>  
  
 UPDATE wrk  
 SET  wrk.std_hrs_per_day = tmp.stdhrsperday  
 FROM pyprc_cmn_ctc_rule_wrk_tmp     wrk  
 INNER JOIN pyprc_cmn_hour_conv_freq_tmp tmp WITH (NOLOCK)  
 ON  tmp.employee_code = wrk.employee_code  
 AND  tmp.assignment_no = wrk.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.process_number = wrk.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 WHERE wrk.hour_conv_freq IS NOT NULL  
 AND  wrk.effective_from = tmp.effective_from_date  
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 UPDATE ctc  
 SET  ctc.opted_amount  = (ISNULL(ctc.opted_amount,0.00) * ISNULL(tmp.sch_hrs,0.00) / NULLIF(tmp.std_hrs_per_day,0.00))  
 FROM pyprc_cmn_ctc_rule_comp_tmp ctc,  
   pyprc_cmn_ctc_rule_wrk_tmp tmp WITH (NOLOCK)  
 WHERE ctc.empin_ou   = tmp.emp_ou  
 AND  ctc.employee_code  = tmp.employee_code  
 AND  ctc.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  ctc.frequency_code  = 'D'  
 AND  ctc.frequency_code  <> @pay_frequency  
 AND  tmp.effective_FROM  BETWEEN ctc.effective_from AND ISNULL(ctc.effective_to ,tmp.effective_to)    
 AND  tmp.pror_type   IN ('WH','AWH')  
 AND  NULLIF(tmp.std_hrs_per_day,0.00) > 0.00  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = ctc.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 UPDATE ctc  
 SET  ctc.opted_amount  = (ISNULL(ctc.opted_amount,0.00) * ISNULL(tmp.paid_wrking_days,0.00) * ISNULL(tmp.std_hrs_per_day,0.00))  
 FROM pyprc_cmn_ctc_rule_comp_tmp ctc,  
   pyprc_cmn_ctc_rule_wrk_tmp tmp WITH (NOLOCK)  
 WHERE ctc.empin_ou   = tmp.emp_ou  
 AND  ctc.employee_code  = tmp.employee_code  
 AND  ctc.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  ctc.frequency_code  = 'H'  
 AND  ctc.frequency_code  <> @pay_frequency  
 AND  tmp.effective_FROM  BETWEEN ctc.effective_from AND ISNULL(ctc.effective_to ,tmp.effective_to)  
 AND  tmp.pror_type   NOT IN ('WH','AWH')  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = ctc.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 UPDATE ctc  
 SET  ctc.opted_amount  = (ISNULL(ctc.opted_amount,0.00) * ISNULL(tmp.sch_hrs,0.00))  
 FROM pyprc_cmn_ctc_rule_comp_tmp ctc,  
   pyprc_cmn_ctc_rule_wrk_tmp tmp WITH (NOLOCK)  
 WHERE ctc.empin_ou   = tmp.emp_ou  
 AND  ctc.employee_code  = tmp.employee_code  
 AND  ctc.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  ctc.frequency_code  = 'H'  
 AND  ctc.frequency_code  <> @pay_frequency  
 AND  tmp.effective_FROM  BETWEEN ctc.effective_from AND ISNULL(ctc.effective_to ,tmp.effective_to)  
 AND  tmp.pror_type   IN ('WH','AWH')  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = ctc.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
  
 --Code added by Sharmila J on 12-Mar-2020 <Begin>  
 UPDATE pyprc_cmn_ctc_rule_wrk_tmp  
 SET  tot_paid_days = paid_wrking_days  
 WHERE process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --Code added by Sharmila J on 12-Mar-2020 <End>  
  
 -- code added by senthil arasu b on 14-Mar-2019 for defect id HMB-29<starts>  
 EXEC pyprc_cmn_pay_rule_proration_hook_sp @rule_type   ,   
             @pay_elt_cd   ,  
             @payroll_ou_cd  ,   
             @payroll_cd   ,   
             @paySET_cd   ,     
             @prcprd_cd   ,   
             @process_number  ,   
             @pprd_FROM_date  ,  
             @pprd_to_date  ,  
             @progressive_flag ,  
             'OA' --to overwrite opted amount   
 -- code added by senthil arasu b on 14-Mar-2019 for defect id HMB-29<ends>  
 --Code moved above by Sharmila J on 26-Aug-2022 for HRPS-4125 <Begin>  
 /*  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
 --Get employee's gre calendar data into the temp table pyprc_cmn_ctc_rule_emp_gre_cal  
 INSERT INTO pyprc_cmn_ctc_rule_emp_gre_cal     
 (   
  master_ou,    employment_ou,   employee_code,    original_shift_code,     
  shift_code,    schedule_date,   holiday_qc,     shift_devn_qc,    
  offday_qc       
  ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,process_number     --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 )    
 SELECT    
  gre.master_ou,   gre.employment_ou,  gre.employee_code,   gre.original_shift_code,     
  gre.shift_code,   gre.schedule_date,  gre.holiday_qc,    gre.shift_devn_qc,    
  gre.offday_qc       
  ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  ,@process_number    --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542   
 FROM tmscd_emp_gre_calendar gre WITH (NOLOCK)    
 JOIN (  
    SELECT DISTINCT  
      master_ou, --Code added by Sharmila.J on 09-Jun-2020 for the defect id JSPH-188  
      emp_ou,  
      employee_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_wrk_tmp  
   )tmp  
 ON  tmp.master_ou  = gre.master_ou --Code added by Sharmila.J on 09-Jun-2020 for the defect id JSPH-188  
 AND  tmp.emp_ou   = gre.employment_ou  
 AND  tmp.employee_code = gre.employee_code  
 AND  tmp.assignment_no = gre.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837      
 --Code added and commented by Sharmila J for the defect id HBM-1843 on 25-Sep-2020 <Begin>  
 WHERE gre.master_ou  = @tmgif_ou   
    AND  gre.employment_ou = @empin_ou --Code added by Sharmila J for the defect id COH-134 on 08-Apr-2020  
    --WHERE gre.employment_ou = @empin_ou --Code added by Sharmila J for the defect id COH-134 on 08-Apr-2020  
 --Code added and commented by Sharmila J for the defect id HBM-1843 on 25-Sep-2020 <End>  
 AND  gre.schedule_date BETWEEN @pprd_from_date AND @pprd_to_date  
 --Code added by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
*/  
 --Code moved above by Sharmila J on 26-Aug-2022 for HRPS-4125 <End>  
 --Computing total paid Days for the mid join partial employees for the given process period as per Calendar Days and fixed days  
 IF EXISTS (   
      SELECT 'X'   
      FROM ldef_leave_parameters WITH (NOLOCK)  
      WHERE master_ou_code  = @lvdef_ou                  
      AND time_mgmt_intgn_flag = 'PART'   
     )    
 BEGIN  
  
  --Computing per day salary for the partial employees having calender days or fixed days as proration type  
  UPDATE tmp  
  --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <Begin>  
  --SET  per_day_sal    = CASE WHEN vw.frequency_code in ('M','W') THEN isnull(vw.opted_amount,0)/ tmp.paid_wrking_days  
  --           WHEN vw.frequency_code ='Y' THEN (isnull(vw.opted_amount,0)/12.0 ) / tmp.paid_wrking_days  
  --           WHEN vw.frequency_code ='D' THEN isnull(vw.opted_amount,0)  
  --         END,  
  -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <starts>  
  --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <Begin>  
  SET  per_day_sal    = isnull(vw.opted_amount,0)/ NULLIF(tmp.paid_wrking_days,0.0),  
  --SET  per_day_sal    = isnull(vw.opted_amount,0)/ tmp.paid_wrking_days,  
  --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <End>  
  /*  
  SET  per_day_sal    = CASE WHEN vw.frequency_code ='D' THEN isnull(vw.opted_amount,0)  
             ELSE isnull(vw.opted_amount,0)/ tmp.paid_wrking_days  
           END,  
  */  
  -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <ends>  
  --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <End>  
    Opted_amount   = vw.opted_amount,  
    ctc_exchange_rate  = vw.ctc_exchange_rate  
    ,tmp.paid_wrking_days = 0--Code added by Sharmila J for the defect id RGSH-99 on 18-Oct-2019  
  FROM pyprc_cmn_ctc_rule_comp_tmp      vw  WITH (NOLOCK),  
    pyprc_cmn_ctc_rule_wrk_tmp      tmp,  
    ldef_leave_parameters   lv WITH (NOLOCK)  
  WHERE vw.master_ou_code  = @empng_ou  
  AND  vw.empin_ou    = @empin_ou  
  AND  tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  AND  vw.empin_ou    = tmp.emp_ou  
  AND  vw.employee_code  = tmp.employee_code  
  AND  tmp.assignment_no  = vw.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  --Code added and commented by Sharmila J for the defect id HST-7014 <Begin>  
  --Code added and commented by Sharmila J on 27-Jul-2021 <Begin>  
  --AND  tmp.pror_type   <> 'CD'     
  AND  tmp.pror_type   NOT IN   ('CD','FCD')   --Code commented and added by HARI for SAIH-909 on 08-Feb-2023      
  --AND  tmp.pror_type   in ('FD', 'WD', 'AWD')    
  --Code added and commented by Sharmila J on 27-Jul-2021 <End>   
  --Code added and commented by Sharmila J for the defect id HST-6932 <Begin>  
  --AND  tmp.pror_type   in ('FD', 'WD')   
  --AND  tmp.pror_type   in ('CD','FD', 'WD') -- WD type added by senthil arasu b on 28-Aug-2018 for the defect id HC-2430  
  --Code added and commented by Sharmila J for the defect id HST-6932 <End>  
  --Code added and commented by Sharmila J for the defect id HST-7014 <End>  
  AND  tmp.effective_FROM between vw.effective_FROM and isnull(vw.effective_to ,tmp.effective_to)                            
  AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  AND  tmp.process_number = vw.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Code added by Sharmila J on 22-Mar-2022 for HRP-6958 <Begin>  
  UPDATE tmp  
  SET  paid_wrking_days  = 0  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp  
  WHERE tmp.process_number  = @process_number  
  AND  tmp.pror_type   IN ('FD','WD','AWD')  
  --Code added by Sharmila J on 22-Mar-2022 for HRP-6958 <End>  
  
  --Computing total paid Days for the partial mid join employees for the given process period as per Fixed Days, if paid week off is Both Day  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     SELECT count(cal.schedule_date)as sch_days,tmp.employee_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM hrcmn_schedule_calendar cal WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
     WHERE cal.empng_ou   = @empng_ou  
     AND  cal.empin_ou   = tmp.master_ou  
     AND  cal.empin_ou   = tmp.emp_ou  
     --AND tmp.employment_flag  = 'Y'  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     AND  tmp.paid_week_off  = 'BD'                                
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     Group by tmp.employee_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
        ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    )a  
  Where a.employee_code  = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND tmp.employment_flag = 'Y' -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  AND  tmp.effective_from = a.effective_from  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Computing total paid Days for the partial mid join employees for the given process period as per Fixed Days, if paid week off is Rest Day  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     SELECT count(cal.schedule_date)as sch_days,tmp.employee_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM hrcmn_schedule_calendar cal WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
     WHERE cal.empng_ou   = @empng_ou  
     AND  cal.empin_ou   = tmp.master_ou  
     AND  cal.empin_ou   = tmp.emp_ou  
     --AND  tmp.employment_flag  = 'Y'  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     AND  tmp.paid_week_off  = 'RD'  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.shift_code   <>  'OFF'  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     --AND  cal.shift_code   =   'WOFF'                     
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     Group by tmp.employee_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
        ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    )a  
  Where a.employee_code  = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND  tmp.employment_flag = 'Y' -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  AND  tmp.effective_from = a.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Computing total paid Days for the partial mid join employees for the given process period as per Fixed Days, if paid week off is OFF Day  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     SELECT count(cal.schedule_date)as sch_days,tmp.employee_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM hrcmn_schedule_calendar cal WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
     WHERE cal.empng_ou   = @empng_ou  
     AND  cal.empin_ou   = tmp.master_ou  
     AND  cal.empin_ou   = tmp.emp_ou  
     --AND  tmp.employment_flag  = 'Y'   
     --Code added and commented by SHarmila J for the defect id HST-7024 on 24-Feb-2020 <Begin>  
     AND  tmp.paid_week_off  = 'OD'  
     --AND  tmp.paid_week_off  = 'OFF'  
     --Code added and commented by SHarmila J for the defect id HST-7024 on 24-Feb-2020 <End>  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.shift_code   <>  'WOFF'           
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     --AND  cal.shift_code   =   'OFF'           
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     Group by tmp.employee_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
        ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    )a  
  Where a.employee_code  = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  AND  tmp.employment_flag = 'Y'  
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  AND  tmp.effective_from = a.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Computing total paid Days for the partial mid join employees for the given process period as per Fixed Days, if paid week off is null  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     SELECT count(cal.schedule_date)as sch_days,tmp.employee_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
       ,tmp.assignment_no--code commented by Arthi R V on 14-June-2021 for the defect id HRPS-1095  
     FROM hrcmn_schedule_calendar cal WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
       --code commented by Arthi R V on 14-June-2021 for the defect id HRPS-1095<Begin>  
       --,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
       --code commented by Arthi R V on 14-June-2021 for the defect id HRPS-1095<End>  
     WHERE cal.empng_ou   = @empng_ou  
     AND  cal.empin_ou   = tmp.master_ou  
     AND  cal.empin_ou   = tmp.emp_ou  
     --AND tmp.employment_flag  = 'Y' -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     --Code added and commented by Sharmila J on 09-Jan-2019 for the defect id HC-2761 <Begin>  
     AND  ((tmp.paid_week_off  = '-1') or (tmp.paid_week_off is null) )  
     --AND  ((tmp.paid_week_off  = -1) or (tmp.paid_week_off is null) )  
     --Code added and commented by Sharmila J on 09-Jan-2019 for the defect id HC-2761 <End>  
     AND  cal.shift_code   not in ( 'OFF','WOFF')                               
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     Group by tmp.employee_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
        ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    )a  
  Where a.employee_code  = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND  tmp.employment_flag = 'Y' -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  AND  tmp.effective_from = a.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Code added and commented by Sharmila J for the defect id HST-6442  <Begin>  
  --Computing total paid Days for the mid join partial employees for the given process period as per Calendar Days  
  --Code commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <Begin>  
  /*  UPDATE tmp  
  SET  paid_wrking_days  = DATEDIFF(dd,effective_from,effective_to)+1  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    ldef_leave_parameters lv WITH (NOLOCK)  
  Where tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  And  lv.master_ou_code  = @lvdef_ou                  
  AND  lv.time_mgmt_intgn_flag = 'PART'  
  AND  tmp.pror_type   = 'CD'  
  AND  ( (tmp.employment_flag  = 'Y' AND (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ))  
    OR (tmp.Separation_flag  = 'Y' AND (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ))   
    )  
  */  
  --Code commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <End>  
  
/*  --Computing total paid Days for the mid join partial employees for the given process period as per Calendar Days  
  UPDATE tmp  
  SET  paid_wrking_days  = DATEDIFF(dd,employment_date,@pprd_to_date)+1  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    ldef_leave_parameters lv WITH (NOLOCK)  
  Where tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  And  lv.master_ou_code  = @lvdef_ou                  
  AND  lv.time_mgmt_intgn_flag = 'PART'  
  AND  tmp.pror_type   = 'CD'  
  AND  tmp.employment_flag  = 'Y'  
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
*/  
  --Code added and commented by Sharmila J for the defect id HST-6442  <End>  
  
 END  
 -- code added and commented by senthil arasu b on 07-May-2018 <starts>  
 ELSE IF EXISTS (   
      SELECT 'X'   
      FROM ldef_leave_parameters WITH (NOLOCK)  
      WHERE master_ou_code   = @lvdef_ou                  
      AND  time_mgmt_intgn_flag = 'FULL'   
     )    
-- ELSE     
 -- code added and commented by senthil arasu b on 07-May-2018 <ends>  
 BEGIN  
  --Computing per day salary AND per hour salary based on the proration type for the given process period  
  UPDATE tmp  
  SET  per_hr_sal    =  --Code added and commented by Sharmila J for the defect id HST-7014 <Begin>  
            CASE WHEN tmp.pror_type IN ( 'WH' ,'AWH')THEN  
           --CASE WHEN tmp.pror_type = 'WH' THEN  
           --Code added and commented by Sharmila J for the defect id HST-7014 <End>  
           --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <Begin>   
             -- CASE WHEN vw.frequency_code in ('M','W') THEN isnull(vw.opted_amount,0)/ tmp.sch_hrs  
             --WHEN vw.frequency_code ='Y' THEN (isnull(vw.opted_amount,0)/12.0 ) / tmp.sch_hrs  
             --WHEN vw.frequency_code ='H' THEN isnull(vw.opted_amount,0)  
             --WHEN vw.frequency_code ='D' THEN (isnull(vw.opted_amount,0)*@cal_days)/ tmp.sch_hrs  
             -- END  
            -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <starts>  
            --GHKH-57  
            --Code added and commented by SHarmila J on 28-Oct-2020 <Begin>  
            ISNULL(vw.opted_amount,0)/ NULLIF(tmp.sch_hrs,0.0) ELSE 0   
            --ISNULL(vw.opted_amount,0)/ tmp.sch_hrs ELSE 0   
            --Code added and commented by SHarmila J on 28-Oct-2020 <End>  
            --GHKH-57  
            /*  
                CASE   
             WHEN vw.frequency_code ='H' THEN isnull(vw.opted_amount,0)  
             ELSE ISNULL(vw.opted_amount,0)/ tmp.sch_hrs  
             END   
            */  
            -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <ends>  
            --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <End>      
            END ,   
    --Code added and commented  by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <Begin>   
    -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <starts>  
    --Code added and commented by Sharmila J for the defect id HST-7014 <Begin>  
    per_day_sal    =  CASE WHEN tmp.pror_type in ('WD','CD','FD','AWD') THEN  
             --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <Begin>  
             ISNULL(vw.opted_amount,0)/ NULLIF(tmp.paid_wrking_days,0.0)  
             --ISNULL(vw.opted_amount,0)/ tmp.paid_wrking_days  
             --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <End>  
             WHEN tmp.pror_type IN ( 'WH','AWH') THEN   
             --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <Begin>  
             (ISNULL(vw.opted_amount,0)/ NULLIF(tmp.sch_hrs,0.0)) * week_tot_hrs  
             --(ISNULL(vw.opted_amount,0)/ tmp.sch_hrs) * week_tot_hrs  
             --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <End>  
  
           END,  
    /*  
    per_day_sal    =  CASE WHEN tmp.pror_type in ('WD','CD','FD') THEN   
             ISNULL(vw.opted_amount,0)/ tmp.paid_wrking_days  
             WHEN tmp.pror_type = 'WH' THEN   
             (ISNULL(vw.opted_amount,0)/ tmp.sch_hrs) * week_tot_hrs  
           END,  
    */  
    --Code added and commented by Sharmila J for the defect id HST-7014 <End>         
    /*  
    per_day_sal    =  CASE WHEN tmp.pror_type in ('WD','CD','FD') THEN   
             CASE WHEN vw.frequency_code ='D' THEN isnull(vw.opted_amount,0)  
               ELSE isnull(vw.opted_amount,0)/ tmp.paid_wrking_days  
             END  
            WHEN tmp.pror_type = 'WH' THEN  
             CASE WHEN vw.frequency_code ='H' THEN isnull(vw.opted_amount,0) * week_tot_hrs  
             ELSE (isnull(vw.opted_amount,0)/ tmp.sch_hrs) * week_tot_hrs  
            END  
           END,     
    */  
    -- code added and commented by senthil arasu b on 15-Mar-2015 for defect id HST-3284 <ends>  
    Opted_amount   = ISNULL(vw.opted_amount,0), -- code added by senthil arasu b on 18-Dec-2018  
   /* per_day_sal    =  CASE WHEN tmp.pror_type in ('WD','CD','FD') THEN   
              
            CASE WHEN vw.frequency_code in ('M','W') THEN isnull(vw.opted_amount,0)/ tmp.paid_wrking_days  
              WHEN vw.frequency_code ='Y' THEN (isnull(vw.opted_amount,0)/12.0 ) / tmp.paid_wrking_days  
              WHEN vw.frequency_code ='D' THEN isnull(vw.opted_amount,0)  
            END  
              
            WHEN tmp.pror_type = 'WH' THEN  
             CASE WHEN vw.frequency_code in ('M','W') THEN (isnull(vw.opted_amount,0)/ tmp.sch_hrs) * week_tot_hrs  
             WHEN vw.frequency_code ='Y' THEN ((isnull(vw.opted_amount,0)/12.0 )/ tmp.sch_hrs)* week_tot_hrs  
             WHEN vw.frequency_code ='H' THEN isnull(vw.opted_amount,0) * week_tot_hrs  
             WHEN vw.frequency_code ='D' THEN ((isnull(vw.opted_amount,0)*@cal_days)/ tmp.sch_hrs)* week_tot_hrs  
            END  
            END,  
    */  
    --Code commented and added by Sharmila J on 22-Nov-2018 for the defect id HC-2734 <End>  
    --Opted_amount   = CASE WHEN vw.frequency_code in ('M') THEN isnull(vw.opted_amount,0)  
    --          WHEN vw.frequency_code ='Y' THEN (isnull(vw.opted_amount,0)/12.0 )  
    --          WHEN vw.frequency_code ='D' THEN (isnull(vw.opted_amount,0)*@cal_days)  
    --       END,  
    ctc_exchange_rate  = vw.ctc_exchange_rate  
    ,tmp.paid_wrking_days = 0 --Code added by Sharmila J for the defect id RGSH-99 on 18-Oct-2019  
  FROM pyprc_cmn_ctc_rule_comp_tmp      vw WITH (NOLOCK),  
    pyprc_cmn_ctc_rule_gre_cal_tmp     temp WITH (NOLOCK),  
    pyprc_cmn_ctc_rule_wrk_tmp      tmp  
  WHERE vw.master_ou_code  = @empng_ou  
  AND  vw.empin_ou    = @empin_ou  
  AND  tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  AND  temp.master_ou   = @empin_ou  
  AND  temp.emp_ou    = @empin_ou  
  AND  vw.empin_ou    = temp.emp_ou  
  AND  vw.empin_ou    = tmp.emp_ou  
  AND  tmp.master_ou   = temp.master_ou  
  AND  tmp.emp_ou    = temp.emp_ou  
  AND  vw.employee_code  = tmp.employee_code   
  AND  vw.employee_code  = temp.emp_code  
  AND  tmp.employee_code  = temp.emp_code  
  AND  tmp.assignment_no  = temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  temp.assignment_no  = vw.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  tmp.effective_from between vw.effective_from and isnull(vw.effective_to,tmp.effective_to)  
  AND  temp.schedule_date  BETWEEN @pprd_FROM_date AND @pprd_to_date  
  --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
  AND  tmp.pror_type   NOT IN ('CD','FCD')--Code added by Sharmila J for the defect id HST-6932 on 16-Aug-2019  
  --AND  tmp.pror_type   <> 'CD'--Code added by Sharmila J for the defect id HST-6932 on 16-Aug-2019  
  --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  AND  tmp.process_number  = temp.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  AND  temp.process_number  = vw.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Code added by Sharmila J on 22-Mar-2022 for HRP-6958 <Begin>  
  UPDATE tmp  
  SET  paid_wrking_days  = 0  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp  
  WHERE tmp.process_number  = @process_number  
  AND  tmp.pror_type   IN ('FD','WD','AWD')  
  --Code added by Sharmila J on 22-Mar-2022 for HRP-6958 <End>  
  
  --Computing total paid Days for the scheduled mid join employees for the given process period as per Fixed Days, if paid week off is both Days  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
     SELECT COUNT(gre.schedule_date)AS sch_days,tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
     WHERE gre.employee_code  = tmp.employee_code              
     AND  gre.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     AND  gre.employment_ou  = tmp.emp_ou  
     AND  tmp.paid_week_off  = 'BD'  
     AND  gre.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   =  'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     /*       
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp  tmp  
     WHERE cal.master_ou   = @payroll_ou_cd                     
     AND  cal.emp_code   = tmp.employee_code              
     AND  cal.emp_ou    = tmp.emp_ou  
     AND  tmp.paid_week_off  = 'BD'  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  cal.effective_from  = tmp.effective_from  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     Group by emp_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     */  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
    )a  
  Where a.emp_code   = tmp.employee_code  
  AND  tmp.assignment_no = a.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND  tmp.employment_flag = 'Y' -- code commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667  
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  AND  tmp.effective_from = a.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    
  --Computing total paid Days for the scheduled mid join employees for the given process period as per Fixed Days, if paid week off is Rest Days  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
     SELECT COUNT(gre.schedule_date)AS sch_days,tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
     WHERE gre.employee_code  = tmp.employee_code              
     AND  gre.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     AND  gre.employment_ou  = tmp.emp_ou  
     AND  tmp.paid_week_off  = 'RD'  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <Begin>  
     AND  ISNULL(gre.shift_code,gre.original_shift_code) <> 'OFF'  
     --AND  gre.shift_code  <> 'OFF'  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <End>  
     AND  gre.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     /*       
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp  tmp  
     WHERE cal.master_ou   = @payroll_ou_cd           
     AND  cal.emp_code   = tmp.employee_code              
     AND  cal.emp_ou    = tmp.emp_ou  
     AND  tmp.paid_week_off  = 'RD'  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.shift_code   <> 'OFF'  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  cal.effective_from  = tmp.effective_from  
     --AND  cal.shift_code   = 'WOFF'  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     Group by emp_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     */  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
    )a  
  Where a.emp_code   = tmp.employee_code  
  AND  tmp.assignment_no = a.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND  tmp.employment_flag= 'Y' -- code commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667  
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
  AND  tmp.effective_from = a.effective_from   
 -- AND  tmp.paid_wrking_days >= a.sch_days--Code commented by Sharmila on 24-Feb-2020  
  --the above condition is not valid if paid working days updated as 0 for Fixed days proration in the previous update for the defect id RGSH-99  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Computing total paid Days for the scheduled mid join employees for the given process period as per Fixed Days, if paid week off is Off Days  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
     SELECT COUNT(gre.schedule_date)AS sch_days,tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
     WHERE gre.employee_code  = tmp.employee_code              
     AND  gre.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     AND  gre.employment_ou  = tmp.emp_ou  
     AND  tmp.paid_week_off  = 'OD'  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <Begin>  
     AND  ISNULL(gre.shift_code,gre.original_shift_code) <> 'WOFF'  
     --AND  gre.shift_code   <> 'WOFF'  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <End>  
     AND  gre.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     /*       
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,tmp.emp_ou  
       ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp  tmp  
     WHERE cal.master_ou   = @payroll_ou_cd                     
     AND  cal.emp_code   = tmp.employee_code              
     AND  cal.emp_ou    = tmp.emp_ou  
     --Code added and commented by SHarmila J for the defect id HST-7024 on 24-Feb-2020 <Begin>  
     AND  tmp.paid_week_off  = 'OD'  
     --AND  tmp.paid_week_off  = 'OFF'  
     --Code added and commented by SHarmila J for the defect id HST-7024 on 24-Feb-2020 <End>  
     AND  cal.shift_code   <> 'WOFF'  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
     AND  cal.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  cal.effective_from  = tmp.effective_from  
     --AND  cal.shift_code   = 'OFF'  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
     Group by emp_code,tmp.emp_ou  
        ,tmp.effective_from -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667   
     */  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
    )a  
  Where a.emp_code   = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  --AND  tmp.employment_flag= 'Y'  -- code commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667  
  AND  (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
  AND  tmp.effective_from = a.effective_from   
 -- AND  tmp.paid_wrking_days >= a.sch_days--Code commented by Sharmila on 24-Feb-2020  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Computing total paid Days for the scheduled mid join employees for the given process period as per Fixed Days, if paid week off is null  
  --Code commented and added by Sharmila J on 27-July-2018 for the defect id HC-2302 <Begin>  
  /*  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,tmp.emp_ou  
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp  tmp  
     WHERE cal.master_ou   = @payroll_ou_cd      
     AND  cal.emp_code   = tmp.employee_code              
     AND  cal.emp_ou    = tmp.emp_ou  
     AND  ((tmp.paid_week_off  = '-1') OR (tmp.paid_week_off  is null))  
     AND  cal.shift_code not in ('OFF','WOFF')  
     AND  cal.schedule_date BETWEEN employment_date AND @pprd_to_date  
     Group by emp_code,tmp.emp_ou  
    )a  
  WHERE a.emp_code   = tmp.employee_code  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
  AND  tmp.employment_flag = 'Y'  
  */  
  
  UPDATE tmp  
  SET  paid_wrking_days  = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
     SELECT COUNT(gre.schedule_date)AS sch_days,tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK),  
       pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
     WHERE gre.employee_code  = tmp.employee_code              
     AND  gre.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     AND  gre.employment_ou  = tmp.emp_ou  
     AND  ((tmp.paid_week_off  = '-1') OR (tmp.paid_week_off IS NULL))  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <Begin>  
     AND  ISNULL(gre.shift_code,gre.original_shift_code) NOT IN ('OFF','WOFF')  
     --AND  gre.shift_code   NOT IN ('WOFF','OFF')  
     --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <End>  
     AND  gre.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
     AND  tmp.pror_type   = 'FD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
     GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
     /*       
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou,tmp.effective_from  
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp tmp  
     WHERE cal.master_ou   = @payroll_ou_cd     
     AND  cal.emp_ou    = tmp.emp_ou  
     AND  cal.emp_code   = tmp.employee_code                              
     AND  ((tmp.paid_week_off  = '-1') OR (tmp.paid_week_off  is null))  
     AND  cal.shift_code not in ('WOFF','OFF')  
     AND  cal.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
     AND  cal.effective_from = tmp.effective_from   
     Group by emp_code,cal.emp_ou,tmp.effective_from  
     */  
     --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
    )a  
  Where a.emp_code   = tmp.employee_code  
  AND  a.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'FD'  
 -- AND  tmp.employment_flag = 'N'  
  AND  tmp.effective_from = a.effective_from  
 -- AND  tmp.paid_wrking_days >= a.sch_days --code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 --Code commented by Sharmila on 24-Feb-2020  
  --Code commented and added by Sharmila J on 27-July-2018 for the defect id HC-2302 <End>  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  --Code added and commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <Begin>  
  --Computing total paid Days for the mid join partial employees for the given process period as per Calendar Days  
  --Code commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <Begin>  
  /*  
  UPDATE tmp  
  SET  paid_wrking_days  = DATEDIFF(dd,effective_from,effective_to)+1  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    ldef_leave_parameters lv WITH (NOLOCK)  
  Where tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  And  lv.master_ou_code  = @lvdef_ou                  
  AND  lv.time_mgmt_intgn_flag = 'FULL'  
  AND  tmp.pror_type   = 'CD'  
  AND  ( (tmp.employment_flag  = 'Y' AND (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ))  
    OR (tmp.Separation_flag  = 'Y' AND (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ))   
    )  
  */  
  --Code commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <End>  
  /*  
  --Computing total paid Days for the scheduled mid join employees for the given process period as per Calendar Days  
  UPDATE tmp  
  SET  paid_wrking_days   = a.sch_days  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
     --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <Begin>  
     SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou, tmp.effective_from   
     --SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou  
     --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <End>  
     FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
       pyprc_cmn_ctc_rule_wrk_tmp    tmp  
     WHERE cal.master_ou   = @payroll_ou_cd  
     AND  cal.master_ou   = tmp.master_ou  
     AND  cal.emp_ou    = tmp.emp_ou  
     AND  cal.emp_code   = tmp.employee_code   
     --AND  tmp.employment_flag  = 'Y'   --Code commented by Senthil Arasu B on 25-Jan-2019 for the defect id HC-2882                              
     --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <Begin>  
     AND  cal.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
     --AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
     --Code added and commented by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667 <End>  
     AND  cal.schedule_date BETWEEN cal.effective_from AND cal.effective_to --Code added by Senthil Arasu B on 25-Jan-2019 for the defect id HC-2882  
     Group by emp_code,cal.emp_ou, tmp.effective_from  
    )a  
  Where a.emp_code   = tmp.employee_code  
  AND  a.emp_ou   = tmp.emp_ou  
  AND  tmp.pror_type  = 'CD'  
  --AND  tmp.employment_flag = 'Y'--Code commented by Senthil Arasu B on 25-Jan-2019 for the defect id HC-2882                              
  AND  tmp.effective_from = a.effective_from --Code added by Senthil Arasu B on 26-Oct-2018 for the defect id HC-2667  
  */  
  --Code added and commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <End>  
 END  
 -- code added by senthil arasu b on 07-May-2019 <starts>  
   
 --Code added and commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <Begin>  
 --Computing per day salary for the employees having calender days as proration type  
    --Code added for NMIH-225 starts  
     UPDATE tmp                                
     set paid_wrking_days  = 0                            
     FROM pyprc_cmn_ctc_rule_wrk_tmp    tmp                                
     WHERE tmp.master_ou   = @empin_ou                                
     AND  tmp.emp_ou    = @empin_ou         
  --Code added and commented by Sharmila J on 22-Mar-2022 for HRP-6958 <Begin>  
     AND  tmp.pror_type   IN ( 'CD','FCD')             
     --AND  tmp.pror_type   = 'CD'             
     --Code added and commented by Sharmila J on 22-Mar-2022 for HRP-6958 <End>  
  AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                                
     and not exists (select 'x' FROM pyprc_cmn_ctc_rule_comp_tmp    vw  WITH (NOLOCK)                               
     WHERE vw.master_ou_code  = @empng_ou                           
     AND  vw.empin_ou    = @empin_ou                                
     AND  tmp.master_ou   = @empin_ou                                
     AND  tmp.emp_ou    = @empin_ou                                
     AND  vw.empin_ou    = tmp.emp_ou                       
     AND  vw.employee_code  = tmp.employee_code                                
     AND  vw.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837                                
     --Code added and commented by Sharmila J on 22-Mar-2022 for HRP-6958 <Begin>  
  AND  tmp.pror_type   IN ( 'CD','FCD')           
  --AND  tmp.pror_type   = 'CD'             
  --Code added and commented by Sharmila J on 22-Mar-2022 for HRP-6958 <End>  
     AND tmp.effective_FROM between vw.effective_FROM and isnull(vw.effective_to ,tmp.effective_to)           
     AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                                
     AND  tmp.process_number  = vw.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                        
     )  
    --Code added for NMIH-225 ends  
 UPDATE tmp  
 --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <Begin>  
 SET  per_day_sal    = isnull(vw.opted_amount,0)/ NULLIF(tmp.paid_wrking_days,0.0),  
 --SET  per_day_sal    = isnull(vw.opted_amount,0)/ tmp.paid_wrking_days,  
 --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <End>  
   Opted_amount   = vw.opted_amount,  
   ctc_exchange_rate  = vw.ctc_exchange_rate,  
   paid_wrking_days  = DATEDIFF(dd,tmp.effective_from,tmp.effective_to)+1  
 FROM pyprc_cmn_ctc_rule_comp_tmp    vw WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp    tmp  
 WHERE vw.master_ou_code  = @empng_ou  
 AND  vw.empin_ou    = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  vw.empin_ou    = tmp.emp_ou  
 AND  vw.employee_code  = tmp.employee_code  
 AND  vw.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
 AND  tmp.pror_type   IN ( 'CD' ,'FCD')  
 --AND  tmp.pror_type   = 'CD'   
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
 AND  tmp.effective_FROM between vw.effective_FROM and isnull(vw.effective_to ,tmp.effective_to)       
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = vw.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542                       
 /*  
 ELSE  
 BEGIN  
  --Computing per day salary for the partial employees having calender days or fixed days as proration type  
  UPDATE tmp  
  SET  per_day_sal    = isnull(vw.opted_amount,0)/ tmp.paid_wrking_days,  
    Opted_amount   = vw.opted_amount,  
    ctc_exchange_rate  = vw.ctc_exchange_rate,  
    paid_wrking_days  = DATEDIFF(dd,tmp.effective_from,tmp.effective_to)+1  
  FROM pyprc_cmn_ctc_rule_comp_tmp    vw ,  
    pyprc_cmn_ctc_rule_wrk_tmp    tmp  
  WHERE vw.master_ou_code  = @empng_ou  
  AND  vw.empin_ou    = @empin_ou  
  AND  tmp.master_ou   = @empin_ou  
  AND  tmp.emp_ou    = @empin_ou  
  AND  vw.empin_ou    = tmp.emp_ou  
  AND  vw.employee_code  = tmp.employee_code  
  AND  tmp.pror_type   in ('CD','FD', 'WD')   
  AND  tmp.effective_FROM between vw.effective_FROM and isnull(vw.effective_to ,tmp.effective_to)                            
 END  
 */  
 --Code added and commented by Sharmila J for the defect id HST-6932 on 16-Aug-2019 <End>  
 -- code added by senthil arasu b on 07-May-2019 <ens>  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
 UPDATE tmp  
 --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <Begin>  
 SET  per_hr_sal    = ISNULL(vw.opted_amount,0)/ NULLIF(tmp.sch_hrs,0.0),  
 --SET  per_hr_sal    = ISNULL(vw.opted_amount,0)/ tmp.sch_hrs,  
 --Code added and commented by Sharmila J on 24-Feb-2021 for HRP-2245 <End>  
   Opted_amount   = vw.opted_amount,  
   ctc_exchange_rate  = vw.ctc_exchange_rate,  
   paid_wrking_days  = DATEDIFF(dd,tmp.effective_from,tmp.effective_to)+1  
 FROM pyprc_cmn_ctc_rule_comp_tmp    vw WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp    tmp  
 WHERE vw.master_ou_code  = @empng_ou  
 AND  vw.empin_ou    = @empin_ou  
 AND  tmp.master_ou   = @empin_ou  
 AND  tmp.emp_ou    = @empin_ou  
 AND  vw.empin_ou    = tmp.emp_ou  
 AND  vw.employee_code  = tmp.employee_code  
 AND  tmp.assignment_no  = vw.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp.pror_type   IN ('AWH')   
 AND  tmp.effective_FROM  BETWEEN vw.effective_FROM AND ISNULL(vw.effective_to ,tmp.effective_to)     
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 AND  tmp.process_number  = vw.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542     
 --Code added by Sharmila J for the defect id HST-7014 <End>  
  
 --Computing total paid Days for the mid join employees for the given process period as per Working Days  
 --code commented by senthil arasu b on 09-Aug-2018 this scenario is handled in the above update for proration method "WD" <starts>  
 /*  
 UPDATE tmp  
 SET  paid_wrking_days   = a.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
      pyprc_cmn_ctc_rule_wrk_tmp    tmp  
    WHERE cal.master_ou   = @payroll_ou_cd  
    AND  cal.master_ou   = tmp.master_ou  
    AND  cal.emp_ou    = tmp.emp_ou  
    AND  cal.emp_code   = tmp.employee_code    
    AND  cal.holiday_qc   = 'N'  
    AND  cal.shift_code   not in ('WOFF','OFF')  
    AND  tmp.employment_flag  = 'Y'  
    AND  cal.schedule_date BETWEEN tmp.employment_date AND @pprd_to_date  
    Group by cal.emp_code,cal.emp_ou  
   )a  
 Where a.emp_code   = tmp.employee_code  
 AND  a.emp_ou   = tmp.emp_ou  
 AND  tmp.pror_type  = 'WD'  
 AND  tmp.employment_flag = 'Y'  
 */  
 --code commented by senthil arasu b on 09-Aug-2018 <ends>  
  
 --Code added by Sharmila J on 22-Mar-2022 for HRP-6958/HKH-4329 <Begin>  
 UPDATE tmp  
 SET  sch_hrs = 0  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp  
 WHERE tmp.process_number  = @process_number  
 AND  tmp.pror_type   IN ('WH','AWH')  
 --Code added by Sharmila J on 22-Mar-2022 for HRP-6958/HKH-4329 <End>  
  
 --Computing total Working Days for the given process period  
 UPDATE tmp  
 SET  paid_wrking_days  = a.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
    SELECT COUNT(gre.schedule_date)AS sch_days,tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from   
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK),  
      pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
    WHERE gre.employee_code  = tmp.employee_code              
    AND  gre.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  gre.employment_ou  = tmp.emp_ou  
    --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <Begin>  
    AND  ISNULL(gre.shift_code,gre.original_shift_code) NOT IN ('OFF','WOFF')  
    --AND  gre.shift_code   NOT IN ('WOFF','OFF')  
    --Code added and commented by Sharmila J for the defect id COH-134 on 08-Apr-2020 <End>  
    AND  gre.schedule_date  BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.pror_type   = 'WD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
    GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    /*       
    SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou,tmp.effective_from  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
      pyprc_cmn_ctc_rule_wrk_tmp tmp  
    WHERE cal.master_ou   = @payroll_ou_cd     
    AND  cal.emp_ou    = tmp.emp_ou  
    AND  cal.emp_code   = tmp.employee_code                              
    --Code commented by Sharmila J for the defect id RGSH-99 on 18-Oct-2019 <Begin>  
    --AND  cal.holiday_qc   = 'N'  
    --Code commented by Sharmila J for the defect id RGSH-99 on 18-Oct-2019 <End>  
    AND  cal.shift_code not in ('WOFF','OFF')  
    AND  cal.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  cal.effective_from = tmp.effective_from   
    Group by emp_code,cal.emp_ou,tmp.effective_from  
    */  
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
   )a  
 Where a.emp_code   = tmp.employee_code  
 AND  tmp.assignment_no = a.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  a.emp_ou   = tmp.emp_ou  
 AND  tmp.pror_type  = 'WD'  
 --AND  tmp.employment_flag = 'N'  
 AND  tmp.effective_from = a.effective_from  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Computing total Calendar Days for the given process period for the scheduled employees  
      
 --Code commented and added by Sharmila J on 27-July-2018 for the defect id HC-2152 <Begin>  
 --UPDATE tmp  
 --SET  paid_wrking_days   = a.sch_days  
 --FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
 --  ldef_leave_parameters lv WITH (NOLOCK),  
 --  (  
 --   SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou  
 --   FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
 --     pyprc_cmn_ctc_rule_wrk_tmp    tmp  
 --   WHERE cal.master_ou   = @payroll_ou_cd   
 --   AND  cal.emp_ou    = tmp.emp_ou  
 --   AND  cal.emp_code   = tmp.employee_code                                 
 --   AND  cal.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
 --   Group by emp_code,cal.emp_ou  
 --  )a  
 --Where a.emp_code   = tmp.employee_code  
 --AND  a.emp_ou   = tmp.emp_ou  
 --AND  lv.master_ou_code = a.emp_ou  
 --AND  lv.master_ou_code = tmp.emp_ou  
 --AND  tmp.pror_type  = 'CD'  
 --AND  lv.time_mgmt_intgn_flag ='FULL'  
 --AND  tmp.employment_flag = 'N'  
 --Code commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <Begin>  
 /*  
 UPDATE tmp  
 SET  paid_wrking_days   = a.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   ldef_leave_parameters lv WITH (NOLOCK),  
   (  
    SELECT count(cal.schedule_date)as sch_days,cal.emp_code,cal.emp_ou,tmp.effective_from  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp   cal,  
      pyprc_cmn_ctc_rule_wrk_tmp    tmp  
    WHERE cal.master_ou   = @payroll_ou_cd   
    AND  cal.emp_ou    = tmp.emp_ou  
    AND  cal.emp_code   = tmp.employee_code                                 
    AND  cal.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  cal.effective_from = tmp.effective_from  
    Group by emp_code,cal.emp_ou,tmp.effective_from  
   )a  
 Where a.emp_code   = tmp.employee_code  
 AND  a.emp_ou   = tmp.emp_ou  
 AND  lv.master_ou_code = a.emp_ou  
 AND  lv.master_ou_code = tmp.emp_ou  
 AND  tmp.pror_type  = 'CD'  
 AND  lv.time_mgmt_intgn_flag ='FULL'  
 AND  tmp.employment_flag = 'N'  
 AND  tmp.effective_from = a.effective_from  
 */  
 --Code commented by Sharmila J on 25-Mar-2019 for the defect id MRH-7 <End>  
 --Code commented and added by Sharmila J on 27-July-2018 for the defect id HC-2152 <End>  
 --Monthly total scheduled hours for the employess  
 Update tmp  
 SET  sch_hrs   = t.tot  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (   
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
    SELECT SUM(ISNULL(DATEDIFF(mi,(gre.schedule_date+hdr.shift_start_time),  
      (DATEADD(dd,hdr.shift_spill_over,gre.schedule_date)+ hdr.shift_end_time)),0.00)/60.00)'tot',  
      tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from 'eff_from'  
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre WITH (NOLOCK)  
    JOIN tmgif_shift_hdr  hdr WITH (NOLOCK)  
    ON  hdr.master_ou  = gre.master_ou  
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <Begin>  
    AND  hdr.shift_code  = ISNULL(gre.shift_code,gre.original_shift_code)  
    --AND  hdr.shift_code  = gre.shift_code   
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <End>  
    JOIN pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
    ON  gre.employee_code = tmp.employee_code              
    AND  gre.assignment_no = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  gre.employment_ou = tmp.emp_ou  
    WHERE gre.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.process_number  = gre.process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.pror_type   = 'WH' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
    GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from   
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    /*  
    SELECT sum(week_tot_hrs) AS TOT,temp.emp_code,tmp1.effective_from as eff_from,temp.rota_schedule_code  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp temp,  
      pyprc_cmn_ctc_rule_wrk_tmp tmp1  
    Where schedule_date BETWEEN tmp1.effective_from AND tmp1.effective_to  
    AND  temp.master_ou  = tmp1.master_ou  
    AND  temp.emp_ou   = tmp1.emp_ou  
    AND  temp.emp_code  = tmp1.employee_code  
    AND  tmp1.effective_from = temp.effective_from  
    group by emp_code,tmp1.effective_from,temp.rota_schedule_code  
    */  
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
   )t  
 WHERE tmp.employee_code  = t.emp_code  
 AND  tmp.assignment_no  = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
-- AND  tmp.employment_flag  = 'N'--Code commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020  
 AND  tmp.pror_type   = 'WH'  
 and  tmp.effective_from  = eff_from  
-- And  tmp.rota_schedule_code = t.rota_schedule_code--Code commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Code commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
/* --Computing total Scheduled Hours for the mid join employees for the given process period as per Working hours proration method  
 UPDATE tmp  
 SET  sch_hrs    = isnull(temp.mid_join_hrs,0)  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   pyprc_cmn_ctc_rule_gre_cal_tmp  temp  
 Where tmp.employee_code = temp.emp_code  
 AND  tmp.emp_ou   = temp.emp_ou  
 AND  tmp.pror_type  = 'WH'  
 AND  tmp.employment_flag = 'Y'  
 AND  tmp.effective_from = temp.effective_from -- code added by senthil arasu b on 13-Jul-2018 for new joinee with mid month salary change for the defect id HC-2071  
*/  
--Code commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
--Code added for ORH-1161 starts  
 Update tmp  
 --Code added and commented by Sharmila J on 10-Oct-2022 <Begin>  
 SET  sch_hrs   = ISNULL(tmp.sch_hrs,0) - ISNULL(t.tot,0)  
 --SET  sch_hrs   = t.tot  
 --Code added and commented by Sharmila J on 10-Oct-2022 <End>  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (   
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <Begin>  
    --Code added and commented by Sharmila J on 10-Oct-2022 <Begin>  
    SELECT SUM((ISNULL( ( CASE WHEN DATEDIFF(mi,dtl.from_time,dtl.to_time) < 0   
              THEN DATEDIFF(mi,CONVERT(DATETIME,dtl.from_time),  
                DATEADD(dd,1,CONVERT(DATETIME,dtl.to_time)))  
              ELSE DATEDIFF(mi,dtl.from_time,dtl.to_time)   
            END ),0.0)/60.0 ))'tot',  
    --SELECT SUM(ISNULL(DATEDIFF(mi,(gre.schedule_date+hdr.shift_start_time),  
    --  (DATEADD(dd,hdr.shift_spill_over,gre.schedule_date)+ hdr.shift_end_time)),0.00)/60.00  - ISNULL(total_break_time_hrs, 0.00))'tot',  
    --Code added and commented by Sharmila J on 10-Oct-2022 <End>  
      tmp.employee_code'emp_code',tmp.emp_ou,tmp.effective_from 'eff_from'  
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_emp_gre_cal  gre   
    JOIN tmgif_shift_hdr  hdr WITH (NOLOCK)  
    ON  hdr.master_ou  = gre.master_ou  
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <Begin>  
    AND  hdr.shift_code  = ISNULL(gre.shift_code,gre.original_shift_code)  
    JOIN tmgif_shift_dtl  dtl WITH (NOLOCK)  
    --AND  hdr.shift_code  = gre.shift_code join tmgif_shift_dtl dtl   
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <ENd>  
                    on  dtl.master_ou = hdr.master_ou  
                 and   dtl.shift_code = hdr.shift_code  
                 and  dtl.time_type_qc =   'BKTI'   
                 and   dtl.brk_type = 'UPAD'          
    JOIN pyprc_cmn_ctc_rule_wrk_tmp   tmp WITH (NOLOCK)  
    ON  gre.employee_code = tmp.employee_code              
    AND  gre.employment_ou = tmp.emp_ou  
    AND  gre.assignment_no = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  tmp.process_number = @process_number--Code added by Sharmila J on 18-Apr-2022 for HRP-7239  
    AND  tmp.process_number = gre.process_number--Code added by Sharmila J on 18-Apr-2022 for HRP-7239  
    WHERE gre.schedule_date BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  tmp.pror_type  = 'WH' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
    GROUP BY tmp.employee_code,tmp.emp_ou,tmp.effective_from, dtl.time_type_qc,   dtl.brk_type ,total_break_time_hrs    
    ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    /*  
    SELECT sum(week_tot_hrs) AS TOT,temp.emp_code,tmp1.effective_from as eff_from,temp.rota_schedule_code  
    FROM pyprc_cmn_ctc_rule_gre_cal_tmp temp,  
      pyprc_cmn_ctc_rule_wrk_tmp tmp1  
    Where schedule_date BETWEEN tmp1.effective_from AND tmp1.effective_to  
    AND  temp.master_ou  = tmp1.master_ou  
    AND  temp.emp_ou   = tmp1.emp_ou  
    AND  temp.emp_code  = tmp1.employee_code  
    AND  tmp1.effective_from = temp.effective_from  
    group by emp_code,tmp1.effective_from,temp.rota_schedule_code  
    */  
    --Code added and commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020 <End>  
   )t  
 WHERE tmp.employee_code  = t.emp_code  
 AND  tmp.assignment_no  = t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
-- AND  tmp.employment_flag  = 'N'--Code commented by Sharmila J for the defect id PAOH-194 on 30_Mar-2020  
 AND  tmp.pror_type   = 'WH'  
 and  tmp.effective_from  = eff_from  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 18-Apr-2022 for HRP-7239  
--Code added for ORH-1161 ends  
  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 --Computing total Working Days for the given process period  
 UPDATE tmp  
 SET  paid_wrking_days  = tmp1.sch_days  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   (  
    SELECT COUNT(tsh.tmsht_date)as sch_days,tsh.employee_code,tsh.empin_ou,tmp.effective_from  
      ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM tmsht_hourly_based_dtl tsh WITH (NOLOCK),  
      pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
    WHERE tsh.empng_ou   = @empng_ou                             
    AND  tsh.master_ou   = @empin_ou  
    AND  tsh.timesheet_status = 'AUTH'  
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <Begin>  
    AND  ISNULL(tsh.shift,'') NOT IN ('WOFF','OFF')   
    --AND  tsh.shift   NOT IN ('WOFF','OFF')   
    --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <End>  
    AND  tsh.empin_ou   = tmp.emp_ou  
    AND  tsh.employee_code  = tmp.employee_code                              
    AND  tsh.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  tsh.tmsht_date   BETWEEN tmp.effective_from AND tmp.effective_to  
    AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    AND  tmp.pror_type   = 'AWD' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
    Group by tsh.employee_code,tsh.empin_ou,tmp.effective_from  
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )tmp1  
 Where tmp1.employee_code = tmp.employee_code  
 AND  tmp.assignment_no = tmp1.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp1.empin_ou  = tmp.emp_ou  
 AND  tmp.pror_type  = 'AWD'  
 AND  tmp.effective_from = tmp1.effective_from  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 UPDATE tmp  
 SET  sch_hrs  = tmp1.act_wrk_hrs  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   ( SELECT in_tmp.employee_code, in_tmp.empin_ou, in_tmp.effective_from, SUM(in_act_wrk_hrs) AS act_wrk_hrs  
      ,in_tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM pyprc_cmn_ctc_rule_wrk_tmp in_wrk WITH (NOLOCK),  
      (  
       SELECT dtl.employee_code, dtl.empin_ou, dtl.tmsht_date, tmp.effective_from,  
       CASE WHEN (ISNULL( (CASE WHEN DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) < 0   
              THEN DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) * (-1)   
              ELSE DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) END)  
            ,0.0)/60.0)   
            < CAST((ISNULL(dtl.regular_hours/60.00,0.0)) AS NUMERIC(20,2))  
        THEN (ISNULL( (CASE WHEN DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) < 0   
              THEN DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) * (-1)   
              ELSE DATEDIFF(mi,CONCAT(CONVERT(DATE,dtl.scheduled_from_date),' ',dtl.scheduled_from_time),CONCAT(CONVERT(DATE,dtl.scheduled_to_date),' ',dtl.scheduled_to_time)) END)  
            ,0.0)/60.0)   
       ELSE ISNULL(dtl.regular_hours/60.00,0.0) END  AS in_act_wrk_hrs  
       --CAST(SUM(ISNULL(regular_hours/60.00,0.0)) AS NUMERIC(20,2)) AS act_wrk_hrs  
       ,tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
       FROM tmsht_hourly_based_dtl dtl WITH (NOLOCK),  
         pyprc_cmn_ctc_rule_wrk_tmp    tmp WITH (NOLOCK)  
       WHERE dtl.empng_ou   = @empng_ou                             
       AND  dtl.empin_ou   = @empin_ou  
       AND  dtl.timesheet_status = 'AUTH'  
       --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <Begin>  
       AND  ISNULL(dtl.shift,'') NOT IN ('WOFF','OFF')  
       --AND  dtl.shift    NOT IN ('WOFF','OFF')  
       --Code added and commented by Sharmila J on 01-Mar-2022 for HRP-6768 <End>  
       AND  dtl.tmsht_date   BETWEEN @pprd_from_date AND @pprd_to_date  
       AND  dtl.employee_code  = tmp.employee_code  
       AND  dtl.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
       AND  dtl.empin_ou   = tmp.emp_ou  
       AND  dtl.tmsht_date   BETWEEN tmp.effective_from AND tmp.effective_to  
       AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
       AND  tmp.pror_type   = 'AWH' -- added by senthil arasu b on 02-Dec-2022 for HRPS-5160  
      )in_tmp  
    WHERE in_tmp.empin_ou   = in_wrk.emp_ou  
    AND  in_tmp.employee_code = in_wrk.employee_code  
    AND  in_tmp.assignment_no = in_wrk.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    AND  in_tmp.effective_from = in_wrk.effective_from                              
    AND  in_tmp.tmsht_date  BETWEEN in_wrk.effective_from AND in_wrk.effective_to  
    AND  in_wrk.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    GROUP BY in_tmp.employee_code, in_tmp.empin_ou, in_tmp.effective_from  
       ,in_tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
   )tmp1  
 WHERE tmp1.employee_code = tmp.employee_code  
 AND  tmp.assignment_no = tmp1.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
 AND  tmp1.empin_ou  = tmp.emp_ou  
 AND  tmp.pror_type  = 'AWH' --Actual working hours  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
    
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
  
 --If LOP deduction through CTC system parameter is enabled  
 IF @sys_param_lopctc = 'Y'  
 BEGIN  
  IF EXISTS ( SELECT 'X'   
      FROM tmgif_LOP_pay_ded_elt_map WITH (NOLOCK)  
      WHERE master_ou  = @tmgif_ou   
      AND  @pprd_to_date BETWEEN eff_from_date  AND ISNULL(eff_to_date, @pprd_to_date)  
     )  
  BEGIN   
   -- To compute lop salary against CTC pay element  
   EXEC pyprc_LOP_pay_rule_sp  @assn_no,   'CTC',    @empin_ou,   @pay_elt_cd,    
           @payroll_cd,  @payroll_ou_cd,  @payset_cd,   @prcprd_cd,     
           --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0004 <Begin>  
           @process_number, NULL,  NULL    
           --@process_number, @amount OUT,  @std_amount OUT    
           --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0004 <End>  
     
   --Code added by Sharmila J for HRPS-5160 on 18-Jan-2023 <Begin>  
   INSERT INTO pyprc_cmn_ctc_lop_dtl_tmp  
   (  
    master_ou,    payroll_code,   payset_code,   process_period,  
    lop_process_number,  employee_code,   assignment_no,   tran_date,  
    lop_input,    leave_unit_in_days,  leave_unit_in_hour,  tna_unit_in_days,  
    tna_unit_in_hour,  pay_element_code,  ded_pay_elt_code,  ded_pay_elt_value,  
    full_month_lop,   payroll_type,   payable_payroll_cd,  payable_payset_cd,  
    payable_pprd_code,  process_number,   lop_type_flag  
   )  
   SELECT  
    master_ou,    payroll_code,   payset_code,   process_period,  
    process_number,   employee_code,   assignment_no,   tran_date,  
    lop_input,    leave_unit_in_days,  leave_unit_in_hour,  tna_unit_in_days,  
    tna_unit_in_hour,  pay_element_code,  ded_pay_elt_code,  ded_pay_elt_value,  
    full_month_lop,   payroll_type,   payable_payroll_cd,  payable_payset_cd,  
    payable_pprd_code,  @process_number,  lop_type_flag  
   FROM pyprc_employee_LOP_details WITH (NOLOCK)  
   WHERE master_ou   = @payroll_ou_cd  
   AND  payroll_code  = @payroll_cd   
   AND  payset_code   = @payset_cd   
   AND  process_period  = @prcprd_cd    
   AND  pay_element_code = @pay_elt_cd  
   AND  lop_input   IN ('L','T','S')  
   --Code added by Sharmila J for HRPS-5160 on 18-Jan-2023 <End>  
  
   UPDATE emp            
   SET  emp.lop_days   = x.lop_days,  
     emp.lop_hours   = x.lop_hours,  
     emp.lop_days_amount  = x.ded_pay_elt_value,  
     emp.lop_hours_amount = x.ded_pay_elt_value  
   FROM pyprc_cmn_ctc_rule_wrk_tmp  emp --WITH (NOLOCK)        
   INNER JOIN    
     ( SELECT ltmp.master_ou,  
        ltmp.employee_code,   
        etmp.effective_from,  
        /*  
        --15-Jul-2021 SGIH-146 <Begin>  
        SUM(ISNULL((CASE WHEN lop_input IN ('T','S') THEN tna_unit_in_days ELSE leave_unit_in_days END),0.00))AS lop_days,  
        SUM(ISNULL((CASE WHEN lop_input IN ('T','S') THEN tna_unit_in_hour ELSE leave_unit_in_hour END),0.00))AS lop_hours,  
        --SUM(ISNULL(leave_unit_in_days,0.00))AS lop_days,  
        --SUM(ISNULL(leave_unit_in_hour,0.00))AS lop_hours,  
        --15-Jul-2021 SGIH-146 <End> */ --code commented n added by hari for CSBI-61 <Begin>  
  
        SUM(ISNULL( CASE WHEN lop_type_flag='LV' THEN leave_unit_in_days  
                                             WHEN lop_type_flag IN ('TA','SPOC') THEN tna_unit_in_days  
                                        END,0.00)) AS lop_days,  
                                SUM(ISNULL( CASE WHEN lop_type_flag='LV' THEN leave_unit_in_hour  
                                             WHEN lop_type_flag IN ('TA','SPOC') THEN tna_unit_in_hour  
                                        END,0.00)) AS lop_hours, --Code added by hari for CSBI-61 <End>  
        SUM(ISNULL(ded_pay_elt_value,0.00)) AS ded_pay_elt_value  
        ,etmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
      --Code added and commented by Sharmila J for HRPS-5160 on 18-Jan-2023<Begin>  
      FROM pyprc_cmn_ctc_lop_dtl_tmp ltmp WITH (NOLOCK) ,  
        pyprc_cmn_ctc_rule_wrk_tmp     etmp WITH (NOLOCK)   
      --FROM pyprc_employee_LOP_details ltmp,  
      --  pyprc_cmn_ctc_rule_wrk_tmp     etmp   
      --Code added and commented by Sharmila J for HRPS-5160 on 18-Jan-2023<End>  
      WHERE ltmp.master_ou   = @payroll_ou_cd  
      AND  ltmp.payroll_code  = @payroll_cd   
      AND  ltmp.payset_code  = @payset_cd   
      AND  ltmp.process_period  = @prcprd_cd    
     -- AND  ltmp.process_number  = @process_number--Code commented by Sharmila J on 22-May-2022 for HRPS-3606  
     -- AND  ltmp.ded_pay_elt_code = @pay_elt_cd  
      AND  ltmp.pay_element_code = @pay_elt_cd  
      AND  ltmp.lop_input   IN ('L','T','S')  
      AND  etmp.master_ou   = ltmp.master_ou  
      AND  etmp.employee_code  = ltmp.employee_code  
      AND  ltmp.assignment_no  = etmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
      AND  ltmp.tran_date   BETWEEN etmp.effective_from AND etmp.effective_to  
      AND  etmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
      AND  ltmp.process_number = @process_number--Code added by Sharmila J for HRPS-5160 18-Jan-2023  
      --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837 <Begin>  
      GROUP BY ltmp.master_ou, ltmp.employee_code,etmp.effective_from,  
        etmp.assignment_no  
      ) x    
      --GROUP BY ltmp.master_ou, ltmp.employee_code,etmp.effective_from) x    
      --Code added and commented by Sharmila J on 05-Feb-2021 for HRP-837 <End>  
   ON  emp.employee_code  = x.employee_code  
   AND  emp.assignment_no  = x.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   AND  emp.master_ou   = x.master_ou    
   AND  emp.effective_from  = x.effective_from  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0037 <Begin>  
   WHERE emp.process_number  = @process_number  
   --AND  emp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0037 <ENd>  
  
   --Code added and commented by Sharmila J for HRPS-5160 on 04-JAN-2023 <Begin>  
   UPDATE emp            
   SET  emp.full_month_lop   = ISNULL(x.full_month_lop,'N')  
   FROM pyprc_cmn_ctc_rule_wrk_tmp  emp WITH (NOLOCK)        
   INNER JOIN    
     ( SELECT master_ou,  
        employee_code,   
        full_month_lop  
        ,assignment_no  
        ,MIN(tran_date) 'tran_date'   
      FROM pyprc_cmn_ctc_lop_dtl_tmp WITH(NOLOCK)  
      WHERE master_ou   = @payroll_ou_cd  
      AND  payroll_code  = @payroll_cd   
      AND  payset_code   = @payset_cd   
      AND  process_period  = @prcprd_cd    
      AND  lop_process_number = @process_number  
      AND  pay_element_code = @pay_elt_cd  
      AND  ded_pay_elt_code = 'CTC'   
      AND  lop_input   IN ('L','T','S')  
      AND  process_number  = @process_number  
      group by master_ou, employee_code, full_month_lop, assignment_no  
     ) x    
   ON  emp.employee_code  = x.employee_code  
   AND  emp.assignment_no  = x.assignment_no   
   AND  emp.master_ou   = x.master_ou   
   WHERE emp.process_number  = @process_number  
  
   UPDATE emp            
   SET  emp.full_month_lop   = lop.full_month_lop  
   FROM pyprc_cmn_ctc_rule_wrk_tmp  emp       
   JOIN   
     pyprc_cmn_ctc_lop_dtl_tmp lop WITH(NOLOCK)  
   ON  emp.employee_code  = lop.employee_code  
   AND  emp.assignment_no  = lop.assignment_no  
   AND  emp.master_ou   = lop.master_ou   
   WHERE lop.master_ou   = @payroll_ou_cd  
   AND  lop.payroll_code  = @payroll_cd   
   AND  lop.payset_code   = @payset_cd   
   AND  lop.process_period  = @prcprd_cd    
   AND  lop.pay_element_code = @pay_elt_cd  
   AND  lop.ded_pay_elt_code = 'CTC'   
   AND  lop.lop_input   IN ('L','T','S')  
   AND  emp.process_number  = @process_number  
   AND  emp.full_month_lop  IS NULL   
   AND  lop.process_number  = @process_number  
   AND  ISNULL(lop.payable_pprd_code,lop.process_period) = ( SELECT MAX(ISNULL(dtl.payable_pprd_code,dtl.process_period))   
                   FROM pyprc_cmn_ctc_lop_dtl_tmp dtl WITH(NOLOCK)  
                   WHERE dtl.master_ou   = @payroll_ou_cd  
                   AND  dtl.payroll_code  = @payroll_cd   
                   AND  dtl.payset_code   = @payset_cd   
                   AND  dtl.process_period  = @prcprd_cd    
                   AND  dtl.pay_element_code = @pay_elt_cd  
                   AND  dtl.ded_pay_elt_code = 'CTC'   
                   AND  dtl.lop_input   IN ('L','T','S')  
                   AND  dtl.process_number  = @process_number  
                   AND  dtl.master_ou   = lop.master_ou    
                   AND  dtl.employee_code   = lop.employee_code    
                   AND  dtl.assignment_no  = lop.assignment_no   
                   AND  dtl.payroll_code  = lop.payroll_code   
                   AND  dtl.payset_code   = lop.payset_code    
                   AND  dtl.process_period  = lop.process_period   
                   AND  dtl.pay_element_code = lop.pay_element_code  
                  )  
   /*  
   UPDATE emp            
   SET  emp.full_month_lop   = x.full_month_lop  
   FROM pyprc_cmn_ctc_rule_wrk_tmp  emp --WITH (NOLOCK)        
   INNER JOIN    
     ( SELECT DISTINCT  
        master_ou,  
        employee_code,   
        full_month_lop  
        ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
      FROM pyprc_employee_LOP_details WITH(NOLOCK)  
      WHERE master_ou   = @payroll_ou_cd  
      AND  payroll_code  = @payroll_cd   
      AND  payset_code   = @payset_cd   
      AND  process_period  = @prcprd_cd    
      AND  process_number  = @process_number  
     -- AND  ded_pay_elt_code = @pay_elt_cd  
      AND  pay_element_code = @pay_elt_cd  
      AND  ded_pay_elt_code = 'CTC'   
      AND  lop_input   IN ('L','T','S')  
     ) x    
   ON  emp.employee_code  = x.employee_code  
   AND  emp.assignment_no  = x.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   AND  emp.master_ou   = x.master_ou   
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0037 <Begin>  
   WHERE emp.process_number  = @process_number  
   --AND  emp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   */  
   --Code added and commented by Sharmila J for HRPS-5160 on 04-JAN-2023 <End>  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0037 <End>  
  END  
 END  
 ELSE  
 BEGIN  
  --Computing lop for the employees for the given process period  
  -- code added and commented by senthil arasu b on 17-Oct-2018 for defect id HC-2634 <starts>  
  UPDATE tmp  
  SET  lop_days   = units_days,  
    lop_days_amount  = units_days_amount , --units_hrs_amount,--Code changed by Sharmila J on 25-Oct-2018 for the defect id HC-2667  
    lop_hours   = CASE WHEN pror_type IN ('WH', 'AWH')/*= 'WH'*/THEN units_hrs ELSE NULL END,  
    lop_hours_amount = CASE WHEN pror_type IN ('WH', 'AWH')/*= 'WH'*/THEN units_hrs_amount ELSE NULL END  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
    (  
    SELECT SUM(request_unit_in_days) units_days,  
      --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <Begin>  
      SUM(request_unit_in_hour) units_hrs,  
      --SUM(week_tot_hrs*request_unit_in_days) units_hrs,  
      --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <End>  
      SUM((temp.per_day_sal / 100.00) * (100 - ISNULL(lv.pay_percen_cd, 0.00)) * ISNULL(dtl.request_unit_in_days,0.00)) units_days_amount,  
      --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <Begin>  
      SUM((temp.per_hr_sal  / 100.00) * (100 - ISNULL(lv.pay_percen_cd, 0.00)) * (ISNULL(dtl.request_unit_in_hour,0.00))) units_hrs_amount,  
      --SUM((temp.per_hr_sal  / 100.00) * (100 - ISNULL(lv.pay_percen_cd, 0.00)) * (ISNULL(tmp.week_tot_hrs,0.00) * ISNULL(dtl.request_unit_in_days,0.00))) units_hrs_amount,  
      --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <End>  
      temp.employee_code ,temp.effective_from  
      ,temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837  
    FROM ladm_leave_breakup_dtl dtl WITH (NOLOCK),  
      ldef_leave_type   lv WITH (NOLOCK),  
      pyprc_cmn_rule_leave_exclude cmn WITH (NOLOCK),  
      --pyprc_cmn_ctc_rule_gre_cal_tmp tmp,--Code commented by Sharmila J on 25-Feb-2021 for HRP-2269  
      pyprc_cmn_ctc_rule_wrk_tmp  temp  
    Where cmn.master_ou  = @empin_ou  
    AND  dtl.empng_ou_code = @empng_ou  
    AND  pay_element_code = @pay_elt_cd  
    AND  dtl.leave_type_code = cmn.leave_type_code  
    --Code commented by Sharmila J on 25-Feb-2021 for HRP-2269 <Begin>  
    --AND  tmp.emp_code  = dtl.employee_code  
    --AND  tmp.emp_code  = temp.employee_code  
    --Code commented by Sharmila J on 25-Feb-2021 for  HRP-2269 <End>  
    AND  dtl.employee_code = temp.employee_code  
    AND  temp.assignment_no = dtl.asgn_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <Begin>  
    AND  temp.emp_ou   = @empin_ou  
    --AND  temp.emp_ou   = tmp.emp_ou  
    --AND  tmp.schedule_date = dtl.a_leave_date  
    --Code added and commented by Sharmila J on 25-Feb-2021 for HRP-2269 <End>  
    AND  dtl.a_leave_date between temp.effective_from and temp.effective_to  
    --Code commented by Sharmila J on 25-Feb-2021 for HRP-2269 <Begin>  
    --AND  dtl.a_leave_date between tmp.effective_from and tmp.effective_to  
    --AND  tmp.schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    --Code commented by Sharmila J on 25-Feb-2021 for HRP-2269 <End>  
    AND  dtl.a_leave_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    AND  dtl.leave_appln_status='AUTH'  
    AND  cmn.Cons_Salary_Proration = 'Y' -- code added by senthil arasu b on 13-Aug-2018 to consider the leave types for lop_days which are marked for Salary Proration.  
    AND  lv.master_ou_code = @lvdef_ou  
    AND  lv.leave_type_code = dtl.leave_type_code  
    AND  dtl.a_leave_date BETWEEN lv.effective_from_date AND ISNULL(lv.effective_to_date, dtl.a_leave_date)  
    AND  temp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    group by temp.employee_code,temp.effective_from  
       ,temp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    )a  
  Where tmp.employee_code = a.employee_code  
  AND  tmp.assignment_no = a.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
  And  tmp.effective_from = a.effective_from  
  AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
  -- Code added by Sharmila J for HRP-5723 on 25-Nov-2021  <Begin>  
  --To Update the lop amount as NULL if the LOP accumulator payelement is configured and also getting the processed value.  
  UPDATE tmp1  
  SET  tmp1.lop_days   = NULL,  
    tmp1.lop_days_amount = NULL,   
    tmp1.lop_hours   = NULL,  
    tmp1.lop_hours_amount = NULL  
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp1  
  JOIN ( SELECT tmp.emp_ou,  
       tmp.employee_code,  
       tmp.assignment_no,  
       SUM(  
       CASE WHEN accm.relational_operator_qc = 'A'   
         THEN (ISNULL(ptmp.pay_element_value, 0)  * (accm.percent_of_elt / 100.00))   
         WHEN accm.relational_operator_qc = 'S'  
         THEN (ISNULL(ptmp.pay_element_value, 0) * (-1) * (accm.percent_of_elt / 100.00))   
       END) 'lop_amount'  
    FROM pyprc_cmn_ctc_rule_wrk_tmp  tmp WITH (NOLOCK)  
    JOIN hrpyprc_emp_pyrol_pe_tmp  ptmp WITH (NOLOCK)  
    ON  ptmp.master_ou    = tmp.master_ou  
    AND  ptmp.process_number   = tmp.process_number  
    AND  ptmp.payroll_code   = @payroll_cd  
    AND  ptmp.process_period_code = @prcprd_cd  
    AND  ptmp.payset_code   = @payset_cd  
    AND  ptmp.employee_code   = tmp.employee_code  
    JOIN pyprc_cmn_rule_leave_exclude lvex WITH (NOLOCK)  
    ON  lvex.master_ou    = tmp.master_ou   
    JOIN hrpyelt_accm_elt_dtl   accm WITH (NOLOCK)  
    ON  accm.accm_cd_qc    = lvex.lop_amt_accm_cd  
    AND  accm.pay_element_code  = ptmp.pay_element_code   
    WHERE tmp.master_ou    = @payroll_ou_cd  
    AND  tmp.process_number   = @process_number   
    AND  lvex.master_ou    = @payroll_ou_cd  
    AND  lvex.pay_element_code  = @pay_elt_cd  
    AND  accm.master_ou    = @payroll_ou_cd  
    AND  ptmp.master_ou    = @payroll_ou_cd  
    AND  ptmp.process_number   = @process_number   
    AND  ptmp.pay_element_value  <> 0  
    GROUP BY tmp.emp_ou,tmp.employee_code,tmp.assignment_no  
    ) tmp2  
  ON  tmp2.emp_ou     = tmp1.emp_ou  
  AND  tmp2.employee_code   = tmp1.employee_code  
  AND  tmp2.assignment_no   = tmp1.assignment_no  
  WHERE tmp1.master_ou    = @payroll_ou_cd  
  AND  tmp1.process_number   = @process_number   
  AND  ISNULL(tmp2.lop_amount,0.0) <> 0.00  
    
  --To Update lop amount with the configured accumulator payelement value  
  UPDATE tmp1  
  SET  tmp1.lop_days_amount = CASE WHEN pror_type IN ('WH', 'AWH') THEN NULL ELSE ISNULL(tmp2.lop_amount,0.0) END,  
    tmp1.lop_hours_amount = CASE WHEN pror_type IN ('WH', 'AWH') THEN ISNULL(tmp2.lop_amount,0.0) ELSE NULL END   
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp1  
  JOIN ( SELECT tmp.emp_ou,  
       tmp.employee_code,  
       tmp.assignment_no,  
       tmp.effective_from,  
       tmp.row_num,  
       SUM(  
       CASE WHEN accm.relational_operator_qc = 'A'   
         THEN (ISNULL(ptmp.pay_element_value, 0)  * (accm.percent_of_elt / 100.00))   
         WHEN accm.relational_operator_qc = 'S'  
         THEN (ISNULL(ptmp.pay_element_value, 0) * (-1) * (accm.percent_of_elt / 100.00))   
       END) 'lop_amount'  
    FROM pyprc_cmn_ctc_rule_wrk_tmp  tmp WITH (NOLOCK)  
    JOIN hrpyprc_emp_pyrol_pe_tmp  ptmp WITH (NOLOCK)  
    ON  ptmp.master_ou    = tmp.master_ou  
    AND  ptmp.process_number   = tmp.process_number  
    AND  ptmp.payroll_code   = @payroll_cd  
    AND  ptmp.process_period_code = @prcprd_cd  
    AND  ptmp.payset_code   = @payset_cd  
    AND  ptmp.employee_code   = tmp.employee_code  
    JOIN pyprc_cmn_rule_leave_exclude lvex WITH (NOLOCK)  
    ON  lvex.master_ou    = tmp.master_ou   
    JOIN hrpyelt_accm_elt_dtl   accm WITH (NOLOCK)  
    ON  accm.accm_cd_qc    = lvex.lop_amt_accm_cd  
    AND  accm.pay_element_code  =   ptmp.pay_element_code   
    WHERE tmp.master_ou    = @payroll_ou_cd  
    AND  tmp.process_number   = @process_number   
    AND  lvex.master_ou    = @payroll_ou_cd  
    AND  lvex.pay_element_code  = @pay_elt_cd  
    AND  accm.master_ou    = @payroll_ou_cd  
    AND  ptmp.master_ou    = @payroll_ou_cd  
    AND  ptmp.process_number   = @process_number   
    AND  ptmp.pay_element_value  <> 0  
    AND  tmp.row_num     = ( SELECT MAX(row_num)  
              FROM pyprc_cmn_ctc_rule_wrk_tmp itmp WITH (NOLOCK)  
              WHERE itmp.master_ou   = @payroll_ou_cd  
              AND  itmp.process_number   = @process_number   
              AND  itmp.employee_code   = tmp.employee_code  
              AND  itmp.assignment_no   = tmp.assignment_no  
               )  
    GROUP BY tmp.emp_ou, tmp.employee_code,tmp.assignment_no,tmp.effective_from,tmp.row_num  
    ) tmp2  
  ON  tmp2.emp_ou     = tmp1.emp_ou  
  AND  tmp2.employee_code   = tmp1.employee_code  
  AND  tmp2.assignment_no   = tmp1.assignment_no  
  AND  tmp2.effective_from   = tmp1.effective_from  
  AND  tmp2.row_num    = tmp1.row_num  
  WHERE tmp1.master_ou    = @payroll_ou_cd  
  AND  tmp1.process_number   = @process_number   
    
  --Update lop days & hours if the accumulator payelement configured under Unit for computation rule type.  
  UPDATE tmp1  
  SET  tmp1.lop_days  = CASE WHEN pror_type IN ('WH', 'AWH') THEN NULL ELSE ISNULL(tmp2.lop_units,0.0) END,  
    tmp1.lop_hours  = CASE WHEN pror_type IN ('WH', 'AWH') THEN ISNULL(tmp2.lop_units,0.0) ELSE NULL END   
  FROM pyprc_cmn_ctc_rule_wrk_tmp tmp1  
  JOIN ( SELECT tmp.emp_ou,  
       tmp.employee_code,  
       tmp.assignment_no,  
       tmp.effective_from,  
       tmp.row_num,  
       SUM(  
       CASE WHEN accm.relational_operator_qc = 'A'   
         THEN (ISNULL(ptmp.pay_element_value, 0)  * (accm.percent_of_elt / 100.00))   
         WHEN accm.relational_operator_qc = 'S'  
         THEN (ISNULL(ptmp.pay_element_value, 0) * (-1) * (accm.percent_of_elt / 100.00))   
       END) 'lop_units'  
    
    FROM pyprc_cmn_ctc_rule_wrk_tmp  tmp WITH (NOLOCK)  
    JOIN hrpyprc_emp_pyrol_pe_tmp  ptmp WITH (NOLOCK)  
    ON  ptmp.master_ou    = tmp.master_ou  
    AND  ptmp.process_number   = tmp.process_number  
    AND  ptmp.payroll_code   = @payroll_cd  
    AND  ptmp.process_period_code = @prcprd_cd  
    AND  ptmp.payset_code   = @payset_cd  
    AND  ptmp.employee_code   = tmp.employee_code  
    JOIN pyprc_cmn_rule_leave_exclude lvex WITH (NOLOCK)  
    ON  lvex.master_ou    = tmp.master_ou   
    JOIN hrpyelt_accm_elt_dtl    accm WITH (NOLOCK)  
    ON  accm.accm_cd_qc    = lvex.lop_amt_accm_cd  
    JOIN pyprc_cmn_rule_config_hdr  hdr WITH (NOLOCK)  
    ON  hdr.configured_pyelt_code = accm.pay_element_code--LOP amt pay element  
    AND  hdr.pay_element_code  = ptmp.pay_element_code --Unit for computation element  
    AND     hdr.rule_type    = 'UFC'  
    AND     hdr.status     = 'C'  
    WHERE tmp.master_ou    = @payroll_ou_cd  
    AND  tmp.process_number   = @process_number   
    AND  lvex.master_ou    = @payroll_ou_cd  
    AND  lvex.pay_element_code  = @pay_elt_cd  
    AND  accm.master_ou    = @payroll_ou_cd  
    AND  ptmp.master_ou    = @payroll_ou_cd  
    AND  ptmp.process_number   = @process_number   
    AND  ptmp.pay_element_value  <> 0  
    AND  hdr.master_ou    = @payroll_ou_cd    
    AND     @pprd_to_date BETWEEN hdr.effective_from AND ISNULL(hdr.effective_to, @pprd_to_date)  
    AND  tmp.row_num  = ( SELECT MAX(row_num)  
             FROM pyprc_cmn_ctc_rule_wrk_tmp itmp WITH (NOLOCK)  
             WHERE itmp.master_ou    = @payroll_ou_cd  
             AND  itmp.process_number   = @process_number   
             AND  itmp.employee_code   = tmp.employee_code  
             AND  itmp.assignment_no   = tmp.assignment_no  
              )  
    GROUP BY tmp.emp_ou, tmp.employee_code,tmp.assignment_no,tmp.effective_from,tmp.row_num  
    ) tmp2  
  ON  tmp2.emp_ou   = tmp1.emp_ou  
  AND  tmp2.employee_code   = tmp1.employee_code  
  AND  tmp2.assignment_no   = tmp1.assignment_no  
  AND  tmp2.effective_from   = tmp1.effective_from  
  AND  tmp2.row_num    = tmp1.row_num  
  WHERE tmp1.master_ou    = @payroll_ou_cd  
  AND  tmp1.process_number   = @process_number   
  -- Code added by Sharmila J for HRP-5723 on 25-Nov-2021  <End>  
  
  /*  
  UPDATE tmp  
  SET  lop_days     = units_days,  
    lop_hours     = CASE WHEN pror_type = 'WH' THEN units_hrs ELSE NULL END  
  FROM pyprc_cmn_ctc_rule_wrk_tmp      tmp,  
    (  
    SELECT sum(request_unit_in_days) units_days,sum(week_tot_hrs*request_unit_in_days) units_hrs,temp.employee_code ,temp.effective_from  
    FROM ladm_leave_breakup_dtl dtl WITH (NOLOCK),  
      pyprc_cmn_rule_leave_exclude cmn WITH (NOLOCK),  
      pyprc_cmn_ctc_rule_gre_cal_tmp tmp,  
      pyprc_cmn_ctc_rule_wrk_tmp  temp  
    Where cmn.master_ou  = @empin_ou  
    AND  dtl.empng_ou_code = @empng_ou  
    AND  pay_element_code = @pay_elt_cd  
    AND  dtl.leave_type_code = cmn.leave_type_code  
    AND  tmp.emp_code  = dtl.employee_code  
    AND  tmp.emp_code  = temp.employee_code  
    AND  dtl.employee_code = temp.employee_code  
    AND  temp.emp_ou   = tmp.emp_ou  
    AND  tmp.schedule_date = dtl.a_leave_date  
    AND  dtl.a_leave_date between temp.effective_from and temp.effective_to  
    AND  dtl.a_leave_date between tmp.effective_from and tmp.effective_to  
    AND  tmp.schedule_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    AND  dtl.a_leave_date BETWEEN @pprd_FROM_date AND @pprd_to_date  
    AND  dtl.leave_appln_status='AUTH'  
    AND  cmn.Cons_Salary_Proration = 'Y' -- code added by senthil arasu b on 13-Aug-2018 to consider the leave types for lop_days which are marked for Salary Proration.  
    group by temp.employee_code,temp.effective_from  
    )a  
  Where tmp.employee_code = a.employee_code  
  And  tmp.effective_from = a.effective_from  
  */  
  -- code added and commented by senthil arasu b on 17-Oct-2018 for defect id HC-2634 <ends>  
 END  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
  
 -- Code added by Sharmila J on 02-Aug-2022 for HRP-8576 <Begin>  
 UPDATE emp            
 SET  emp.no_of_holidays  = x.holy_days,  
   emp.tot_holiday_hrs  = x.holy_hours,  
   emp.holy_amount   = x.holy_amount  
 FROM pyprc_cmn_ctc_rule_wrk_tmp  emp   
 INNER JOIN    
   ( SELECT ltmp.master_ou,  
      ltmp.employee_code,   
      etmp.effective_from,  
      etmp.assignment_no,  
      SUM(ISNULL(tna_unit_in_days,0.00)) AS holy_days,  
      SUM(ISNULL(tna_unit_in_hour,0.00)) AS holy_hours,  
      SUM(ISNULL(ded_pay_elt_value,0.00)) AS holy_amount  
    FROM pyprc_employee_LOP_details  ltmp  WITH (NOLOCK)  
    JOIN pyprc_cmn_ctc_rule_wrk_tmp  etmp  WITH (NOLOCK)  
    ON  etmp.master_ou   = ltmp.master_ou  
    AND  etmp.employee_code  = ltmp.employee_code  
    AND  etmp.assignment_no  = ltmp.assignment_no  
    WHERE ltmp.master_ou   = @payroll_ou_cd  
    AND  ltmp.payroll_code  = @payroll_cd   
    AND  ltmp.payset_code  = @payset_cd   
    AND  ltmp.process_period  = @prcprd_cd    
    AND  ltmp.pay_element_code = @pay_elt_cd  
    AND  ltmp.lop_input   <> 'D'  
    AND  ltmp.lop_type_code   IN ('HLHR', 'HOLY')  
    AND  etmp.process_number  = @process_number  
    AND  ltmp.tran_date   BETWEEN etmp.effective_from AND etmp.effective_to  
    GROUP BY ltmp.master_ou, ltmp.employee_code,etmp.effective_from,etmp.assignment_no  
    ) x    
 ON  emp.master_ou   = x.master_ou    
 AND  emp.assignment_no  = x.assignment_no   
 AND  emp.employee_code  = x.employee_code   
 AND  emp.effective_from  = x.effective_from  
 WHERE emp.process_number  = @process_number  
 -- Code added by Sharmila J on 02-Aug-2022 for HRP-8576 <End>  
  
 -- Code added by senthil arasu b on 20-Oct-2020 for defect id TIUH-122 <Begin>  
 EXEC pyprc_cmn_pay_rule_proration_hook_sp @rule_type   ,   
             @pay_elt_cd   ,  
             @payroll_ou_cd  ,   
             @payroll_cd   ,   
             @paySET_cd   ,     
             @prcprd_cd   ,   
             @process_number  ,   
             @pprd_FROM_date  ,  
             @pprd_to_date  ,  
             @progressive_flag ,  
             'LOP' --to overwrite the LOP  Days/Hours & amount  
 -- Code added by senthil arasu b on 20-Oct-2020 for defect id TIUH-122 <End>  
  
 --Computing Monthly Salary for the non-mid month separator employees with lop for the given process period  
 UPDATE tmp  
 --Code added and commented by Sharmila J for the defect id HST-7014 <Begin>  
 --Code added and commented by Sharmila J on 18-May-2020 for HRP-9 <Begin>  
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
 SET  mon_sal = (CASE WHEN pror_type in ('CD','WD','FD','AWD','FCD') THEN ((paid_wrking_days * per_day_sal))  
 --SET  mon_sal = (CASE WHEN pror_type in ('CD','WD','FD','AWD') THEN ((paid_wrking_days * per_day_sal))  
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
       WHEN pror_type IN ('WH','AWH') THEN ((sch_hrs * per_hr_sal)) END)  
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD','AWD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days_amount,0.00)))  
 --          WHEN pror_type IN ('WH','AWH') THEN ((sch_hrs * per_hr_sal)-isnull(lop_hours_amount,0)) END)  
 --Code added and commented by Sharmila J on 18-May-2020 for HRP-9 <End>  
 --Code added and commented by Senthil Arasu B on 17-Oct-2018 for the defect id HC-2634 <Begin>   
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days_amount,0.00)))  
 --          WHEN pror_type = 'WH' THEN ((sch_hrs * per_hr_sal)-isnull(lop_hours_amount,0)) END)  
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days,0)*per_day_sal))  
 --          WHEN pror_type = 'WH' THEN ((sch_hrs * per_hr_sal)-(isnull(lop_hours,0))*per_hr_sal) END)  
 --Code added and commented by Senthil Arasu B on 17-Oct-2018 for the defect id HC-2634 <End>   
 --Code added and commented by Sharmila J for the defect id HST-7014 <End>  
 From pyprc_cmn_ctc_rule_wrk_tmp tmp  
 WHERE separation_flag   = 'N'  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Computing Monthly Salary for the mid month separator employees with lop for the given process period  
 UPDATE tmp  
 --Code added and commented by Sharmila J for the defect id HST-7014 <Begin>  
 --Code added and commented by Sharmila J on 18-May-2020 for HRP-9 <Begin>  
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
 SET  mon_sal = (CASE WHEN pror_type in ('CD','WD','FD','AWD','FCD') THEN ((paid_wrking_days * per_day_sal))  
 --SET  mon_sal = (CASE WHEN pror_type in ('CD','WD','FD','AWD') THEN ((paid_wrking_days * per_day_sal))  
 --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
       WHEN pror_type IN ('WH','AWH') THEN ((sch_hrs * per_hr_sal)) END)  
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD','AWD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days_amount,0.00)))  
 --          WHEN pror_type IN ('WH','AWH') THEN ((sch_hrs * per_hr_sal)-isnull(lop_hours_amount,0)) END)  
 --Code added and commented by Sharmila J on 18-May-2020 for HRP-9 <End>  
 --Code added and commented by Senthil Arasu B on 17-Oct-2018 for the defect id HC-2634 <Begin>   
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days_amount,0.00)))  
 --          WHEN pror_type = 'WH' THEN ((sch_hrs * per_hr_sal)-isnull(lop_hours_amount,0)) END)  
 --SET  mon_sal     = (CASE WHEN pror_type in ('CD','WD','FD') THEN ((paid_wrking_days * per_day_sal)-(isnull(lop_days,0)*per_day_sal))  
 --          WHEN pror_type = 'WH' THEN ((sch_hrs * per_hr_sal)-(isnull(lop_hours,0))*per_hr_sal) END)  
 --Code added and commented by Senthil Arasu B on 17-Oct-2018 for the defect id HC-2634 <End>   
 --Code added and commented by Sharmila J for the defect id HST-7014 <End>  
 From pyprc_cmn_ctc_rule_wrk_tmp tmp  
 WHERE separation_flag     = 'Y'  
 AND  (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' )--Code added by Sharmila J on 11-July-2018 for the defect id HC-2097   
 --AND  convert(date,separation_date) = convert(date,effective_to) --Code commented by Sharmila J for the defect id HC-3141 in 20-Feb-2019   
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    
 UPDATE cmn  
 SET  opted_amount   = tmp.opted_amount  
 FROM pyprc_cmn_rule_emp_process_tmp cmn ,--WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp      tmp WITH (NOLOCK)  
 WHERE cmn.master_ou_code  = @payroll_ou_cd              
 AND  cmn.process_number  = @process_number                          
 AND  cmn.payroll_code  = @payroll_cd                                 
 AND  cmn.paySET_code   = @paySET_cd                      
 AND  cmn.process_period_code = @prcprd_cd    
 AND  cmn.rule_type   = @rule_type  
 AND  cmn.pay_element_code = @pay_elt_cd  
 AND  cmn.employee_code  = tmp.employee_code  
 AND  cmn.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
 AND  cmn.employment_ou  = tmp.emp_ou  
 AND  cmn.master_ou_code  = tmp.master_ou  
 AND  cmn.effective_from  = tmp.effective_from  
-- AND  @pprd_to_date between tmp.effective_from and isnull(tmp.effective_to,@pprd_to_date)--Code commented by Sharmila J on 27-July-2018 for the defect id HC-2152  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --code added by senthil arasu b on 30-Nov-2018 for the defect id HC-2667 <starts>  
 -- to handle salary proration on salary change, new joinee & termination scenarios when proration type is 'fixed days'  
 UPDATE tmp  
 SET  salary_change_flag = 'Y'  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,    
   (  
   SELECT t.master_ou, t.emp_ou, t.employee_code, COUNT('x') cnt  
     ,t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   FROM  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <Begin>  
   (SELECT DISTINCT master_ou,  
   --(SELECT master_ou,  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <ENd>  
     emp_ou,    
     employee_code  
     ,opted_amount -- code added by senthil arasu b on 12-Nov-2019 for <ticket>  
     ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   FROM pyprc_cmn_ctc_rule_wrk_tmp WITH (NOLOCK)  
   WHERE process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   --Code commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <Begin>  
   --GROUP BY master_ou, emp_ou,  employee_code  
   --  ,opted_amount -- code added by senthil arasu b on 12-Nov-2019 for <ticket>  
   --  ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   --Code commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <End>  
   ) t  
   GROUP BY t.master_ou, emp_ou, employee_code  
     ,t.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
   HAVING COUNT('x') > 1  
   ) tmp1  
 WHERE tmp.master_ou  = tmp1.master_ou   
 AND  tmp.emp_ou   = tmp1.emp_ou    
 AND  tmp.employee_code = tmp1.employee_code  
 AND  tmp.assignment_no = tmp1.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
 AND  tmp.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
 --code added by senthil arasu b on 30-Nov-2018 for the defect id HC-2667 <ends>  
  
 -- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121 <Begin>  
 --To update standard pay element value flag based on sum of opted amount or latest opted amount  
 UPDATE tmp  
 SET  tmp.std_amt_flag = 'S'  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   ( SELECT tmp1.master_ou,  
      tmp1.emp_ou,    
      tmp1.employee_code,  
      tmp1.opted_amount   
      ,tmp1.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    FROM pyprc_cmn_ctc_rule_wrk_tmp tmp1 WITH (NOLOCK),  
      ( SELECT master_ou,  
         emp_ou,    
         employee_code,  
         MAX(effective_to)'max_effective_to'  
         ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
       FROM pyprc_cmn_ctc_rule_wrk_tmp WITH (NOLOCK)  
       WHERE salary_change_flag = 'Y'  
       AND  process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
       GROUP BY master_ou, emp_ou,  employee_code  
         ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
      ) tmp2  
    WHERE tmp1.master_ou  = tmp2.master_ou   
    AND  tmp1.emp_ou   = tmp2.emp_ou    
    AND  tmp1.employee_code = tmp2.employee_code  
    AND  tmp1.effective_to  = tmp2.max_effective_to   
    AND  tmp1.assignment_no = tmp2.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    AND  tmp1.process_number = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   )tmp3  
 WHERE tmp.master_ou   = tmp3.master_ou   
 AND  tmp.emp_ou    = tmp3.emp_ou    
 AND  tmp.employee_code  = tmp3.employee_code  
 AND  tmp.assignment_no  = tmp3.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
 --AND  tmp.opted_amount  > tmp3.opted_amount  
 AND  isnull(tmp.opted_amount ,0.0)  > isnull(tmp3.opted_amount , 0.0)  -- code commented and added by HARI for RWH-25 on 07-jul-2023  
 AND  tmp.salary_change_flag = 'Y'  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 UPDATE tmp  
 SET  std_amt_flag = 'S'  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp,  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <Begin>  
   ( SELECT DISTINCT master_ou,  
   --( SELECT master_ou,  
   --Code added and commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <End>  
      emp_ou,    
      employee_code  
      ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    FROM pyprc_cmn_ctc_rule_wrk_tmp WITH (NOLOCK)  
    WHERE std_amt_flag  = 'S'  
    AND  salary_change_flag = 'Y'  
    AND  process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
    --Code commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <Begin>  
    --GROUP BY master_ou, emp_ou,  employee_code  
    --   ,assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
    --Code commented by Sharmila J on 04-Oct-2021 for RULE -SA0033 <End>  
   ) tmp1  
 WHERE tmp.master_ou   = tmp1.master_ou   
 AND  tmp.emp_ou    = tmp1.emp_ou    
 AND  tmp.employee_code  = tmp1.employee_code  
 AND  tmp.assignment_no  = tmp1.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
 AND  tmp.salary_change_flag = 'Y'  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
   
 --HRPS-1824  
 UPDATE tmp  
 SET  tmp.mon_sal = tmp.opted_amount - (tmp.per_day_sal * (@cal_days - tmp.paid_wrking_days))  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp  
 WHERE ( (tmp.separation_flag  = 'Y' AND (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ))  
   OR (tmp.employment_flag  = 'Y' AND (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ))  
   )  
 AND  tmp.pror_type IN ('CD','FCD')  
 AND  tmp.mid_prd_prora_based_on = 'NPD'  
 AND  (( tmp.pror_type = 'FCD'  
   AND tmp.fixed_days <> (@cal_days - tmp.paid_wrking_days)  
   )  
   OR  
   (  
   tmp.pror_type <> 'FCD'  
   ))  
 AND  tmp.process_number  = @process_number  
 --HRPS-1824  
 -- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121 <End>  
  
 --- Code added By Narendra for RPFF-30 on 30 May 2023 <Begin> ---  
 UPDATE tmp   
 SET paid_wrking_days = CASE WHEN ISNULL(paid_wrking_days,0.00) = 0 AND sch_hrs IS NOT NULL   
         THEN ISNULL(sch_hrs,0.00) / NULLIF(std_hrs_per_day,0.00) ELSE ISNULL(paid_wrking_days,0.00) END ,  
  sch_hrs    = CASE WHEN ISNULL(sch_hrs,0.00) = 0 AND paid_wrking_days IS NOT NULL   
         THEN ISNULL(paid_wrking_days,0.00) * ISNULL(std_hrs_per_day,0.00) ELSE ISNULL(sch_hrs,0.00) END,  
  tot_holiday_hrs  = CASE WHEN ISNULL(tot_holiday_hrs,0.00) = 0 AND no_of_holidays IS NOT NULL   
         THEN ISNULL(no_of_holidays,0.00) * ISNULL(std_hrs_per_day,0.00) ELSE ISNULL(tot_holiday_hrs,0.00) END ,  
  no_of_holidays   = CASE WHEN ISNULL(no_of_holidays,0.00) = 0 AND tot_holiday_hrs IS NOT NULL   
         THEN ISNULL(tot_holiday_hrs,0.00)/ NULLIF(std_hrs_per_day,0.00) ELSE ISNULL(no_of_holidays,0.00) END  
 FROM pyprc_cmn_ctc_rule_wrk_tmp tmp  
 WHERE tmp.process_number  = @process_number  
 --- Code added By Narendra for RPFF-30 on 30 May 2023 <End> ---  
  
 --Updating final amount in employee process table  
 UPDATE cmn  
 --Code commented and added by Sharmila J on 11-July-2018 for the defect id HC-2097 <Begin>  
 --SET  final_amount   = mon_sal,  
 -- code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
 --SET  final_amount   = CASE WHEN tmp.pror_type NOT IN ('NA', 'FD')  THEN tmp.mon_sal   
 SET  final_amount   = CASE WHEN tmp.full_month_lop = 'Y' THEN 0.00  
            --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
            WHEN tmp.pror_type NOT IN ('NA', 'FD','FCD')  THEN tmp.mon_sal   
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ) AND tmp.employment_flag = 'Y' AND tmp.pror_type NOT IN ( 'FD' ,'FCD')  
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ) AND tmp.separation_flag = 'Y' AND tmp.pror_type NOT IN ( 'FD' ,'FCD')  
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ) AND (tmp.employment_flag = 'Y' OR tmp.salary_change_flag = 'Y') AND tmp.pror_type IN ( 'FD' ,'FCD')  
             THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ) AND (tmp.separation_flag = 'Y' OR tmp.salary_change_flag = 'Y') AND tmp.pror_type IN ( 'FD' ,'FCD')  
             THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            /*  
            WHEN tmp.pror_type NOT IN ('NA', 'FD')  THEN tmp.mon_sal   
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ) AND tmp.employment_flag = 'Y' AND tmp.pror_type <> 'FD'   
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ) AND tmp.separation_flag = 'Y' AND tmp.pror_type <> 'FD'   
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' ) AND (tmp.employment_flag = 'Y' OR tmp.salary_change_flag = 'Y') AND tmp.pror_type = 'FD'   
             THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' ) AND (tmp.separation_flag = 'Y' OR tmp.salary_change_flag = 'Y') AND tmp.pror_type = 'FD'  
             THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            */  
            --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
            -- code added and commented by senthil arasu b on 15-Mar-2019 for defect id HST-3284 <starts>  
            --Code added and commented by Sharmila J on 13-Aug-2019 for the defect SNPL-358 <Begin>  
            --Code commented by Sharmila J on 18-May-2020 for HRP-9 <Begin>  
            --WHEN tmp.separation_flag = 'N' AND tmp.employment_flag = 'N' AND tmp.salary_change_flag = 'N' AND tmp.pror_type = 'FD'   
            -- THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            --Code commented by Sharmila J on 18-May-2020 for HRP-9 <End>  
            --WHEN tmp.separation_flag = 'N' AND tmp.employment_flag = 'N' AND tmp.salary_change_flag = 'N' AND tmp.pror_type = 'FD' AND (tmp.paid_week_off IS NULL OR tmp.paid_week_off = -1 OR tmp.paid_week_off <> 'BD')  
            -- THEN CASE WHEN tmp.mon_sal > tmp.opted_amount  THEN tmp.opted_amount  ELSE tmp.mon_sal END  
            --WHEN tmp.separation_flag = 'N' AND tmp.employment_flag = 'N' AND tmp.salary_change_flag = 'N' AND tmp.pror_type = 'FD' AND tmp.paid_week_off = 'BD'  
            --    THEN tmp.opted_amount  
            --Code added and commented by Sharmila J on 13-Aug-2019 for the defect SNPL-358 <End>  
            /*  
            WHEN tmp.separation_flag = 'N' AND tmp.employment_flag = 'N' AND tmp.salary_change_flag = 'N' AND tmp.pror_type = 'FD'   
             THEN tmp.opted_amount    
            */  
            -- code added and commented by senthil arasu b on 15-Mar-2019 for defect id HST-3284 <ends>   
            ELSE cmn.opted_amount   
          END,  
/* SET  final_amount   = CASE WHEN tmp.pror_type <> 'NA' THEN tmp.mon_sal   
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )AND tmp.employment_flag = 'Y' AND tmp.pror_type <> 'FD'   
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' )AND tmp.separation_flag = 'Y' AND tmp.pror_type <> 'FD'   
             THEN tmp.mon_sal  
            WHEN (tmp.proration_applicable_for = 'N' OR tmp.proration_applicable_for = 'B' )AND tmp.employment_flag = 'Y' AND tmp.pror_type = 'FD'   
             THEN CASE WHEN tmp.mon_sal > cmn.opted_amount  THEN cmn.opted_amount  ELSE tmp.mon_sal END  
            WHEN (tmp.proration_applicable_for = 'S' OR tmp.proration_applicable_for = 'B' )AND tmp.separation_flag = 'Y' AND tmp.pror_type = 'FD'  
             THEN CASE WHEN tmp.mon_sal > cmn.opted_amount  THEN cmn.opted_amount  ELSE tmp.mon_sal END  
            ELSE cmn.opted_amount   
          END,  
*/  
 --code added and commented by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
 --Code commented and added by Sharmila J on 11-July-2018 for the defect id HC-2097 <End>  
   lop_days    = tmp.lop_days  
   -- code added by senthil arasu b on 03-Apr-2018 for defect id HST-2991 <starts>  
   --code added and commented by Vidya A for the defect id HRP-208 <starts>  
            --,ctc_paid_wrking_days = DATEDIFF(DD,tmp.effective_from,tmp.effective_to)+1 - ISNULL(tmp.LOP_days,0.00)   --Commented for SGIH-137       
            --,ctc_paid_wrking_days = tmp.paid_wrking_days  
            ,ctc_paid_wrking_days = tmp.paid_wrking_days   --Uncommented for SGIH-137        
   -- Commenetd and added By Narendra for RPFF-30 on 30 May 2023 <Begin>----  
            --,paid_days            = tmp.paid_wrking_days  -ISNULL(tmp.LOP_days,0.00) --Added for SGIH-137    
   ,paid_days            = tmp.paid_wrking_days  - (ISNULL(tmp.LOP_days,0.00)+ ISNULL(tmp.no_of_holidays,0.00))   
   -- Commenetd and added By Narendra for RPFF-30 on 30 May 2023 <End>----  
   --code added and commented by Vidya A for the defect id HRP-208 <ends>  
   ,ctc_per_day_salary  = tmp.per_day_sal   
   ,ctc_per_hour_salary = tmp.per_hr_sal  
   ,ctc_sch_hrs   = tmp.sch_hrs  
   ,ctc_cal_days   = @cal_days  
   ,ctc_exchange_type  = tmp.ctc_exchange_type  
   ,ctc_exchange_date  = tmp.ctc_exchange_date  
   ,ctc_exchange_rate  = tmp.ctc_exchange_rate  
   -- code added by senthil arasu b on 03-Apr-2018 for defect id HST-2991 <ends>  
   -- code added by Keerthana S on 01-Aug-2019 for defect id HST-6829 <starts>  
   ,lop_hours    = tmp.lop_hours    
      --,Paid_hrs    =   (case when tmp.sch_hrs-isnull(  tmp.lop_hours,0)<0 then 0 else tmp.sch_hrs-isnull(  tmp.lop_hours,0) end)       
   -- Commenetd and added By Narendra for RPFF-30 on 30 May 2023 <Begin>----  
   --,Paid_hrs    =   tmp.sch_hrs- isnull( tmp.lop_hours,0)  --code modified for the ticket id ORH-2148  
   ,Paid_hrs    =   tmp.sch_hrs- (isnull( tmp.lop_hours,0)+ISNULL(tmp.tot_holiday_hrs,0.00))  
   -- Commenetd and added By Narendra for RPFF-30 on 30 May 2023 <End>----  
   -- code added by Keerthana S on 01-Aug-2019 for defect id HST-6829 <ends>  
   --Code added by Sharmila J for the defect id HST-7014 <Begin>  
   ,std_hrs_per_day  = tmp.std_hrs_per_day,  
   ctc_frequency   = tmp.ctc_frequency  
   --Code added by Sharmila J for the defect id HST-7014 <End>  
   ,std_amt_flag   = tmp.std_amt_flag -- Code added by Sharmila J on 24-Mar-2020 for the defect id COH-121  
   --Code added by Sharmila J on 18-May-2020 for HRP-9 <Begin>  
   --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <Begin>  
   ,lop_amount    = (CASE WHEN pror_type in ('CD','WD','FD','AWD','FCD') THEN isnull(lop_days_amount,0.00)  
   --,lop_amount    = (CASE WHEN pror_type in ('CD','WD','FD','AWD') THEN isnull(lop_days_amount,0.00)  
   --Code added and commented by Sharmila J on 09-Sep-2021 for HRPS-1824 <End>  
            WHEN pror_type IN ('WH','AWH') THEN isnull(lop_hours_amount,0) END)   
   --Code added by Sharmila J on 18-May-2020 for HRP-9 <End>  
   -- Code added by Sharmila J on 02-Aug-2022 for HRP-8576 <Begin>  
   ,cmn.rota_plan_code  = tmp.rota_plan_code   
   ,cmn.no_of_holidays  = tmp.no_of_holidays   
   ,cmn.tot_holiday_hrs = tmp.tot_holiday_hrs   
   ,cmn.holy_amount  = tmp.holy_amount   
   -- Code added by Sharmila J on 02-Aug-2022 for HRP-8576 <End>  
 FROM pyprc_cmn_rule_emp_process_tmp cmn ,--WITH (NOLOCK),  
   pyprc_cmn_ctc_rule_wrk_tmp      tmp WITH (NOLOCK)  
 WHERE cmn.master_ou_code  = @payroll_ou_cd              
 AND  cmn.process_number  = @process_number                          
 AND  cmn.payroll_code  = @payroll_cd                                 
 AND  cmn.paySET_code   = @paySET_cd                      
 AND  cmn.process_period_code = @prcprd_cd    
 AND  cmn.rule_type   = @rule_type  
 AND  cmn.pay_element_code = @pay_elt_cd  
 AND  cmn.employee_code  = tmp.employee_code  
 AND  cmn.assignment_no  = tmp.assignment_no--Code added by Sharmila J on 05-Feb-2021 for HRP-837    
 AND  cmn.employment_ou  = tmp.emp_ou  
 AND  cmn.master_ou_code  = tmp.master_ou  
 AND  cmn.effective_from  = tmp.effective_from  
-- AND  @pprd_to_date between tmp.effective_from and isnull(tmp.effective_to,@pprd_to_date)--Code commented by Sharmila J on 27-July-2018 for the defect id HC-2152  
 AND  tmp.process_number  = @process_number--Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542  
  
 --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <Begin>  
 DELETE FROM pyprc_cmn_ctc_rule_wrk_tmp  WHERE process_number = @process_number    
 DELETE FROM pyprc_cmn_ctc_rule_week_begins WHERE process_number = @process_number    
 DELETE FROM pyprc_cmn_ctc_rule_gre_cal_tmp WHERE process_number = @process_number    
 DELETE FROM pyprc_cmn_ctc_rule_comp_tmp  WHERE process_number = @process_number    
 DELETE FROM pyprc_cmn_hour_conv_freq_tmp WHERE process_number = @process_number    
 DELETE FROM pyprc_cmn_ctc_rule_emp_gre_cal WHERE process_number = @process_number    
 --Code added by Sharmila J on 12-Oct-2020 for the defect id SMH-542 <End>  
 DELETE FROM pyprc_cmn_ctc_lop_dtl_tmp WHERE process_number = @process_number--Code added by Sharmila J for HRPS-5160 on 18-Jan-2023  
  
SET NOCOUNT OFF  
  
  
END  
  