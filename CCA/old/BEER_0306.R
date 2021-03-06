# Batch EffEct Remover of single-cell data (BEER)
# Author: Feng Zhang
# Date: Mar. 6, 2019

#source('https://raw.githubusercontent.com/jumphone/Bioinformatics/master/CCA/BEER.R')

#library(Seurat)
#library(dtw)
#library(MALDIquant)
#library(pcaPP)
#source('https://raw.githubusercontent.com/jumphone/scRef/master/scRef.R')


.data2one <- function(DATA, GENE, CPU=4, PCNUM=100){
    PCUSE=1:PCNUM
    print('Start')
    library(Seurat)
    print('Step1.Create Seurat Object...')
    DATA = CreateSeuratObject(raw.data = DATA, min.cells = 0, min.genes = 0, project = "DATA") 
    print('Step2.Normalize Data...')
    DATA <- NormalizeData(object = DATA, normalization.method = "LogNormalize", scale.factor = 10000)
    print('Step3.Scale Data...')
    DATA <- ScaleData(object = DATA, genes.use =GENE, vars.to.regress = c("nUMI"), num.cores=CPU, do.par=TRUE)
    print('Step4.PCA...')
    DATA <- RunPCA(object = DATA, pcs.compute=PCNUM, pc.genes =GENE, do.print = FALSE)
    print('Step5.One-dimention...')
    DATA <- RunTSNE(object = DATA, dims.use = PCUSE, do.fast=TRUE,dim.embed = 1)
    DR=DATA@dr$tsne@cell.embeddings
    print('Finished!!!')
    return(DR)
    }

.getGroup <- function(X,TAG,CNUM=100){
    DR=X
    RANK=rank(DR,ties.method='random')
    CUTOFF=CNUM 
    GROUP=rep('NA',length(RANK))
    i=1
    j=1
    while(i<=length(RANK)){
        GROUP[which(RANK==i)]=paste0(TAG,'_',as.character(j))
        #if(i%%CUTOFF==1){j=j+1;print(j)}
        if(i%%CUTOFF==1){j=j+1}
        i=i+1}
    print('Group Number:')
    print(j-1)
    return(GROUP)
}


.getValidpair <- function(DATA1, GROUP1, DATA2, GROUP2, CPU=4, method='kendall', print_step=10){
    source('https://raw.githubusercontent.com/jumphone/scRef/master/scRef.R')
    print('Start')
    print('Step1.Generate Reference...')
    REF1=.generate_ref(DATA1, cbind(GROUP1, GROUP1), min_cell=1) 
    REF2=.generate_ref(DATA2, cbind(GROUP2, GROUP2), min_cell=1) 
    print('Step2.Calculate Correlation Coefficient...')
    out = .get_cor( REF1, REF2, method=method,CPU=CPU, print_step=print_step)
    print('Step3.Analyze Result...')
    tag1=.get_tag_max(out)
    tag2=.get_tag_max(t(out))
    V=c()
    i=1
    while(i<=nrow(tag1)){
        t1=tag1[i,1]
        t2=tag1[i,2]
        if(tag2[which(tag2[,1]==t2),2]==t1){V=c(V,i)}           
        i=i+1}
    VP=tag1[V,]
    C=c()
    t=1
    while(t<=nrow(VP)){
        this_c=out[which(rownames(out)==VP[t,2]),which(colnames(out)==VP[t,1])]
        C=c(C,this_c)
        t=t+1}
    #if(do.plot==TRUE){plot(C)}
    #VP=VP[which(C>=CUTOFF),]  
    print('Finished!!!')
    OUT=list()
    OUT$vp=VP
    OUT$cor=C
    return(OUT)
    }



.dr2adr <- function(DR, B1index, B2index, GROUP, VP, CUTOFF=0.05){
    
    OUT=list()
    OUT$adr=DR
    VALID_PAIR=VP
    
    ALL_COEF=c()
    ALL_COEFPV=c()
    ALL_COR=c()   
    ALL_PV=c() 
    
    index1=B1index
    index2=B2index 
    
    print('Start')
    THIS_DR=1
    while(THIS_DR<=ncol(DR)){
        THIS_PC = DR[,THIS_DR]
        
        all_lst1=DR[index1,THIS_DR]
        all_lst2=DR[index2,THIS_DR] 
        
        lst1_mean=c()
        lst2_mean=c()
        i=1
        while(i<=nrow(VALID_PAIR)){
            this_pair=VALID_PAIR[i,]
            this_index1=which(GROUP %in% this_pair[1])
            this_index2=which(GROUP %in% this_pair[2])
            lst1_mean=c(lst1_mean,mean(DR[this_index1,THIS_DR]))
            lst2_mean=c(lst2_mean,mean(DR[this_index2,THIS_DR]))
            
            i=i+1}
        
        
        
        this_fit=lm(lst2_mean~lst1_mean) 
        this_coef= this_fit$coefficients
        sum_this_fit=summary(this_fit)
        this_coefpv=sum_this_fit$coefficients[,4]
        
        if(this_coefpv[1]<CUTOFF & this_coefpv[2]<CUTOFF){
            
            OUT$adr[index1,THIS_DR]= this_coef[1]+ all_lst1*this_coef[2] 
            
        }else if(this_coefpv[1]<CUTOFF & this_coefpv[2]>CUTOFF){
            
            OUT$adr[index1,THIS_DR]= this_coef[1]+ all_lst1
            
        }else if(this_coefpv[1]>CUTOFF & this_coefpv[2]<CUTOFF){
            
            OUT$adr[index1,THIS_DR]= all_lst1*this_coef[2]
            
        }else{ OUT$adr[index1,THIS_DR]= all_lst1 }
            
            OUT$adr[index2,THIS_DR]= all_lst2
        
        this_test=cor.test(lst1_mean,lst2_mean)
        this_cor=this_test$estimate
        this_pv=this_test$p.value
       
        ALL_COEF=cbind(ALL_COEF,this_coef)
        ALL_COEFPV=cbind(ALL_COEFPV,this_coefpv)
        ALL_COR=c(ALL_COR, this_cor)
        ALL_PV=c(ALL_PV, this_pv) 
        print(THIS_DR)
        
        THIS_DR=THIS_DR+1}
    
    OUT$adr=OUT$adr
    OUT$coef=ALL_COEF
    OUT$coefpv=ALL_COEFPV
    OUT$cor=ALL_COR
    OUT$pv=ALL_PV
    OUT$fdr=p.adjust(ALL_PV,method='fdr')
    print('Finished!!!')
    return(OUT)
   }


BEER <- function(D1, D2, CNUM=10, PCNUM=50, VPCOR=0, CPU=4, print_step=10){
    RESULT=list()
    library(Seurat)
    source('https://raw.githubusercontent.com/jumphone/scRef/master/scRef.R')
    print('BEER start!')
    D1=D1
    D2=D2
    CNUM=CNUM
    PCNUM=PCNUM
    print_step=print_step
    
    print('############################################################################')
    print('MainStep1.Combine Data...')
    print('############################################################################')
    EXP=.simple_combine(D1,D2)$combine
    pbmc=CreateSeuratObject(raw.data = EXP, min.cells = 0, min.genes = 0, project = "ALL")
    
    
    print('############################################################################')
    print('MainStep2.Preprocess Data...')
    print('############################################################################')
    pbmc <- NormalizeData(object = pbmc, normalization.method = "LogNormalize", scale.factor = 10000)
    pbmc <- FindVariableGenes(object = pbmc, do.plot=F,mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff = 0.0125, x.high.cutoff = 3, y.cutoff = 0.5)
    #length(x = pbmc@var.genes)
    pbmc <- ScaleData(object = pbmc, genes.use=pbmc@var.genes, vars.to.regress = c("nUMI"), num.cores=CPU, do.par=TRUE)
    pbmc <- RunPCA(object = pbmc, pcs.compute=PCNUM,pc.genes = pbmc@var.genes, do.print =F)
    
    print('############################################################################')
    print('MainStep3.Convert to one-dimension...')
    print('############################################################################')
    D1X=.data2one(D1, pbmc@var.genes, CPU, PCNUM)
    D2X=.data2one(D2, pbmc@var.genes, CPU, PCNUM)
    G1=.getGroup(D1X,'D1',CNUM)
    G2=.getGroup(D2X,'D2',CNUM)
    GROUP=c(G1,G2)
    CONDITION=c(rep('D1',ncol(D1)),rep('D2',ncol(D2)))
    pbmc@meta.data$group=GROUP
    pbmc@meta.data$condition=CONDITION
    
    
    print('############################################################################')
    print('MainStep4.Get Valid Pairs...')
    print('############################################################################')
    VP_OUT=.getValidpair(D1, G1, D2, G2, CPU, method='kendall', print_step)
    #VP_OUT=.getValidpair(D1, G1, D2, G2, 4, 'kendall', 10)
    VP=VP_OUT$vp
    VP=VP[which(VP_OUT$cor>=VPCOR),]
    MAP=rep('NA',length(GROUP))
    MAP[which(GROUP %in% VP[,1])]='D1'
    MAP[which(GROUP %in% VP[,2])]='D2'
    pbmc@meta.data$map=MAP
    
    print('############################################################################')
    print('MainStep5.Detect batch effect & linear adjustment...')
    print('############################################################################')
    DR=pbmc@dr$pca@cell.embeddings 
    B1index=which(CONDITION=='D1')
    B2index=which(CONDITION=='D2')
    OUT=.dr2adr(DR, B1index, B2index, GROUP, VP, 0.05)
    pbmc@dr$adjpca=pbmc@dr$pca
    pbmc@dr$adjpca@cell.embeddings=OUT$adr
    
    ########################## 
    RESULT$seurat=pbmc
    RESULT$vp=VP
    RESULT$vpcor=VP_OUT$cor
    RESULT$d1x=D1X
    RESULT$d2x=D2X
    RESULT$g1=G1
    RESULT$g2=G2
    RESULT$cor=OUT$cor
    RESULT$pv=OUT$pv
    RESULT$fdr=OUT$fdr
    RESULT$coef=OUT$coef
    RESULT$coefpv=OUT$coefpv
    #RESULT$pcuse=PCUSE
    print('############################################################################')
    print('BEER cheers !!! All main steps finished.')
    print('############################################################################')
    return(RESULT)
    }


