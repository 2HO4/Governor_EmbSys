# START ----
.Packages <- 'tictoc, tidyverse, openxlsx, readODS, data.table'; {
    .Packages <- strsplit(.Packages, ', ')[[1]]
    
    .curScript <- rstudioapi::getSourceEditorContext()$path
    
    .inactive <- function() {
        if (exists('.active'))
            if (.active == .curScript)
                return (FALSE)
        return (TRUE)
    }
    
    .include <- function(p) {
        if (!is.element(p, rownames(installed.packages())))
            install.packages(p, quiet=TRUE)
        .nOldPackages <- length(.packages())
        suppressPackageStartupMessages(require(p, quietly=TRUE, character.only=TRUE))
        return (.packages()[1:(length(.packages()) - .nOldPackages)])
    }
    
    .exclude <- function(packages)
        lapply(paste0('package:', packages), function(p)
            suppressWarnings(detach(p, character.only=TRUE, unload=TRUE)))
    
    if (.inactive()) {
        .prvDirectory <- getwd()
        if (exists('.allPackages')) {
            if (length(.prvPackages <- names(.allPackages)))
                .exclude(unlist(.allPackages))
        } else if (length(.packages()) > 7) {
            .exclude(.prvPackages <- .packages()[1:(length(.packages()) - 7)])
        } else
            .prvPackages <- c()
        .prvOs <- setdiff(objects(all.names=TRUE), c('.Packages', '.curScript', '.inactive', '.include', '.exclude'))
        save(list=.prvOs, file='~/R/.prvEnvironment.RData', envir=.GlobalEnv)
        rm(list=.prvOs)
        .active <- .curScript
        .allPackages <- sapply(.Packages, .include, simplify=FALSE)
    }
    
    .curDirectory <- ''
    
    if (.curDirectory == '') 
        .curDirectory <- dirname(.curScript)
    
    setwd(ifelse(.curDirectory == '', '~', .curDirectory))
    
    .oldPackages <- setdiff(names(.allPackages), .Packages)
    
    for (p in .oldPackages) {
        .exclude(.allPackages[[p]])
        .allPackages[[p]] <- NULL
    }
    
    .newPackages <- setdiff(.Packages, names(.allPackages))
    
    for (p in .newPackages)
        .allPackages[[p]] <- .include(p)
    
    rm(p)
    cat('\nCurrent File: ', ifelse(.active!='', .active, 'unsaved'), '\n\n', sep='')
}




# EXECUTION ----
.Main <- function() {
    analyzeFrequencies()
    sapply(c('AlexNet', 'GoogleNet', 'MobileNet'), analyzeOrder)
    analyzePartitioning()
    
    return ()
}


analyzeFrequencies <- function() {
    LittleCPU <- read_ods('Data collection.ods', 1)
    GPU <- read.xlsx('Data collection.xlsx', 2)
    BigCPU <- read_ods('Data collection.ods', 3)
    
    LittleCPU_cnns <- group_by(LittleCPU, CNN)
    BigCPU_cnns <- group_by(BigCPU, CNN)
    
    theme_default <- theme_light() + theme(
            plot.title=element_text(color='black', size=20, face='bold', hjust=.5), 
            axis.title=element_text(color='black',size=12, face=1), 
            aspect.ratio=1, 
            text=element_text(family='serif')
        )
    
    ## Little core's graphs
    plots_little <- LittleCPU_cnns %>% 
        do(powerVSlatency=ggplot(data=., mapping=aes(Latency, W_avg)) + 
               geom_point(size=2) + 
               geom_smooth(method='loess', formula='y ~ x', linetype=0) + 
               geom_line(color='black', size=1) + 
               geom_errorbar(aes(ymin=W_min, ymax=W_max, width=(max(Latency) - min(Latency))/80), position=position_dodge(.9)) +
               labs(
                   title=sprintf('%s | Power vs. Latency Plot (Little)', .$CNN), 
                   x='Latency (ms)', 
                   y= 'Median power (W)'
               ) + 
               theme_default
           )
    
    lapply(seq(1, 5), function(i) ggsave(sprintf('Little/lit - %s.png', plots_little[i, 1]), plot=plots_little[['powerVSlatency']][[i]], width=20, height=20, units='cm'))
    
    ## Big core's graphs
    plots_big <- BigCPU_cnns %>% 
        do(powerVSlatency=ggplot(data=., mapping=aes(Latency, W_avg)) + 
               geom_point(size=2) + 
               geom_smooth(method='loess', formula='y ~ x', linetype=0) + 
               geom_line(color='black', size=1) + 
               geom_errorbar(aes(ymin=W_min, ymax=W_max, width=(max(Latency) - min(Latency))/80), position=position_dodge(.9)) +
               labs(
                   title=sprintf('%s | Power vs. Latency Plot (Big)', .$CNN), 
                   x='Latency (ms)', 
                   y= 'Median power (W)'
               ) + 
               theme_default
        )
    
    lapply(seq(1, 5), function(i) ggsave(sprintf('Big/big - %s.png', plots_big[i, 1]), plot=plots_big[['powerVSlatency']][[i]], width=20, height=20, units='cm'))
    
    ## GPU's graphs
    plotGPU <- function(color=NULL, trans='identity') {
        title_plot <- 'Power vs. Latency Plot (GPU'
        title_file <- 'GPU'
        if (! is.null(color)) {
            color <- GPU[['CNN']]
            title_file <- paste0(title_file, ' - colored')
        }
        title_file <- paste0(title_file, '/gpu - power_latency')
        if (trans != 'identity') {
            title_plot <- paste0(title_plot, sprintf(' - %s-scaled', trans))
            title_file <- paste0(title_file, sprintf(' (%s)', trans))
        }
        title_plot <- paste0(title_plot, ')')
        title_file <- paste0(title_file, '.png')
        powerVSlatencyPlot_GPU <- ggplot(data=GPU, mapping=aes(Latency, W_avg, color=color, shape=CNN, linetype=CNN)) + 
            geom_point(size=2) + 
            geom_errorbar(aes(ymin=W_min, ymax=W_max, width=do.call(trans, list(max(Latency) - min(Latency)))/80), position=position_dodge(.9)) + 
            labs(
                title=title_plot,
                x='Latency (ms)', 
                y='Median power (W)'
            ) + 
            scale_x_continuous(trans=trans) +
            theme_default
        ggsave(title_file, plot=powerVSlatencyPlot_GPU, width=20, height=20, units='cm')
        return ()
    }
    
    plotGPU()
    plotGPU(trans='log10')
    plotGPU(color=TRUE)
    plotGPU(color=TRUE, trans='log10')
    
    
    ## Little & Big Cores combined graphs
    Core <- c(rep('Little', times=9), rep('Big', times=13))
    cnns <- unique(LittleCPU[['CNN']])
    
    plotLittleBig <- function(cnn, color=NULL) {
        title_file <- 'LittleBig'
        if (! is.null(color)) {
            color <- Core
            title_file <- paste0(title_file, ' - colored')
        }
        title_file <- paste0(title_file, sprintf('/litBig - %s.png', cnn))
        plot_LB <- ggplot(
            data=rbind(filter(LittleCPU, CNN==cnn), filter(BigCPU, CNN==cnn)), 
            mapping=aes(Latency, W_avg, color, shape=Core, linetype=Core)
            ) + 
            geom_line(color='black', size=1) + 
            geom_point(size=2) + 
            geom_errorbar(mapping=aes(ymin=W_min, ymax=W_max, width=(max(Latency) - min(Latency))/80), position=position_dodge(.9)) +
            labs(
                title=sprintf('%s | Power vs. Latency Plot (Little vs. Big)', cnn), 
                x='Latency (ms)', 
                y= 'Median power (W)'
            ) + 
            theme_default
        ggsave(title_file, plot=plot_LB, width=20, height=20, units='cm')
        return ()
    }
    
    lapply(cnns, plotLittleBig)
    lapply(cnns, plotLittleBig, color=TRUE)
    
    # Bar plot of efficiency scores FPS/W
    Little_temp <- LittleCPU_cnns %>% 
        mutate(Efficiency=FPS/W_avg) %>% 
        mutate(
            E_min=min(Efficiency), 
            E_max=max(Efficiency)
        ) %>%
        summarize(
            F=as.character(c(Frequency[Efficiency == E_min]/1000, Frequency[Efficiency == E_max]/1000)), 
            E=c(E_min[1], E_max[1]), 
            Type=c('LIT_min', 'LIT_max')
        )
    
    Big_temp <- BigCPU_cnns %>% 
        mutate(Efficiency=FPS/W_avg) %>% 
        mutate(
            E_min=min(Efficiency), 
            E_max=max(Efficiency)
        ) %>%
        summarize(
            F=as.character(c(Frequency[Efficiency == E_min]/1000, Frequency[Efficiency == E_max]/1000)), 
            E=c(E_min[1], E_max[1]), 
            Type=c('BIG_min', 'BIG_max')
        )
    
    GPU_temp <- transmute(GPU, 
                          CNN=CNN, 
                          F = '',
                          E=FPS/W_avg, 
                          Type='GPU')
    
    Plot_eff <- ggplot(data=rbind(Little_temp, Big_temp, GPU_temp), mapping=aes(x=Type, y=E, fill=Type)) + 
        geom_bar(stat='identity') + 
        scale_fill_viridis_d() + 
        facet_grid(. ~ CNN) + 
        labs(
            title='Bar Chart of Efficiency across Processors & CNNs', 
            x='', 
            y= 'Efficiency score (FPS/W)'
        ) + 
        theme_light() + 
        theme(
            plot.title=element_text(color='black', size=20, face='bold', hjust=.5), 
            axis.title=element_text(color='black',size=12, face=1), 
            legend.title=element_text(color='black', size=15),
            legend.text=element_text(color='black', size=12),
            text=element_text(family='serif')
        )
    
    ggsave(file='Bar/efficiency.png', plot=Plot_eff, width=40, height=20, units='cm')
        
    
    return ()
}


analyzeOrder <- function(cnn) {
    # Orders <- read_ods('Data collection.ods', 4, range='A3:AX12')
    # row.names(Orders) <- paste(Orders[, 1], Orders[, 2], sep=':')
    # Orders <- Orders[-1:-2]
    # Orders[is.na(Orders)] <- 0
    
    Orders <- read_ods('Data collection.ods', 6) %>% 
        mutate(
            Part=factor(Part, levels=Part[1:9]), 
            Order=factor(Order, levels=c('GBL', 'GLB', 'BGL', 'BLG', 'LGB', 'LBG')), 
            Core=factor(Core, levels=c('G', 'B', 'L'))
        ) %>% 
        arrange(Part) %>% 
        # filter(! grepl('-0-0', Part)) %>%  # comment out to plot all orders
        filter(CNN == cnn)

    
    Plot_orders <- ggplot(data=Orders) + 
        geom_bar(mapping=aes(x=Order, y=Time, fill=Core, group=interaction(3, 2, 1)), stat='identity') + 
        scale_fill_viridis_d() + 
        facet_grid(. ~ Part) + 
        scale_fill_manual(
            labels=c('GPU', 'Big CPU', 'Little CPU'), 
            values=c(G='#089830', B='red', L='#00009F')
        ) +
        labs(
            title=sprintf('%s | Bar Chart of Each Core\'s Inference Times in Different Orders', cnn), 
            x='Cores\' order', 
            y= 'Inference time (ms)'
        ) + 
        theme_light() + 
        theme(
            plot.title=element_text(color='black', size=24, face='bold', hjust=.5), 
            axis.title=element_text(color='black',size=20, face=1), 
            axis.text=element_text(color='black', size=16), 
            legend.title=element_text(color='black', size=20, face='bold'),
            legend.text=element_text(color='black', size=16),
            text=element_text(family='serif'), 
            strip.text.x = element_text(size = 20)
        )
    
    ggsave(file=sprintf('O/%s%i.png', cnn, length(unique(Orders[['Part']]))), plot=Plot_orders, width=40, height=10, units='cm')
    
    Plot_eff <- Orders %>%
        group_by(Part, Order) %>%
        summarize(
            TotalTime=sum(Time), 
            FPS=FPS[1], 
            Lat. =Lat.[1], 
            W_min=W_min[1], 
            W_max=W_max[1], 
            W_avg=W_avg[1]
        ) %>%
        ungroup() %>%
        mutate(
            E_min=FPS/W_max, 
            E_max=FPS/W_min,
            E_avg=FPS/W_avg
        ) %>%
        ggplot(mapping=aes(x=Order, y=E_avg)) + 
        geom_bar(stat='identity', fill='black', linetype='solid', color='black', alpha=0.05) + 
        geom_point(size=2) +
        scale_fill_viridis_d() + 
        facet_grid(. ~ Part) + 
        labs(
            title=sprintf('%s | Bar Chart of Efficiency of Different Orders', cnn), 
            x='Cores\' order', 
            y= 'Efficiency score (FPS/W)'
        ) + 
        geom_errorbar(aes(ymin=E_min, ymax=E_max, width=0.3), position=position_dodge(.9)) +
        theme_light() + 
        theme(
            plot.title=element_text(color='black', size=24, face='bold', hjust=.5), 
            axis.title=element_text(color='black',size=20, face=1), 
            axis.text=element_text(color='black', size=16), 
            legend.title=element_text(color='black', size=20, face='bold'),
            legend.text=element_text(color='black', size=16),
            text=element_text(family='serif'), 
            strip.text.x = element_text(size = 20)
        )
    
    ggsave(file=sprintf('O/%s%i_eff.png', cnn, length(unique(Orders[['Part']]))), plot=Plot_eff, width=40, height=10, units='cm')
    
    return ()
}


analyzePartitioning <- function() {
    
    
    return ()
}


if (!sys.nframe() | sys.nframe() == 4) {
    tic()
    
    if (!is.null(.answer <- .Main())) 
        print(.answer)
    
    toc()
}




# END ----
if (0) {
    if (!exists('.Packages')) {  # create default sessions
        if (length(.packages()) > 7)
            lapply(paste0('package:', .packages()[1:(length(.packages()) - 7)]), function(p) 
                suppressWarnings(detach(p, character.only=TRUE, unload=TRUE)))
        rm(list=objects(all.names=TRUE))
        setwd('~')
    }
    
    else{  # restore previous script
        if (length(.allPackages))
            lapply(paste0('package:', unlist(.allPackages)), function(p) 
                suppressWarnings(detach(p, character.only=TRUE, unload=TRUE)))
        rm(list=objects(all.names=TRUE))
        load('~/R/.prvEnvironment.RData')
        invisible(lapply(.prvPackages, function(p) 
            suppressPackageStartupMessages(require(p, quietly=TRUE, character.only=TRUE))))
        setwd(.prvDirectory)
        rm(.prvPackages, .prvDirectory)
    }
    
    cat('\n', ifelse(exists('.active'), paste('Current File:', .active), 'R session reset...'), '\n\n', sep='')
}
