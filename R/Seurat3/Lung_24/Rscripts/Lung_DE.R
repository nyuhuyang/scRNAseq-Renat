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
source("../R/Seurat3_functions.R")
path <- paste0("output/",gsub("-","",Sys.Date()),"/")
if(!dir.exists(path))dir.create(path, recursive = T)

# SLURM_ARRAY_TASK_ID
slurm_arrayid <- Sys.getenv('SLURM_ARRAY_TASK_ID')
if (length(slurm_arrayid)!=1)  stop("Exact one argument must be supplied!")
# coerce the value to an integer
args <- as.numeric(slurm_arrayid)
print(paste0("slurm_arrayid=",args))

# samples
samples = c("proximal","distal","terminal")
(con <- samples[args])
(load(file = paste0("data/Lung_24",con,"_20191004.Rda")))

if(con == "proximal"){
    print(unique(object@meta.data$conditions))
    DefaultAssay(object) <- 'SCT'
    Idents(object) = "integrated_snn_res.0.8"
    object %<>% RenameIdents("0" = "T cells:CD4+",
                             "1" = "T cells:TRM",
                             "2" = "Intermediate cells",
                             "3" = "Mucous gland cells",
                             "4" = "Goblet",
                             "5" = "Macrophages",
                             "6" = "B cells",
                             "7" = "T cells:TRM",
                             "8" = "Endothelial cells:HEVs",
                             "9" = "Ciliated cells",
                             "10" = "Smooth muscle:Vascular",
                             "11" = "T cells:7SK.2+",
                             "12" = "Endothelial cells:Capillary",
                             "13" = "Basal cells",
                             "14" = "Fibroblasts",
                             "15" = "Neutrophils",
                             "16" = "Cartilage",
                             "17" = "Hybrid cells",
                             "18" = "Mast cells",
                             "19" = "Myo-epithelial cells",
                             "20" = "Pericytes",
                             "21" = "NK cells",
                             "22" = "Basal cells:Proliferating",
                             "23" = "T cells:CD4+",
                             "24" = "Ionocytes/NEC",
                             "25" = "Neurons",
                             "26" = "Endothelial cells:Lymphatic",
                             "27" = "Dendritic cells:Plasmacytoid")
    object@meta.data$cell.types = as.character(Idents(object))
    object@meta.data = cbind(object@meta.data,object@reductions$umap@cell.embeddings)
    plasma <- object@meta.data$UMAP_1 >7 & object@meta.data$UMAP_2 < -10
    object@meta.data[plasma,"cell.types"] = "B cells:Plasma"
    pre_ciliated <- object$integrated_snn_res.0.8==9 & object@meta.data$UMAP_2 < 14.25 & object@meta.data$UMAP_1 > 1.5
    object@meta.data[pre_ciliated,"cell.types"] = "Pre-ciliated cells"
    basal_like <- object$integrated_snn_res.0.8==11 &  object@meta.data$UMAP_1 < 2.2 & object@meta.data$UMAP_2 > -2.2
    object@meta.data[basal_like,"cell.types"] = "Basal-like cells"
    ASM <- object$integrated_snn_res.0.8==19 &  object@meta.data$UMAP_1 < -7.8
    object@meta.data[ASM,"cell.types"] = "Smooth muscle:Airway"
    
    (load(file = "data/Epi_23proximal_20190904.Rda"))
    serous <- colnames(Epi)[Epi$integrated_snn_res.0.8 == 1]
    object@meta.data[serous,"cell.types"] = "Serous gland cells"
    ESML <- object$integrated_snn_res.0.8==10 &  object@meta.data$UMAP_2 < -3
    object@meta.data[ESML,"cell.types"] = "Endothelial cells:Smooth muscle"
    prlif_mf <- object$integrated_snn_res.0.8==5 &  object@meta.data$UMAP_1 < 7.2
    object@meta.data[prlif_mf,"cell.types"] = "Macrophages:Proliferating"
    monocytes <- object$integrated_snn_res.0.8==5 &  object@meta.data$UMAP_2 < 2
    object@meta.data[monocytes,"cell.types"] = "Monocytes"
    DC <- object$integrated_snn_res.0.8==5 &  object@meta.data$UMAP_1 >10
    object@meta.data[DC,"cell.types"] = "Dendritic cells"
    
    # Endothelial cells
    Distal_markers <- read.csv("Yang/distal/Lung_24-distal_cell.types_markers.csv",
                               row.names = 1,stringsAsFactors = F)
    Terminal_markers <- read.csv("Yang/terminal/Lung_24-terminal_cell.types_markers.csv",
                               row.names = 1,stringsAsFactors = F)
    EC_At <- Distal_markers[(Distal_markers$cluster %in% "Endothelial cells:Arterial"),"gene"]
    (EC_At %<>% head(20))
    object %<>% AddModuleScore(features = list(EC_At), name = "EC_At")
    object@meta.data[object$EC_At1 > 1.1 ,"cell.types"]="Endothelial cells:Arterial"
    EC_p = object@assays$SCT@data["MKI67",] > 0 & object$integrated_snn_res.0.8 %in% 8
    object@meta.data[EC_p,"cell.types"]="Endothelial cells:Proliferating"
    
    mf_like <- Terminal_markers[(Terminal_markers$cluster %in% "Macrophages-like"),] %>% 
        .[order(.$avg_logFC, decreasing = TRUE),"gene"]
    (mf_like %<>% head(20))
    object %<>% AddModuleScore(features = list(mf_like), name = "mf_like")
    
}

if(con == "distal"){
    DefaultAssay(object) <- 'integrated'
    for(i in c(15,16)/10){
        object %<>% FindClusters(resolution = i)
        Idents(object) = paste0("integrated_snn_res.",i)
    }
    DefaultAssay(object) = "SCT"
    print(unique(object@meta.data$conditions))
    Idents(object) = "integrated_snn_res.0.8"
    object %<>% RenameIdents("0" = "Ciliated cells",
                             "1" = "T cells:TRM",
                             "2" = "Fibroblasts",
                             "3" = "Endothelial cells:Capillary",
                             "4" = "Endothelial cells:HEVs",
                             "5" = "Alveolar type 2",
                             "6" = "Secretory cells",
                             "7" = "Smooth muscle",
                             "8" = "NK cells",
                             "9" = "Monocytes",
                             "10" = "Ciliated intermediate cells",
                             "11" = "Basal cells",
                             "12" = "Macrophages",
                             "13" = "B cells",
                             "14" = "Neutrophils",
                             "15" = "T cells:CD4+",
                             "16" = "Mast cells",
                             "17" = "Hybrid cells",
                             "18" = "Alveolar macrophages",
                             "19" = "Endothelial cells:Lymphatic",
                             "20" = "T cells:7SK.2+",
                             "21" = "Pre-ciliated cells",
                             "22" = "Endothelial cells",
                             "23" = "B cells:Plasma",
                             "24" = "Endothelial cells:Arterial",
                             "25" = "Neutrophils",
                             "26" = "Endothelial cells:Proliferating",
                             "27" = "Cartilage",
                             "28" = "Neuroendocrine")
    Proximal_markers <- read.csv("Yang/proximal/Lung_24-proximal_cell.types_markers.csv",
                                 row.names = 1,stringsAsFactors = F)       
    object@meta.data$cell.types = as.character(Idents(object))
    object@meta.data = cbind(object@meta.data,object@reductions$umap@cell.embeddings)
    
    DC <- Proximal_markers[(Proximal_markers$cluster %in% "Dendritic cells"),"gene"]
    (DC %<>% head(20))
    object %<>% AddModuleScore(features = list(DC), name = "DC")
    DC = object$DC1 > 1.5 & object$integrated_snn_res.0.8 %in% 12
    object@meta.data[DC,"cell.types"]="Dendritic cells"
    
    NK_like <- Proximal_markers[(Proximal_markers$cluster %in% "NK-like cells"),"gene"]
    (NK_like %<>% head(20))
    object %<>% AddModuleScore(features = list(NK_like), name = "NK_like")
    NK_like = object$NK_like1 > 0.8
    object@meta.data[NK_like,"cell.types"]="Dendritic cells:Plasmacytoid"
    
    object@meta.data[DC,"cell.types"]="Dendritic cells"
    macrophage_p = object@assays$SCT@data["MKI67",] > 0 & object$integrated_snn_res.0.8 %in% 12
    object@meta.data[macrophage_p,"cell.types"]="Macrophages:Proliferating"
    
    object@meta.data[object$integrated_snn_res.1.5 %in% 21,"cell.types"]="Secretory cells:Distal"
    basal_p <- object@meta.data$UMAP_1 < -5 & object@meta.data$UMAP_2 > 0 & 
        object@meta.data$UMAP_2 < 5 & object$integrated_snn_res.1.5 %in% 28
    
    object@meta.data[basal_p,"cell.types"]="Basal cells:Proliferating"
    unknow <- object@meta.data$UMAP_1 > 0  & object@meta.data$UMAP_1 < 5 & 
        object$integrated_snn_res.1.5 %in% 28
    object@meta.data[unknow,"cell.types"]="Unknown"
    Fibroblast_p <- object@meta.data$UMAP_2 > 9 & object$integrated_snn_res.1.5 %in% 28
    object@meta.data[Fibroblast_p,"cell.types"]="Fibroblasts:Proliferating"
    
    Idents(object) = "integrated_snn_res.1.5"
    Intermediate_genes <- Proximal_markers[(Proximal_markers$cluster %in% "Intermediate cells"),"gene"]
    (Intermediate_genes %<>% head(20))
    object %<>% AddModuleScore(features = list(c(Intermediate_genes)), name = "Intermediate_genes")
    Intermediate = object$Intermediate_genes1 > 1.5 & object$UMAP_1 < -6
    object@meta.data[Intermediate,"cell.types"]="Intermediate cells"

    
    object@meta.data[object$integrated_snn_res.1.6 %in% 11,"cell.types"]="Smooth muscle:Vascular"
    object@meta.data[object$integrated_snn_res.1.6 %in% 21,"cell.types"]="Smooth muscle:Airway"
    object@meta.data[object$integrated_snn_res.1.6 %in% 27,"cell.types"]="Endothelial cells:Smooth muscle"
    object@meta.data[object$integrated_snn_res.1.6 %in% 28,"cell.types"]="Pericytes"
    object@meta.data[object$integrated_snn_res.1.6 %in% 31,"cell.types"]="B cells:Plasma"
    object@meta.data[object$integrated_snn_res.1.6 %in% 36,"cell.types"]="Alveolar type 1"
    object@meta.data[object$cell.types %in% "Endothelial cells","cell.types"] = "T cells:TRM"
    object@meta.data[object$cell.types %in% "Smooth muscle","cell.types"] = "Ciliated cells"

    }


if(con == "terminal"){
    DefaultAssay(object) = "integrated"
    DefaultAssay(object) = "SCT"
    Idents(object) = "integrated_snn_res.0.8"
    print(unique(object@meta.data$conditions))
    object@meta.data = cbind(object@meta.data,object@reductions$umap@cell.embeddings)
    object %<>% RenameIdents("0" = "T cells:TRM",
                             "1" = "Macrophages",
                             "2" = "Alveolar type 2",
                             "3" = "Endothelial cells:Capillary",
                             "4" = "Neutrophils",
                             "5" = "NK cells",
                             "6" = "Monocytes",
                             "7" = "Ciliated cells",
                             "8" = "Secretory cells",
                             "9" = "Smooth muscle:Vascular",
                             "10" = "B cells", 
                             "11" = "Fibroblasts",
                             "12" = "Alveolar macrophages",
                             "13" = "Endothelial cells:HEVs",
                             "14" = "Basal cells",
                             "15" = "T cells:TRM",
                             "16" = "Neutrophils",
                             "17" = "Mast cells",
                             "18" = "Endothelial cells:Smooth muscle",
                             "19" = "Endothelial cells:Arterial",
                             "20" = "Endothelial cells:Lymphatic",
                             "21" = "B cells:Plasma")
    object@meta.data$cell.types = as.character(Idents(object))
    (load(file="data/Epi_23terminal_20190904.Rda"))
    object@meta.data[colnames(Epi)[Epi$integrated_snn_res.1 %in% 11],
                     "cell.types"] = "Hybrid cells" # double check
    object@meta.data[colnames(Epi)[Epi$integrated_snn_res.1 %in% 1],
                     "cell.types"] = "Secretory cells"
    object@meta.data[colnames(Epi)[Epi$integrated_snn_res.1 %in% c(2,10)],
                     "cell.types"] = "Secretory cells:Distal"
    object@meta.data[colnames(Epi)[Epi$integrated_snn_res.1 %in% 9],
                     "cell.types"] = "Basal cells"
    #
    Proximal_markers <- read.csv("Yang/proximal/Lung_24-proximal_cell.types_markers.csv",
                                 row.names = 1,stringsAsFactors = F)
    Distal_markers <- read.csv("Yang/distal/Lung_24-distal_cell.types_markers.csv",
                               row.names = 1,stringsAsFactors = F)
    object@meta.data[colnames(Epi)[Epi$integrated_snn_res.0.8 %in% 13],"cell.types"] = "Pre-ciliated cells"
    AT1 <- object@meta.data$UMAP_1 < -1 & object@meta.data$UMAP_2 > 7.4 & object@meta.data$UMAP_1 > -2.5
    object@meta.data[AT1,"cell.types"] = "Alveolar type 1"
    object@meta.data[(object$integrated_snn_res.0.8 %in% 14 &
                         object$UMAP_2 < 5.3),"cell.types"] = "Neuroendocrine"
    object@meta.data[(object$UMAP_1 < -5 & object$UMAP_2 < -5),"cell.types"] = "B cells"
    object@meta.data[(object$integrated_snn_res.0.8 %in% 9 &
                          object$UMAP_1 < 8.7 & object$UMAP_2 < 3.6),"cell.types"] = "Pericytes"

    basal <- object@meta.data$cell.types %in% "Basal cells"
    type1 <- object@meta.data$UMAP_1 < -1 & object@meta.data$UMAP_2 >6 
    object@meta.data[(basal & type1),"cell.types"] = "Alveolar type 1"
    
    proliferating <- as.vector(object@assays$SCT["MKI67",] >0 )
    object@meta.data[proliferating & basal,"cell.types"] = "Basal cells:Proliferating"
    object@meta.data[proliferating & object$cell.types %in% "Macrophages","cell.types"] = "Macrophages:Proliferating"

    Av_mf <-  Distal_markers[(Distal_markers$cluster %in% "Alveolar macrophages"),"gene"]
    (Av_mf %<>% head(20))
    object %<>% AddModuleScore(features = list(Av_mf), name = "Alveolar macrophages")
    Av_mf = object$`Alveolar macrophages1` > 1.5 & object$integrated_snn_res.0.8 %in% c(1,12)
    object@meta.data[Av_mf,"cell.types"] = "Alveolar macrophages"
    
    DC <- Proximal_markers[(Proximal_markers$cluster %in% "Dendritic cells"),"gene"]
    (DC %<>% head(20))
    object %<>% AddModuleScore(features = list(DC), name = "DC")
    DC = (as.vector(object@assays$SCT["CCR7"] > 1) & object$cell.types %in% "Macrophages") |
        (object$integrated_snn_res.0.8 %in% 21 & object$UMAP_2 >0 )
    
    object@meta.data[DC,"cell.types"]="Dendritic cells"
    object@meta.data[(object$cell.types %in% "Macrophages" &
                          object$UMAP_1 > 0 ),"cell.types"] = "Macrophages-like"
    NK_like <- Proximal_markers[(Proximal_markers$cluster %in% "NK-like cells"),"gene"]
    (NK_like %<>% head(20))
    object %<>% AddModuleScore(features = list(NK_like), name = "NK_like")
    NK_like = object$NK_like1 > 0.8
    object@meta.data[NK_like,"cell.types"]="Dendritic cells:Plasmacytoid"
    
    Airway <- Proximal_markers[(Proximal_markers$cluster %in% "Airway smooth muscle"),] %>% 
        .[order(.$avg_logFC, decreasing = TRUE),"gene"]
    (Airway %<>% head(20))
    object %<>% AddModuleScore(features = list(Airway), name = "Airway")
    Airway = object$Airway1 > 2
    object@meta.data[Airway,"cell.types"]="Smooth muscle:Airway"
    
    # for T cells
    object@meta.data[(object$integrated_snn_res.0.8 %in% 15 &
                          object$UMAP_2 > -7.3 ),"cell.types"] = "T cells:7SK.2"
    T_CD4 <- Proximal_markers[(Proximal_markers$cluster %in% "T cells:CD4+"),"gene"]
    (T_CD4 %<>% head(20))
    object %<>% AddModuleScore(features = list(T_CD4), name = "T_CD4")
    T_CD4 = object$T_CD41 > 1 & object$integrated_snn_res.0.8 %in% 0
    object@meta.data[T_CD4,"cell.types"]="T cells:CD4+"

    }

Idents(object) = "cell.types"
object %<>% sortIdent()
UMAPPlot.1(object = object, label = T,label.repel = T, group.by = "cell.types", 
           cols = Singler.colors,legend.size = 15,
           do.return = F, no.legend = T, title = paste("UMAP plot for all clusters in",con),
           pt.size = 0.2,alpha = 0.85, label.size = 3, do.print = T,
           unique.name = "conditions")

UMAPPlot.1(object = object, label = F,label.repel = F, group.by = "cell.types", 
           cols = Singler.colors,legend.size = 15,
           do.return = F, no.legend = F, title = paste("UMAP plot for all clusters in",con),
           pt.size = 0.2,alpha = 0.85, label.size = 3, do.print = T,unique.name = "conditions")
UMAPPlot.1(object = object, label = F,label.repel = F, group.by = "cell.types", 
           cols = Singler.colors,legend.size = 15,
           do.return = F, no.legend = T, title = paste("UMAP plot for all clusters in",con),
           pt.size = 0.2,alpha = 0.85, label.size = 3, do.print = T,unique.name = "conditions")
save(object, file = paste0("data/Lung_24",con,"_20191004.Rda"))

Lung_markers <- FindAllMarkers.UMI(object, logfc.threshold = 0.1, only.pos = F,
                                   test.use = "MAST")
Lung_markers = Lung_markers[Lung_markers$p_val_adj<0.05,]
write.csv(Lung_markers,paste0(path,"Lung_24-",con,"_cell.types_markers.csv"))
