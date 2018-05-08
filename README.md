# iMETHYL database RDF converter

```
Usage: imethyl2rdf [options]
    -v              verbose mode 
    -t              split output by chromosome (optional)
    -c COMMNAD      stats || dataset (required)
    -i FILENAME     input file (required)
    -s DATASET      dataset name (required when -c stats)
    -o FILEPREFIX   prefix of the output file(s) (default: 'out')
    -d DIRNAME      output directory (default: '.')

Example:
    > imethyl2rdf -v -t -c stats -i example.stat.txt -s Mono -o out -d ./out/ 
    > imethyl2rdf -v -c dataset -i ../dat/iMethyl-RDF-Dataset-Description.tsv -o -d ./out/ 
```
