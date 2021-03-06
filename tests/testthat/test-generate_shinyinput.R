context("test-generate_shinyinput.R")


test_that("generate_shinyinput correctly produces a shiny input structure",
{

            # For some weird reason this test fails for older OS versions on CRAN, thus skipping it there
            skip_on_cran()

            packagename = 'DSAIDE'

            appdir = system.file("appinformation", package = packagename) #find path to apps
            simdir = system.file("simulatorfunctions", package = packagename) #find path to simulator functions

            #load app table that has all the app information
            at = read.table(file = file.path(appdir,"apptable.tsv"), sep = '\t', header = TRUE)

            appName = "basicsir"

            appsettings <- as.list(at[which(at$appid == appName),])

            #a few apps have 2 simulator functions, combine here into vector
            if (nchar(appsettings$simfunction2) > 1)
            {
              appsettings$simfunction <- c(appsettings$simfunction,appsettings$simfunction2)
            }

            #all columns are read in as characters, convert some
            appsettings$use_mbmodel = as.logical(appsettings$use_mbmodel)
            appsettings$use_doc = as.logical(appsettings$use_doc)
            appsettings$nplots = as.numeric(appsettings$nplots)

            #if an mbmodel should be used, check that it exists and load
            appsettings$mbmodel <- NULL
            appsettings$mbmodel = readRDS(appsettings$mbmodelname) #mbmodel needs to be in current folder

            #if the doc of a file should be parsed for UI generation, get it here
            filepath = file.path(simdir,paste0(appsettings$simfunction[1],'.R'))
            appsettings$filepath = filepath

            #try to generate shiny input for an mbmodel input
            modelinputs1 <- generate_shinyinput(use_mbmodel = TRUE, mbmodel = appsettings$mbmodel,
                                               use_doc = FALSE, model_file = appsettings$filepath,
                                               model_function = appsettings$simfunction[1],
                                               otherinputs = appsettings$otherinputs, packagename = packagename)


            #this element of the tag list needs to contain the word susceptible
            expect_true(grepl('Susceptible',modelinputs1[[2]][[1]][[3]]))


            #try to generate shiny input for a non-mbmodel input using the doc/header of a model file to make UI
            appName = "idcontrolvaccine"
            appsettings <- as.list(at[which(at$appid == appName),])
            filepath = file.path(simdir,paste0(appsettings$simfunction[1],'.R'))
            appsettings$filepath = filepath

            modelinputs2 <- generate_shinyinput(use_mbmodel = FALSE, use_doc = TRUE, model_file = appsettings$filepath,
                                               model_function = appsettings$simfunction[1],
                                               otherinputs = appsettings$otherinputs, packagename = packagename)

            #this element of the tag list needs to contain the word susceptible
            expect_true(grepl('susceptible',modelinputs2[[2]][[1]][[3]]))

            #this uses the name of the function and parses the function call to generate a UI
            modelinputs3 <- generate_shinyinput(use_mbmodel = FALSE, mbmodel = appsettings$mbmodel,
                                                use_doc = FALSE, model_file = appsettings$filepath,
                                                model_function = appsettings$simfunction[1],
                                                otherinputs = appsettings$otherinputs, packagename = packagename)

            #this element of the tag list only contains the label S, not the word susceptible
            expect_false(grepl('Susceptible',modelinputs3[[2]][[1]][[3]]))
            expect_true(grepl('S',modelinputs3[[2]][[1]][[3]]))

            expect_equal(length(modelinputs1),length(modelinputs2))
            expect_equal(length(modelinputs1),length(modelinputs3))
})
