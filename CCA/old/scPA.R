
#library(Seurat)
#source('https://raw.githubusercontent.com/jumphone/scRef/master/scRef.R')


.data2one <- function(DATA, CPU=4, PCNUM=50){
    PCUSE=1:PCNUM
    print('Start')
    library(Seurat)
    print('Step1.Create Seurat Object...')
    DATA = CreateSeuratObject(raw.data = DATA, min.cells = 0, min.genes = 0, project = "DATA") 
    print('Step2.Normalize Data...')
    DATA <- NormalizeData(object = DATA, normalization.method = "LogNormalize", scale.factor = 10000)
    print('Step3.Scale Data...')
    DATA <- ScaleData(object = DATA, vars.to.regress = c("nUMI"), num.cores=CPU, do.par=TRUE)
    print('Step4.PCA...')
    DATA <- RunPCA(object = DATA, pcs.compute=PCNUM, pc.genes = rownames(DATA@data), do.print = FALSE)
    print('Step5.tSNE...')
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
        if(i%%CUTOFF==1){j=j+1;print(j)}
        i=i+1}
    return(GROUP)
}


.getValidpair <- function(DATA1, GROUP1, DATA2, GROUP2, CUTOFF=0, CPU=4, method='kendall', do.plot=FALSE, print_step=10){
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
    if(do.plot==TRUE){plot(C)}
    VP=VP[which(C>=CUTOFF),]  
    print('Finished!!!')
    return(VP)
    }



.dr2adr <- function(DR, B1index, B2index, GROUP, VP){
    OUT=list()
    OUT$adr=DR
    VALID_PAIR=VP
    ALL_COEF=c()   
    ALL_PV=c()
    index1=B1index
    index2=B2index
    print('Start')
    THIS_DR=1
    while(THIS_DR<=ncol(DR)){
        THIS_PC = DR[,THIS_DR]
        M1=c()
        M2=c()
        i=1
        while(i<=nrow(VALID_PAIR)){
            this_pair=VALID_PAIR[i,]
            this_index1=which(GROUP %in% this_pair[1])
            this_index2=which(GROUP %in% this_pair[2])
            this_m1=mean(THIS_PC[this_index1])
            this_m2=mean(THIS_PC[this_index2])
            M1=c(M1,this_m1)
            M2=c(M2,this_m2)
            i=i+1}
        fit=lm(M2~M1)
        sum_fit=summary(fit)
        this_pv=summary(fit)$coefficients[,4] 
        ALL_PV=cbind(ALL_PV,this_pv)
        this_coef=fit$coefficients
        ALL_COEF=cbind(ALL_COEF,this_coef)
        colnames(ALL_COEF)[THIS_DR]=as.character(THIS_DR)
        OUT$adr[index1,THIS_DR]=ALL_COEF[1,THIS_DR]+DR[index1,THIS_DR]*ALL_COEF[2,THIS_DR]
        print(THIS_DR)
        THIS_DR=THIS_DR+1}
    OUT$coef=ALL_COEF
    OUT$pv=ALL_PV
    print('Finished!!!')
    return(OUT)
    }

#.getUseddr <- function(COEF, CUTOFF){
#    USE=which(COEF[2,] <1/RATIO & COEF[2,]>RATIO  )
#    return(USE)
#    }



.dr2adr <- function(DR, B1index, B2index, GROUP, VP){
    library(dtw)
    library(MALDIquant)
    library(pcaPP)
    OUT=list()
    OUT$adr=DR
    VALID_PAIR=VP
    ALL_COR=c()   
    ALL_PW=c() 
    index1=B1index
    index2=B2index
  
    vindex1=which(GROUP %in% VP[,1])
    vindex2=which(GROUP %in% VP[,2])
    
    print('Start')
    THIS_DR=1
    while(THIS_DR<=ncol(DR)){
        THIS_PC = DR[,THIS_DR]
        M1=c()
        M2=c()
        maplst1=c()
        maplst2=c()
        i=1
        while(i<=nrow(VALID_PAIR)){
            this_pair=VALID_PAIR[i,]
            this_index1=which(GROUP %in% this_pair[1])
            this_index2=which(GROUP %in% this_pair[2])
            seq1=sort(THIS_PC[this_index1])
            seq2=sort(THIS_PC[this_index2])
            this_aln=dtw(seq1,seq2,keep=TRUE)
            maplst1=c(maplst1, seq1[this_aln$index1])
            maplst2=c(maplst2, seq2[this_aln$index2])
            
            i=i+1}
        comlst=cbind(maplst1,maplst2)
        compc=apply(comlst,1,mean)
        comlst1o=order(comlst[,1])
        comlst2o=order(comlst[,2])
        
        lst1lst1=compc[comlst1o][match.closest(DR[index1,THIS_DR], comlst[,1][comlst1o])]
        lst2lst2=compc[comlst2o][match.closest(DR[index2,THIS_DR], comlst[,2][comlst2o])]
        
        OUT$adr[index1,THIS_DR]=lst1lst1
        OUT$adr[index2,THIS_DR]=lst2lst2
        

        this_pw=var(DR[c(vindex1,vindex2),THIS_DR])#/sd(DR[,THIS_DR])
        ALL_PW=c(ALL_PW, this_pw)
      
        #this_cor=cor.fk(OUT$adr[,THIS_DR],DR[,THIS_DR])
        #ALL_COR=c(ALL_COR, this_cor)
        
        #lst1tocom = function(x){quantile(compc,ecdf(comlst[,1])(x))}   
        #lst2tocom = function(x){quantile(compc,ecdf(comlst[,2])(x))}
         
        #OUT$adr[index1,THIS_DR]=lst1tocom(DR[index1,THIS_DR])
        #OUT$adr[index2,THIS_DR]=lst2tocom(DR[index2,THIS_DR])
         
        print(THIS_DR)
        THIS_DR=THIS_DR+1}
    
    #OUT$cor=ALL_COR
    OUT$var=ALL_PW
    print('Finished!!!')
    return(OUT)
    }

