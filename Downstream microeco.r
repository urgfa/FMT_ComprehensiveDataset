library(microeco)
library(ggplot2)
library(magrittr)
library(treeio)
library(file2meco)
library(picante)

work_path <- #Your own file path
setwd(work_path)

groupnum <- "Group1"

taxonomy_id <- c("Phylum","Class","Order","Family","Genus")

abund_file_path <- file.path(work_path, "qiime2/02_dada2-table.qza")
taxonomy_file_path <- file.path(work_path, "qiime2/03_taxonomy.qza")
phylo_tree_path <- file.path(work_path, "qiime2/04_rooted-tree.qza")
sample_file_path <- file.path(work_path, paste(paste("Group_files", groupnum,sep = "/"), "txt", sep = ".")) 
group_order1 <- unique(read.delim(sample_file_path)$Group)

dir.create("microeco")
setwd("microeco")

#Creat Group Folder
dir.create(groupnum)
setwd(groupnum)

#Read data
dataset <- qiime2meco(abund_file_path,  taxonomy_table = taxonomy_file_path, phylo_tree = phylo_tree_path, sample_table = sample_file_path, auto_tidy = TRUE)
dataset$sample_table$Group %<>% factor(., levels = group_order1)
str(dataset$sample_table)
dataset$filter_pollution(taxa = c("mitochondria", "chloroplast")) #去除线粒体叶绿体
dataset$tidy_dataset()
sort(dataset$sample_sums())
dataset$rarefy_samples(sample.size = min(dataset$sample_sums()))
dataset$sample_sums() %>% range


#abundance
dataset$cal_abund()
dataset$cal_alphadiv(PD = TRUE) #TRUE for Faith's phylogenetic diversity
dataset$cal_betadiv(unifrac = TRUE) #TRUE only if there is a tree file

#alpha_diversity
dir.create("alpha_diversity")
setwd("alpha_diversity")
data_alpha <- trans_alpha$new(dataset = dataset, group = "Group")
data_alpha$cal_diff(method = "KW") #previously wilcox for 0330
alpha_measure <- c("Chao1", "Shannon", "Simpson",  "Observed", "PD") #"ACE",
for (measure1 in alpha_measure) {
    data_alpha$plot_alpha(measure = measure1, color_values = color1)
    filename <- paste(measure1,"pdf",sep = ".")
    ggsave(filename, width = 1000, height = 1500, units = "px", dpi = 300)
    filename <- paste(measure1,"jpeg",sep = ".")
    ggsave(filename, width = 1000, height = 1500, units = "px", dpi = 300)
}
setwd("..")

#beta_diversity
dir.create("beta_diversity")
setwd("beta_diversity")
distance_methods <- c("bray", "jaccard","wei_unifrac","unwei_unifrac")
beta_measure <- c("PCA", "PCoA","NMDS")
for (distance1 in distance_methods) {
    for (measure2 in beta_measure){
        data_beta <- trans_beta$new(dataset = dataset, group = "Group", measure = distance1)
        data_beta$cal_ordination(method = measure2)
        data_beta$plot_ordination(plot_color = "Group", plot_shape = "Group", plot_type = c("point", "ellipse"), color_values = color1)
        filename <- paste(distance1,measure2,"pdf",sep = ".")
        ggsave(filename, dpi = 300)
        filename <- paste(distance1,measure2,"jpeg",sep = ".")
        ggsave(filename, dpi = 300)
    }
}
setwd("..")

##venn
dir.create("venn")
setwd("venn")
dataset1 <- dataset$merge_samples(use_group = "Group")
data_venn <- trans_venn$new(dataset1, ratio = NULL)
data_venn$plot_venn(color_circle = color1)
ggsave("venn.pdf", width = 2000, height = 1500, units = "px",dpi = 300)
data_venn_seqratio <- trans_venn$new(dataset1, ratio = "seqratio") 
data_venn_seqratio$plot_venn(color_circle = color1)
ggsave("venn_seqratio.pdf", width = 2000, height = 1500, units = "px",dpi = 300)
data_venn_numratio <- trans_venn$new(dataset1, ratio = "numratio") 
data_venn_seqratio$plot_venn(color_circle = color1)
ggsave("venn_numratio.pdf", width = 2000, height = 1500, units = "px",dpi = 300)
setwd("..")

### top10

dir.create("bar_plot")
setwd("bar_plot")
for (tax in taxonomy_id) {
    ##bar plot
    data_bar <- trans_abund$new(dataset = dataset, taxrank = tax, ntaxa = 10)
    data_bar$plot_bar(others_color = "grey70", facet = "Group", xtext_keep = TRUE, xtext_angle = 90, legend_text_italic = FALSE)
    filename <- paste(tax,"bar_polt","pdf",sep = ".")
    ggsave(filename, width = 4200, height = 2100, units = "px", dpi = 300)
    filename <- paste(tax,"bar_polt","jpeg",sep = ".")
    ggsave(filename, width = 4200, height = 2100, units = "px", dpi = 300)
}
setwd("..")

###barplot_Group

dir.create("bar_plot_group")
setwd("bar_plot_group")
for (tax in taxonomy_id) {
    data_bar_group <- trans_abund$new(dataset = dataset, taxrank = tax, ntaxa = 10, groupmean = "Group")
    g2 <- data_bar_group$plot_bar(others_color = "grey70", legend_text_italic = FALSE, use_alluvium = TRUE)
    g2 + theme_classic() + theme(axis.title.y = element_text(size = 18))
    filename <- paste(tax,"bar_polt_group","pdf",sep = ".")
    ggsave(filename, width = 1600, height = 2000, units = "px",dpi = 300)
    filename <- paste(tax,"bar_polt_group","jpeg",sep = ".")
    ggsave(filename, width = 1600, height = 2000, units = "px",dpi = 300)
}
setwd("..")

###boxplot
dir.create("box_plot")
setwd("box_plot")
for (tax in taxonomy_id) {
    data_box <- trans_abund$new(dataset = dataset, taxrank = tax, ntaxa = 10)
    data_box$plot_box(group = "Group")
    filename <- paste(tax,"box_polt","pdf",sep = ".")
    ggsave(filename, width = 4200, height = 2100, units = "px",dpi = 300)
    filename <- paste(tax,"box_polt","jpeg",sep = ".")
    ggsave(filename, width = 4200, height = 2100, units = "px",dpi = 300)
}  
setwd("..")

#Difference
dir.create("Difference")
setwd("Difference")
data_diff <- trans_diff$new(dataset = dataset, method = "lefse", group = "Group", alpha = 0.05, lefse_subgroup = NULL,  p_adjust_method = "none")
data_diff$plot_diff_bar(threshold = 2)
g1 <- data_diff$plot_diff_bar(use_number = 1:30, width = 0.8, group_order = group_order1, color_values = RColorBrewer::brewer.pal(8, "Accent"))
g2 <- data_diff$plot_diff_abund(group_order = group_order1, select_taxa = data_diff$plot_diff_bar_taxa, add_sig = T, add_sig_label = "Significance", color_values = color1)
g1 <- g1 + theme(legend.position = "none")
g2 <- g2 + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
arranged_plots <- gridExtra::grid.arrange(g1, g2, ncol = 2, nrow = 1, widths = c(2, 1.7))
filename <- paste("Lefse","jpeg",sep = ".")
ggsave(filename, arranged_plots, width = 4200, height = 2100, units = "px",dpi = 300)
filename <- paste("Lefse", "pdf",sep = ".")
ggsave(filename, arranged_plots, width = 4200, height = 2100, units = "px",dpi = 300)
data_diff$plot_diff_cladogram(use_taxa_num = 200, use_feature_num = 50, clade_label_level = 5, group_order = group_order1, color = color1)
ggsave("Lefse_cladogram.jpeg", width = 4200, height = 2100, units = "px",dpi = 300)
write.table(data_diff$res_diff, "lefse_res_diff.txt", sep = "\t", row.names = FALSE, col.names = TRUE)
write.table(data_diff$res_abund, "lefse_res_abund.txt", sep = "\t", row.names = FALSE, col.names = TRUE)
setwd("..")


#Network
dir.create("Network")
setwd("Network")
for (net in group_order1) {
tmp <- clone(dataset)
tmp$sample_table %<>%subset(Group == net)
tmp$tidy_dataset()
tmp_net <- trans_network$new(dataset = tmp, cor_method ="sparcc", use_sparcc_method = "NetCoMi", filter_thres =0.001)
tmp_net$cal_network(network_method = "SpiecEasi", SpiecEasi_method = "mb", add_taxa_name = taxonomy_id)
filename <- paste(net,"network","gexf",sep = ".")
tmp_net$save_network(filepath = filename)
}
setwd("..")
