from __future__ import print_function

import sys

from pyspark import SparkContext


inputFile  = sys.argv[1]
outputDir = sys.argv[2]

sc = SparkContext(appName="processDataSample")

text_file = sc.textFile(inputFile)

counts = text_file.flatMap(lambda line: line.split(" ")) \
             .map(lambda word: (word, 1)) \
             .reduceByKey(lambda a, b: a + b)

counts.saveAsTextFile(outputDir)