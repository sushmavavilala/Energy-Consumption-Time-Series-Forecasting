/* STSM03d05.sas */
/* Forecasting out-of-sample and validating */
/* This option causes the macro-generated SAS code to be printed in the log. */
options mprint;

/* Specify the number of timepoints for holdback across the program with &nhold. */


%let nhold=13;

/* This reads in the external file containing the actual macros and submits it when */
/* this statement is submitted. */

%include "C:/Users/sushm/OneDrive/Desktop/Data Mining/Forecasting-datasets-OPIM5671/macros2.sas" / source2;

/* The %accuracy_prep macro prepares the series by assuring that the holdout */
/* measurements are not included in the estimation of the time series model, */
/* but rather saved for a later time, when the %accuracy macro is submitted. */
/* The macro creates a temporary data set called WORK._TEMP, containing two  */
/* variables: Y_FIT for the in-sample observations; and */
/*            Y_HOLDOUT for the out-of-sample observations. */
/* The syntax for the %accuracy_prep macro is: */
/* %ACCURACY_PREP (INDSN=              series data set name, */
/*                 SERIES=             name of the target series, */
/*                 TIMEID=             time ID variable, */
/*                 NUMHOLDBACK=        number of time points to hold out); */

     
%accuracy_prep(indsn=STSM.PROJECT, series=Consumption, timeid=Date, 
    numholdback=&nhold);

/* ODS SELECT NONE is used to suppress printing of the PROC ARIMA output. */
/* PROC ARIMA is run to estimate the model based on the non-holdout sample  */
/* and a forecast is requested for the entire sample.  Here, this is done
/* for two different models - the AR(1) model and the ARX(1) model. */
ods select none;

proc arima data=work._temp;
    identify var=_y_fit /*crosscorr=(Cloud_Cover cosval); */
    estimate p=(1 2 3) q=(1 2 3 4 5 6 7) method=ML; 
    forecast lead=&nhold id=Date interval=week out=work.OUT123 nooutall;
    estimate p=(1 2) method=ML;
    forecast lead=&nhold id=Date interval=week out=work.out nooutall;
   /* estimate p=(1) input=(cosval) method=ML;
    forecast lead=&nhold id=EDT interval=week out=AR1_cos_forecast nooutall;
    estimate p=(1) input=(Cloud_Cover cosval) method=ML;
    forecast lead=&nhold id=EDT interval=week out=AR1_Cloudcos_forecast nooutall;*/
quit;

ods select all;

/* Using the %ACCURACY macro */
/* The syntax for the %accuracy macro is: */
/* %ACCURACY (INDSN=              series data set name, */
/*            SERIES=             name of the target series, */
/*            TIMEID=             time ID variable, */
/*            NUMHOLDBACK=        number of time points to hold out, */
/*            FORECAST=           name of the variable containing forecasts); */


%accuracy(indsn=work.out, timeid=Date, series=Consumption, 
    numholdback=&nhold);
%accuracy(indsn=work.OUT123, timeid=Date, series=Consumption, 
    numholdback=&nhold);
/*%accuracy(indsn=work.AR1_cos_forecast, timeid=EDT, series=kW_Gen, 
    numholdback=&nhold);
%accuracy(indsn=work.AR1_Cloudcos_forecast, timeid=EDT, series=kW_Gen, 
    numholdback=&nhold);*/

data work.allmodels;
    set work.out_1 work.out123_1; 
       
run;

proc print data=work.allmodels label;
    id series model;
run;