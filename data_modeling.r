

---title:"Khurana Modeling - Dec"
date:12 - 08 - 2020
output:html_notebook---This script takes in a csv input from three SQL script corresponding to Khurana PDR and wet AMD subcohorts (Anti -
                                                                                                                      VEGF, PRP, and BOTH).
```{
  r
}
# Data Set Up
## Get necessary packages needed for analysis
##These packages contain collections of functions for data analysis
##Many packages come with basic R installation but we have to install them
##if we want to work with them. This means putting them in a directory called "library".
# Tidyverse helps us manage/organize our data --> "tidy" up our messy dataset
install.packages("tidyverse")
# Dplyr is a package of tidyverse which allows us to maniuplate our data, i.e. summarise, filter, select, etc
install.packages("dplyr")
#Hmisc is the best package for imputing our missing values 
#Hmisc automatically recognizes the variables types and uses bootstrap sample 
#and predictive mean matching to impute missing values.
install.packages("Hmisc")
# epitools contains tools for training and practicing epidemiologists including methods for twoway and multi-way contingency tables
install.packages("epitools")
library(tidyverse)
library(dplyr)
library(Hmisc)
library(epitools)
```
# VEGF - Data Formatting/Demographics
```{
  r
}
--
  ## We need to load in the master dataframe output that we got from SQL.
  ## Assign 'df' as the alias to make referring the data easier in later steps.
  ## Whenever we have "___ <-" we are giving an alias to our data set.
  
pdr_vegf <- read.csv('Desktop/AAO/khurana_wetamd_cohort_fix_vegf.csv')
##Do some exploratory analysis of pdf_vegf 
##Take a peek at df using the head and tail functions 
##lets see a small part of the data
head(pdr_vegf)

# Format the demographic variables, eye involvment, diabetes, VA into the categories we need for analysis 
# We need to do this in order to create the requested categories 

### Format tx age
pdr_vegf<- mutate(pdr_vegf,agecat = ifelse(is.na(txage),'Unreported', 
                                           ifelse((txage<0),'Unreported',
                                                  ifelse((txage<=70), '<=70', 
                                                         ifelse((txage %in% 71:75),'71-75',
                                                                ifelse((txage  %in% 76:80),'76-80',
                                                                       ifelse((txage %in% 81:85),'81-85',
                                                                              ifelse((txage %in% 86:90),'86-90',
                                                                                     ifelse((txage %in% 90:115),'>90',
                                                                                            ifelse((txage >115),'Unreported',
                                                                                                   '999'))))))))))
### Format Race
pdr_vegf <- mutate(pdr_vegf, racecat = ifelse(
  race == 'White',
  'White',
  ifelse(
    race == 'Black or African American',
    'African American',
    ifelse(
      race == 'Asian',
      'Asian',
      ifelse(
        race == 'Hispanic',
        'Hispanic',
        ifelse(race ==
                 'Unknown', 'Unreported',
               'Other')
      )
    )
  )
))
### Format Eye Involvement
pdr_vegf <-
  mutate(pdr_vegf, eyecat = ifelse(eye_involve == 1, 'Unilateral', 'Bilateral'))
### Format bl_va
pdr_vegf <-
  mutate(pdr_vegf, vacat = ifelse(
    is.na(bl_va),
    'Unreported',
    ifelse(bl_va < 0, 'Unreported',
           ifelse(
             bl_va <= 0.3,
             '>=20/40',
             ifelse(bl_va <=
                      1, '20/50-20/200',
                    ifelse(
                      bl_va > 1, '<20/200',
                      ifelse(is.null(bl_va), 'Unreported',
                             '')
                    ))
           ))
  ))
### Format Region
pdr_vegf <-
  mutate(pdr_vegf, regioncat = ifelse(
    region == 'South',
    'South',
    ifelse(
      region == 'Midwest',
      'Midwest',
      ifelse(
        region == 'Northeast',
        'Northeast',
        ifelse(region ==
                 'West', 'West',
               'Unknown')
      )
    )
  ))
### Format Insurance
pdr_vegf <-
  mutate(pdr_vegf, inscat = ifelse(
    ins_final == 'Dual',
    'Dual',
    ifelse(
      ins_final == 'Govt' | ins_final == 'Military',
      'Govt/Military',
      ifelse(
        ins_final == 'Medicaid',
        'Medicaid',
        ifelse(
          ins_final == 'Medicare',
          'Medicare',
          ifelse(ins_final ==
                   'Private', 'Private',
                 'Unknown')
        )
      )
    )
  ))
### Format Aggregate Gross Income
pdr_vegf <- mutate(
  pdr_vegf,
  agicat = ifelse(
    is.na(mhi),
    'Unknown',
    ifelse(
      mhi < 0,
      'Unknown',
      ifelse(
        mhi <= 25000,
        '25k and below',
        ifelse(
          mhi %in% 25001:75000,
          '25,001-75,000',
          ifelse(
            mhi %in% 75001:100000,
            '75,001-100,000',
            ifelse(
              mhi > 100000 ,
              '>100,000',
              'Unknown')))))))
              ## Create First Year Followup Indicators
              ### first follow up first year
              pdr_vegf <-
                mutate(pdr_vegf, f_followup_yearone_ind = ifelse((oneyrindonemo == 1), 1,
                                                                 ifelse((oneyrindonemo ==
                                                                           0), 0,
                                                                        ''
                                                                 )))

              # Summary Statistics / Demographics
              ##Totals
              # Count per breakdown of each variable 
              
              # Counts of first follow up within one year vs who did not 
              
              table(pdr_vegf$oneyrindonemo)
              ## AGE
              table(pdr_vegf$agecat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$agecat))
              ## SEX
              table(pdr_vegf$gender, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$gender))
              ## RACE/ETHNICITY
              table(pdr_vegf$racecat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$racecat))
              ## EYE INVOLVEMENT
              table(pdr_vegf$eyecat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$eyecat))
              ## BASELINE VA
              table(pdr_vegf$vacat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$vacat))
              ## DIABETES
              table(pdr_vegf$diab_indicator, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$diab_indicator))
              ## REGION
              table(pdr_vegf$regioncat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$regioncat))
              ## INSURANCE
              table(pdr_vegf$inscat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$inscat))
              ## MEDIAN HOUSEHOLD INCOME
              table(pdr_vegf$agicat, pdr_vegf$oneyrindonemo)
              chisq.test(table(pdr_vegf$agicat))
              
              ## RESTRICTION: patients with a folup VA
              # Need to remove missing values
              pdr_vegf_rest <-
                filter(pdr_vegf, (!is.na(folup_va)))
              
              ### Year 1
              # No follow up within one year (VA)
              dim(filter(pdr_vegf_rest, oneyrindonemo ==
                           0))
              # Follow up within one year (VA)
              dim(filter(pdr_vegf_rest, oneyrindonemo ==
                           1))
              ## TX TIME
              # No follow up
              summary((filter(pdr_vegf_rest,oneyrindonemo == 0))$tx_time)
              sd((filter(pdr_vegf_rest,oneyrindonemo == 0))$tx_time) 
              # Follow up
              summary((filter(pdr_vegf_rest,oneyrindonemo == 1))$tx_time)
              sd((filter(pdr_vegf_rest,oneyrindonemo == 1))$tx_time) 
              ## CHANGE IN VA  (442 days)
              ### Year 1
              # Follow up
              summary((filter(pdr_vegf,oneyrindonemo == 1))$va_change)
              sd((filter(pdr_vegf,oneyrindonemo == 1))$va_change,na.rm=TRUE)
              # No follow up
              summary((filter(pdr_vegf,oneyrindonemo == 0))$va_change)
              sd((filter(pdr_vegf,oneyrindonemo == 0))$va_change,na.rm=TRUE) 
              
              ## NUMBER OF ANTI-VEGF INJECTION TOTAL  (442 days)
              ## Year 1
              # Follow up
              summary((filter(pdr_vegf,oneyrindonemo == 1))$inj_ct_final_sum)
              sd((filter(pdr_vegf,oneyrindonemo == 1))$inj_ct_final_sum,na.rm=TRUE) 
              # No follow up
              summary((filter(pdr_vegf,oneyrindonemo == 0))$inj_ct_final_sum)
              sd((filter(pdr_vegf,oneyrindonemo == 0))$inj_ct_final_sum,na.rm=TRUE)
              
              ## LAST IRIS >=20/40  (442 days)
              table(pdr_vegf$twentyforty_ind_442,pdr_vegf$oneyrindonemo)
              
              ## LAST IRIS <20/200  (442 days)
              table(pdr_vegf$ind_442,pdr_vegf$oneyrindonemo)
              ```
              # VEGF -- Model Setup/Modeling
              ```{
                r
              }
              # Modeling Set Up (Must run before Models)
              ## Setting Reference Values (Only the ones that do not default to what we want)
              pdr_vegf$gender <-
                factor(pdr_vegf$gender, levels = c("Male", "Female", "Unknown"))
              pdr_vegf$racecat <-
                factor(
                  pdr_vegf$racecat,
                 # ordered = TRUE,
                  levels = c(
                    "White",
                    "African American",
                    "Asian",
                    "Hispanic",
                    "Other",
                    "Unreported"
                  )
                )
              pdr_vegf$eyecat <-
                factor(pdr_vegf$eyecat, levels = c("Bilateral", "Unilateral"))
              pdr_vegf$regioncat <-
                factor(
                  pdr_vegf$regioncat,
                 # ordered = TRUE,
                  levels = c("South", "Midwest", "Northeast", "West", "Unknown")
                )
              pdr_vegf$inscat <-
                factor(
                  pdr_vegf$inscat,
                  #ordered = TRUE,
                  levels = c(
                    "Private",
                    "Dual",
                    "Govt/Military",
                    "Medicaid",
                    "Medicare",
                    "Unknown"
                  )
                )
              pdr_vegf$vacat <-
                factor(
                  pdr_vegf$vacat,
                  #ordered = TRUE,
                  levels = c(">=20/40", "20/50-20/200", "<20/200", "Unreported")
                )
              pdr_vegf$agicat <-
                factor(
                  pdr_vegf$agicat ,
                  #ordered = TRUE,
                  levels = c(
                    ">100,000",
                    "75,001-100,000",
                    "25,001-75,000",
                    "25k and below",
                    "Unreported"
                  )
                )
              
              ## Switch the binary dependent variables so that 1 means loss of follow up
              ### Year 1
              pdr_vegf_year1_model <-
                mutate(pdr_vegf, oneyear_model_ind = ifelse(oneyrindonemo == 1, 0, 1))
              
              ## SET UP FOR UNKNOWNS REMOVED
              ### Year 1
              pdr_vegf_year1_model_rm <-
                pdr_vegf_year1_model
              pdr_vegf_year1_model_rm[pdr_vegf_year1_model_rm ==
                                        'Unreported'] <- NA
              pdr_vegf_year1_model_rm[pdr_vegf_year1_model_rm ==
                                        'Unknown'] <- NA
              
              # Models (YEAR 1)
              ## UNIVARIATE ANALYSIS
              
              lm_age_1<- glm(oneyear_model_ind ~ agecat, data=pdr_vegf_year1_model_rm, family="binomial")
              summary(lm_age_1)
              exp(cbind("odds ratio"=coef(lm_age_1),confint.default(lm_age_1,level=0.95)))
              ))
              ### Gender
              lm_gender_1 <-
                glm(oneyear_model_ind ~ gender, data = pdr_vegf_year1_model_rm, family =
                      "binomial")
              summary(lm_gender_1)
              exp(cbind(
                "odds ratio" = coef(lm_gender_1),
                confint.default(lm_gender_1, level = 0.95)
              ))
              ### Race
              lm_race_1 <-
                glm(
                  oneyear_model_ind ~ racecat,
                  data = pdr_vegf_year1_model_rm,
                  family = "binomial"
                )
              summary(lm_race_1)
              exp(cbind(
                "odds ratio" = coef(lm_race_1),
                confint.default(lm_race_1, level = 0.95)
              ))
              ### Eye
              lm_eye_1 <-
                glm(oneyear_model_ind ~ eyecat, data = pdr_vegf_year1_model_rm, family =
                      "binomial")
              summary(lm_eye_1)
              exp(cbind(
                "odds ratio" = coef(lm_eye_1),
                confint.default(lm_eye_1, level = 0.95)
              ))
              ### Baseline VA
              lm_va_1 <-
                glm(oneyear_model_ind ~ vacat, data = pdr_vegf_year1_model_rm, family =
                      "binomial")
              summary(lm_va_1)
              exp(cbind(
                "odds ratio" = coef(lm_va_1), confint.default(lm_va_1, level = 0.95)
              ))
              ### Diabetes Indicator
              lm_diab_1 <-
                glm(
                  oneyear_model_ind ~ diab_indicator,
                  data = pdr_vegf_year1_model_rm,
                  family = "binomial"
                )
              summary(lm_diab_1)
              exp(cbind(
                "odds ratio" = coef(lm_diab_1),
                confint.default(lm_diab_1, level = 0.95)
              ))
              ### Region
              lm_region_1 <-
                glm(
                  oneyear_model_ind ~ regioncat,
                  data = pdr_vegf_year1_model_rm,
                  family = "binomial"
                )
              summary(lm_region_1)
              exp(cbind(
                "odds ratio" = coef(lm_region_1),
                confint.default(lm_region_1, level = 0.95)
              ))
              ### Insurance
              lm_ins_1 <-
                glm(oneyear_model_ind ~ inscat, data = pdr_vegf_year1_model_rm, family =
                      "binomial")
              summary(lm_ins_1)
              exp(cbind(
                "odds ratio" = coef(lm_ins_1),
                confint.default(lm_ins_1, level = 0.95)
              ))
              ### Income
              lm_agi_1 <-
                glm(oneyear_model_ind ~ agicat, data = pdr_vegf_year1_model_rm, family =
                      "binomial")
              summary(lm_agi_1)
              exp(cbind(
                "odds ratio" = coef(lm_agi_1),
                confint.default(lm_agi_1, level = 0.95)
              ))
              
              ## MULTIVARIATE ANALYSIS
              multi_rm_1 <-
                glm(
                  oneyear_model_ind ~ agecat + gender + racecat + eyecat + vacat + diab_indicator +
                    regioncat + inscat + agicat,
                  data = pdr_vegf_year1_model_rm,
                  family = binomial
                )
              summary(multi_rm_1)
              with(summary(multi_rm_1), 1 - deviance /
                     null.deviance)
              exp(cbind(
                "odds ratio" = coef(multi_rm_1),
                confint.default(multi_rm_1, level = 0.95)
              ))
              
              ```

