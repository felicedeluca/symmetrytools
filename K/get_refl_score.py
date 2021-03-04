from sys import argv

filename = argv[1]
outputfile = argv[2]

desired = [
	"Mirror Symmetry",
#	"Translational Symmetry",
#	"Rotational Symmetry",
#	"Angle Deviation From Ideal"
]

with open(filename, 'r') as f:
	lines = f.readlines()
labels = lines[0].strip().split(',')
values = lines[1].strip().split(',')

out = []
for prop in desired:
	idx = labels.index(prop)
	out.append(values[idx])
result = ",".join(map(str,out))
print result

f=open(outputfile, "a+")
f.write(filename + ";" + result + "\n")
