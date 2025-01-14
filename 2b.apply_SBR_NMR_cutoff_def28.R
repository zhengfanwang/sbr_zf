#load the full data set
full_data <- readRDS("output/sbr.full.rds")

# load the values from the cutoff analysis
params_cutoff <- readRDS(file = "output/results_cutoff_analysis.rds")
# params_cutoff is list(mu.hat, delta.hat.sq, sigma.hat.sq)

cutoff_prob <- 0.05
cutoff_bound_zerovar <- exp(qnorm(cutoff_prob,params_cutoff$mu.hat,
                                  sqrt(params_cutoff$delta.hat.sq + params_cutoff$sigma.hat.sq)))
                            
                            
# for observed nmr
fsbr <- full_data$adj_sbr_unknown
flb <- full_data$nLB
ftb <- full_data$nLB + full_data$nSB
fnmr_obs <- full_data$NMR
prob_obs_i <- get_probs_sbrnmr(ftb = ftb, fsbr = fsbr, 
                               fnmr = fnmr_obs, 
                               flb = flb, 
                               params_cutoff)
exclude_sbrnmr_obs_i <- (prob_obs_i < cutoff_prob)
                            
# now same for UN nmr for selected obs
fnmr_un <- full_data$UN_NMR
flb_un <- full_data$WPP_LB 
prob_un_i <- get_probs_sbrnmr(ftb = ftb, 
                              fsbr = fsbr, 
                              fnmr = fnmr_un,
                              flb = flb_un, 
                              params_cutoff)
exclude_sbrnmr_un_i <- (prob_un_i < cutoff_prob)
 
## AM: I think something about this isn't working because will return INF if both are missing -- should check later  
## prob_min_i <- map2_dbl(prob_un_i,prob_obs_i,min,na.rm=T)
## exclude_sbrnmr_max_i <- (prob_min_i < cutoff_prob)


# some exploratory analysis 
#hist(prob_i_obs,freq = FALSE, breaks = 20)
#hist(prob_i_un,freq = FALSE, breaks = 20)
                            
#mean(prob_i_obs < cutoff_prob,na.rm = T)
#mean(prob_i_un < cutoff_prob,na.rm = T)

############################        
# process is to add prob_i columns to the data set (to have it for analysis) 
# as well as the exclusion outcome (to filter by)
# NOTE: the exclusion conslusions are based on assuming all def are 28wks. 
#        There is another round excludsion after def adj 
              
              
## AM: After talking to Lucia, I think we should use the "exclude_sbrnmr" variable for exclusion in first round
##     which only uses UN IGME-NMR based exclusion rule if obs NMR is missing. Creating that variable here
##     and using it for filtering step in 3.def_adj script. 
SBR.full.ratio <- full_data %>% mutate(exclude_sbrnmr = ifelse(is.na(NMR) | source %in% c("HMIS","subnat.LR"),exclude_sbrnmr_un_i,exclude_sbrnmr_obs_i)) %>%
                                #mutate(exclude_sbrnmr_max = exclude_sbrnmr_max_i) %>% 
                                mutate(exclude_sbrnmr_obs = exclude_sbrnmr_obs_i) %>% 
                                mutate(exclude_sbrnmr_un = exclude_sbrnmr_un_i) %>% 
                                #mutate(prob_min = prob_min_i) %>% 
                                mutate(prob_obs = prob_obs_i) %>%
                                mutate(prob_un = prob_un_i)


                               
### Overwrite exclusion for small countries ## 
## if we observe 0 SBR & non-zero NMR country exclude_sbrnmr_obs_i= TRUE, since log(fsbr/fnmr)=0, 
## if we observe 0 SBR & 0 NMR country exclude_sbrnmr_obs_i==NA since log(fsbr/fnmr) will be NaN 
##                                     but  exclude_sbrnmr_un_i=TRUE and exclude_sbrnmr_max_i=TRUE since NMR=0

#in these cases apply the small country exclusion, to overwrite these probabilities as "FALSE" 


SBR.full.ratio <- SBR.full.ratio %>% mutate(#exclude_sbrnmr_max= replace(exclude_sbrnmr_max,exclude_sbrnmr_max==TRUE & WPP_LB <= 30000 & (nSB < 1 | NMR==0),FALSE),
                                            exclude_sbrnmr_obs = replace(exclude_sbrnmr_obs,exclude_sbrnmr_obs==TRUE & WPP_LB <= 30000 & (nSB < 1| NMR==0),FALSE),
                                            exclude_sbrnmr_un = replace(exclude_sbrnmr_un,exclude_sbrnmr_un==TRUE & WPP_LB <= 30000 & (nSB < 1 | NMR==0),FALSE),
                                            exclude_sbrnmr = replace(exclude_sbrnmr,exclude_sbrnmr==TRUE & WPP_LB <= 30000 & (nSB < 1 | NMR==0),FALSE))



## AM: Based on above note on line 49, I think we should set all exclusions that are for non-28 wk defintions back to missing 
##     They will get overwritten in "3.comp_cutoff_for_non28wks_def.R. ZF do you agreee? Might not be necessary 

SBR.full.ratio <- SBR.full.ratio %>% mutate(#exclude_sbrnmr_max= replace(exclude_sbrnmr_max,definition_rv!="ge28wks",NA),
                                            exclude_sbrnmr_obs = replace(exclude_sbrnmr_obs,definition_rv!="ge28wks",NA),
                                            exclude_sbrnmr_un = replace(exclude_sbrnmr_un,definition_rv!="ge28wks",NA),
                                            exclude_sbrnmr = replace(exclude_sbrnmr,definition_rv!="ge28wks",NA))



#table(SBR.full.ratio$exclusion_ratio)
#write.csv(SBR.full.ratio,"output/fullset.csv")
saveRDS(SBR.full.ratio,"output/fullset.rds")

