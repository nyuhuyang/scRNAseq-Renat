########################################################################
#
#  0 setup environment, install libraries if necessary, load libraries
# 
# ######################################################################

library(Seurat)
library(dplyr)
library(tidyr)
library(gplots)
library(MAST)
library(ggpubr)
source("../R/Seurat3_functions.R")
path <- paste0("output/",gsub("-","",Sys.Date()),"/")
if(!dir.exists(path))dir.create(path, recursive = T)
set.seed(1001)

# SLURM_ARRAY_TASK_ID
slurm_arrayid <- Sys.getenv('SLURM_ARRAY_TASK_ID')
if (length(slurm_arrayid)!=1)  stop("Exact one argument must be supplied!")
# coerce the value to an integer
args <- as.numeric(slurm_arrayid)
print(paste0("slurm_arrayid=",args))

# samples
samples = c("proximal","distal","terminal")
(con <- samples[args])

# 5.0 Preliminaries: Load the data
(load(file = paste0("data/Epi_23",con,"_20190904.Rda")))
Idents(Epi) = "integrated_snn_res.0.8"
Lung_markers <- FindAllMarkers.UMI(Epi, logfc.threshold = 0.1, only.pos = T,
                                   test.use = "MAST")
Lung_markers = Lung_markers[Lung_markers$p_val_adj<0.05,]
write.csv(Lung_markers,paste0(path,"Epi_23-",con,"_markers.csv"))

Top_n = 5
top = Lung_markers %>% group_by(cluster) %>% top_n(Top_n, avg_logFC)
Epi %<>% ScaleData(features=unique(c(as.character(top$gene))))

DoHeatmap.1(Epi, marker_df = Lung_markers, Top_n = 5, do.print=T,
            angle = 0,group.bar = T, title.size = 13, no.legend = F,size=4,hjust = 0.5,
            assay = "SCT",
            label=T, cex.row=5, legend.size = 5,width=10, height=7,unique.name = "conditions",
            title = paste("Top 5 markers of each clusters in",con,"sampels"))