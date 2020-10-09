/*Load data*/
PROC IMPORT OUT= WORK.kickstarter
            DATAFILE= 'C:\Users\exn121330\HW 1 Data\DATA.csv'
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
proc print data=WORK.kickstarter;
 title1 'Kickstarter Projects';
PROC CONTENTS;
RUN;

/*Analysis*/

/*General Statistical Analysis and Percents*/
proc sql;
create table scsl_fld_cncl_prjcts as
select * 
from work.kickstarter
where state = 'successful' OR state = 'failed' OR state = 'canceled';

proc means data= scsl_fld_cncl_prjcts n mean median stddev min max p25 p75 maxdec= 2;
 var USD_pledged_real USD_goal_real;
 title 'Summary Statistics';
run;

proc tabulate data= scsl_fld_cncl_prjcts;
 class Main_Category State; 
 var USD_pledged_real USD_goal_real; 
 table Main_Category,State*(USD_pledged_real USD_goal_real)*(N Mean Median StdDev Min Max p25 p75); 
 title 'Summary Statistics';
run;

proc sql;
create table categories_state as
select Main_Category, COUNT(Main_Category) as Projects, State
from scsl_fld_cncl_prjcts
group by Main_Category, State;

/*Pledged Real Amounts*/
proc sql;
create table categories_pledged as
select Main_Category, SUM(USD_pledged_real) as Total_Pledged_Real, State
from scsl_fld_cncl_prjcts
group by Main_Category, State;

proc sql;
create table pledged_success as 
select Main_Category, Total_Pledged_Real, State
from categories_pledged
where state = 'successful';

data pledged_success_fee;
 set pledged_suc_sort;
 Fee_on_Funds_Raised = Total_Pledged_Real * .05;
run;

/*Successful projects*/ 
proc sql;
create table successful_projects as
select *
from work.kickstarter
where state= 'successful';

proc sql;
create table successful_projects_count as
select COUNT(*)
from work.kickstarter
where state= 'successful';

proc means data= successful_projects n mean median stddev min max p25 p75 maxdec= 2;
 var USD_pledged_real USD_goal_real;
 title 'Summary Statistics of Successful Projects';
run;

/*Failed projects*/
proc sql;
create table failed_projects as
select *
from work.kickstarter
where state= 'failed';

proc sql;
create table failed_projects_count as
select COUNT(*)
from work.kickstarter
where state= 'failed';

proc means data= failed_projects n mean median stddev min max p25 p75 maxdec= 2;
 var USD_pledged_real USD_goal_real;
 title 'Summary Statistics of Failed Projects';
run;


/*Canceled projects*/
proc sql;
create table canceled_projects as
select *
from work.kickstarter
where state= 'canceled';

proc sql;
create table canceled_projects_count as
select COUNT(*)
from work.kickstarter
where state= 'canceled';

proc means data= canceled_projects n mean median stddev min max p25 p75 maxdec= 2;
 var USD_pledged_real USD_goal_real;
 title 'Summary Statistics of Canceled Projects';
run;

/*Year Variable and 2014-2018 Data Sets*/
data prjct_yrs;
set scsl_fld_cncl_prjcts;
Deadline_Year = year(deadline);
run;

proc sql;
create table scsl_fld_cncl_prjcts_yrs as
select * 
from prjct_yrs
where Deadline_Year = 2014 OR Deadline_Year = 2015 OR Deadline_Year = 2016 OR Deadline_Year = 2017 OR Deadline_Year = 2018;

/*Historgrams and Normality*/
proc sgplot data= scsl_fld_cncl_prjcts_yrs;
 histogram usd_pledged_real / binstart = 0 binwidth = 200000 ; 
 density usd_pledged_real / type = kernel; 
 density usd_pledged_real; 
 title 'USD Pledged Real';
run;

proc sgplot data= scsl_fld_cncl_prjcts_yrs;
 histogram usd_goal_real / binstart = 0 binwidth = 1000000 ; 
 density usd_goal_real / type = kernel; 
 density usd_goal_real; 
 title 'USD Goal Real';
run;

data usd_project_success;
set scsl_fld_cncl_prjcts_yrs;
Pledged_Goal_Real_Diff = usd_pledged_real - usd_goal_real;
run; 

proc sgplot data= usd_project_success;
 histogram Pledged_Goal_Real_Diff ; 
 density Pledged_Goal_Real_Diff / type = kernel; 
 density Pledged_Goal_Real_Diff; 
 title 'USD Goal Real';
run;

/*Tests for Normality*/
proc univariate normal plot data= usd_project_success alpha=0.05; 
 var usd_pledged_real;
 title 'USD Pledged Real Normality Test';
run;

proc univariate normal plot data= usd_project_success alpha=0.05; 
 var usd_goal_real;
 title 'USD Pledged Real Normality Test';
run;

proc univariate normal plot data= usd_project_success alpha=0.05; 
 var Pledged_Goal_Real_Diff;
 title 'USD Pledged Real Normality Test';
run;

/*Correlation and Causation*/
data new_launch;
   set usd_project_success;  
   launch_date = datepart(launched);
   format launch_date mmddyy10.; 
run;

data l_d_duration;
   set new_launch;
   date1=launch_date;
   date2=deadline;
   days=intck('day', date1, date2);
   put days=;
run;

proc corr data=l_d_duration spearman;
 var usd_goal_real usd_pledged_real backers days;
 title 'Study Spearman Correlation Test';
run;

/*Duration averages*/
proc sql;
create table prjcts_duration as
select State, COUNT(ID) as Number_of_Projects, SUM(days) as Total_Days_Btwn_Launch_Deadline, AVG(days) as Average_Duration
from l_d_duration
group by State;

/*Failed and Successful Comparison and T-test*/
proc sort data= l_d_duration; 
 by Deadline_Year state;
run;

proc sql;
create table fail_success_pjcts as
select *
from l_d_duration
where state = 'failed' OR state = 'successful';

proc means data= fail_success_pjcts mean maxdec= 2 noprint;
 by Deadline_Year state;
 var usd_pledged_real usd_goal_real;
 output out=means2 
  mean= AvgPledgedReal AvgGoalReal;
run;

proc sgpanel  data= means2;
 panelby state;
 series x=Deadline_Year y=AvgPledgedReal;
 series x=Deadline_Year y=AvgGoalReal;
 title 'Average USD Goal Real and USD Pledged Real for Failed and Successful Projects Over Time';
run;

proc ttest data=means2 sides=L alpha=0.05;
 class state;
 var AvgGoalReal;
run;
