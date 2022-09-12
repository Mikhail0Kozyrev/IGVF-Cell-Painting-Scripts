#!/usr/bin/env Rscript
#Create a correlation plot between two dataframes

#load in data
library(data.table)
library(reshape)
library(ggplot2)
library(ggpmisc)
library(plyr)
library(zplyr)

args=commandArgs(trailingOnly=TRUE)

#read in the data frames
mydf=fread(args[1])
comparisondf=fread(args[2])
filetype=args[3]

#change data frames from short and wide to tall and skinny - My Data
mydf_new<-mydf[,grep("Cells",colnames(mydf))[[1]]:ncol(mydf)]
mydf_new<-cbind(mydf$Metadata_broad_sample,mydf_new)
colnames(mydf_new)[1]<-"Metadata_broad_sample"
mydf_new$Metadata_broad_sample[which(mydf_new$Metadata_broad_sample=="")]<-"DMSO"
compounds=unique(mydf_new$Metadata_broad_sample)
mydf_new<-melt(mydf_new)
names(mydf_new)[names(mydf_new)=="variable"]<-"Measurement"
names(mydf_new)[names(mydf_new)=="value"]<-"UTSW_Median"

#change data frames from short and wide to tall and skinny - Broad Data
comparisondf_new<-comparisondf[,grep("Cells",colnames(comparisondf))[[1]]:ncol(comparisondf)]
comparisondf_new<-cbind(comparisondf$Metadata_broad_sample,comparisondf_new)
colnames(comparisondf_new)[1]<-"Metadata_broad_sample"
comparisondf_new$Metadata_broad_sample[which(comparisondf_new$Metadata_broad_sample=="")]<-"DMSO"
comparisondf_subset=comparisondf_new[comparisondf_new$Metadata_broad_sample %in% compounds,]
comparisondf_new<-melt(comparisondf_subset)
names(comparisondf_new)[names(comparisondf_new)=="variable"]<-"Measurement"
names(comparisondf_new)[names(comparisondf_new)=="value"]<-"Broad_Median"

#merge data sheets by type
df_all<-merge(mydf_new,comparisondf_new,by=c("Metadata_broad_sample","Measurement"))
#calculate the slope and add to the plot
df_all_lm<-lm(UTSW_Median~Broad_Median,df_all)
df_all_lmcoef<-coef(df_all_lm)
df_all_lmcoef<-data.frame(Slope=round(df_all_lmcoef[[2]],3))
df_all_lmcoef$Slope<-paste0("Slope=",df_all_lmcoef$Slope)
df_all_lmcoef=cbind(UTSW_Median=1,Broad_Median=1,df_all_lmcoef)

#creating correlation plot by Metadata_Compound
ggplot(df_all, aes(x=UTSW_Median,Broad_Median)) + geom_point(colour="black") + geom_smooth(method='lm',formula=y~x, colour="black") + stat_poly_eq() + labs(title=paste0("Correlation between Broad Data Set and UTSW\nAfter PyCytominer Using the ",filetype," File")) + geom_abs_text(data=df_all_lmcoef,mapping = aes(label = Slope),color="black",size=3.8,xpos=0.1,ypos=0.9)
ggsave(paste0("CorrelationPlot_AllData_",filetype,".png"), type = "cairo")

#summarizing by compound
#calculate lm for each broad sample
cmpd_lm<-dlply(df_all,"Metadata_broad_sample",function(df) lm(UTSW_Median~Broad_Median,data=df))
cmpd_lm_coef<-ldply(cmpd_lm,coef)
names(cmpd_lm_coef)[names(cmpd_lm_coef)=="Broad_Median"]<-"Slope"
cmpd_lm_coef[,2]=c(1,2,3,4,5,6,7,8,9)
names(cmpd_lm_coef)[names(cmpd_lm_coef)=="(Intercept)"]<-"UTSW_Median"
cmpd_lm_coef=cbind(cmpd_lm_coef,Broad_Median=c(1,2,3,4,5,6,7,8,9))
cmpd_lm_coef[,3]=round(cmpd_lm_coef$Slope,3)
cmpd_lm_coef$Slope<-ldply(paste0("Slope=",cmpd_lm_coef$Slope))
colnames(cmpd_lm_coef[,3])<-"Slope"

ggplot(df_all, aes(x=UTSW_Median,y=Broad_Median,group=Metadata_broad_sample,color=Metadata_broad_sample)) + geom_point() + geom_smooth(method='lm',formula=y~x) + facet_wrap(~Metadata_broad_sample,scales="free") + labs(title=paste0("Correlation between Broad Data Set and Ours\nAfter PyCytominer Using the ",filetype," File")) + stat_poly_eq(label.x="left",label.y="top",size=2.5,color="black") + theme(strip.text = element_text(size = 6.2)) + geom_abs_text(data=cmpd_lm_coef,mapping = aes(label = Slope),color="black",size=2.5,xpos=0.7,ypos=0.18)
ggsave(paste0("CorrelationPlot_ByCmpd_",filetype,".png"), type = "cairo")