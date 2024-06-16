---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
/**********************************************************************************************/  
/* procedure      pyprc_cmn_pay_rule_emp_fetch                                                 */  
/* description    To fetch employee details based on common rule configuration      */  
/*                                                                                            */  
/**********************************************************************************************/  
/* project        NGP                                                                         */  
/* version        1 0 00                                                                      */  
/* rule version   1 0 00                                                                      */  
/**********************************************************************************************/  
/* referenced                                                                                 */  
/* tables/views                                                                               */  
/*                                                                                            */  
/**********************************************************************************************/  
/* development history                                                                        */  
/* author           : Senthil Arasu . B                                                       */  
/* date             : 02-Aug-2017                                                             */  
/**********************************************************************************************/  
/* modified by      : Pradeep Balaji . B                                                      */  
/* date    : 29-jan-2018                                                     */  
/* description  : Modified procedure for handling proration methods        */  
/* modified by      : Palaniappan A                                                        */  
/* date    : 21-OCT-2019                                                     */  
/* description  : Modified procedure for handling proration methods        */  
/**********************************************************************************************/  
  
  
  
  
----------------------------------Do not Delete or alter this line-------------------------------  
--$versionnumber$::$$$29$$$$  Please dont delete this line$$$$$$$$$$$$$$$$$$$  
----------------------------------Do not Delete or alter this line-------------------------------  
  
CREATE procedure pyprc_hcl_aws_cmn_pay_rule_emp_fetch  
 @rule_type   hrcd,   
 @pay_elt_cd   hrcd,  
 @payroll_ou_cd  hrouinstance,   
 @payroll_cd   hrcd,   
 @payset_cd   hrcd,  
 @prcprd_cd   hrcd,  
 @process_number  hrint,  
 @pprd_from_date  DATETIME,  
 @pprd_to_date  DATETIME,  
 @progressive_flag hrcd  
AS  
BEGIN  
  
 SET NOCOUNT ON  
  
 DECLARE @progressive_date_tmp DATETIME  
 DECLARE @empin_ou    hrouinstance  
 DECLARE @empng_ou    hrouinstance  
 DECLARE @pydef_ou    hrouinstance  
    DECLARE @tmgt_interface   hrquickcode  
 DECLARE @lv_interface   hrquickcode  
  
 CREATE TABLE #EMP_PROCESS_TMP  
 (  
 master_ou_code     INT,  
 rule_type      NVARCHAR(20),  
 pay_element_code    NVARCHAR(20),  
 payroll_code     NVARCHAR(20),  
 payset_code      NVARCHAR(20),  
 process_period_code    INT,  
 process_number     INT,  
 effective_from     DATETIME,  
 effective_to     DATETIME,  
 cut_off_from_date    DATETIME,  
 cut_off_to_date     DATETIME,  
 employment_ou     INT,  
 employee_code     NVARCHAR(60),  
 assignment_no     INT,  
 employee_type     NVARCHAR(20),  
 employment_start_date   DATETIME,  
 confirmation_date    DATETIME,  
 last_available_date    DATETIME,  
 wlocn_code      NVARCHAR(10),  
 dept_code      NVARCHAR(20),  
 gradeset_code     NVARCHAR(10),  
 grade_code      NVARCHAR(10),  
 position_code     NVARCHAR(20),  
 nationality_code    NVARCHAR(10),  
 org_business_unit_code   NVARCHAR(60),  
 contract_type     NVARCHAR(10),  
 separation_date     DATETIME,  
 sep_reason_code     NVARCHAR(10),  
 sep_reason_desc     nvarchar(160),  
 rota_schedule_code    NVARCHAR(20),  
 policy_effective_from   DATETIME,  
 policy_effective_to    DATETIME,  
 lop_considered     NVARCHAR(6),  
 prog_service_slab    NVARCHAR(6),  
 service_prd_based_on   NVARCHAR(10),  
 lop_days      NUMERIC(8,2),  
 emp_service      NUMERIC(28,8),  
 emp_service_rnd     NUMERIC(15,4),  
 emp_service_in_mth    NUMERIC(28,8),  
 DOJ_effective_from    DATETIME,  
 Service_Month_From    NUMERIC(8,2),  
 Service_Month_To    NUMERIC(8,2),  
 each_service_year    NVARCHAR(6),  
 min_service_days    INT,  
 max_service_mth_cap    INT,  
 accm_cd_qc      NVARCHAR(10),  
 accm_salary_factor    NUMERIC(5,2),--NVARCHAR(5), -- added by senthil arasu b on 04-Dec-2017  
 salary_factor     NUMERIC(5,2),  
 salary_uom      NVARCHAR(10),  
 no_of_mth_avg_salary   NUMERIC(28,8),  
 basis_avg_salary    NVARCHAR(10),  
 avg_salary_mul_factor   NUMERIC(28,8),  
 percent_of_salary    NUMERIC(5,2),  
 local_avg_salary    NUMERIC(28,8),  
 no_of_times_local_avg_salary NUMERIC(5,2),  
 salary_precedence    NVARCHAR(10),  
 max_salary_cap     NUMERIC(28,8),  
 max_amount_cap     NUMERIC(28,8),  
 emp_service_in_mth_cap   NUMERIC(28,8),   
 spoc_value_type     NVARCHAR(160), -- added by senthil arasu b on 04-Dec-2017  
 flat_value      NUMERIC(28,8),  
 local_avg_salary_amount   NUMERIC(28,8),  
 proration_method    NVARCHAR(10), --added by pradeep for proration methods  
 -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
 fixed_days      NUMERIC(15,4),  
 --fixed_days      hrint , --added by pradeep for proration methods  
 -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
 paid_week_off     NVARCHAR(10) --added by pradeep for proration methods  
 ,service_ref_date    DATETIME -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
 --Code added by Sharmila J on 11-July-2018 for the defect id HC-2097 <Begin>  
 ,proration_applicable_for  NVARCHAR(10)  
 ,date_join_based_on    NVARCHAR(10)  
 ,age_factor      NUMERIC(5,2)  
 ,process_based_on    NVARCHAR(10)  
 ,payroll_calendar_code   NVARCHAR(10)  
 ,process_pay_period    NVARCHAR(10)  
 ,date_of_birth     DATETIME  
 ----Code added by Sharmila J on 11-July-2018 for the defect id HC-2097 <End>  
 ,encash_lv_type     NVARCHAR(10)  
 ,encash_lv_units_max_cap  NUMERIC(15,4)/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/    
 ,min_salary_cap     NUMERIC(15,4)--Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
 ,legal_entity     NVARCHAR(20) --code added by Keerthana S on Mar-25-2019 for defect id HST-5201  
 ,computation_for    NVARCHAR(10)  
 ,final_notic_per_sort_fall  INT -- code added by palani for Notice period rule  
 ,pay_days_in_leiu_not_per  INT -- code added by palani for Notice period rule  
 ,adju_pay_days_leiu_notc  INT -- code added by palani for Notice period rule  
 --Code added by Sharmila J for the defect id HST-7014 <Begin>  
 ,hour_conv_freq     NVARCHAR(20),      
 super_user_cmb1     NVARCHAR(20),     
 super_user_cmb2     NVARCHAR(20),     
 super_user_cmb3     NVARCHAR(20),  
 super_user_cmb4     NVARCHAR(20),      
 super_user_cmb5     NVARCHAR(20),     
 super_user_cmb6     NVARCHAR(20),     
 super_user_cmb7     NVARCHAR(20),  
 super_user_cmb8     NVARCHAR(20),      
 super_user_cmb9     NVARCHAR(20)  
 --Code added by Sharmila J for the defect id HST-7014 <End>  
 )  
 /*  
 DECLARE @emp_process_tmp TABLE  
 (    
  master_ou_code     hrouinstance,  
  rule_type      hrcd,  
  pay_element_code    hrcd,  
  payroll_code     hrcd,  
  payset_code      hrcd,  
  process_period_code    hrint,  
  process_number     hrint,  
  effective_from     datetime,  
  effective_to     datetime,  
  cut_off_from_date    datetime,  
  cut_off_to_date     datetime,  
  employment_ou     hrouinstance,  
  employee_code     hrempcode,  
  assignment_no     hrassgnno,  
  employee_type     hrcd,  
  employment_start_date   datetime,  
  confirmation_date    datetime,  
  last_available_date    datetime,  
  wlocn_code      hrcode,  
  dept_code      hrcd,  
  gradeset_code     hrcode,  
  grade_code      hrcode,  
  position_code     hrposncode,  
  nationality_code    hrquickcode,  
  org_business_unit_code   buid,  
  contract_type     hrquickcode,  
  separation_date     datetime,  
  sep_reason_code     hrquickcode,  
  sep_reason_desc     nvarchar(200),  
  rota_schedule_code    hrcd,  
  policy_effective_from   datetime,  
  policy_effective_to    datetime,  
  lop_considered     hrflag,  
  prog_service_slab    hrflag,  
  service_prd_based_on   hrcode,  
  lop_days      hrleaveunits,  
  emp_service      amount,  
  emp_service_rnd     hrsalary,  
  emp_service_in_mth    numeric,  
  DOJ_effective_from    datetime,  
  Service_Month_From    hrleaveunits,  
  Service_Month_To    hrleaveunits,  
  each_service_year    hrflag,  
  min_service_days    hrint,  
  max_service_mth_cap    hrint,  
  accm_cd_qc      hrquickcode,  
  accm_salary_factor    hrpercentage, -- added by senthil arasu b on 04-Dec-2017  
  salary_factor     hrpercentage,  
  salary_uom      hrquickcode,  
  no_of_mth_avg_salary   amount,  
  basis_avg_salary    hrquickcode,  
  avg_salary_mul_factor   amount,  
  percent_of_salary    hrpercentage,  
  local_avg_salary    amount,  
  no_of_times_local_avg_salary hrpercentage,  
  salary_precedence    hrquickcode,  
  max_salary_cap     amount,  
  max_amount_cap     amount,  
  emp_service_in_mth_cap   amount,   
  spoc_value_type     hrdesc40, -- added by senthil arasu b on 04-Dec-2017  
  flat_value      amount,  
  local_avg_salary_amount   amount,  
  proration_method    hrquickcode, --added by pradeep for proration methods  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <starts>  
  fixed_days      hrsalary,  
  --fixed_days      hrint , --added by pradeep for proration methods  
  -- code added by senthil arasu b on 30-Oct-2018 for defect id HC-2667 <ends>  
  paid_week_off     hrquickcode --added by pradeep for proration methods  
  ,service_ref_date    DATETIME -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
  --Code added by Sharmila J on 11-July-2018 for the defect id HC-2097 <Begin>  
  ,proration_applicable_for  hrcode  
  ,date_join_based_on    hrcode  
  ,age_factor      hrpercentage  
  ,process_based_on    hrcode  
  ,payroll_calendar_code   hrcode  
  ,process_pay_period    hrcode  
  ,date_of_birth     DATETIME  
  ----Code added by Sharmila J on 11-July-2018 for the defect id HC-2097 <End>  
  ,encash_lv_type     hrcode  
  ,encash_lv_units_max_cap   hrsalary/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/    
  ,min_salary_cap     hrsalary--Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
  ,legal_entity     hrcd --code added by Keerthana S on Mar-25-2019 for defect id HST-5201  
 )  
 */  
 -- Finding the payroll definition ou code  
 SELECT @pydef_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'   
 AND  target_component = 'HRMSPYDEF'  
  
 --Finding the employment ou code    
 SELECT @empin_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)   
 WHERE source_ou_code  = @payroll_ou_cd   
 AND  source_component = 'HRMSPYPRC'  
 AND  target_component = 'HRMSEMPIN'  
  
 --Finding the Master definition ou        
 SELECT @empng_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @empin_ou  
 AND  source_component = 'HRMSEMPIN'  
 AND  target_component = 'HRMSEMPNG'  
  
 --Finding the Master definition ou        
 SELECT @empng_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @empin_ou  
 AND  source_component = 'HRMSEMPIN'  
 AND  target_component = 'HRMSEMPNG'  
  
 --Finding the T&A, leave interface flag   
 SELECT @tmgt_interface = pdef.ars_interface ,   
   @lv_interface = pdef.leave_interface        
 FROM hrpydef_pyrl_parameter_vw pdef WITH (NOLOCK)         
 WHERE pdef.master_ou = @pydef_ou  
  
 SELECT @progressive_date_tmp = NULL  
  
 IF ISDATE(@progressive_flag) = 1  
 BEGIN -- 1  
  SELECT @progressive_date_tmp = CONVERT(DATETIME,@progressive_flag,101)  
 END -- 1  
  
 --Code added by Senthil Arasu B for the defect id HC-2071 <Begin>  
 DECLARE @payroll_calendar_code hrcode  
 DECLARE @payroll_type   hrquickcode  
  
 --Finding payroll calendar code  
 SELECT @payroll_calendar_code = payroll_calendar_code                      
 FROM hrpydef_pyrl_def_hdr WITH (NOLOCK)                 
 WHERE master_ou    = @pydef_ou  
 AND  payroll_code   = @payroll_cd     
  
 SELECT @payroll_type = payroll_type  
 FROM hrpydef_pyrl_def_hdr WITH (NOLOCK)  
 WHERE payroll_code   = @payroll_cd  
 AND  master_ou    = @pydef_ou  
 AND  payroll_calendar_code = @payroll_calendar_code  
 --Code added by Senthil Arasu B for the defect id HC-2071 <End>  
  
 --code added by Keerthana S on 08-July-2019 for the defect id HST-5201 <starts>  
 DECLARE @syspr_ou     hrouinstance  
 DECLARE @system_param_value   hrremarks  
 DECLARE @mul_legal_entity_dyn_sv hrflag  
  
 --Finding the System parameter ou  
 SELECt @syspr_ou   = target_ou_code  
 FROM hrcmn_cim_view WITH(NOLOCK)  
 WHERE source_ou_code  = @empin_ou  
 AND  source_component = 'HRMSEMPIN'   
 AND  target_component = 'HRMSSYSPR'  
  
 /* to identify the system_param_value based on the set process parameter "Legal Entity Identifier" */  
 SELECT @system_param_value   = system_param_value  
 FROM hrsp_sysparam_values WITH (NOLOCK)         
 WHERE master_ou_code    = @syspr_ou  
 AND  UPPER(system_param_code) = 'ZLEG'  
 AND  quick_code_flag    = 'Y'   
  
 --Code added by Sharmila J on 09-Aug-2019 for the defect id HC-3830 <Begin>  
 IF @system_param_value IS NULL  
  SELECT @system_param_value = 'EMPU'  
 --Code added by Sharmila J on 09-Aug-2019 for the defect id HC-3830 <End>  
  
 IF @system_param_value = 'DEPT'  
 BEGIN  
  SELECT  @mul_legal_entity_dyn_sv  = 'y'  
 END  
 ELSE  
 BEGIN  
  SELECT  @mul_legal_entity_dyn_sv  = 'n'  
 END  
 --code added by Keerthana S on 08-July-2019 for the defect id HST-5201 <ends>  
  
 -- to get the list of employees who are seperated in the given process period, when rule is called for severance pay element  
 --Code added and commented by Senthil Arasu B on 28-Nov-2018 for the defect id HC-2734 <Begin>  
 IF (@rule_type in  ('SEV') and @payroll_type = 'E') or @rule_type= 'NPP'  
 --IF @rule_type =  'SEV' AND @payroll_type = 'E'  
 --IF @rule_type =  'SEV'   
 --Code added and commented by Senthil Arasu B on 28-Nov-2018 for the defect id HC-2734 <End>  
 BEGIN -- 2  
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,     rule_type,     pay_element_code,   payroll_code,     
    payset_code,     process_period_code,  process_number,    effective_from,      
    effective_to,     cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,     assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,    last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,    rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,    service_prd_based_on  
    ,date_of_birth, --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302  
    computation_for,    final_notic_per_sort_fall,  pay_days_in_leiu_not_per, adju_pay_days_leiu_notc --code added by palani for npp rule  
  )  
  SELECT pre.master_ou,     @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,      @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,   tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,    pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,   sep.last_available_date, sep.separation_date,  sep.separation_reason_code,   
    sep.other_reason_description, pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,   cfg.service_prd_based_on  
    ,pre.date_of_birth,--Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302  
    cfg.computation_for,   sep.final_notic_per_sort_fall, sep.pay_days_in_leiu_not_per,sep.adju_pay_days_leiu_notc--code added by palani for npp rule  
   FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    hrmv_emp_sep_hdr   sep (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                                   
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  -- code added and commented by senthil arasu b on 06-Nov-2017 to ignore the timestamp from the last available date <begin>  
  AND  (   
     (  
      pre.last_available_date IS NOT NULL  
      AND CONVERT(DATETIME,CONVERT(VARCHAR(10),pre.last_available_date,101)) BETWEEN @pprd_from_date AND @pprd_to_date  
     )   
    OR   
     (  
      pre.last_available_date IS NULL  
      --code added and commented by Keerthana S on Mar-29-2019 for defect id HST-5201<starts>  
      AND  pre.effective_from_date <= @pprd_to_date     
      AND  isnull(pre.effective_to_date,@pprd_from_date) >= @pprd_from_date   
      --AND @pprd_to_date BETWEEN pre.effective_from_date AND pre.effective_to_date  
      --code added and commented by Keerthana S on Mar-29-2019 for defect id HST-5201<end>  
     )         
    )  
  AND  pre.employee_status <> 'S' -- code added by senthil arasu b on 22-Mar-2018 for defect id HST-2991  
  --AND  CONVERT(DATETIME,CONVERT(VARCHAR(10),pre.last_available_date,101)) BETWEEN @pprd_from_date AND @pprd_to_date  
--  AND  pre.last_available_date BETWEEN @pprd_from_date AND @pprd_to_date  
  -- code added and commented by senthil arasu b on 06-Nov-2017 to ignore the timestamp from the last available date <end>  
  AND  sep.master_ou_code  = @empng_ou  
  AND  sep.employee_code  = tmp.empcode  
  -- code added and commented by senthil arasu b on 06-Nov-2017 to ignore the timestamp from the last available date <begin>  
  AND  CONVERT(DATETIME,CONVERT(VARCHAR(10),sep.last_available_date,101)) BETWEEN @pprd_from_date AND @pprd_to_date  
--  AND  sep.last_available_date BETWEEN @pprd_from_date AND @pprd_to_date  
  -- code added and commented by senthil arasu b on 06-Nov-2017 to ignore the timestamp from the last available date <end>  
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND( -- 1  
    ( -- 2  
     -- when progressive computation is selected as Date of join  
     -- Policies in which employee's date of join falls as well as following policies   
     @progressive_flag = 'DOJ' AND @progressive_date_tmp IS NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= pre.date_of_joining  
    ) -- 2  
   OR   
    ( -- 3  
     -- when progressive computation is selected as one of the policy effective period  
     -- All the policies will be fetched after selected effective period   
     @progressive_flag NOT IN ('DOJ', 'NA') AND @progressive_date_tmp IS NOT NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= @progressive_date_tmp  
    ) -- 3  
   OR    
    ( -- 4  
     -- when progressive computation is selected as Not Applicable  
     -- Policies in which 'process period to date' falls   
     @progressive_flag = 'NA' AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 4  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <starts>  
   OR   
    ( -- 5  
     -- Progressive computation is not mandatory for SPOC based payment & Compensation Payment rule types   
     @progressive_flag IS NULL AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 5  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <ends>  
   ) -- 1  
 END -- 2  
  
 /*Code added by senthil/Arun V on 28-Jul-2020 for JLIH-229 <starts>*/  
 IF @rule_type = 'SEV' and @payroll_type = 'E'  
 BEGIN  
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,     rule_type,     pay_element_code,   payroll_code,     
    payset_code,     process_period_code,  process_number,    effective_from,      
    effective_to,     cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,     assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,    last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,    rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,    service_prd_based_on  
    ,date_of_birth,   
    computation_for,    final_notic_per_sort_fall,  pay_days_in_leiu_not_per, adju_pay_days_leiu_notc   
  )  
  SELECT pre.master_ou,     @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,      @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,   tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,    pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,   sep.last_available_date, sep.separation_date,  sep.separation_reason_code,   
    sep.other_reason_description, pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,   cfg.service_prd_based_on  
    ,pre.date_of_birth,  
    cfg.computation_for,   sep.final_notic_per_sort_fall, sep.pay_days_in_leiu_not_per,sep.adju_pay_days_leiu_notc  
   FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    hrmv_emp_sep_hdr   sep (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                                   
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  AND  pre.last_available_date IS NULL   
  AND  pre.effective_from_date  >=  ( SELECT MAX(CONVERT(DATETIME,CONVERT(VARCHAR(10),seph.last_available_date,101)))  
            FROM hrmv_emp_sep_hdr seph WITH (NOLOCK)  
            WHERE seph.master_ou_code  = @empng_ou  
            AND  seph.employee_code  = sep.employee_code  
            )   
  AND  pre.employee_status = 'S'  
  AND  sep.master_ou_code  = @empng_ou  
  AND  sep.employee_code  = tmp.empcode  
  AND  CONVERT(DATETIME,CONVERT(VARCHAR(10),sep.last_available_date,101)) <= @pprd_from_date   
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND( -- 1  
    ( -- 2  
     -- when progressive computation is selected as Date of join  
     -- Policies in which employee's date of join falls as well as following policies   
     @progressive_flag = 'DOJ' AND @progressive_date_tmp IS NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= pre.date_of_joining  
    ) -- 2  
   OR   
    ( -- 3  
     -- when progressive computation is selected as one of the policy effective period  
     -- All the policies will be fetched after selected effective period   
     @progressive_flag NOT IN ('DOJ', 'NA') AND @progressive_date_tmp IS NOT NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= @progressive_date_tmp  
    ) -- 3  
   OR    
    ( -- 4  
     -- when progressive computation is selected as Not Applicable  
     -- Policies in which 'process period to date' falls   
     @progressive_flag = 'NA' AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 4  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <starts>  
   OR   
    ( -- 5  
     -- Progressive computation is not mandatory for SPOC based payment & Compensation Payment rule types   
     @progressive_flag IS NULL AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 5  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <ends>  
   ) -- 1  
  
 END   
 /*Code added by senthil/Arun V on 28-Jul-2020 for JLIH-229 <end>*/  
  
 -- to fetch employees from payroll interim table, when rule is called for other pay elements  
 --code added and commented by Keerthana S on May-24-2019 for the defect id HST-6038 <starts>  
 IF @rule_type not in ( 'SEV','CMP','SBP', 'ENC','NPP')   
 --IF @rule_type not in ( 'SEV','CMP')   
 --code added and commented by Keerthana S on May-24-2019 for the defect id HST-6038 <end>  
 BEGIN -- 3  
   
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,    rule_type,     pay_element_code,   payroll_code,     
    payset_code,    process_period_code,  process_number,    effective_from,      
    effective_to,    cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,    assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,   last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,   rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,   service_prd_based_on  
    ,date_of_birth, --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302  
    computation_for --Code added by palani for NPP Rule  
  )  
  SELECT pre.master_ou,    @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,     @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,  tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,   pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,  pre.last_available_date, NULL,      NULL,  
    NULL,      pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,  cfg.service_prd_based_on  
    ,pre.date_of_birth, --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302  
    cfg.computation_for --Code added by palani for NPP Rule  
  FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                                   
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  -- code added and commented by senthil arasu b on 20-Feb-2018 for defect id HC-1689 <starts>  
  AND  (   
     (  
      pre.last_available_date IS NOT NULL  
      AND CONVERT(DATETIME,CONVERT(VARCHAR(10),pre.last_available_date,101)) BETWEEN @pprd_from_date AND @pprd_to_date  
     )   
    OR   
     (  
      pre.last_available_date IS NULL  
      --code added and commented by Keerthana S on Mar-29-2019 for defect id HST-5201<starts>  
      --Code commented and uncommented by Sharmila J for the defect id JLIH-13 on 02-Mar-2020 <Begin>  
      --AND  pre.effective_from_date <= @pprd_to_date     
      --AND  isnull(pre.effective_to_date,@pprd_from_date) >= @pprd_from_date   
      AND @pprd_to_date BETWEEN pre.effective_from_date AND pre.effective_to_date  
      --Code commented and uncommented by Sharmila J for the defect id JLIH-13 on 02-Mar-2020 <End>  
      --code added and commented by Keerthana S on Mar-29-2019 for defect id HST-5201<end>  
     )         
    )  
  AND  pre.employee_status <> 'S' -- code added by senthil arasu b on 22-Mar-2018 for defect id HST-2991   
  -- code added by senthil arasu b on 13-Jul-2018 for new joinee & exit in same process period for the defect id HC-2071 <starts>  
  AND (   
    (  
     pre.employee_flag <> 'EXNJ'  
    )  
    OR   
    (  
     @payroll_type    = 'E'  
     AND pre.employee_flag  = 'EXNJ'   
     AND pre.effective_to_date <= ( SELECT prp.effective_to_date  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
--     AND pre.last_available_date IS NOT NULL  
    )  
    OR   
    (  
     @payroll_type    <> 'E'   
     AND pre.employee_flag  = 'EXNJ'   
     -- code add and commented by senthil arasu b on 09-May-2019 for defect id HST-6220 <starts>  
     --Code added and commented by SHarmila J on 17-Sep-2020  for the defect id ORH 650 <Begin>  
     AND pre.effective_from_date > (  SELECT prp.effective_to_date  
     --AND pre.effective_from_date < (  SELECT prp.effective_to_date  
     --Code added and commented by SHarmila J on 17-Sep-2020  for the defect id ORH 650 <End>  
     --AND pre.effective_from_date > (  SELECT prp.effective_to_date  
     -- code add and commented by senthil arasu b on 09-May-2019 for defect id HST-6220 <ends>  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
--     AND pre.last_available_date IS NULL  
    )  
   )  
  -- code added by senthil arasu b on 13-Jul-2018 for new joinee & exit in same process period for the defect id HC-2071 <ends>  
--  AND  @pprd_to_date   BETWEEN pre.effective_from_date AND pre.effective_to_date  
--  AND  pre.employee_status  = 'C'  
  -- code added and commented by senthil arasu b on 20-Feb-2018 for defect id HC-1689 <ends>  
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND( -- 1   
    ( -- 2  
     -- when progressive computation is selected as Date of join  
     -- Policies in which employee's date of join falls as well as following policies   
     @progressive_flag = 'DOJ' AND @progressive_date_tmp IS NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= pre.date_of_joining  
    ) -- 2    
   OR   
    ( -- 3   
     -- when progressive computation is selected as one of the policy effective period  
     -- All the policies will be fetched after selected effective period for each employee  
     @progressive_flag NOT IN ('DOJ', 'NA') AND @progressive_date_tmp IS NOT NULL AND ISNULL(cfg.effective_to,@pprd_to_date) >= @progressive_date_tmp  
    ) -- 3  
   OR   
    ( -- 4  
     -- when progressive computation is selected as Not Applicable  
     -- Policies in which 'process period to date' falls   
     @progressive_flag = 'NA' AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 4  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <starts>  
   OR   
    ( -- 5  
     -- Progressive computation is not mandatory for SPOC based payment & Compensation Payment rule types   
     @progressive_flag IS NULL AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 5  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <ends>  
   ) -- 1  
 END -- 3  
  
 -- senthil  
 IF @rule_type = 'ENC'  
 BEGIN -- 3  
   
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,    rule_type,     pay_element_code,   payroll_code,     
    payset_code,    process_period_code,  process_number,    effective_from,      
    effective_to,    cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,    assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,   last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,   rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,   service_prd_based_on  
    ,date_of_birth,    computation_for--code added by palani for NPP Rule   
  )  
  SELECT pre.master_ou,    @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,     @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,  tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,   pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,  pre.last_available_date, NULL,      NULL,  
    NULL,      pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,  cfg.service_prd_based_on  
    ,pre.date_of_birth,   cfg.computation_for--code added by palani for NPP Rule  
  FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                                   
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  AND  pre.effective_from_date = ( SELECT MAX(prp.effective_from_date)  
           FROM pyprc_pre_payroll prp WITH (NOLOCK)  
           WHERE prp.master_ou   = tmp.master_ou  
           AND  prp.employee_code  = tmp.empcode  
           AND  prp.employment_ou  = tmp.employment_ou   
           AND  prp.assignment_number = tmp.assignment_no   
           AND  prp.process_number  = tmp.process_number  
           AND  prp.payroll_code  = tmp.payroll_code  
           AND  prp.payset_code   = tmp.payset_code  
           AND  prp.process_period_code = tmp.process_period)   
  --AND  pre.employee_status  <> 'S' -- code commented by senthil arasu b on 13-Dec-2019 for defect id ORH-95  
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND  @pprd_to_date   BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
  
  --Code added by Sharmila J for the defect id HBM-752 on 30-Mar-2020 <Begin>  
  UPDATE emp  
  SET  emp.last_available_date = sep.last_available_date,  
    emp.separation_date  = sep.separation_date,  
    emp.sep_reason_code  = sep.separation_reason_code,  
    emp.sep_reason_desc  = sep.other_reason_description  
  FROM pyprc_cmn_rule_emp_info  emp    
  JOIN hrmv_emp_sep_hdr   sep WITH (NOLOCK)     
  ON  sep.employee_code   = emp.employee_code                
  WHERE emp.master_ou_code   = @payroll_ou_cd  
  AND  emp.rule_type    = @rule_type  
  AND  emp.pay_element_code  = @pay_elt_cd  
  AND  emp.payroll_code   = @payroll_cd  
  AND  emp.payset_code    = @payset_cd  
  AND  emp.process_period_code  = @prcprd_cd  
  AND  emp.process_number   = @process_number  
  AND  sep.master_ou_code   = @empng_ou                   
  AND  CONVERT(DATETIME,CONVERT(VARCHAR(10),sep.last_available_date,101)) BETWEEN @pprd_from_date AND @pprd_to_date  
  --Code added by Sharmila J for the defect id HBM-752 on 30-Mar-2020<End>  
 END -- 3  
 -- senthil  
  
  
 --code added by Keerthana S on May-24-2019 for the defect id HST-6038<starts>  
 IF @rule_type ='SBP'  
 BEGIN -- 3  
   
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,    rule_type,     pay_element_code,   payroll_code,     
    payset_code,    process_period_code,  process_number,    effective_from,      
    effective_to,    cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,    assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,   last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,   rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,   service_prd_based_on,  date_of_birth,    computation_for--code added by palani for NPP Rule  
  )  
  SELECT pre.master_ou,    @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,     @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,  tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,   pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,  pre.last_available_date, NULL,      NULL,  
    NULL,      pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,  cfg.service_prd_based_on, pre.date_of_birth,   cfg.computation_for--code added by palani for NPP Rule   
  FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                  
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  AND  (   
     (  
      pre.last_available_date IS NOT NULL  
      AND  pre.effective_from_date <= @pprd_to_date     
      AND  ISNULL(pre.effective_to_date,@pprd_from_date) >= @pprd_from_date  
     )   
    OR   
     (  
      pre.last_available_date IS NULL  
      AND  pre.effective_from_date <= @pprd_to_date     
      AND  ISNULL(pre.effective_to_date,@pprd_from_date) >= @pprd_from_date  
     )         
    )  
  AND  pre.employee_status <> 'S'   
  AND (   
    (  
     pre.employee_flag <> 'EXNJ'  
    )  
    OR   
    (  
     @payroll_type    = 'E'  
     AND pre.employee_flag  = 'EXNJ'   
     AND pre.effective_to_date <= ( SELECT prp.effective_to_date  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
    )  
    OR   
    (  
     @payroll_type    <> 'E'   
     AND pre.employee_flag  = 'EXNJ'   
     AND pre.effective_from_date > (  SELECT prp.effective_to_date  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
    )  
   )  
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND( -- 1   
    ( -- 2  
     -- when progressive computation is selected as Date of join  
     -- Policies in which employee's date of join falls as well as following policies   
     @progressive_flag = 'DOJ' AND @progressive_date_tmp IS NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= pre.date_of_joining  
    ) -- 2    
   OR   
    ( -- 3   
     -- when progressive computation is selected as one of the policy effective period  
     -- All the policies will be fetched after selected effective period for each employee  
     @progressive_flag NOT IN ('DOJ', 'NA') AND @progressive_date_tmp IS NOT NULL AND ISNULL(cfg.effective_to,@pprd_to_date) >= @progressive_date_tmp  
    ) -- 3  
   OR   
    ( -- 4  
     -- when progressive computation is selected as Not Applicable  
     -- Policies in which 'process period to date' falls   
     @progressive_flag = 'NA' AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 4  
   OR   
    ( -- 5  
     -- Progressive computation is not mandatory for SPOC based payment & Compensation Payment rule types   
     @progressive_flag IS NULL AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 5  
   ) -- 1  
 END -- 3  
 --code added by Keerthana S on May-24-2019 for the defect id HST-6038<end>  
  
 IF @rule_type ='CMP'  
 BEGIN -- 3  
  INSERT into pyprc_cmn_rule_emp_info  
  (   
    master_ou_code,    rule_type,     pay_element_code,   payroll_code,     
    payset_code,    process_period_code,  process_number,    effective_from,      
    effective_to,    cut_off_from_date,   cut_off_to_date,   employment_ou,     
    employee_code,    assignment_no,    employee_type,    employment_start_date,    
    confirmation_date,   last_available_date,  separation_date,   sep_reason_code,  
    sep_reason_desc,   rota_schedule_code,   policy_effective_from,  policy_effective_to,  
    prog_service_slab,   service_prd_based_on  
    ,date_of_birth, --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302,  
    computation_for--code added by palani for NPP Rule  
  )  
  SELECT pre.master_ou,    @rule_type,     @pay_elt_cd,    @payroll_cd,       
    @payset_cd,     @prcprd_cd,     @process_number,   pre.effective_from_date,    
    pre.effective_to_date,  tmp.cut_off_from_date,  tmp.cut_off_to_date,  pre.employment_ou,      
    pre.employee_code,   pre.assignment_number,  pre.employee_type,   pre.date_of_joining,     
    pre.actl_confirm_date,  pre.last_available_date, NULL,      NULL,  
    NULL,      pre.rota_schedule_code,  cfg.effective_from,   ISNULL(cfg.effective_to,@pprd_to_date),  
    cfg.prog_service_slab,  cfg.service_prd_based_on  
    ,pre.date_of_birth, --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302  
    cfg.computation_for --code added by palani for NPP Rule  
  FROM pyprc_emp_loop_tmp   tmp (NOLOCK),  
    pyprc_pre_payroll   pre (NOLOCK),  
    pyprc_cmn_rule_config_hdr cfg (NOLOCK)  
  WHERE tmp.master_ou   = @payroll_ou_cd              
  AND  tmp.process_number  = @process_number                                  
  AND  tmp.payroll_code  = @payroll_cd                                 
  AND  tmp.payset_code   = @payset_cd                                   
  AND  tmp.process_period  = @prcprd_cd                                   
  AND  tmp.process_flag  = 'N'  
  AND  pre.master_ou   = tmp.master_ou  
  AND  pre.employee_code  = tmp.empcode  
  AND  pre.employment_ou  = tmp.employment_ou   
  AND  pre.assignment_number = tmp.assignment_no   
  AND  pre.process_number  = tmp.process_number                            
  AND  pre.payroll_code  = tmp.payroll_code                            
  AND  pre.payset_code   = tmp.payset_code                                   
  AND  pre.process_period_code = tmp.process_period    
  -- code added and commented by senthil arasu b on 20-Feb-2018 for defect id HC-1689 <starts>  
  AND  pre.effective_from_date <= @pprd_to_date     
  AND  isnull(pre.effective_to_date,@pprd_from_date) >= @pprd_from_date     
  --AND  @pprd_to_date   BETWEEN pre.effective_from_date AND pre.effective_to_date  
--  AND  pre.employee_status  = 'C'  
  -- code added and commented by senthil arasu b on 20-Feb-2018 for defect id HC-1689 <ends>  
  
  
  -- code added and commented by senthil arasu b on  20-Mar-2019 for backdated termination issue for the defect id HC-3312<starts>  
  AND  (  
    (  
     pre.employee_status <> 'S'   
    )  
    OR    
    (  
     pre.employee_status = 'S'   
    AND pre.effective_from_date > ( SELECT sep.last_available_date  
            FROM hrmv_emp_sep_hdr sep WITH (NOLOCK)  
            where sep.master_ou_code = @empng_ou  
            AND  sep.employee_code = tmp.empcode  
            AND  sep.separation_status = 'A'  
            AND( CONVERT(DATETIME,CONVERT(VARCHAR(10),sep.last_available_date,101)) < @pprd_from_date   
            OR  CONVERT(DATETIME,CONVERT(VARCHAR(10),sep.last_available_date,101)) > @pprd_to_date)  
            )    
    AND pre.createdby   = 'ARREAR' --code added by Keerthana S on 31-July-2019 for the defect id KBH-304      
    )  
   )  
  --AND  pre.employee_status <> 'S' -- code added by senthil arasu b on 22-Mar-2018 for defect id HST-2991  
  -- code added and commented by senthil arasu b on  20-Mar-2019 for backdated termination issue  for the defect id HC-3312<ends>  
  -- code added by senthil arasu b on 13-Jul-2018 for new joinee & exit in same process period for the defect id HC-2071 <starts>  
  AND (   
    (  
     pre.employee_flag <> 'EXNJ'  
    )  
    OR  
    (  
     @payroll_type    = 'E'  
     AND pre.employee_flag  = 'EXNJ'   
     AND pre.effective_to_date <= ( SELECT prp.effective_to_date  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
--     AND pre.last_available_date IS NOT NULL  
    )  
    OR   
    (  
     @payroll_type    <> 'E'   
     AND pre.employee_flag  = 'EXNJ'   
     -- code add and commented by senthil arasu b on 09-May-2019 for defect id HST-6220 <starts>  
     --Code added and commented by SHarmila J on 17-Sep-2020  for the defect id ORH 650 <Begin>  
     AND pre.effective_from_date > (  SELECT prp.effective_to_date  
     --AND pre.effective_from_date < (  SELECT prp.effective_to_date  
     --Code added and commented by SHarmila J on 17-Sep-2020  for the defect id ORH 650 <End>  
     --AND pre.effective_from_date > (  SELECT prp.effective_to_date  
     -- code add and commented by senthil arasu b on 09-May-2019 for defect id HST-6220 <ends>  
              FROM pyprc_pre_payroll prp WITH (NOLOCK)  
              WHERE prp.master_ou   = tmp.master_ou  
              AND  prp.employee_code  = tmp.empcode  
              AND  prp.employment_ou  = tmp.employment_ou   
              AND  prp.assignment_number = tmp.assignment_no   
              AND  prp.process_number  = tmp.process_number  
              AND  prp.payroll_code  = tmp.payroll_code  
              AND  prp.payset_code   = tmp.payset_code  
              AND  prp.process_period_code = tmp.process_period  
              AND  prp.last_available_date IS NOT NULL)  
--     AND pre.last_available_date IS NULL  
    )  
   )  
  -- code added by senthil arasu b on 13-Jul-2018 for new joinee & exit in same process period for the defect id HC-2071  <ends>  
  AND  cfg.master_ou   = @payroll_ou_cd  
  AND  cfg.rule_type   = @rule_type  
  AND  cfg.pay_element_code = @pay_elt_cd  
  AND  cfg.status    = 'C'  
  AND( -- 1   
    ( -- 2  
     -- when progressive computation is selected as Date of join  
     -- Policies in which employee's date of join falls as well as following policies   
     @progressive_flag = 'DOJ' AND @progressive_date_tmp IS NULL AND ISNULL(cfg.effective_to, @pprd_to_date) >= pre.date_of_joining  
    ) -- 2    
   OR   
    ( -- 3   
     -- when progressive computation is selected as one of the policy effective period  
     -- All the policies will be fetched after selected effective period for each employee  
     @progressive_flag NOT IN ('DOJ', 'NA') AND @progressive_date_tmp IS NOT NULL AND ISNULL(cfg.effective_to,@pprd_to_date) >= @progressive_date_tmp  
    ) -- 3  
   OR   
    ( -- 4  
     -- when progressive computation is selected as Not Applicable  
     -- Policies in which 'process period to date' falls   
     @progressive_flag = 'NA' AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 4  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <starts>  
   OR   
    ( -- 5  
     -- Progressive computation is not mandatory for SPOC based payment & Compensation Payment rule types   
     @progressive_flag IS NULL AND @pprd_to_date BETWEEN cfg.effective_from AND ISNULL(cfg.effective_to, @pprd_to_date)  
    ) -- 5  
   -- code added by senthil arasu b on 20-Feb-2018 for defect id HST-2991 <ends>  
   ) -- 1  
   
 END -- 3  
   
 -- to update employee assignment details as on policy effective to date  
 UPDATE emp  
 SET  org_business_unit_code   = asgn.org_business_unit_code,  
   wlocn_code      = asgn.org_work_locn_code,  
   dept_code      = asgn.dept_code,  
   gradeset_code     = asgn.job_grade_set_code,       
   grade_code      = asgn.job_grade_code,       
   position_code     = asgn.position_code,      
   job_code      = asgn.job_code  
   ,legal_entity     = asgn.legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id HST-7024 PE-LOP enhancements <Begin>  
   ,super_user_cmb1    = asgn.user_cmb1,  
   super_user_cmb2     = asgn.user_cmb2,  
   super_user_cmb3     = asgn.user_cmb3,  
   super_user_cmb4     = asgn.user_cmb4,  
   super_user_cmb5     = asgn.user_cmb5,  
   super_user_cmb6     = asgn.user_cmb6,  
   super_user_cmb7     = asgn.user_cmb7,  
   super_user_cmb8     = asgn.user_cmb8,  
   super_user_cmb9     = asgn.user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id HST-7024 PE-LOP enhancements <End>  
 FROM pyprc_cmn_rule_emp_info emp,   
   hrei_asgn_eff_auth_dtl  asgn WITH (NOLOCK)   
 WHERE emp.master_ou_code    = @payroll_ou_cd  
 AND  emp.rule_type     = @rule_type  
 AND  emp.pay_element_code   = @pay_elt_cd  
 AND  emp.payroll_code    = @payroll_cd  
 AND  emp.payset_code     = @payset_cd  
 AND  emp.process_period_code   = @prcprd_cd  
 AND  emp.process_number    = @process_number  
 AND  asgn.master_ou_code    = @empng_ou  
 AND  asgn.employee_code    = emp.employee_code  
 AND  asgn.assignment_defined_ou_code = emp.employment_ou  
 AND     asgn.assignment_number   = emp.assignment_no  
 --Code added and commented by Sharmila J on 28-May-2020 <Begin>  
 AND  emp.effective_to BETWEEN asgn.assignment_effective_from_date   
        AND ISNULL(asgn.assignment_effective_to_date, emp.effective_to)  
 --AND  emp.policy_effective_to   BETWEEN asgn.assignment_effective_from_date   
 --               AND ISNULL(asgn.assignment_effective_to_date, emp.policy_effective_to)  
 --Code added and commented by Sharmila J on 28-May-2020 <End>  
  
 -- to update employee nationality_code as on 'policy effective to' date   
 UPDATE emp  
 -- code added and commented by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <begins>  
 SET  emp.nationality_code  = epin.nationality_code  
 -- SET  emp.citizenship_code  = epin.citizenship_code  
 -- code added and commented by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <ends>  
   ,emp.service_ref_date  = epin.service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
 FROM pyprc_cmn_rule_emp_info  emp,    
   epin_personal_hist   epin (nolock)                   
 WHERE emp.master_ou_code   = @payroll_ou_cd  
 AND  emp.rule_type    = @rule_type  
 AND  emp.pay_element_code  = @pay_elt_cd  
 AND  emp.payroll_code   = @payroll_cd  
 AND  emp.payset_code    = @payset_cd  
 AND  emp.process_period_code  = @prcprd_cd  
 AND  emp.process_number   = @process_number  
 --Code added and commented by Sharmila J on 14-Feb-2019 for the defect id HC-3077 <Begin>  
 AND  epin.master_ou_code   = @empng_ou                    
 --AND  epin.master_ou_code   = @empin_ou        
 --Code added and commented by Sharmila J on 14-Feb-2019 for the defect id HC-3077 <End>              
 AND  epin.employee_code   = emp.employee_code  
 AND  emp.policy_effective_to  BETWEEN epin.effective_from_date AND ISNULL(epin.effective_to_date, ISNULL(emp.policy_effective_to,@pprd_to_date))  
  
 -- to update employee contract type  
 UPDATE emp  
 SET  emp.contract_type   = cnt.contract_type    
 FROM pyprc_cmn_rule_emp_info emp,  
   epin_mtn_contract_hdr cnt  
 WHERE emp.master_ou_code   = @payroll_ou_cd  
 AND  emp.rule_type    = @rule_type  
 AND  emp.pay_element_code  = @pay_elt_cd  
 AND  emp.payroll_code   = @payroll_cd  
 AND  emp.payset_code    = @payset_cd  
 AND  emp.process_period_code  = @prcprd_cd  
 AND  emp.process_number   = @process_number  
 AND  cnt.master_ou_code   = @empin_ou  
 AND  cnt.employee_code   = emp.employee_code  
 AND  emp.policy_effective_to  BETWEEN cnt.start_date AND cnt.end_date  
  
 --  to fetch total no.of LOP leave applied days during employee's service period  
 IF @lv_interface = 'Y'  
 BEGIN  
  IF EXISTS ( SELECT 'X'  
     FROM pyprc_cmn_rule_leave_exclude WITH (NOLOCK)  
     WHERE master_ou   = @payroll_ou_cd  
     AND  pay_element_code = @pay_elt_cd)  
  BEGIN  
   EXEC pyprc_cmn_pay_rule_LOP_Days @rule_type, @pay_elt_cd, @payroll_ou_cd, @payroll_cd, @payset_cd, @prcprd_cd, @process_number,   
            @pprd_from_date, @pprd_to_date, @progressive_flag  
  END  
 END  
   
 IF EXISTS ( SELECT 'X'  
    FROM pyprc_cmn_rule_service_year_rnd WITH (NOLOCK)  
    WHERE master_ou   = @payroll_ou_cd  
    AND  pay_element_code = @pay_elt_cd)  
 BEGIN  
  --  to round off employee's service year based on service year round off configuration aginst rule type  
  EXEC pyprc_cmn_pay_rule_service_prd_rnd @rule_type, @pay_elt_cd, @payroll_ou_cd, @payroll_cd, @payset_cd, @prcprd_cd, @process_number,   
            @pprd_from_date, @pprd_to_date, @progressive_flag  
 END  
  
 -- to populate employee details into inetrim process table based on employee serivce month, date of join & seperation reason  
   
 -- code added by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <begins>  
 INSERT #EMP_PROCESS_TMP  
 (  
   master_ou_code,      rule_type,      pay_element_code,    payroll_code,  
   payset_code,      process_period_code,   process_number,     effective_from,  
   effective_to,      cut_off_from_date,    cut_off_to_date,    employment_ou,  
   employee_code,      assignment_no,     employee_type,     employment_start_date,  
   confirmation_date,     last_available_date,   wlocn_code,      dept_code,  
   gradeset_code,      grade_code,      position_code,     nationality_code,  
   org_business_unit_code,    separation_date,    sep_reason_code,    sep_reason_desc,  
   rota_schedule_code,     policy_effective_from,   policy_effective_to,   lop_considered,  
   prog_service_slab,     service_prd_based_on,   lop_days,      emp_service,  
   emp_service_rnd,     emp_service_in_mth,    DOJ_effective_from,    service_month_from,  
   service_month_to,     each_service_year,    min_service_days,    max_service_mth_cap,  
   accm_cd_qc,       salary_factor,     salary_uom,      no_of_mth_avg_salary,  
   basis_avg_salary,     avg_salary_mul_factor,   percent_of_salary,    local_avg_salary,  
   no_of_times_local_avg_salary,  salary_precedence,    max_salary_cap,     max_amount_cap,  
   emp_service_in_mth_cap,  
   flat_value,         
   local_avg_salary_amount,  
   accm_salary_factor,     spoc_value_type,  
   proration_method,     fixed_days  ,    paid_week_off --code Added By Pradeep for proration methods on 29-jan-2018  
   ,service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991    
   ,proration_applicable_for,   date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <Begin>   
   ,age_factor,      process_based_on,    payroll_calendar_code,   process_pay_period   
   ,date_of_birth  
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <End>  
   ,min_salary_cap--Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
   ,encash_lv_type,  
   encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201   
   ,computation_for     ,final_notic_per_sort_fall  ,pay_days_in_leiu_not_per  ,adju_pay_days_leiu_notc --code added by palani for NPP Rule  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   ,hour_conv_freq,     super_user_cmb1,    super_user_cmb2,    super_user_cmb3,  
   super_user_cmb4,     super_user_cmb5,    super_user_cmb6,    super_user_cmb7,  
   super_user_cmb8,     super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id HST-7024 PE-LOP enhancements <End>  
 )  
 SELECT emp.master_ou_code,     emp.rule_type,     emp.pay_element_code,   emp.payroll_code,  
   emp.payset_code,     emp.process_period_code,  emp.process_number,    emp.effective_from,  
   emp.effective_to,     emp.cut_off_from_date,   emp.cut_off_to_date,   emp.employment_ou,  
   emp.employee_code,     emp.assignment_no,    emp.employee_type,    emp.employment_start_date,  
   emp.confirmation_date,    emp.last_available_date,  emp.wlocn_code,     emp.dept_code,   
   emp.gradeset_code,     emp.grade_code,     emp.position_code,    emp.nationality_code,   
   emp.org_business_unit_code,   emp.separation_date,   emp.sep_reason_code,   emp.sep_reason_desc,  
   emp.rota_schedule_code,    emp.policy_effective_from,  emp.policy_effective_to,  emp.lop_considered,  
   emp.prog_service_slab,    emp.service_prd_based_on,  emp.lop_days,     emp.emp_service,  
   emp.emp_service_rnd,    emp.emp_service_in_mth,   dtl.DOJ_effective_from,   dtl.service_month_from,  
   dtl.service_month_to,    dtl.each_service_year,   dtl.min_service_days,   dtl.max_service_mth_cap,  
   dtl.accm_cd_qc,      dtl.salary_factor,    dtl.salary_uom,     dtl.no_of_mth_avg_salary,  
   dtl.basis_avg_salary,    dtl.avg_salary_mul_factor,  dtl.percent_of_salary,   dtl.local_avg_salary,  
   dtl.no_of_times_local_avg_salary, dtl.salary_precedence,   dtl.max_salary_cap,    dtl.max_amount_cap,  
   CASE WHEN emp.emp_service_in_mth < dtl.max_service_mth_cap OR dtl.max_service_mth_cap IS NULL   
     THEN emp.emp_service_in_mth ELSE dtl.max_service_mth_cap END,  
   dtl.flat_value,        
   dtl.local_avg_salary * ISNULL(no_of_times_local_avg_salary,1),  
   dtl.accm_salary_factor,    dtl.spoc_value_type, -- added by senthil arasu b on 04-Dec-2017  
   dtl.proration_method,    dtl.fixed_days,     dtl.paid_week_off --code Added By Pradeep for proration methods on 29-jan-2018  
   ,emp.service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
   ,dtl.proration_applicable_for,  dtl.date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <Begin>  
   ,dtl.age_factor,     dtl.process_based_on,   dtl.payroll_calendar_code,  dtl.process_pay_period  
   ,emp.date_of_birth  
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <End>  
   ,dtl.min_salary_cap --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639  
   ,dtl.encash_lv_type  
   ,dtl.encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,emp.legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201   
   ,emp.computation_for    ,emp.final_notic_per_sort_fall ,emp.pay_days_in_leiu_not_per ,emp.adju_pay_days_leiu_notc --code added by palani for NPP Rule  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id HST-7024 PE-LOP enhancements <Begin>  
   ,dtl.hour_conv_freq,    dtl.super_user_cmb1,   dtl.super_user_cmb2,   dtl.super_user_cmb3,  
   dtl.super_user_cmb4,    dtl.super_user_cmb5,   dtl.super_user_cmb6,   dtl.super_user_cmb7,  
   dtl.super_user_cmb8,    dtl.super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id HST-7024 PE-LOP enhancements <End>  
 FROM pyprc_cmn_rule_emp_info  emp,   
   pyprc_cmn_rule_config_dtl dtl WITH (NOLOCK)  
 WHERE emp.master_ou_code    = @payroll_ou_cd  
 AND  emp.rule_type     = @rule_type  
 AND  emp.pay_element_code   = @pay_elt_cd  
 AND  emp.payroll_code    = @payroll_cd  
 AND  emp.payset_code     = @payset_cd  
 AND  emp.process_period_code   = @prcprd_cd  
 AND  emp.process_number    = @process_number  
 AND  dtl.master_ou     = @payroll_ou_cd  
 AND  dtl.rule_type     = @rule_type  
 AND  dtl.pay_element_code   = @pay_elt_cd    
 AND  dtl.effective_from    = emp.policy_effective_from  
 AND  (ISNULL(emp.employee_type,'*') = ISNULL(dtl.emp_type_cd,'*') OR dtl.emp_type_cd IS NULL)  
 AND  (ISNULL(emp.wlocn_code,'*')  = ISNULL(dtl.wlocn_code,'*') OR dtl.wlocn_code IS NULL)  
 --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <starts>  
 AND (  
   (  
   @system_param_value = 'DEPT' AND (ISNULL(emp.legal_entity,'*') = ISNULL(dtl.legal_entity,'*') OR dtl.legal_entity IS NULL)  
   )  
  OR  
   (  
   @system_param_value = 'EMPU'  
   )  
  )  
 /*  
 --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <starts>  
 AND (ISNULL(emp.legal_entity,'*') = ISNULL(dtl.legal_entity,'*') OR dtl.legal_entity IS NULL)  
 --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <end>  
 */  
 --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <ends>  
 AND  (ISNULL(emp.dept_code,'*')  = ISNULL(dtl.dept_code,'*') OR dtl.dept_code IS NULL)  
 AND  (ISNULL(emp.gradeset_code,'*') = ISNULL(dtl.gradeset_code,'*') OR dtl.gradeset_code IS NULL)  
 AND  (ISNULL(emp.grade_code,'*')  = ISNULL(dtl.grade_code,'*') OR dtl.grade_code IS NULL)  
 AND  (ISNULL(emp.position_code,'*') = ISNULL(dtl.posn_code,'*') OR dtl.posn_code IS NULL)  
 AND  (ISNULL(emp.nationality_code,'*')= ISNULL(dtl.nationality_code,'*') OR dtl.nationality_code IS NULL)  
 AND  (ISNULL(emp.contract_type,'*') = ISNULL(dtl.contract_type,'*') OR dtl.contract_type IS NULL)  
 AND  (ISNULL(emp.org_business_unit_code,'*') = ISNULL(dtl.org_business_unit_code,'*') OR dtl.org_business_unit_code IS NULL)  
 --Code added by Sharmila J for the defect id HST-6263 on 13-May-2019 to exclude specific defined seperation reason when all option is defined <Begin>  
 AND  (ISNULL(emp.sep_reason_code,'*') = ISNULL(dtl.separation_reason_code,'*') OR dtl.separation_reason_code IS NULL)  
 --Code added by Sharmila J for the defect id HST-6263 on 13-May-2019 <End>  
 AND (   
    dtl.emp_type_cd    IS NOT NULL   
   OR dtl.wlocn_code    IS NOT NULL      
   --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <starts>  
   OR (  
     (  
     @system_param_value = 'DEPT' AND dtl.legal_entity IS NOT NULL   
     )  
    OR  
     (  
     @system_param_value = 'EMPU'  
     )  
    )  
   /*  
   --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <starts>  
   OR dtl.legal_entity    IS NOT NULL  
   --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <end>  
   */  
   --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <ends>     
   OR dtl.dept_code    IS NOT NULL  
   OR dtl.gradeset_code   IS NOT NULL  
   OR dtl.grade_code    IS NOT NULL  
   OR dtl.posn_code    IS NOT NULL  
   OR dtl.nationality_code  IS NOT NULL  
   OR dtl.contract_type   IS NOT NULL  
   OR dtl.org_business_unit_code IS NOT NULL  
   OR dtl.separation_reason_code IS NOT NULL --Code added by Sharmila J for the defect id HST-6263 on 13-May-2019   
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   OR dtl.payset_code    IS NOT NULL   
   OR dtl.rota_schedule_code  IS NOT NULL   
   OR dtl.super_user_cmb1   IS NOT NULL    
   OR dtl.super_user_cmb2   IS NOT NULL    
   OR dtl.super_user_cmb3   IS NOT NULL    
   OR dtl.super_user_cmb4   IS NOT NULL    
   OR dtl.super_user_cmb5   IS NOT NULL    
   OR dtl.super_user_cmb6   IS NOT NULL    
   OR dtl.super_user_cmb7   IS NOT NULL    
   OR dtl.super_user_cmb8   IS NOT NULL    
   OR dtl.super_user_cmb9   IS NOT NULL    
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
  )  
 AND (   
   (  
    dtl.DOJ_effective_from IS NOT NULL   
    AND dtl.DOJ_effective_from = ( SELECT MAX(tmp.DOJ_effective_from)  
            FROM pyprc_cmn_rule_config_dtl tmp  
            WHERE tmp.master_ou   = dtl.master_ou  
            AND  tmp.rule_type   = dtl.rule_type  
            AND  tmp.pay_element_code = dtl.pay_element_code  
            AND  tmp.effective_from  = dtl.effective_from  
            AND  tmp.DOJ_effective_from <= emp.employment_start_date)  
   )  
  OR   
   (  
    ISNULL(dtl.DOJ_effective_from,'01/01/1900') = '01/01/1900'  
   )  
  )  
 AND (  
   (  
    dtl.service_month_from IS NULL  
   )  
  OR  
   (  
    emp.prog_service_slab = 'Y' AND dtl.service_month_from IS NOT NULL AND dtl.service_month_from <= emp.emp_service_in_mth  
   )  
  OR  
   (  
    emp.prog_service_slab = 'N' AND dtl.service_month_from IS NOT NULL   
     AND emp.emp_service_in_mth BETWEEN dtl.service_month_from AND ISNULL(dtl.service_month_to, emp.emp_service_in_mth)  
   )  
  )  
 --Code commented by Sharmila J for the defect id HST-6263 on 13-May-2019 <Begin>  
 --AND (  
 --  (  
 --   ISNULL(dtl.separation_reason_code,'*')  = '*'  
 --  )  
 -- OR  
 --  (  
 --   dtl.separation_reason_code IS NOT NULL AND dtl.separation_reason_code = emp.sep_reason_code  
 --  )  
 -- )  
 --Code commented by Sharmila J for the defect id HST-6263 on 13-May-2019 <End>  
 --Code added by Sharmila J on 30-July-2018 for the defect id HC-2302 <BEgin>  
 AND ( (   
    dtl.process_based_on = 'EACH'   
   )  
  OR  
   (  
    dtl.process_based_on = 'ADHC' AND  dtl.process_pay_period = @prcprd_cd  
   )  
  OR   
   (  
    (dtl.process_based_on = 'DOJN' OR dtl.process_based_on = 'REHR') AND emp.employment_start_date BETWEEN @pprd_from_date AND @pprd_to_date  
   )  
  OR  
   (  
    dtl.process_based_on = 'ANNV' AND (DATEADD(YEAR,DATEDIFF(YEAR,emp.employment_start_date,@pprd_to_date),emp.employment_start_date) BETWEEN @pprd_from_date AND @pprd_to_date)  
   )  
  )  
 AND ( (  
    @rule_type =  'SEV' AND dtl.age_factor IS NOT NULL AND DATEDIFF(MONTH,emp.separation_date,emp.date_of_birth) = dtl.age_factor  
   )  
   OR  
   (  
    @rule_type =  'SEV' AND dtl.age_factor IS NULL  
   )  
   OR  
   (  
    @rule_type <>  'SEV'  
   )  
  )  
 --Code added by Sharmila J on 30-July-2018 for the defect id HC-2302 <End>  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639 <Begin>  
 AND ( (@rule_type NOT IN ('SEV','SEA'))  
     
   OR   
   ( (@rule_type IN ('SEV','SEA'))  
    AND   
    ( ( dtl.min_salary_cap IS NULL )  
     OR  
     ( dtl.min_salary_cap IS NOT NULL  AND emp.min_sal_opt_amt >= dtl.min_salary_cap )  
    )  
   )  
  )  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639 <End>  
 --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
 AND ISNULL(dtl.payset_code,@payset_cd)  =  @payset_cd  
 AND ( (   
    dtl.rota_schedule_code IS NULL  
   )  
  OR  
   (  
    dtl.rota_schedule_code IS NOT NULL AND ISNULL(dtl.rota_schedule_code,'*') = ISNULL(emp.rota_schedule_code,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb1 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb1 IS NOT NULL AND ISNULL(dtl.super_user_cmb1,'*') = ISNULL(emp.super_user_cmb1,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb2 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb2 IS NOT NULL AND ISNULL(dtl.super_user_cmb2,'*') = ISNULL(emp.super_user_cmb2,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb3 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb3 IS NOT NULL AND ISNULL(dtl.super_user_cmb3,'*') = ISNULL(emp.super_user_cmb3,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb4 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb4 IS NOT NULL AND ISNULL(dtl.super_user_cmb4,'*') = ISNULL(emp.super_user_cmb4,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb5 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb5 IS NOT NULL AND ISNULL(dtl.super_user_cmb5,'*') = ISNULL(emp.super_user_cmb5,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb6 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb6 IS NOT NULL AND ISNULL(dtl.super_user_cmb6,'*') = ISNULL(emp.super_user_cmb6,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb7 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb7 IS NOT NULL AND ISNULL(dtl.super_user_cmb7,'*') = ISNULL(emp.super_user_cmb7,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb8 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb8 IS NOT NULL AND ISNULL(dtl.super_user_cmb8,'*') = ISNULL(emp.super_user_cmb8,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb9 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb9 IS NOT NULL AND ISNULL(dtl.super_user_cmb9,'*') = ISNULL(emp.super_user_cmb9,'*')  
   )  
  )  
   
 --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
  
 INSERT #EMP_PROCESS_TMP  
 (  
   master_ou_code,      rule_type,      pay_element_code,    payroll_code,  
   payset_code,      process_period_code,   process_number,     effective_from,  
   effective_to,      cut_off_from_date,    cut_off_to_date,    employment_ou,  
   employee_code,      assignment_no,     employee_type,     employment_start_date,  
   confirmation_date,     last_available_date,   wlocn_code,      dept_code,  
   gradeset_code,      grade_code,      position_code,     nationality_code,  
   org_business_unit_code,    separation_date,    sep_reason_code,    sep_reason_desc,  
   rota_schedule_code,     policy_effective_from,   policy_effective_to,   lop_considered,  
   prog_service_slab,     service_prd_based_on,   lop_days,      emp_service,  
   emp_service_rnd,     emp_service_in_mth,    DOJ_effective_from,    service_month_from,  
   service_month_to,     each_service_year,    min_service_days,    max_service_mth_cap,  
   accm_cd_qc,       salary_factor,     salary_uom,      no_of_mth_avg_salary,  
   basis_avg_salary,     avg_salary_mul_factor,   percent_of_salary,    local_avg_salary,  
   no_of_times_local_avg_salary,  salary_precedence,    max_salary_cap,     max_amount_cap,  
   emp_service_in_mth_cap,  
   flat_value,  
   local_avg_salary_amount,  
   accm_salary_factor,     spoc_value_type, -- code added by senthil arasu b on 04-Dec-2017  
   proration_method,     fixed_days  ,    paid_week_off  --code Added By Pradeep for proration methods on 29-jan-2018  
   ,service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
   ,proration_applicable_for,   date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   ,age_factor,      process_based_on,    payroll_calendar_code,   process_pay_period --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302    
   ,encash_lv_type,  
   encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201  
   ,min_salary_cap --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
   ,computation_for-- code added by palani for NPP Rule  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   ,hour_conv_freq,     super_user_cmb1,    super_user_cmb2,    super_user_cmb3,  
   super_user_cmb4,     super_user_cmb5,    super_user_cmb6,    super_user_cmb7,  
   super_user_cmb8,     super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
 )  
 SELECT emp.master_ou_code,     emp.rule_type,     emp.pay_element_code,   emp.payroll_code,  
   emp.payset_code,     emp.process_period_code,  emp.process_number,    emp.effective_from,  
   emp.effective_to,     emp.cut_off_from_date,   emp.cut_off_to_date,   emp.employment_ou,  
   emp.employee_code,     emp.assignment_no,    emp.employee_type,    emp.employment_start_date,  
   emp.confirmation_date,    emp.last_available_date,  emp.wlocn_code,     emp.dept_code,   
   emp.gradeset_code,     emp.grade_code,     emp.position_code,    emp.nationality_code,   
   emp.org_business_unit_code,   emp.separation_date,   emp.sep_reason_code,   emp.sep_reason_desc,  
   emp.rota_schedule_code,    emp.policy_effective_from,  emp.policy_effective_to,  emp.lop_considered,  
   emp.prog_service_slab,    emp.service_prd_based_on,  emp.lop_days,     emp.emp_service,  
   emp.emp_service_rnd,    emp.emp_service_in_mth,   dtl.DOJ_effective_from,   dtl.service_month_from,  
   dtl.service_month_to,    dtl.each_service_year,   dtl.min_service_days,   dtl.max_service_mth_cap,  
   dtl.accm_cd_qc,      dtl.salary_factor,    dtl.salary_uom,     dtl.no_of_mth_avg_salary,  
   dtl.basis_avg_salary,    dtl.avg_salary_mul_factor,  dtl.percent_of_salary,   dtl.local_avg_salary,  
   dtl.no_of_times_local_avg_salary, dtl.salary_precedence,   dtl.max_salary_cap,    dtl.max_amount_cap,       
   CASE WHEN emp.emp_service_in_mth < dtl.max_service_mth_cap OR dtl.max_service_mth_cap IS NULL   
     THEN emp.emp_service_in_mth ELSE dtl.max_service_mth_cap END,  
   dtl.flat_value,  
   dtl.local_avg_salary * ISNULL(no_of_times_local_avg_salary,1),  
   dtl.accm_salary_factor,    dtl.spoc_value_type, -- code added by senthil arasu b on 04-Dec-2017  
   dtl.proration_method,    dtl.fixed_days,     dtl.paid_week_off--code Added By Pradeep for proration methods on 29-jan-2018  
   ,emp.service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
   ,dtl.proration_applicable_for,  dtl.date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   ,dtl.age_factor,     dtl.process_based_on,   dtl.payroll_calendar_code,  dtl.process_pay_period --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302    
   ,dtl.encash_lv_type,  
   dtl.encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,emp.legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201   
   ,dtl.min_salary_cap --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
   ,dtl.computation_for -- code added by palani for NPP Rule   
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   ,dtl.hour_conv_freq,    dtl.super_user_cmb1,   dtl.super_user_cmb2,   dtl.super_user_cmb3,  
   dtl.super_user_cmb4,    dtl.super_user_cmb5,   dtl.super_user_cmb6,   dtl.super_user_cmb7,  
   dtl.super_user_cmb8,    dtl.super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
 FROM pyprc_cmn_rule_emp_info  emp,   
   pyprc_cmn_rule_config_dtl dtl WITH (NOLOCK)  
 WHERE emp.master_ou_code    = @payroll_ou_cd  
 AND  emp.rule_type     = @rule_type  
 AND  emp.pay_element_code   = @pay_elt_cd  
 AND  emp.payroll_code    = @payroll_cd  
 AND  emp.payset_code     = @payset_cd  
 AND  emp.process_period_code   = @prcprd_cd  
 AND  emp.process_number    = @process_number  
 AND  dtl.master_ou     = @payroll_ou_cd  
 AND  dtl.rule_type     = @rule_type  
 AND  dtl.pay_element_code   = @pay_elt_cd    
 AND  dtl.effective_from    = emp.policy_effective_from  
 AND  (ISNULL(emp.employee_type,'*') = ISNULL(dtl.emp_type_cd,'*') OR dtl.emp_type_cd IS NULL)  
 AND  (ISNULL(emp.wlocn_code,'*')  = ISNULL(dtl.wlocn_code,'*') OR dtl.wlocn_code IS NULL)   
 --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <starts>  
 AND (  
   (  
   @system_param_value = 'DEPT' AND (ISNULL(emp.legal_entity,'*') = ISNULL(dtl.legal_entity,'*') OR dtl.legal_entity IS NULL)  
   )  
  OR  
   (  
   @system_param_value = 'EMPU'  
   )  
  )  
 /*  
 --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <starts>  
 AND (ISNULL(emp.legal_entity,'*') = ISNULL(dtl.legal_entity,'*') OR dtl.legal_entity IS NULL)  
 --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <end>  
 */  
 --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <ends>   
 AND  (ISNULL(emp.dept_code,'*')  = ISNULL(dtl.dept_code,'*') OR dtl.dept_code IS NULL)  
 AND  (ISNULL(emp.gradeset_code,'*') = ISNULL(dtl.gradeset_code,'*') OR dtl.gradeset_code IS NULL)  
 AND  (ISNULL(emp.grade_code,'*')  = ISNULL(dtl.grade_code,'*') OR dtl.grade_code IS NULL)  
 AND  (ISNULL(emp.position_code,'*') = ISNULL(dtl.posn_code,'*') OR dtl.posn_code IS NULL)  
 AND  (ISNULL(emp.nationality_code,'*')= ISNULL(dtl.nationality_code,'*') OR dtl.nationality_code IS NULL)  
 AND  (ISNULL(emp.contract_type,'*') = ISNULL(dtl.contract_type,'*') OR dtl.contract_type IS NULL)  
 AND  (ISNULL(emp.org_business_unit_code,'*') = ISNULL(dtl.org_business_unit_code,'*') OR dtl.org_business_unit_code IS NULL)  
 --Code added by Sharmila J for the defect id HST-6263 on 13-May-2019 <Begin>  
 AND  (ISNULL(emp.sep_reason_code,'*') = ISNULL(dtl.separation_reason_code,'*') OR dtl.separation_reason_code IS NULL)  
 --Code added by Sharmila J for the defect id HST-6263 on 13-May-2019 <End>  
 AND (   
    dtl.emp_type_cd    IS NULL   
   AND dtl.wlocn_code    IS NULL     
   --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <starts>  
   AND (  
     (  
     @system_param_value = 'DEPT' AND dtl.legal_entity IS NULL   
     )  
    OR  
     (  
     @system_param_value = 'EMPU'  
     )  
    )  
   /*  
   --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <starts>  
   AND dtl.legal_entity  IS NULL  
   --code added by Keerthana S on Mar-25-2019 for defect id HST-5201 <end>   
   */  
   --code added and commented by Keerthana S on 08-July-2019 for defect id HST-5201 <ends>   
   AND dtl.dept_code    IS NULL  
   AND dtl.gradeset_code   IS NULL  
   AND dtl.grade_code    IS NULL  
   AND dtl.posn_code    IS NULL  
   AND dtl.nationality_code  IS NULL  
   AND dtl.contract_type   IS NULL  
   AND dtl.org_business_unit_code IS NULL  
   AND dtl.separation_reason_code IS NULL--Code added by Sharmila J for the defect id HST-6263 on 13-May-2019  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   AND dtl.payset_code    IS NULL   
   AND dtl.rota_schedule_code  IS NULL   
   AND dtl.super_user_cmb1   IS NULL    
   AND dtl.super_user_cmb2   IS NULL    
   AND dtl.super_user_cmb3   IS NULL    
   AND dtl.super_user_cmb4   IS NULL    
   AND dtl.super_user_cmb5   IS NULL    
   AND dtl.super_user_cmb6   IS NULL    
   AND dtl.super_user_cmb7   IS NULL    
   AND dtl.super_user_cmb8   IS NULL    
   AND dtl.super_user_cmb9   IS NULL    
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
  )  
 AND (   
   (  
    dtl.DOJ_effective_from IS NOT NULL   
    AND dtl.DOJ_effective_from = ( SELECT MAX(tmp.DOJ_effective_from)  
            FROM pyprc_cmn_rule_config_dtl tmp  
            WHERE tmp.master_ou   = dtl.master_ou  
            AND  tmp.rule_type   = dtl.rule_type  
            AND  tmp.pay_element_code = dtl.pay_element_code  
            AND  tmp.effective_from  = dtl.effective_from  
            AND  tmp.DOJ_effective_from <= emp.employment_start_date)  
   )  
  OR   
   (  
    ISNULL(dtl.DOJ_effective_from,'01/01/1900') = '01/01/1900'  
   )  
  )  
 AND (  
   (  
    dtl.service_month_from IS NULL  
   )  
  OR  
   (  
    emp.prog_service_slab = 'Y' AND dtl.service_month_from IS NOT NULL AND dtl.service_month_from <= emp.emp_service_in_mth  
   )  
  OR  
   (  
    emp.prog_service_slab = 'N' AND dtl.service_month_from IS NOT NULL   
     AND emp.emp_service_in_mth BETWEEN dtl.service_month_from AND ISNULL(dtl.service_month_to, emp.emp_service_in_mth)  
   )  
  )  
 --Code commented by Sharmila J for the defect id HST-6263 on 13-May-2019 <Begin>  
 --AND (  
 --  (  
 --   ISNULL(dtl.separation_reason_code,'*')  = '*'  
 --  )  
 -- OR  
 --  (  
 --   dtl.separation_reason_code IS NOT NULL AND dtl.separation_reason_code = emp.sep_reason_code  
 --  )  
 -- )  
 --Code commented by Sharmila J for the defect id HST-6263 on 13-May-2019 <End>  
 --Code added by Sharmila J on 30-July-2018 for the defect id HC-2302 <BEgin>  
 AND ( (   
    dtl.process_based_on = 'EACH'   
   )  
  OR  
   (  
    dtl.process_based_on = 'ADHC' AND  dtl.process_pay_period = @prcprd_cd  
   )  
  OR   
   (  
    (dtl.process_based_on = 'DOJN' OR dtl.process_based_on = 'REHR') AND emp.employment_start_date BETWEEN @pprd_from_date AND @pprd_to_date  
   )  
  OR  
   (  
    dtl.process_based_on = 'ANNV' AND (DATEADD(YEAR,DATEDIFF(YEAR,emp.employment_start_date,@pprd_to_date),emp.employment_start_date) BETWEEN @pprd_from_date AND @pprd_to_date)  
   )  
  )  
 AND ( (  
    @rule_type =  'SEV' AND dtl.age_factor IS NOT NULL AND DATEDIFF(MONTH,emp.separation_date,emp.date_of_birth) = dtl.age_factor  
   )  
   OR  
   (  
    @rule_type =  'SEV' AND dtl.age_factor IS NULL  
   )  
   OR  
   (  
    @rule_type <>  'SEV'  
   )  
  )  
 --Code added by Sharmila J on 30-July-2018 for the defect id HC-2302 <End>  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639 <Begin>  
 AND ( ( @rule_type NOT IN ('SEV','SEA'))  
     
   OR   
   ( ( @rule_type IN ('SEV','SEA') )  
    AND   
    ( ( dtl.min_salary_cap IS NULL )  
     OR  
     ( dtl.min_salary_cap IS NOT NULL AND emp.min_sal_opt_amt >= dtl.min_salary_cap )  
    )  
   )  
  )  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639 <End>  
 --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
 AND ISNULL(dtl.payset_code,@payset_cd)  =  @payset_cd  
 AND ( (   
    dtl.rota_schedule_code IS NULL  
   )  
  OR  
   (  
    dtl.rota_schedule_code IS NOT NULL AND ISNULL(dtl.rota_schedule_code,'*') = ISNULL(emp.rota_schedule_code,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb1 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb1 IS NOT NULL AND ISNULL(dtl.super_user_cmb1,'*') = ISNULL(emp.super_user_cmb1,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb2 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb2 IS NOT NULL AND ISNULL(dtl.super_user_cmb2,'*') = ISNULL(emp.super_user_cmb2,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb3 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb3 IS NOT NULL AND ISNULL(dtl.super_user_cmb3,'*') = ISNULL(emp.super_user_cmb3,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb4 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb4 IS NOT NULL AND ISNULL(dtl.super_user_cmb4,'*') = ISNULL(emp.super_user_cmb4,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb5 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb5 IS NOT NULL AND ISNULL(dtl.super_user_cmb5,'*') = ISNULL(emp.super_user_cmb5,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb6 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb6 IS NOT NULL AND ISNULL(dtl.super_user_cmb6,'*') = ISNULL(emp.super_user_cmb6,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb7 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb7 IS NOT NULL AND ISNULL(dtl.super_user_cmb7,'*') = ISNULL(emp.super_user_cmb7,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb8 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb8 IS NOT NULL AND ISNULL(dtl.super_user_cmb8,'*') = ISNULL(emp.super_user_cmb8,'*')  
   )  
  )  
 AND ( (   
    dtl.super_user_cmb9 IS NULL  
   )  
  OR  
   (  
    dtl.super_user_cmb9 IS NOT NULL AND ISNULL(dtl.super_user_cmb9,'*') = ISNULL(emp.super_user_cmb9,'*')  
   )  
  )  
 --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
 AND NOT EXISTS (SELECT 'X'  
     FROM #EMP_PROCESS_TMP tmp  
     WHERE tmp.master_ou_code   = emp.master_ou_code  
     AND  tmp.rule_type    = emp.rule_type  
     AND  tmp.pay_element_code  = emp.pay_element_code   
     AND  tmp.payroll_code   = emp.payroll_code  
     AND  tmp.payset_code    = emp.payset_code  
     AND  tmp.process_period_code  = emp.process_period_code  
     AND  tmp.process_number   = emp.process_number  
     AND  tmp.employment_ou   = emp.employment_ou   
     AND  tmp.employee_code   = emp.employee_code  
     AND  tmp.assignment_no   = emp.assignment_no  
     AND  tmp.policy_effective_from = emp.policy_effective_from)  
  
  
  
--select @pprd_to_date='2021-12-31'--HCLT  
     
--select 'test',@payroll_type'@payroll_type'  
--select * from pyprc_pre_payroll  
--select * from pyprc_cmn_rule_emp_info  
--select * from #EMP_PROCESS_TMP  
--return  
  IF @payroll_type = 'R'  AND  DATENAME(mm,@pprd_to_date)='DECEMBER'-- code added for HCLT to give AWS at every december  
 begin  
 INSERT pyprc_cmn_rule_emp_process_tmp  
 (  
   row_num,  
   master_ou_code,      rule_type,      pay_element_code,    payroll_code,  
   payset_code,      process_period_code,   process_number,     effective_from,  
   effective_to,      cut_off_from_date,    cut_off_to_date,    employment_ou,  
   employee_code,      assignment_no,     employee_type,     employment_start_date,  
   confirmation_date,     last_available_date,   wlocn_code,      dept_code,   
   gradeset_code,      grade_code,      position_code,     nationality_code,   
   org_business_unit_code,    separation_date,    sep_reason_code,    sep_reason_desc,  
   rota_schedule_code,     policy_effective_from,   policy_effective_to,   lop_considered,        
   prog_service_slab,     service_prd_based_on,   lop_days,      emp_service,  
   emp_service_rnd,     emp_service_in_mth,    DOJ_effective_from,    service_month_from,  
   service_month_to,     each_service_year,    min_service_days,    max_service_mth_cap,     
   accm_cd_qc,       salary_factor,     salary_uom,      no_of_mth_avg_salary,     
   basis_avg_salary,     avg_salary_mul_factor,   percent_of_salary,    local_avg_salary,      
   no_of_times_local_avg_salary,  salary_precedence,    max_salary_cap,     max_amount_cap,         
   emp_service_in_mth_cap,  
   flat_value,  
   local_avg_salary_amount,  
   accm_salary_factor,     spoc_value_type, -- code added by senthil arasu b on 04-Dec-2017  
   proration_method,     fixed_days ,     paid_week_off  --code Added By Pradeep for proration methods on 29-jan-2018  
   ,service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
   ,proration_applicable_for,   date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <Begin>  
   ,age_factor,      process_based_on,    payroll_calendar_code,   process_pay_period   
   ,date_of_birth     
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <End>  
   ,min_salary_cap --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
   ,encash_lv_type,  
   encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201  
   ,computation_for     ,final_notic_per_sort_fall   ,pay_days_in_leiu_not_per  ,adju_pay_days_leiu_notc-- code added by palani for npp rule  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   ,hour_conv_freq,    super_user_cmb1,   super_user_cmb2,   super_user_cmb3,  
   super_user_cmb4,    super_user_cmb5,   super_user_cmb6,   super_user_cmb7,  
   super_user_cmb8,    super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
 )  
 SELECT ROW_NUMBER() OVER (ORDER BY master_ou_code) row_num,  
   master_ou_code,      rule_type,      pay_element_code,    payroll_code,  
   payset_code,      process_period_code,   process_number,     effective_from,  
   effective_to,      cut_off_from_date,    cut_off_to_date,    employment_ou,  
   employee_code,      assignment_no,     employee_type,     employment_start_date,  
   confirmation_date,     last_available_date,   wlocn_code,      dept_code,   
   gradeset_code,      grade_code,      position_code,     nationality_code,   
   org_business_unit_code,    separation_date,    sep_reason_code,    sep_reason_desc,  
   rota_schedule_code,     policy_effective_from,   policy_effective_to,   lop_considered,        
   prog_service_slab,     service_prd_based_on,   lop_days,      emp_service,  
   emp_service_rnd,     emp_service_in_mth,    DOJ_effective_from,    service_month_from,  
   service_month_to,     each_service_year,    min_service_days,    max_service_mth_cap,     
   accm_cd_qc,         
   case when @rule_type = 'NPP' then '1' else salary_factor end,    
   case when @rule_type = 'NPP' then 'D' else salary_uom end,       
   no_of_mth_avg_salary,     
   basis_avg_salary,     avg_salary_mul_factor,   percent_of_salary,    local_avg_salary,      
   no_of_times_local_avg_salary,  salary_precedence,    max_salary_cap,     max_amount_cap,         
   emp_service_in_mth_cap,  
   flat_value,  
   local_avg_salary_amount,  
   accm_salary_factor,     spoc_value_type, -- code added by senthil arasu b on 04-Dec-2017  
   proration_method,     fixed_days,      paid_week_off--code Added By Pradeep for proration methods on 29-jan-2018  
   ,service_ref_date -- code added by senthil arasu b on 06-Mar-2018 for defect id HST-2991  
   --Code added and commented by keerthana S on May-24-2019 for the defect id HST-6038<starts>  
   ,CASE WHEN @rule_type='SBP' THEN ISNULL(proration_applicable_for,'N') ELSE proration_applicable_for END, date_join_based_on  
   --,proration_applicable_for,   date_join_based_on --Code added by Sharmila J on 11-July-2018 for the defect id HC-2302   
   --Code added and commented by keerthana S on May-24-2019 for the defect id HST-6038<end>  
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <Begin>   
   ,age_factor,      process_based_on,    payroll_calendar_code,   process_pay_period   
   ,date_of_birth  
   --Code added by Sharmila J on 01-Aug-2018 for the defect id HC-2302 <End>  
   ,min_salary_cap --Code added by Sharmila J on 04-Sep-2018 for the defect id HST-6639   
   ,encash_lv_type,  
   encash_lv_units_max_cap/*Code added by Shanmugam G on 11_Feb_2019 columns (Leave_type, max_leave_encash_cap) for Leave Encashment HST-5715*/  
   ,legal_entity --code added by Keerthana S on Mar-25-2019 for defect id HST-5201   
   ,computation_for     ,final_notic_per_sort_fall   ,pay_days_in_leiu_not_per  ,adju_pay_days_leiu_notc -- code added by palani for npp rule  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <Begin>  
   ,hour_conv_freq,     super_user_cmb1,    super_user_cmb2,    super_user_cmb3,  
   super_user_cmb4,     super_user_cmb5,    super_user_cmb6,    super_user_cmb7,  
   super_user_cmb8,     super_user_cmb9  
   --Code added by Sharmila J on 18-Nov-2019 for the defect id  HST-7024 PE-LOP enhancements <End>  
 FROM #EMP_PROCESS_TMP  
 ORDER BY employee_code, service_month_from  
end  
 /*   
 INSERT pyprc_cmn_rule_emp_process_tmp  
 (  
   row_num,  
   master_ou_code,      rule_type,      pay_element_code,    payroll_code,  
   payset_code,      process_period_code,   process_number,     effective_from,  
   effective_to,      cut_off_from_date,    cut_off_to_date,    employment_ou,  
   employee_code,      assignment_no,     employee_type,     employment_start_date,  
   confirmation_date,     last_available_date,   wlocn_code,      dept_code,   
   -- code added by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <begins>  
   gradeset_code,      grade_code,      position_code,     nationality_code,   
   --gradeset_code,     grade_code,      position_code,     citizenship_code,   
   -- code added by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <ends>  
   org_business_unit_code,    separation_date,    sep_reason_code,    sep_reason_desc,  
   rota_schedule_code,     policy_effective_from,   policy_effective_to,   lop_considered,        
   prog_service_slab,     service_prd_based_on,   lop_days,      emp_service,  
   emp_service_rnd,     emp_service_in_mth,    DOJ_effective_from,    service_month_from,  
   service_month_to,     each_service_year,    min_service_days,    max_service_mth_cap,     
   accm_cd_qc,       salary_factor,     salary_uom,      no_of_mth_avg_salary,     
   basis_avg_salary,     avg_salary_mul_factor,   percent_of_salary,    local_avg_salary,      
   no_of_times_local_avg_salary,  salary_precedence,    max_salary_cap,     max_amount_cap,         
   emp_service_in_mth_cap,  
   flat_value,  
   local_avg_salary_amount  
 )  
 SELECT ROW_NUMBER() OVER (ORDER BY emp.master_ou_code) row_num,  
   emp.master_ou_code,     emp.rule_type,     emp.pay_element_code,   emp.payroll_code,  
   emp.payset_code,     emp.process_period_code,  emp.process_number,    emp.effective_from,  
   emp.effective_to,     emp.cut_off_from_date,   emp.cut_off_to_date,   emp.employment_ou,  
   emp.employee_code,     emp.assignment_no,    emp.employee_type,    emp.employment_start_date,  
   emp.confirmation_date,    emp.last_available_date,  emp.wlocn_code,     emp.dept_code,   
   emp.gradeset_code,     emp.grade_code,     emp.position_code,    emp.citizenship_code,   
   emp.org_business_unit_code,   emp.separation_date,   emp.sep_reason_code,   emp.sep_reason_desc,  
   emp.rota_schedule_code,    emp.policy_effective_from,  emp.policy_effective_to,  emp.lop_considered,  
   emp.prog_service_slab,    emp.service_prd_based_on,  emp.lop_days,     emp.emp_service,  
   emp.emp_service_rnd,    emp.emp_service_in_mth,   dtl.DOJ_effective_from,   dtl.service_month_from,  
   dtl.service_month_to,    dtl.each_service_year,   dtl.min_service_days,   dtl.max_service_mth_cap,  
   dtl.accm_cd_qc,      dtl.salary_factor,    dtl.salary_uom,     dtl.no_of_mth_avg_salary,  
   dtl.basis_avg_salary,    dtl.avg_salary_mul_factor,  dtl.percent_of_salary,   dtl.local_avg_salary,  
   dtl.no_of_times_local_avg_salary, dtl.salary_precedence,   dtl.max_salary_cap,    dtl.max_amount_cap,       
   CASE WHEN emp.emp_service_in_mth < dtl.max_service_mth_cap OR dtl.max_service_mth_cap IS NULL   
     THEN emp.emp_service_in_mth ELSE dtl.max_service_mth_cap END,  
   dtl.flat_value,  
   dtl.local_avg_salary * ISNULL(no_of_times_local_avg_salary,1)  
 FROM pyprc_cmn_rule_emp_info  emp,   
   pyprc_cmn_rule_config_dtl dtl WITH (NOLOCK)  
 WHERE emp.master_ou_code    = @payroll_ou_cd  
 AND  emp.rule_type     = @rule_type  
 AND  emp.pay_element_code   = @pay_elt_cd  
 AND  emp.payroll_code    = @payroll_cd  
 AND  emp.payset_code     = @payset_cd  
 AND  emp.process_period_code   = @prcprd_cd  
 AND  emp.process_number    = @process_number  
 AND  dtl.master_ou     = @payroll_ou_cd  
 AND  dtl.rule_type     = @rule_type  
 AND  dtl.pay_element_code   = @pay_elt_cd    
 AND  dtl.effective_from    = emp.policy_effective_from  
 AND  ISNULL(emp.employee_type,'*') = CASE ISNULL(dtl.emp_type_cd,'ALL')  WHEN 'ALL' THEN ISNULL(emp.employee_type,'*')  ELSE dtl.emp_type_cd  END  
 AND  ISNULL(emp.wlocn_code,'*')  = CASE ISNULL(dtl.wlocn_code,'ALL')   WHEN 'ALL' THEN ISNULL(emp.wlocn_code,'*')   ELSE dtl.wlocn_code   END  
 AND  ISNULL(emp.dept_code,'*')  = CASE ISNULL(dtl.dept_code,'ALL')   WHEN 'ALL' THEN ISNULL(emp.dept_code,'*')   ELSE dtl.dept_code   END  
 AND  ISNULL(emp.gradeset_code,'*') = CASE ISNULL(dtl.gradeset_code,'ALL')  WHEN 'ALL' THEN ISNULL(emp.gradeset_code,'*')  ELSE dtl.gradeset_code  END  
 AND  ISNULL(emp.grade_code,'*')  = CASE ISNULL(dtl.grade_code,'ALL')   WHEN 'ALL' THEN ISNULL(emp.grade_code,'*')   ELSE dtl.grade_code   END  
 AND  ISNULL(emp.position_code,'*') = CASE ISNULL(dtl.posn_code,'ALL')   WHEN 'ALL' THEN ISNULL(emp.position_code,'*')  ELSE dtl.posn_code   END  
 AND  ISNULL(emp.citizenship_code,'*')= CASE ISNULL(dtl.citizenship_code,'ALL') WHEN 'ALL' THEN ISNULL(emp.citizenship_code,'*') ELSE dtl.citizenship_code END  
 AND  ISNULL(emp.contract_type,'*') = CASE ISNULL(dtl.contract_type,'ALL')  WHEN 'ALL' THEN ISNULL(emp.contract_type,'*')  ELSE dtl.contract_type  END  
 AND  ISNULL(emp.org_business_unit_code,'*') = CASE ISNULL(dtl.org_business_unit_code,'ALL') WHEN 'ALL' THEN ISNULL(emp.org_business_unit_code,'*') ELSE dtl.org_business_unit_code END  
 AND (   
   (  
    dtl.DOJ_effective_from IS NOT NULL   
    AND dtl.DOJ_effective_from = ( SELECT MAX(tmp.DOJ_effective_from)  
            FROM pyprc_cmn_rule_config_dtl tmp  
            WHERE tmp.master_ou   = dtl.master_ou       
            AND  tmp.rule_type   = dtl.rule_type  
            AND  tmp.pay_element_code = dtl.pay_element_code  
            AND  tmp.effective_from  = dtl.effective_from  
            AND  tmp.DOJ_effective_from <= emp.employment_start_date)  
   )  
  OR   
   (  
    ISNULL(dtl.DOJ_effective_from,'01/01/1900') = '01/01/1900'  
   )  
  )  
 AND (  
   (  
    ISNULL(dtl.service_month_from,0.00) = 0.00  
   )  
  OR  
   (  
    emp.prog_service_slab = 'Y' AND dtl.service_month_from IS NOT NULL AND dtl.service_month_from <= emp.emp_service_in_mth  
   )  
  OR  
   (  
    emp.prog_service_slab = 'N' AND dtl.service_month_from IS NOT NULL   
     AND emp.emp_service_in_mth BETWEEN dtl.service_month_from AND ISNULL(dtl.service_month_to, emp.emp_service_in_mth)  
   )  
  )  
 AND (  
   (  
    ISNULL(dtl.separation_reason_code,'*')  = '*'  
   )  
  OR  
   (  
    dtl.separation_reason_code IS NOT NULL AND dtl.separation_reason_code = emp.sep_reason_code  
   )  
  )  
 */  
 -- code added and commented by senthil arasu b on 12-Oct-2017 for defect id HST-2339 <ends>  
   
 --Code added by Sharmila J on 04-Jun-2020 for the defect id SMH-385 <Begin>  
 IF @rule_type IN ('SEV','SEA')  
 BEGIN  
 --Code added by Sharmila J on 04-Jun-2020 for the defect id SMH-385 <End>  
 -- to get employee's actual service years in each service slab,   
 -- actual service year will be derived with current month slab "service month to" and prevsious slab "service month to"  
 UPDATE tmp1  
 SET  prev_serv_month_to  =  (SELECT MAX(tmp2.service_month_to)      
          FROM pyprc_cmn_rule_emp_process_tmp tmp2  
          WHERE tmp2.master_ou_code  = tmp1.master_ou_code  
          AND  tmp2.process_number  = tmp1.process_number  
          AND  tmp2.employment_ou  = tmp1.employment_ou    
          AND  tmp2.employee_code  = tmp1.employee_code  
          AND  tmp2.service_month_to < tmp1.service_month_to)  
 FROM pyprc_cmn_rule_emp_process_tmp tmp1  
  
 -- to update maximum service months in each service slab when progressive service slab flag is checked  
 UPDATE pyprc_cmn_rule_emp_process_tmp  
 SET  months_in_each_slab = CASE WHEN prog_service_slab = 'Y' THEN   
          (  
           CASE WHEN ISNULL(service_month_to, 9999) <= emp_service_in_mth_cap THEN   
            ISNULL(service_month_to, 9999) - ISNULL(prev_serv_month_to,0.00)   
            --ISNULL(service_month_to, emp_service_in_mth_cap)     
           ELSE  
            (emp_service_in_mth_cap - CONVERT(INT,service_month_from))   
           END  
          )  
         ELSE   
          emp_service_in_mth_cap   
         END  
  
 -- to update employee service when value provied for accumulated salary facotr   
 UPDATE pyprc_cmn_rule_emp_process_tmp  
 SET  emp_service   = ((ISNULL(emp_service_in_mth_cap,0.00) - ISNULL(Service_Month_From,0.00)) / 12.0)  
 WHERE prog_service_slab = 'N'  
 AND  each_service_year = 'Y'  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HC-2480 <Begin>   
 AND  NULLIF(accm_salary_factor,0.00) IS NOT NULL  
 --AND  accm_salary_factor IS NOT NULL  
 --Code added by Sharmila J on 04-Sep-2018 for the defect id HC-2480 <End>   
  
 -- to update maximum service years in each service slab when progressive service slab flag is checked  
 UPDATE pyprc_cmn_rule_emp_process_tmp  
 SET  emp_service   = (ISNULL(months_in_each_slab, 0.00) / 12.0)   
 WHERE prog_service_slab = 'Y'   
  
 END --Code added by Sharmila J on 04-Jun-2020 for the defect id SMH-385  
  
 SET NOCOUNT OFF  
  
END  
  
  
  
  
  
  
  