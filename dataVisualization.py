
# coding: utf-8

# In[11]:


from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from matplotlib import cm
import numpy as np
import pandas as pd
from sys import argv
from sklearn import svm
import random
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from scipy.stats import kde
import time
from scipy.interpolate import Rbf
import sys, os
from matplotlib import cm

print('sys.argv[0] =', sys.argv[0])
pathname = os.path.dirname(sys.argv[0])
full_path = os.path.abspath(pathname)

time_start=time.time()

df = pd.read_csv ( full_path +"\\testdata.csv", na_values="?")
x = df["Beam radius(μm)"]
y = df["Intensity(W/m²)"]
z = df["Drilling velocity(m/s)"]
min_y = min(y) 
range_y = max(y)- min_y
range_y
y=[]
for k in df["Intensity(W/m²)"]:
    y.append((k-min_y)/range_y)
    
df["Intensity(W/m²)"] = y
df["Beam radius(μm)"] = (x-min(x))/(max(x)-min(x))
df["Drilling velocity(m/s)"] = (z-min(z))/(max(z)-min(z))

x = df["Beam radius(μm)"]
y = df["Intensity(W/m²)"]
z = df["Drilling velocity(m/s)"]
ti = np.linspace(0, 1.0, 50)
XI, YI = np.meshgrid(ti, ti)

time_end0=time.time()
print('time cost 0',time_end0-time_start,'s')

rbf = Rbf(x, y, z, epsilon=2)
ZI = rbf(XI, YI)

# Make the plot
fig = plt.figure(figsize=(6, 4),dpi=180)
plt.subplot(1, 1, 1)
plt.pcolor(XI, YI, ZI, cmap="viridis")
#plt.scatter(x, y, 10, z, cmap="viridis")
#plt.title('RBF interpolation - multiquadrics')
plt.xlim(0, 1)
plt.ylim(0, 1)
plt.grid(ls=':', color='k')

plt.savefig( full_path +'\\image\\testdata-diagram_01.png',transparent=True,bbox_inches='tight')
#plt.show()

time_end1=time.time()
print('time cost 1',time_end1-time_start,'s')
