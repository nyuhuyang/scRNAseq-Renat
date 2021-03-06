# ######################################################################
library(Seurat)
library(dplyr)
library(kableExtra)
library(magrittr)
library(ggplot2)
library(cowplot)
library(tibble)
library(ggsci)
library(openxlsx)
library(viridisLite)
source("https://raw.githubusercontent.com/nyuhuyang/SeuratExtra/master/R/Seurat3_functions.R")
path <- paste0("output/",gsub("-","",Sys.Date()),"/")
if(!dir.exists(path)) dir.create(path, recursive = T)

#======1.2 load  Seurat =========================
# load files
object = readRDS(file = "data/Lung_30_20200710.rds") 
DefaultAssay(object) = "SCT"
Idents(object) = "Doublets"
object <- subset(object, idents = "Singlet")

anno <- readxl::read_excel("doc/Annotations/Cell type abbreviation.xlsx")
table(anno$Abbreviation %in% object$annotations3)
object$cell_types <- plyr::mapvalues(object$annotations3,
                                     from = anno$Abbreviation,
                                     to = anno$`Revised abbreviations`)
cell.type_list <- list("Epithelial" = c("BC1","BC2","BC-p","IC1","IC2","IC3","S","d-S",
                                        "H","p-C","C1","C2","C3","Ion","NE","ME","g-Muc",
                                        "g-Ser","AT1","AT2","AT2-1","AT2-p"),
                       "Stromal"=c("F1","F2","F3","F4","Cr","Gli","Nr","SM1",
                                   "SM2","SM3","Pr","En-a","En-c","En-c1","En-v","En-l","En-sm","En-p"),
                       "Immune" = c("MC","Neu","Mon","M0","M1","M1-2","M2","M-p","DC","p-DC",
                                    "B","PC","T-cn","T-reg","T-int","T-rm","T-NK","T-ifn","T-p"))
cell.type_list = unlist(cell.type_list)
Idents(object) = "cell_types"
object %<>% subset(idents = cell.type_list)
object@meta.data$cell_types %<>% factor(levels =cell.type_list)
object$regions = object$conditions
object@meta.data$regions %<>% factor(levels = c("proximal","distal","terminal","COPD"))
Idents(object) = "regions"
object %<>% subset(idents = c("proximal","distal","terminal"))
# save data and subset
object <- Lung
#Lung <- object
cells <- sample(colnames(object), size = 1000)
object %<>% subset(cells=cells)
# sort order
meta.data = object@meta.data[,c("cell_types","regions")]
meta.data = meta.data[order(meta.data$regions,meta.data$cell_types),]

heatmap_df <- readxl::read_excel("doc/PDT for heatmap.xlsx",col_names = F)

group1.colors<- c("#1F78B4","#4ca64c","#E6AB02")##C53B19
names(group1.colors) = c("proximal","distal","terminal")#,"COPD")

group_colors <- object@meta.data[!duplicated(object$cell_types),c("cell_types","cell_types.colors")]
group2.colors = group_colors[order(group_colors$cell_types),"cell_types.colors"]
names(group2.colors) = sort(group_colors$cell_types)

object@meta.data$cell_types %<>% droplevels()
object@meta.data$regions %<>% droplevels()

Idents(object) = "regions"
DoHeatmap.2(object = object, features = heatmap_df$...2, cells = rownames(meta.data),
            do.print=T, do.return=F,
            angle = 0,
            slot = "data",
            group.by = c("regions","cell_types"),group.bar = T,
            group1.colors = group1.colors,
            group2.colors= group2.colors,
            title.size = 22, no.legend = F,legend.size = 20,
            size=7,hjust = 0.5,
            group.bar.height = 0.02, label=F, cex.row= 20,
            width=16, height=10,
            #colors = ggsci::pal_gsea()(12),
            #colors = c(viridis(8),"white",inferno(8,direction = -1))[3:15],
            colors = c("#1034A6",viridis(8)[c(5,7)],"yellow","orange","chocolate1","red"),
            nrow = 5, ncol = 8, design = c(patchwork::area(1, 1, 5, 5),
                                           patchwork::area(3, 6, 3, 8)),
            file.name = "Heatmap_cell.types_tissue.jpeg",
            title = "Lung cell types and regions",
            save.path = path)


