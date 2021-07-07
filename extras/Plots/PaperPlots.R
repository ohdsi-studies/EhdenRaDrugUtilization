# packages ----
library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(stringr)
library(forcats)

# data -----
database<-read_csv(here("inst/shiny/ResultsExplorer/data/database.csv"))
dmards_by_year<-read_csv(here("inst/shiny/ResultsExplorer/data/dmards_by_year.csv"))
dmards_total<-read_csv(here("inst/shiny/ResultsExplorer/data/dmards_total.csv"))
# plotting -----
colours<-rev(c("#e41a1c", "#377eb8","#4daf4a","#984ea3","#ff7f00","grey"))
gg.general.format<-function(plot){
  plot+
  theme_bw()+
  scale_x_continuous(labels = label_percent(accuracy = 1L), expand = c(0, 0))+
  scale_y_discrete(position = "right", expand = c(0, 0))+
  scale_fill_manual(values={{colours}},guide = guide_legend(reverse = TRUE,
                                                            byrow = TRUE,
                                                            ncol=3
                                                            ))+
  theme(legend.title = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y=element_blank(),
        axis.text=element_text(size=18, colour="black"),
        axis.title.x=element_text(size=18,face="bold"),
        axis.line = element_blank(),
        panel.spacing = unit(0.75, "lines"),
          panel.background = element_rect(size = 2, linetype = "solid"),
          panel.border = element_rect(color = "black", fill = NA, size = 1),
        strip.text.y.left = element_text(angle = 0),
        strip.text = element_text(size=18, face="bold"),
        strip.background = element_rect( fill="#f7f7f7", size = 1, colour = "black"),
        legend.text=element_text(size=18, colour="black"), 
        legend.position = "bottom") 

}

gg.polar.format<-function(plot){
  plot+
  theme_bw()+
  scale_fill_manual(values={{colours}},guide = guide_legend(reverse = TRUE,
                                                            byrow = TRUE,
                                                            ncol=2
                                                            ))+
  theme(legend.title = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text=element_blank(),
        axis.title=element_blank(),
        axis.line = element_blank(),
        panel.spacing = unit(0, "lines"),
        panel.background = element_rect(size = 2, linetype = "solid"),
        panel.border = element_rect(color = "black", fill = NA, size = 1),
        strip.text.y.left = element_text(angle = 0),
        strip.text = element_text(size=14, face="bold"),
        strip.background = element_rect( fill="#f7f7f7", size = 1, colour = "black"),
        legend.text=element_text(size=16, colour="black"), 
        legend.position = "bottom") 

}

# overall -----
plot.data<-dmards_total %>%
  left_join(database,
            by=c("Database"="database_id")) %>%
  mutate(drug=str_to_sentence(drug))%>%
  mutate(drug=str_replace(drug, "dmards", "DMARDs"))%>%
  mutate(drug=str_replace(drug, "mino", "Mino")) %>% 
  mutate(drug=str_replace(drug, "hy", "Hy")) %>% 
  mutate(drug=factor(drug,
                     levels=rev(c("Methotrexate",
                              "Methotrexate +  Hydroxychloroquine",
                              "Hydroxychloroquine",
                              "Leflunomide",
                              "Sulfasalazine",
                              "Other DMARDs & Minocycline")))) %>% 
  mutate(Database=ifelse(Database=="Optum_DOD", "Optum DOD",
                  ifelse(Database=="Optum_Panther", "Optum Panther", Database ))) %>% 
  mutate(db=paste0(country_code, ": ", Database, " (n: ", patient_count, ")")) %>% 
  mutate(db=fct_rev(factor(db)))


plot<-plot.data %>% 
ggplot(aes(x = pct,
                    y = db,
                    fill = drug)) +
  facet_grid(region ~ ., 
              switch="y",
             scales = "free_y",
             space = "free")+
  geom_bar(stat = "identity", 
           position = "stack",
           colour = "black",
           width=1)+
  xlab("First-line DMARD regimens")

gg.general.format(plot)
ggsave(here("extras", "Plots", "Overall.png"),
       width=14, height=8,
       dpi=300)



# by year -----
plot.data<-dmards_by_year %>%
  left_join(database,
            by=c("DATABASE"="database_id"))%>% 
  rename(Database=DATABASE) %>% 
  mutate(drug=group) %>%
  mutate(drug=str_to_sentence(drug))%>%
  mutate(drug=str_replace(drug, "dmards", "DMARDs"))%>%
  mutate(drug=str_replace(drug, "mino", "Mino")) %>% 
  mutate(drug=str_replace(drug, "hy", "Hy")) %>% 
  mutate(drug=factor(drug,
                     levels=rev(c("Methotrexate",
                              "Methotrexate +  Hydroxychloroquine",
                              "Hydroxychloroquine",
                              "Leflunomide",
                              "Sulfasalazine",
                              "Other DMARDs & Minocycline")))) %>% 
  mutate(Database=ifelse(Database=="Optum_DOD", "Optum DOD",
                  ifelse(Database=="Optum_Panther", "Optum Panther", Database ))) %>% 
  mutate(db=paste0(region, ": ", Database, "\n(n: ", patient_count, ")"))
  
plot<-plot.data %>% 
  mutate(YEAR=factor(as.character(YEAR))) %>% 
  mutate(YEAR=fct_rev(factor(YEAR))) %>% 
ggplot(aes(x = percentage,
                    y = YEAR,
                    fill = drug)) +
  facet_wrap(. ~ db)+
  geom_bar(stat = "identity", 
           position = "stack",
           colour = "black",
           width=1)+
  xlab("First-line DMARD regimens")
gg.general.format(plot)

ggsave(here("extras", "Plots", "Time.png"),
       width=19, height=17,
       dpi=450)



# by year: polar -----
plot.data<-plot.data  %>% 
  mutate(YEAR=factor(as.character(YEAR))) 

plot<-plot.data%>% 
ggplot(aes(x = YEAR,
                    y = percentage,
                    fill = drug)) + 
  facet_wrap(. ~ db)+
  geom_bar(stat = "identity", 
           position = "stack",
           colour = "black",
           width=1)+
  coord_polar(theta = "y", start = 0)+
    ylim(c(0,1)) +
    theme_minimal() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_blank(),
          axis.text.y = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks = element_blank())
gg.polar.format(plot)

ggsave(here("extras", "Plots", "Time_polar.png"),
       width=19, height=17,
       dpi=450)
