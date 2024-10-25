conda activate qiime2-amplicon-2024.5

###Set Workdir
workdir= #Your own file path  
cd $workdir
mkdir $workdir/qiime2
cd $workdir/qiime2

qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path $workdir/paired_file_paths.txt \
    --output-path 01_demux.qza \
    --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize \
    --i-data 01_demux.qza \
    --o-visualization 01_demux_summary.qzv
 
qiime cutadapt trim-paired \
    --i-demultiplexed-sequences 01_demux.qza \
    --p-cores 8 \
    --p-no-indels \
    --p-front-f GTGYCAGCMGCCGCGGTAA \
    --p-front-r GGACTACHVGGGTWTCTAAT \
    --o-trimmed-sequences 01_primer-trimmed-demux.qza\
    --verbose

qiime demux summarize \
    --i-data 01_primer-trimmed-demux.qza \
    --o-visualization 01_primer-trimmed-demux_summary.qzv

qiime dada2 denoise-paired \
    --i-demultiplexed-seqs 01_primer-trimmed-demux.qza \
    --p-n-threads 0 \
    --p-trim-left-f 0 --p-trim-left-r 0 \
    --p-trunc-len-f 0 --p-trunc-len-r 0 \
    --p-min-overlap 8\
    --o-table 02_dada2-table.qza \
    --o-representative-sequences 02_dada2-rep-seqs.qza \
    --o-denoising-stats 02_denoising-stats.qza \
    --verbose

qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences 02_dada2-rep-seqs.qza \
    --o-alignment 04_aligned-repset-seqs.qza \
    --p-n-threads 16 \
    --o-masked-alignment 04_masked-aligned-repset-seqs.qza \
    --o-tree 04_unrooted-tree.qza \
    --o-rooted-tree 04_rooted-tree.qza

### https://resources.qiime2.org/
qiime feature-classifier classify-sklearn \
    --i-classifier silva/silva-138-99-nb-human-stool-weighted-classifier.qza \ 
    --i-reads 02_dada2-rep-seqs.qza \
    --p-n-jobs 1 \
    --o-classification 03_taxonomy.qza \
    --verbose

#collapse
mkdir $workdir/qiime2/collapse
cd $workdir/qiime2/collapse
for i in {2..7}
do
    qiime taxa collapse \
        --i-table $workdir/qiime2/02_dada2-table.qza \
        --i-taxonomy $workdir/qiime2/03_taxonomy.qza \
        --p-level $i \
        --o-collapsed-table feature-table-level-$i.qza
    qiime tools export \
        --input-path feature-table-level-$i.qza \
        --output-path $workdir/qiime2/collapse
    biom convert -i feature-table.biom -o feature_table_tax_L$i.txt \
        --to-tsv --header-key taxonomy
done
cd ..

#taxonomy.tsv
qiime tools export --input-path 03_taxonomy.qza \
    --output-path $workdir/qiime2

#feature-table.biom，已过滤
qiime tools export --input-path 02_dada2-table.qza \
    --output-path $workdir/qiime2

#tree.nwk
qiime tools export --input-path 04_rooted-tree.qza \
    --output-path $workdir/qiime2

#rep-seq
qiime tools export --input-path 02_dada2-rep-seqs.qza \
    --output-path $workdir/qiime2

sed  '1s/Feature ID\tTaxon/#Feature ID\ttaxonomy/' taxonomy.tsv >taxonomy_add_head.tsv

#add taxonomy
biom add-metadata -i feature-table.biom \
    --observation-metadata-fp taxonomy_add_head.tsv \
    --sc-separated taxonomy -o feature_table_tax.biom
    
#Transfer 
biom convert -i feature_table_tax.biom -o feature_table_tax.txt \
        --to-tsv --header-key taxonomy
