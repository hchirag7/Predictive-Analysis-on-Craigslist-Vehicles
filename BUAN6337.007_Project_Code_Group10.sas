*********************************************************************************************************************;
dm 'clear log'; dm 'clear output';  /* clear log and output */

/* Set File/Path */

libname proj "E:\Users\aks171430\Documents\My SAS Files\Project_EDA";
title 'Project';

*******************************************************************************************************************************;												
											/* Load Dataset */
*******************************************************************************************************************************;


proc import out= cars 
datafile= "E:\Users\aks171430\Documents\My SAS Files\Project_EDA\vehicles.csv" 
dbms=csv replace;
getnames = yes; 
run;

/*An import error may occur for lat and long, however, it’s redundant and will be dropped going further so, 
it’s not an issue */

/* View DataSet Content */
proc contents data=cars;
title 'Cars Dataset';
run;

/* View Top 5 Records*/
proc print data=cars(obs=5);
run;

*******************************************************************************************************************************;												
											/* Data Cleaning */
*******************************************************************************************************************************;

/* Dropping Irrelevant Columns */
data cars; 
set cars; 
drop url image_url region_url county lat long state region id description model size vin manufacturer ; /*title_status*/ 
run; 

ods graphics / imagemap=on;

proc univariate data=cars normal noprint;
	var price year odometer;
	histogram price year odometer / normal kernel;
	inset n mean std / position = ne;
	title "Distribution Analysis";
run;

/* Removing outliers for Price, Odometer and Year*/

data cars;
set cars;
if price <500 then delete;
if price> 100000 then delete;
if odometer > 300000 then delete;
if year < 1960 then delete;
if year > 2020 then delete;
run;


/* Identify Missing Records */
proc format;
value $missfmt ' ' = 'Empty Records' other = 'Non Empty Records';
value missfmt . = 'Empty Records' other = 'Non Empty Records';
run;

proc freq data=cars;
format _CHAR_ $missfmt.; 
tables _CHAR_ / missing missprint nocum;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum;
run;

/* Dropping records */

data cars;
set cars;
if condition=' ' then delete;
if cylinders=' ' then delete;
if paint_color=' ' then delete;
run;

/*Checking for empty records after dropping records*/

proc freq data=cars;
format _CHAR_ $missfmt.; 
tables _CHAR_ / missing missprint nocum;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum;
run;


/*Imputing Values*/
proc stdize data=cars out=cars 
      oprefix=Orig_         /* prefix for original variables */
      reponly               /* only replace; do not standardize */
      method=MEAN;          /* or MEDIAN, MINIMUM, MIDRANGE, etc. */
   var odometer;              /* you can list multiple variables to impute */
run;

data cars;
set cars;
odometer = round(odometer);
drop Orig_odometer;
run;

/* To determine mode values*/

proc freq data=cars;
tables drive fuel transmission type/missing;
run;

/*  fuel - gas
	type - sedan
	transmission - automatic
	drive - 4wd
*/

/* Imputing Categorical Variables */

data cars;
set cars;
if fuel=' ' then fuel = 'gas';
if type=' ' then type = 'sedan';
if transmission=' ' then transmission = 'automatic';
if drive=' ' then drive = '4wd';
run;


proc corr data=cars;
run;

proc contents data=cars;
run;


/* View Top 10 Records */

proc print data=cars (obs=10);
title 'Top 10 Records';
run;


proc freq data=cars;
tables condition cylinders;
run;

/* Assigning Labels to Ordinal Variables */

data cars;
set cars;
if condition='salvage' then condition = 1;
if condition='fair' then condition = 2;
if condition='good' then condition = 3;
if condition='excellent' then condition = 4;
if condition='like new' then condition = 5;
if condition='new' then condition = 6;
condition_new = input(condition, best.);
drop condition;
rename condition_new= condition;
if cylinders='3 cylinders' then cylinders = 1;
if cylinders='4 cylinders' then cylinders = 2;
if cylinders='5 cylinders' then cylinders = 3;
if cylinders='6 cylinders' then cylinders = 4;
if cylinders='8 cylinders' then cylinders = 5;
if cylinders='10 cylinder' then cylinders = 6;
if cylinders='12 cylinder' then cylinders = 7;
if cylinders='other' then cylinders = 8;
cylinders_new = input(cylinders, best.);
drop cylinders;
rename cylinders_new= cylinders;
run;


/* Formatting fuel type names*/

proc sql;
alter table cars
  modify fuel char(10) format=$10.;
quit;

data cars;
set cars;
if fuel='die' then fuel = 'diesel';
if fuel='ele' then fuel = 'electric';
if fuel='hyb' then fuel = 'hybrid';
if fuel='oth' then fuel = 'others';
run;

proc freq data=cars;
tables fuel;
run;



/* Transforming price and creating Age Variable */
data cars;
set cars;
logPrice = log(price);
logPrice = round(logPrice,.01);
age = 2020-year;
run;

proc contents data=cars;
run;

proc print data=cars (obs =10);
run;

/* For writing CSV file */
/*proc export data=cars
outfile='cars.csv'
dbms=csv
replace;
run;*/

*******************************************************************************************************************************;
													/* EDA */
*******************************************************************************************************************************;


/* Data Overview */
proc contents data=cars;
title 'Data Overview';
run;

/*Top 5 rows*/
proc print data=cars(obs=5);
title 'Top 5 records';
run;

/* Correlation Matrix*/

proc corr data=cars;
title 'Correlation Matrix';
run;



/*Distribution Analysis - Continuous Variables*/

proc univariate data=cars normal noprint;
	var logPrice year odometer condition cylinders age;
	histogram logPrice year odometer condition cylinders age / normal kernel;
	inset n mean std / position = ne;
	title "Distribution Analysis - Continuous Variables";
run;

/*Change in Price with Condition */

proc gplot data=cars;
 plot price*condition / hminor=0;
 title 'Price V/s Condition';
 run;
quit;

/* Distribution analysis for categorical variables */

proc freq data=cars;
	tables fuel title_status transmission drive type paint_color / plots= freqplot;
	title "Frequency Analysis - Categorical Variables";
run;


proc sgplot data= cars;
vbar cylinders /group = type;
title 'Analyzing car types and cylinders';
run;

proc freq data=cars order=freq;
   tables condition*type / 
       plots=freqplot(twoway=stacked orient=horizontal);
	   title 'Distribution of car types by condition';
run;


proc GCHART DATA=cars;
BLOCK fuel;
PIE type;
title 'Type Variable Distribution';
run;

/*Checking impact of Categorical Predictors */
ods html;
ods graphics on;
ODS Trace On/Listing;
proc Anova Data = cars;
Class condition;
Model price = condition;
ODS Select OverallANOVA;
title "Impact of Condition Variable";
Quit;
ODS Trace Off;
proc Anova Data = cars;
Class  cylinders ;
Model price = cylinders;
ODS Select OverallANOVA;
title "Impact of Cylinder  Variable";
Quit;
ODS Trace Off;
proc Anova Data = cars;
Class  paint_color ;
Model price = paint_color;
ODS Select OverallANOVA;
title "Impact of Paint  Variable";
Quit;
proc Anova Data = cars;
Class  year ;
Model price = year;
ODS Select OverallANOVA;
title "Impact of year  Variable";
Quit;
proc Anova Data = cars;
Class  transmission ;
Model price = transmission;
ODS Select OverallANOVA;
title "Impact of transmission  Variable";
Quit;
proc Anova Data = cars;
Class  type ;
Model price = type;
ODS Select OverallANOVA;
title "Impact of type  Variable";
Quit;
proc Anova Data = cars;
Class  drive ;
Model price = drive;
ODS Select OverallANOVA;
title "Impact of drive  Variable";
Quit;

proc Anova Data = cars;
Class  title_status ;
Model price = title_status;
ODS Select OverallANOVA;
title "Impact of title_status Variable";
Quit;



*******************************************************************************************************************************;
											/* Multi Logit Model*/
*******************************************************************************************************************************;

* creating groups based on price *;
data cars_logit;
set cars;
If(price <= 5000)
        then Cgroup = 1;
If(price => 5001 and price <= 10000)
        then Cgroup = 2;
If(price => 10001 and price <= 25000)
        then Cgroup = 3;
If(price => 25001 and price <= 40000)
        then Cgroup = 4;
If(price => 40001)
        then Cgroup =5;
run;
 
* odometer standardization *;
data cars_logit1;
set cars_logit;
run;
proc standard data=cars_logit1 mean=0 std=1 out=cars_logit1;
var odometer;
run;
 
* create dummy variables for fuel: *;
Data cars_logit1;
set cars_logit1;
  IF fuel = 'diesel' THEN Fuel_diesel = 1;
    ELSE Fuel_diesel = 0;
 IF fuel = 'gas' THEN Fuel_gas = 1;
    ELSE Fuel_gas = 0;
 IF fuel = 'electr' THEN Fuel_electric = 1;
    ELSE Fuel_electric = 0;
 IF fuel = 'hybrid' THEN Fuel_hybrid = 1;
    ELSE Fuel_hybrid = 0;
 IF fuel = 'others' THEN Fuel_others = 1;
    ELSE Fuel_others = 0;
RUN;
 
* multi-logit with important five variables: *;
proc logistic data= cars_logit1;
class cgroup;
model cgroup = age odometer cylinders Fuel_gas / link = glogit;
run;
 
* make new data set with only non-gas fuel values and run multi-logit *;
Data cars_logit2;
set cars_logit1;
if fuel = "gas" then delete;
run;
proc logistic data= cars_logit2;
class cgroup;
model cgroup = Fuel_diesel Fuel_electric Fuel_hybrid Fuel_others / link = glogit;
run;
 
/*Logistic regression*/
proc Surveyselect data=cars_logit out=split seed=1234 samprate=.7 outall;
Run;
Data training validation;
Set split;
if selected = 1 then output training;
else output validation;
Run;
 

/* Logistic Model*/
ods graphics on;
proc Logistic Data = training
    plots (only)=(effect (clband x=(year condition fuel odometer title_status type cylinders)) 
                           oddsratio (type=horizontalstat));
    class drive fuel paint_color title_status transmission type;
    Model Cgroup = year fuel odometer title_status transmission drive type paint_color condition cylinders / selection = stepwise slstay=0.15 slentry=0.15 stb;
    score data=training out = Logit_Training fitstat outroc=troc;
    score data=validation out = Logit_Validation fitstat outroc=vroc;
Run;
proc freq data=Logit_Training;
tables f_Cgroup*I_Cgroup;
run;
proc freq data=Logit_Validation;
tables f_Cgroup*I_Cgroup;
Run;


*******************************************************************************************************************************;												
											/* Linear Regression */
*******************************************************************************************************************************;



/*standardizing the variables */
proc STANDARD DATA=cars MEAN=0 STD=1 OUT=zcars;
  VAR odometer  age;
RUN;

/* Manipulating the data set for proc reg statement */
proc glmselect data=zcars outdesign(fullmodel)=GLSDesign noprint;
   class title_status fuel  drive  paint_color   transmission type condition ( param = ordinal) cylinders(ref = '2' param = ordinal)
          / delimiter = ',' showcoding ; ;
   model logprice =  condition cylinders drive fuel paint_color title_status  transmission type age odometer  / selection=none; /* include ALL dummy variables */
run;
 
ods select Position;
proc contents data=GLSDesign varnum; run;   /* display all variables in OUTDESIGN= data set */
 
%put &_GLSMod;    

/* splitting the Dataset */

/* If propTrain + propValid = 1, then no observation is assigned to testing */
%let propTrain = 0.7;         /* proportion of training data */
%let propValid = 0.3;         /* proportion of validation data */
%let propTest = %sysevalf(1 - &propTrain - &propValid); /* remaining are used for testing */


data Train Validate Test;
array p[2] _temporary_ (&propTrain, &propValid);
set GLSDesign;
call streaminit(123);         /* set random number seed */
/* RAND("table") returns 1, 2, or 3 with specified probabilities */
_k = rand("Table", of p[*]);
if      _k = 1 then output Train;
else if _k = 2 then output Validate;
else                output Test;
drop _k;
run;



/* Running proc reg */
 proc reg data = train plots(maxpoints = none); 
    model logprice = &_GLSMod ;
output out = reg_out_lr predicted = pred_lr residual = res_lr ;
Quit;
run;

/* Test for Multicollinearity */
  proc reg data = train plots(maxpoints = none); 
    model logprice = &_GLSMod /VIF ;
	Title "Test for multicollinearity";
	Run;

/* Test for Normality */
proc univariate data=reg_out_lr;
	var Res_lr;
	histogram Res_lr/ normal kernel;
	qqplot Res_lr / normal(mu=est sigma=est);
	title "Test for Normality";
	run;
/*Test for Homoscedasticity */
proc REG DATA = train;
MODEL   logprice = &_GLSMod
/spec;
ODS Select SpecTest;
title "Test for Homoscedasticity ";
Quit;

/*Test for Autocorrelation */
proc REG DATA = train;
MODEL logprice = &_GLSMod

/dw;
ODS Select DWStatistic;
title "Test for Autocorrelation ";
Quit;
proc freq data = zcars;
tables title_status cylinders type;
run;

/* Solving for Heteroskedasticity */

proc reg data=train PLOTS(maxpoints = none); 
   model logprice = &_GLSMod / acov clb;
 title   "Solving for Heteroskedasticity" ;
run;

/* regression analysis by using All variables using GLMSelect */
 
proc glmselect data= zcars plots=(criterion ase) seed = 1;
class title_status   drive  paint_color   transmission type condition (param = ordinal order = data) cylinders(param = ordinal order = data)fuel
          / delimiter = ',' showcoding ; 
partition fraction(validate=0.3); 
   model logprice =  condition cylinders drive  paint_color title_status  transmission type age odometer fuel
 / selection=none showpvalues;
 output out=RegOut_glm predicted=Pred_glm residual=Residual_glm;
title "Regression Analysis with all variables using GLM select";
Run;

proc sgplot data=RegOut_glm ;
   scatter x=Pred_glm y=Residual_glm;
   loess x=Pred_glm y=Residual_glm / nomarkers smooth=0.5;

   xaxis grid; yaxis grid;
run;

/*Lasso Regression  */

proc glmselect data= zcars plots=(criterion ase) seed = 1;

class title_status   drive  paint_color   transmission type condition (param = ordinal) cylinders(param = ordinal) fuel
          / delimiter = ',' showcoding ;
partition fraction(validate=0.3); 
model logprice =  condition cylinders drive title_status paint_color  transmission type age odometer fuel
 / selection=lasso(  stop=cv) showpvalues;
output out=RegOut_lasso predicted=Pred_lasso residual=Residual_lasso ;
title "Regression Analysis with Lasso Penalty" ;
run;
proc sgplot data=RegOut_lasso ;
   scatter x=Pred_lasso y=Residual_lasso;
   loess x=Pred_lasso y=Residual_lasso / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
run;

/* Elastic Net */

proc glmselect data=zcars plots=(criterion ase) seed=1;
class   drive  paint_color  title_status transmission type condition (param = ordinal) cylinders(param = ordinal) fuel
          / delimiter = ',' showcoding ;
partition fraction(validate=0.3); 
model logprice =  condition cylinders drive  paint_color  title_status transmission type age odometer fuel
 / selection=elasticnet(stop=cv) showpvalues;
output out=RegOut_elastic predicted=Pred_elastic residual=Residual_elastic;
title "Regression Analysis with Elastic Net" ;
run;
proc sgplot data=RegOut_elastic ;
   scatter x=Pred_elastic y=Residual_elastic;
   loess x=Pred_elastic y=Residual_elastic / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
run;

/* Forward Selection */
proc glmselect data=zcars plots=(CriterionPanel ASE) seed=1;
partition fraction(validate=0.3);
class  drive  paint_color  title_status transmission type condition (param = ordinal) cylinders(param = ordinal) fuel
          / delimiter = ',' showcoding ;
model  logprice =  condition cylinders drive  paint_color  title_status transmission type age odometer fuel
/ selection=forward(select = cv choose=cv stop=cv) slstay = 0.05 hierarchy = single showpvalues ;
output out=RegOut_forward predicted=Pred_forward residual=Residual_forward;
title "Regresion with forward Selection" ;
run;
proc sgplot data=RegOut_forward;
   scatter x=Pred_forward y=Residual_forward;
   loess x=Pred_forward y=Residual_forward / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
run;

/* Backward Selection */
proc glmselect data=zcars plots=(CriterionPanel ASE) seed=1;
partition fraction(validate=0.3 );
class  drive  paint_color title_status  transmission type condition (param = ordinal) cylinders(param = ordinal) fuel
/ delimiter = ',' showcoding ;
model  logprice =  condition cylinders drive  paint_color  title_status transmission type age odometer fuel
/ selection=backward(choose = cv)  slstay = 0.05 hierarchy = single showpvalues;
output out=RegOut_backward predicted=Pred_backward residual=Residual_backward;
title "Regression Analysis with Backward Selection" ;
run;
proc sgplot data=RegOut_backward;
   scatter x=Pred_backward y=Residual_backward;
   loess x=Pred_backward y=Residual_backward / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
Run;

/*Stepwise Aic */
proc glmselect data=zcars plots=(CriterionPanel ASE) seed=1;
partition fraction(validate=0.3 );
class   drive  paint_color  title_status transmission type condition(param = ordinal) cylinders(param = ordinal) fuel
/ delimiter = ',' showcoding ;
model  logprice =  condition cylinders drive  paint_color  title_status transmission type  odometer  age*condition age fuel
/ selection=stepwise( choose=cv stop=cv) slstay = 0.05 hierarchy = single showpvalues
;

output out=RegOut_stepwise predicted=Pred_stepwise residual=Residual_stepwise;
title " StepWise Regression with interaction of condition and age" ;
run;
proc sgplot data=RegOut_stepwise ;
   scatter x=Pred_stepwise y=Residual_stepwise;
   loess x=Pred_stepwise y=Residual_stepwise / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
Run;

/* Polynomial regression */
proc glmselect data= zcars plots=(criterion ase) seed = 1;
effect p_age = polynomial(age / degree = 2);
class   drive  paint_color  title_status transmission type condition(param = ordinal) cylinders (param = ordinal) fuel ;
partition fraction(validate=0.3 ); 
model logprice =  condition cylinders drive  paint_color  title_status transmission type p_age odometer  fuel
 / selection=stepwise( select = sl choose=cv stop=cv)   showpvalues;
output out=RegOut_poly predicted=Pred_Poly residual=Residual_poly ;
title " Polynomial Regression" ;
Run;

proc sgplot data=RegOut_poly ;
   scatter x= logPrice y=Pred_Poly;
   loess x=logPrice y=Pred_Poly / nomarkers smooth=0.5;
   refline 0 / axis=y;
   xaxis grid; yaxis grid;
run;

proc univariate data=RegOut_poly;
	var Residual_poly;
	histogram Residual_poly/ normal kernel;
	qqplot Residual_poly / normal(mu=est sigma=est);
	run;

ods graphics off;
ods html close;

*******************************************************************************************************************************;
													/* Regression tree */;
*******************************************************************************************************************************;

ods graphics on;
proc hpsplit data= cars seed=2812 maxdepth=5 splitonce nodes=detail;/*plots=zoomedtree(nodes=("0") depth=3 fracprec=4 predictorprec=4) nodes;;*/
partition fraction(validate=0.30,seed=2812);
class  drive paint_color  title_status type transmission fuel condition(order = formatted) cylinders( order = formatted);
model logprice =  condition cylinders drive paint_color title_status type transmission age odometer fuel;
output out=hpsplout;
prune costcomplexity;
 title "Regression tree";
Run;


/*creating Residual column*/
data residu;
set hpsplout;
residual=abs(logprice-P_logprice);
Run;

/*Residual vs Predicted plot*/
proc sgplot data=residu;
scatter y=residual x=P_logprice ;
 run;
/*Final nodes price predictions*/
proc sgplot data=hpsplout;
vbox logprice / category=_NODE_   fill ;
Run;

ods graphics off;

*******************************************************************************************************************************;
													/* End of Project */
*******************************************************************************************************************************;






