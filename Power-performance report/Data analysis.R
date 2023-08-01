# START ----
.Packages <- 'tictoc, tidyverse'; {
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
DATA <- read.csv('data_2procs.csv') %>% 
    mutate(
        Graph=as.factor(Graph), 
        Order=as.factor(Order)
    )

ggsave('p.png', plot=ggplot(data=DATA, mapping=aes(PartitionPoint1, InferenceTime1)) + geom_point(mapping=aes(color=Order)) + facet_wrap( ~ Graph) + geom_smooth(method='lm', alpha=.5, se=F, mapping=aes(color=Order)) + theme_light(), width=20, height=10, units='cm')




.Main <- function() {
    
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
