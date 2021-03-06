library(Seurat)
library(dplyr)

case.data <- read.table('CASE.txt',sep='\t',check.name=F,row.names=1,header=T)
case <- CreateSeuratObject(raw.data = case.data, min.cells = 3, min.genes = 200, project = "Natalie")
mito.genes <- grep(pattern = "^mt-", x = rownames(x = case@data), value = TRUE)
percent.mito <- Matrix::colSums(case@raw.data[mito.genes, ])/Matrix::colSums(case@raw.data)
case <- AddMetaData(object = case, metadata = percent.mito, col.name = "percent.mito")
case <- AddMetaData(object = case, metadata = case@ident, col.name = "batch")
VlnPlot(object = case, features.plot = c("nGene", "nUMI", "percent.mito"), nCol = 3)
case@meta.data$stim <- "case"
case=FilterCells(object = case, subset.names = c("nGene", "percent.mito"), low.thresholds = c(500, -Inf), high.thresholds = c(2500, 0.1))
case <- NormalizeData(object = case, normalization.method = "LogNormalize", scale.factor = 10000)
case <- FindVariableGenes(object = case, do.plot = F, mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff =0, y.cutoff = 0.0)
length(x=case@var.genes) #10963
case = ScaleData(object = case,vars.to.regress = c("percent.mito", "nUMI", "batch"), genes.use=case@var.genes)


wt.data <- read.table('WT.txt',sep='\t',check.name=F,row.names=1,header=T)
wt <- CreateSeuratObject(raw.data = wt.data, min.cells = 3, min.genes = 200, project = "Natalie")
mito.genes <- grep(pattern = "^mt-", x = rownames(x = wt@data), value = TRUE)
percent.mito <- Matrix::colSums(wt@raw.data[mito.genes, ])/Matrix::colSums(wt@raw.data)
wt <- AddMetaData(object = wt, metadata = percent.mito, col.name = "percent.mito")
wt <- AddMetaData(object = wt, metadata = wt@ident, col.name = "batch")
VlnPlot(object = wt, features.plot = c("nGene", "nUMI", "percent.mito"), nCol = 3)
wt@meta.data$stim <- "wt"
wt=FilterCells(object = wt, subset.names = c("nGene", "percent.mito"), low.thresholds = c(500, -Inf), high.thresholds = c(2500, 0.1))
wt <- NormalizeData(object = wt, normalization.method = "LogNormalize", scale.factor = 10000)
wt <- FindVariableGenes(object = wt, do.plot = F, mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff =0, y.cutoff = 0.0)
length(x=wt@var.genes) #6977
wt = ScaleData(object = wt,vars.to.regress = c("percent.mito", "nUMI", "batch"), genes.use=wt@var.genes)


case <- FindVariableGenes(object = case, do.plot = F, mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff =0, y.cutoff = 0.2)
length(x=case@var.genes) #6851
wt <- FindVariableGenes(object = wt, do.plot = F, mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff =0, y.cutoff = 0.2)
length(x=wt@var.genes) #5678

g.1=case@var.genes
g.2=wt@var.genes
genes.use <- unique(c(g.1, g.2)) 
genes.use <- intersect(genes.use, rownames(case@scale.data))
genes.use <- intersect(genes.use, rownames(wt@scale.data))
length(genes.use) #3523


rm(case.data)
rm(wt.data)

NUMCC=30
combined_data = RunCCA(case, wt, genes.use = genes.use, num.cc = NUMCC)
pdf('CCA1.pdf') 
DimPlot(object = combined_data, reduction.use = "cca", group.by = "stim",  pt.size = 0.5, do.return = F)
dev.off()

DIM=1:30
combined_data <- AlignSubspace(combined_data, reduction.type = "cca", grouping.var = "stim",  dims.align = DIM)

TSNE_DIM=1:20
combined_data <- RunTSNE(combined_data, reduction.use = "cca.aligned", dims.use = TSNE_DIM, do.fast = T)

save(combined_data, file = "./combine.Robj")


pdf('./TSNE.pdf',width=20, height=12)
TSNEPlot(combined_data, do.return = F,  group.by = "stim")
dev.off()




