##########################

from sklearn.datasets import load_digits
from sklearn.decomposition import PCA
from MulticoreTSNE import MulticoreTSNE as TSNE
from matplotlib import pyplot as plt
import numpy as np

NT=8
RS=123
PCP=100
PP=30
NC=1

##########################

fi=open('GSE118257_MSCtr_snRNA_FinalAnnotationTable.txt')
header=fi.readline()
anno=[]
for line in fi:
    seq=line.rstrip().split('\t')
    anno.append(seq[3])
fi.close()

MSI=list(np.where(np.array(anno)=='MS')[0])
CTI=list(np.where(np.array(anno)=='Ctrl')[0])

##########################
import fileinput

fi=fileinput.input('GSE118257_MSCtr_snRNA_ExpressionMatrix_R.txt')
header=fi.readline()
exp=[]
for line in fi:
    exp.append([])
    seq=line.rstrip().split('\t')
    for one in seq[1:]:
        exp[-1].append(float(one))
fi.close()
    
##########################
len(exp) 
exp=np.array(exp)
np.shape(exp)
exp=np.transpose(exp)
np.shape(exp)
#np.save('exp', exp)
#########################
########################
########################
########################
########################
########################
########################
########################


exp=np.load('exp.npy')

from sklearn.datasets import load_digits
from sklearn.decomposition import PCA
from MulticoreTSNE import MulticoreTSNE as TSNE
from matplotlib import pyplot as plt
import numpy as np
from sklearn import preprocessing

NT=8
RS=123
PCP=100
PP=30
NC=1


###########

pt = preprocessing.PowerTransformer(method='box-cox', standardize=True)
pca = PCA(n_components=PCP,random_state=RS)
tsne = TSNE(n_jobs=NT,n_components=NC,perplexity=PP,random_state=RS)

def raw2tsne(X):
    print('Start')
    print('1.Removing unexpressed & unchanged genes ...')
    tmp=np.apply_along_axis(np.var, 0, X)
    used=np.where(tmp>0)[0]
    X=X[:,used]
    print('2.Box-cox transforming & standardizing ...')
    X=pt.fit_transform((X+1))
    print('3.PCA ...')
    X=pca.fit_transform(X)
    print('4.tSNE ...')
    X=tsne.fit_transform(X)
    print('End')
    return(X)

###########


fi=open('GSE118257_MSCtr_snRNA_FinalAnnotationTable.txt')
header=fi.readline()
anno=[]
for line in fi:
    seq=line.rstrip().split('\t')
    anno.append(seq[3])
fi.close()

MSI=list(np.where(np.array(anno)=='MS')[0])
CTI=list(np.where(np.array(anno)=='Ctrl')[0])
#################

MSexp=exp[MSI,:]
CTexp=exp[CTI,:]
np.shape(MSexp)
np.shape(CTexp)

#####################

tsne_MS = raw2tsne(MSexp)
MS_x = tsne_MS[:,0]

tsne_CT = raw2tsne(CTexp)
CT_x = tsne_CT[:,0]

#####
vis_x=MS_x
plt.hist(vis_x, color = 'blue', edgecolor = 'black',
         bins = int(180/5))
plt.show()
#####

vis_x=CT_x
plt.hist(vis_x, color = 'blue', edgecolor = 'black',
         bins = int(180/5))
plt.show()
######## 
    

##############
#np.save('MSexp', MSexp)
#np.save('CTexp', CTexp)
#np.save('MS_x', MS_x)
#np.save('CT_x', CT_x)
##############
##############

import numpy as np

##############
MSexp=np.load('MSexp')
CTexp=np.load('CTexp')
MS_x=np.load('MS_x')
CT_x=np.load('CT_x')
######################## 
MS_o=np.argsort(MS_x)
CT_o=np.argsort(CT_x)


fo=open('MS_x.txt','w')
for one in MS_x:
    fo.write(str(one)+'\n')
fo.close()


fo=open('CT_x.txt','w')
for one in MS_x:
    fo.write(str(one)+'\n')
fo.close()


########################
CT_embeddings = TSNE(n_jobs=NT,n_components=NC,perplexity=PP,random_state=RS).fit_transform(CTexp)
CT_x = CT_embeddings[:, 0]

#####################
vis_x=MS_x
plt.hist(vis_x, color = 'blue', edgecolor = 'black',
         bins = int(180/5))
plt.show()

#plt.scatter(vis_x,vis_x, cmap=plt.cm.get_cmap("jet", 10), marker='.')
#plt.colorbar(ticks=range(10))
#plt.clim(-0.5, 9.5)
#plt.show()


vis_x = embeddings[:, 0]
vis_y = embeddings[:, 1]
plt.scatter(vis_x, vis_y, c=digits.target, cmap=plt.cm.get_cmap("jet", 10), marker='.')
plt.colorbar(ticks=range(10))
plt.clim(-0.5, 9.5)
plt.show()


