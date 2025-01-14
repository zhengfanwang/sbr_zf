#load data
SBR.full.ori <- readRDS("output/fullset.rds")
hq.lmic.def.ori <- openxlsx::read.xlsx("input/high quality LMIC study data/High Quality LMIC data_Definition.xlsx",sheet=1) ## high quality LMIC data
SBR.full.ori$lmic[SBR.full.ori$iso == "COK"] <- 1

SBR.full <- SBR.full.ori %>% filter(is.na(exclusion_notes)|
                                    exclusion_notes %in% c("Duplicate, use different system")) %>% 
                             filter(exclude_sbrnmr==FALSE | is.na(exclude_sbrnmr)) %>%
                             mutate(definition_rv2 = replace(definition_rv2, definition_rv == "ge1000g" & lmic == 1, "ge28wks.m")) %>% 
                             mutate(definition_rv2 = replace(definition_rv2, definition_rv == "ge500g" & lmic == 1, "ge22wks.m"))  %>% 
                             mutate(definition_rv = replace(definition_rv, definition_rv == "ge1000g" & lmic == 1, "ge28wks")) %>% 
                             mutate(definition_rv = replace(definition_rv, definition_rv == "ge500g" & lmic == 1, "ge22wks"))
# SBR.full.lmic <- SBR.full %>% filter(lmic == 1) %>% 
#                               filter(source != "survey")

SBR.full.hic <- SBR.full %>% filter(lmic == 0) %>% 
                             filter(source %in% c("admin","subnat.admin")) ## change to exclude HMIS or subnational literatuer as well 
                                                                            ## (though don't think there duplicates there)

#-----------------------------------------------#
# find combiations for Lmic country             # 
#-----------------------------------------------#

#def_adj_lmic_res <- find_comb_def_adj(SBR.full.lmic)
# Read in high quality LMIC data (Database 6) and re-arrange and relable HQ data so looks like output of find_comb_def_adj() function
hq.lmic.def <- hq.lmic.def.ori %>% mutate(definition_rv = "ge22wks",definition_rv2 = "ge22wks",
                                          definition_raw = "ge22wks", definition= "ge22wks",
                                          ori_def28 = "ge28wks", nSB28 = sb_28wks,SBR28 = sbr_28wks,
                                          SBR = sbr_22wks, nSB = sb_22wks, nLB =lb, source = seriesname) %>%
                                   mutate(nTB = nLB + nSB) %>%  
                                   rename("iso" = "iso3","year"="reference_year") %>%
                                   select(country,iso,year,nSB,SBR,nSB28,SBR28, nLB,
                                          definition_rv, definition_rv2, definition_raw,definition,ori_def28, source)%>%
                                    arrange(country, year)

def_adj_lmic_res <- list(dat = hq.lmic.def,
                         alter.def = "ge22wks")


#store each combation as a element of a list
def_adj_list_lmic <- def_adj_lmic_res$dat
def_adj_name_lmic <- def_adj_lmic_res$alter.def
#the alter def name
saveRDS(def_adj_list_lmic,"output/def_adj_data_lmic.rds")

#-----------------------------------------------#
# find combiations for HIC country              # 
#-----------------------------------------------#

def_adj_hic_res <- find_comb_def_adj(SBR.full.hic)
#store each combation as a element of a list
def_adj_list_hic <- def_adj_hic_res$dat
def_adj_name_hic <- def_adj_hic_res$alter.def
#the alter def name
saveRDS(def_adj_list_hic,"output/def_adj_data_hic.rds")





######################################################################
#  

#---------------------------------------------------------#
# Overview for num paired obs and obs where need to adj   # 
#---------------------------------------------------------#

# def_adj_res <- find_comb_def_adj(SBR.full)
# #store each combation as a element of a list
# def_adj_list <- def_adj_res$dat
# alter.def <- def_adj_res$alter.def
# nobs <- def_adj_list %>% sapply(dim)
# num_paired_obs <- as.vector(nobs[1,]) 
# N <- length(alter.def)
# nobs.lmic <- rep(NA,N)
# nobs.hic <- rep(NA,N)
# for(i in 1:N){
#   nobs.lmic[i] <- sum(def_adj_list[[i]]$lmic)
#   nobs.hic[[i]] <- num_paired_obs[i] - nobs.lmic[i]
# }
# 
# summ <- data.frame(definition = alter.def, num_paired_obs = num_paired_obs , 
#                    nobs_paired_lmic = nobs.lmic, nobs_paired_hic = nobs.hic) %>% 
#   arrange(desc(num_paired_obs))

#-------------------------------------------------#
#    selecting only 1 def per country-year        # 
#-------------------------------------------------#

# ## AM: Assuming this is what gets used in 3.comp_cutoff, so need to include LB,NMR,etc.
# SBR.full <- SBR.full %>% filter(is.na(exclusion_notes))
# SBR.model <- SBR.full  %>% filter(!(definition_rv %in% c("any","not defined","unknownGA"))) %>% 
#                            filter(source != "subnat.admin") %>% 
#                            select(uniqueID,iso,country,year,source,shmdg2,lmic,definition_rv,definition_rv2,definition_raw,definition,
#                                  adj_sbr_unknown,country_idx,SE.logsbr) %>% 
#                            mutate(definition_rv2 = as.factor(definition_rv2),
#                                   source = as.factor(source),
#                                   duplicates = NA)
# SBR.model$definition_rv2 <- droplevels(SBR.model$definition_rv2)
# 
# priority.for.adj <- summ %>% filter(definition %in% levels(SBR.model$definition_rv)) %>% 
#                              filter(!(definition %in% c("unknownGA","any","not defined")))
# 
# #### the following vector is decided by where we can do def adj(priority.for.adj) and where we need adj(SBR.model$definition_rv2)
# priority.for.adj_vec <- c("ge28wks","ge28wks.m","ge22wks","ge22wks.m","ge1000g",
#                           "ge1000g.m","ge20wks","ge500g","ge24wks","ge37wks",
#                           "ge1000gANDge28wks")
# 
# SBR.model <- SBR.model %>% filter(definition_rv2 %in% priority.for.adj_vec)
# SBR.model$definition_rv2 <- droplevels(SBR.model$definition_rv2)
# 
# #---------------------------------------------------------------------#
# ###important: reorder factor level as priority 
# SBR.model$definition_rv2 <- factor(SBR.model$definition_rv2,levels = priority.for.adj_vec)
# #---------------------------------------------------------------------#
# 
# def <- levels(droplevels(SBR.model$definition_rv2))
# source <- levels(droplevels(SBR.model$source))
# record <- 0
# for(c in 1:195){
#   for(t in 2000:2020){
#     for(s in source){
#           i<- which(SBR.model$country_idx == c&
#                     SBR.model$year == t&
#                     SBR.model$source == s)
#           len <- length(i)
#           dev <- as.numeric(SBR.model[i,"definition_rv2"])
#           if(len > 1)  {
#             exclude <- i[-which(dev == min(dev))]
#             record <- c(record,exclude)
#           }    
#       for(d in def){
#           i2 <- which(SBR.model$country_idx == c&
#                       SBR.model$year == t&
#                       SBR.model$definition_rv2 == d&
#                       SBR.model$source == s)
#           len2 <- length(i2)
#       if(len2 > 1) (SBR.model[i2,"duplicates"] <- 1:len2)    
#       }
#     }
#   }
# }
# 
# SBR.model2 <- SBR.model %>% mutate(SBR = adj_sbr_unknown)
# SBR.model.f <- SBR.model2[-record,] 
# ## apply new exclusion rule, there is one observation with def "ge500gORge20wks" in Brazil 2010 from subnat lit Rv database. 
# # In condition that we already have time-series HMIS data in that country-year. I think we can exclude the obs with def "ge500gORge20wks".
# 
# saveRDS(SBR.model.f,"output/data_for_model.rds")
# write.csv(SBR.model.f,"output/data_for_model.csv")
# SBR.need.adj <- SBR.model.f %>% filter(definition_rv != "ge28wks" )
# #-------------------------------------------------#
# #                  summary table                  # 
# #-------------------------------------------------#
# def <- droplevels(as.factor(SBR.need.adj$definition_rv))
# N1 <- length(levels(def))
# k <- table(def)
# definition <- names(k)
# veck <- as.vector(k)
# 
# nobs.lmic1 <- rep(NA,N1)
# nobs.hic1 <- rep(NA,N1)
# for(i in 1:N1){
#   nobs.lmic1[i] <- sum(SBR.need.adj$lmic[SBR.need.adj$definition_rv == levels(def)[i]])
#   nobs.hic1[i] <- veck[i] - nobs.lmic1[i]
# }
# 
# tab <- data.frame(definition = definition, num_obs = veck, num_lmic = nobs.lmic1,num_hic = nobs.hic1)
# 
# summ1 <- summ %>% merge(tab,by = "definition") %>% arrange(desc(num_paired_obs))
# 
# write.csv(summ1,"table/def_adj_num_paired_obs_exclustion_strict.csv")




# need_adj_list <- create_list_for_country(SBR.need.adj)
# pdf_name <- paste0("fig/exploratory_plot/need_def_adj.pdf")
# pdf(pdf_name,width=12)
# need_adj_list %>% lapply(exploratory_plot)
# dev.off()
# 
















