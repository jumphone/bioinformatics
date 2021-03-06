library('gplots')

CLUSTER_NUM=5


rawdata=read.table('CHANGE.tsv',header=T,row.names=1)
data=as.matrix(rawdata)#-log(rawdata,10))
rownames(data)=rownames(rawdata)
colnames(data)=colnames(rawdata)

#data[which(data>3)]=3
#data[which(data <=-3)]= -3

DIST=dist(data)
HCLUST=hclust(DIST)
N=cutree(HCLUST,k=CLUSTER_NUM)
CCC=rainbow(CLUSTER_NUM)
COL=rep('red',length(data[,1]))
i=1
while(i<=CLUSTER_NUM){
COL[which(N==i)]=CCC[i]
i=i+1
}


pdf('image/HEATMAP.pdf',width=10,height=20)
hmr=heatmap.2(data,scale=c("none"),dendrogram='row',Colv=F,trace='none',col=colorRampPalette(c('blue','white','red')),RowSideColors=COL,margins=c(20,20))
dev.off()

pdf('image/COLORMAP.pdf',width=25,height=50)

MULTI_COL=c()
i=1
while(i<=CLUSTER_NUM){
TMP_COL=rep('grey',length(data[,1]))
TMP_COL[which(N==i)]=CCC[i]
MULTI_COL=cbind(MULTI_COL,TMP_COL)
colnames(MULTI_COL)[length(colnames(MULTI_COL))]=as.character(i)
heatmap.2(data,scale=c("none"),dendrogram='row',Colv=F,trace='none',col=colorRampPalette(c('grey95','indianred')),RowSideColors=TMP_COL,main=as.character(i) ,margins=c(20,20))
write.table(data[ rownames(data) %in% rownames(data)[which(N==i)],],paste0('CLUSTER/',as.character(i),'.txt'),quote=F,sep='\t')
print(i)
i=i+1
}

dev.off()

heatmap.2(data,scale=c("none"),dendrogram='row',Colv=F,trace='none',col=colorRampPalette(c('grey95','indianred')),RowSideColors=MULTI_COL,main=as.character(i) ,margins=c(20,20))

require("heatmap.plus")
heatmap.plus(t(data), scale=c("none"),ColSideColors=MULTI_COL,main=as.character(i) ,margins=c(20,20))





library(spatstat)
set.seed(3)

mypattern <- ppp(PC[,1], PC[,2], c(-10,10), c(-10,10))
X <- mypattern
par(mfrow = c(2,2))
plot(density(X, 1))
plot(density(X, 0.1))
plot(density(X, 0.05))
plot(density(X, 0.01))


Z <- density(X, 0.1)
logZ <- eval.im(log(Z))
bias_palette <- colorRampPalette(c("blue", "magenta", "red", "yellow", "white"), bias=2, space="Lab")
norm_palette <- colorRampPalette(c("white","red"))
par(mfrow = c(2,2))
plot(Z)
plot(logZ)
plot(Z, col=bias_palette(256))
plot(Z, col=norm_palette(5))


library(spatstat)
set.seed(3)
X <- rpoispp(10)
Z <- density(X, 0.1)
A <- rpoispp(100) #points other places than density


norm_palette <- colorRampPalette(c("white","red"))
pal_opaque <- norm_palette(5)
pal_trans <- norm_palette(5)
pal_trans[1] <- "#FFFFFF00" #was originally "#FFFFFF" 

par(mfrow = c(1,3))
plot(A, Main = "Opaque Density")
plot(Z, add=T, col = pal_opaque)
plot(A, Main = "Transparent Density")
plot(Z, add=T, col = pal_trans)


pal_trans2 <- paste(pal_opaque,"50",sep = "")
plot(A, Main = "All slightly transparent")
plot(Z, add=T, col = pal_trans2)
