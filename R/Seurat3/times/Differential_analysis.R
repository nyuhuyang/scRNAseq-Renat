########################################################################
#
#  0 setup environment, install libraries if necessary, load libraries
# 
# ######################################################################

library(Seurat)
library(dplyr)
library(tidyr)
library(kableExtra)
library(gplots)
library(MAST)
source("https://raw.githubusercontent.com/nyuhuyang/SeuratExtra/master/R/Seurat3_functions.R")
path <- paste0("output/",gsub("-","",Sys.Date()),"/")
if(!dir.exists(path))dir.create(path, recursive = T)
#3.1  Compare DE across all major cell types==================
#We would need the data for all clusters, as well the subclusters.
#detect changes in gene expression between young and aged, 
#in the different cell types and subtypes. 
#It will also be interesting to check if there is some subtype enriched in young compared to aged or viceversa. 

# 3.1.1 load data
# Rename ident
samples = c("All","Day-0","Day-3","Day-7","Day-14","Day-21","Day-28")
             #"Day-56","Day-122"))
object = readRDS(file = "data/Lung_time_6_20201001.rds")
Idents(object) <-  "Doublets"
#table(Idents(object)) %>% prop.table(margin=2) %>% kable_styling()
object %<>% subset(idents = "Singlet")
Idents(object) <- "orig.ident"
for(sample in samples){
        sub_object <- subset(object, idents = (if(sample == "All") samples[-1] else sample))
        Idents(sub_object) <- "integrated_snn_res.0.6"
        Lung_markers <- FindAllMarkers.UMI(sub_object, logfc.threshold = 0.25,
                                           only.pos = T)
        
        write.csv(Lung_markers,paste0(path,"Lung_6-",sample,"_markers.csv"))

        Lung_markers =read.csv(file = paste0("output/20190808/Lung_6-",sample,"_markers.csv"),
                               row.names = 1, stringsAsFactors=F)
        TSNEPlot.1(sub_object,label = T, repel = T, label.repel = T,no.legend = F,pt.size = 1,
                   cols = ExtractMetaColor(sub_object),do.return = F,do.print = T,
                   unique.name = T,label.size = 5,
                   title = paste("All clusters in",sample,
                                 ifelse(sample=="All","sampels","sample")))
        UMAPPlot.1(sub_object,label = T, repel = T, label.repel = T,no.legend = F,pt.size = 1,
                   cols = ExtractMetaColor(sub_object),do.return = F,do.print = T,
                   unique.name = T,label.size = 5,
                   title = paste("All clusters in",sample,
                                 ifelse(sample=="All","sampels","sample")))
        Top_n = 5
        top = Lung_markers %>% group_by(cluster) %>% top_n(Top_n, avg_logFC)
        sub_object %<>% ScaleData(features=unique(c(as.character(top$gene))))
        
        DoHeatmap.1(sub_object, marker_df = Lung_markers, Top_n = 5, do.print=T, angle = 0,
                    group.bar = T, title.size = 13, no.legend = F,size=4,hjust = 0.5,
                    assay = "SCT",
                    label=T, cex.row=5, legend.size = 5,width=10, height=7,unique.name = T,
                    title = paste("Top 5 markers in each clusters",sample,
                                  ifelse(sample=="All","sampels","sample")))
}

for(sample in samples){
        Lung_markers =read.csv(file = paste0("output/20190808/Lung_6-",sample,"_markers.csv"),
                               row.names = 1, stringsAsFactors=F)
        Lung_markers = Lung_markers[Lung_markers$p_val_adj<0.05,]
        write.csv(Lung_markers,paste0("output/20190808/Lung_6-",sample,"_markers.csv"))
        
}

#split by samples================
Idents(object) <- 'orig.ident'
table(Idents(object))

#CU12-D
CU12_D <- subset(object, ident = "CU12-D")
Idents(CU12_D) <-"singler1sub"

TSNEPlot.1(CU12_D,label = F, repel = F, no.legend = F,pt.size = 1,
           cols = ExtractMetaColor(CU12_D),do.return = F,do.print = T,
           title = "All clusters in CU12-D")

CU12_D.markers <- FindAllMarkers.UMI(object = CU12_D, logfc.threshold = 1,
                                     only.pos = T,test.use = "MAST")
write.csv(CU12_D.markers,paste0(path,"CU12_D.markers.csv"))
table(CU12_D.markers$cluster)
DoHeatmap.1(CU12_D, CU12_D.markers, Top_n = 10, do.print=T, angle = 0,
            group.bar = T, title.size = 13, no.legend = F,size=0,hjust = 0.5,
            label=T, cex.row=4, legend.size = 5,width=10, height=7,
            title = "Top 10 markers in all clusters in CU12-D")

#CU12-D-repeat
CU12_D_r <- subset(object, ident = "CU12-D-Repeat")
Idents(CU12_D_r) <-"singler1sub"

TSNEPlot.1(CU12_D_r,label = F, repel = F, no.legend = F,pt.size = 1,
           cols = ExtractMetaColor(CU12_D_r),do.return = F,do.print = T,
           title = "All clusters in CU12-D-Repeat")
CU12_D_r.markers <- FindAllMarkers.UMI(object = CU12_D_r, logfc.threshold = 1,
                                       only.pos = T,test.use = "MAST")
write.csv(CU12_D_r.markers,paste0(path,"CU12_D_r.markers.csv"))

DoHeatmap.1(CU12_D_r, CU12_D_r.markers, Top_n = 10, do.print=T, angle = 0,
            group.bar = T, title.size = 13, no.legend = F,size=0,hjust = 0.5,
            label=T, cex.row=4, legend.size = 5,width=10, height=7,
            title = "Top 3 markers in all clusters in CU12-D-Repeat")

#CU12-T
CU12_T <- subset(object, ident = "CU12-T")
Idents(CU12_T) <-"singler1sub"

TSNEPlot.1(CU12_T,label = F, repel = F, no.legend = F,pt.size = 1,
           cols = ExtractMetaColor(CU12_T),do.return = F,do.print = T,
           title = "All clusters in CU12-T")
CU12_T.markers <- FindAllMarkers.UMI(object = CU12_T, logfc.threshold = 1,
                                     only.pos = T,test.use = "MAST")
write.csv(CU12_T.markers,paste0(path,"CU12_T.markers.csv"))

table(CU12_T.markers$cluster)
DoHeatmap.1(CU12_T, CU12_T.markers, Top_n = 10, do.print=T, angle = 0,
            group.bar = T, title.size = 13, no.legend = F,size=0,hjust = 0.5,
            label=T, cex.row=4, legend.size = 5,width=10, height=7,
            title = "All clusters in CU12-T")
