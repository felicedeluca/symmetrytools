import format_for_klapaukh
import os
import sys


graphs_folder = sys.argv[1]
layouts_folder = sys.argv[2]
svg_folder = sys.argv[3]

graphs = []

for fullfilepath in os.listdir(graphs_folder):

    filename = os.path.basename(fullfilepath)

    graphfile = graphs_folder + filename
    layoutfile = layouts_folder + filename.split("_")[0] + "_layout.csv"
    svgfile = svg_folder + filename.split("_")[0] + "_svg.svg"

    if not (os.path.isfile(graphfile) and os.path.isfile(layoutfile)):

        print("file doesnt exist: ", graphfile, layoutfile)
        continue

    if not os.path.exists(svg_folder):
        os.makedirs(svg_folder)

    format_for_klapaukh.start(graphfile, layoutfile, 1, svgfile)
