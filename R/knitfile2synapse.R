
#' knitfile2synapse
#' 
#' Allow users to leverage knitr when constructing Synapse Wiki content
#' 
#' @export
#' @param file path to a local .Rmd file which to knit
#' @param owner A Synapse object which will own the resulting WikiPage (usually a Project, Folder, or File)
#' @param parentWikiId If the resulting WikiPage is to be a subpage of another WikiPage, this is the id for the parent WikiPage (NOTE: owner is still required)
#' @param wikiName A title for the resulting WikiPage - will default to the file name without the .Rmd extension
#' @param overwrite Only if owner specified and parentWikiId is NULL - flag for whether or not to overwrite the previous root WikiPage (if it exists)
#' @param knitmd Flag for whether or not to knit; if false and file already exists, don't knit it again
#' @return a synapseClient::WikiPage object
knitfile2synapse <- function(file, owner, parentWikiId=NULL, wikiName=NULL, overwrite=FALSE, knitmd=TRUE){
  ## CHECK TO MAKE SURE FILE EXISTS
  file <- path.expand(file)
  if( !file.exists(file) ){
    stop(sprintf("file %s does not exist at this location:\n", basename(f), f))
  }
  
  ## IF NO WIKI NAME GIVEN, DEFAULT TO FILE NAME WITHOUT EXTENSION
  fName <- basename(tools::file_path_sans_ext(file))
  if( is.null(wikiName) ){
    wikiName <- fName
  }
  
  ## IF OWNER IS CHARACTER, TRY TO GET FROM SYNAPSE
  if( is.character(owner) & length(owner) == 1 ){
    owner <- synapser::synGet(owner, downloadFile=FALSE)
  }
  
  #####
  ## Set Synapse-specific markdown hooks
  #####
  knitr::render_markdown()
  
  ## Set plotting and knitr options
  old_knitr_opts <- knitr::opts_chunk$get()
  knitr::opts_chunk$set(tidy=FALSE, error=FALSE)
  
  old_knitr_hooks <- knitr::knit_hooks$get()
  knitr::knit_hooks$set(plot=hook_synapseMdSyntax_plot)
  
  ## Create temporary output directory for Markdown and plots
  ## If a cache directory exists, then do not create a new one
  knitDir <- paste(tools::file_path_sans_ext(file),'cache',sep='_')
  if (!file.exists(paste(tools::file_path_sans_ext(file),'cache',sep='_')))
    dir.create(knitDir)
  
  ## Create plots directory
  knitPlotDir <- file.path(knitDir, "plots/")
  if (!file.exists(knitPlotDir))
    dir.create(knitPlotDir)  
  knitr::opts_chunk$set(fig.path = knitPlotDir)
  
  ## File name 
  mdName <- file.path(knitDir, paste(fName, ".md", sep=""))
  
  ## Knit file to markdown
  if (knitmd) {
    mdFile <- knitr::knit(file,
                          envir = parent.frame(n=2),
                          output = mdName)
  } else if (file.exists(mdName)) { # if knitmd is false check already markdown exists
    mdFile <- mdName
  } else {
    stop(sprintf("markdown file %s does not exist at this location: %s", basename(mdName), mdName))
  }
  att <- as.list(list.files(knitPlotDir, full.names=TRUE))
  
  # New wiki page
  
  # A quick fix for SYNR-1270/SYNPY-689
  # https://sagebionetworks.jira.com/browse/SYNPY-689
  # R-to-Python conversion of an empty list isn't working properly
  # in the case that there are no attachments
  if(length(att) == 0) {
    newWiki <- synapser::Wiki(owner=owner,
                              title=wikiName,
                              markdownFile=mdFile,
                              parentWikiId=as.character(parentWikiId))
  }
  else {
    newWiki <- synapser::Wiki(owner=owner,
                              title=wikiName,
                              markdownFile=mdFile,
                              attachments=att,
                              parentWikiId=as.character(parentWikiId))
  }

  ## Create/retrieve and store Wiki markdown to Synapse
  w <- try(synapser::synGetWiki(owner),silent=T)
  
  ## create new wiki if doesn't exist
  if (class(w)[1] == 'try-error') {
    w <- newWiki
    # delete existing wiki along with history
  } else if (overwrite && is.na(parentWikiId)) {
    w <- synapser::synDelete(w)
    w <- newWiki
    # update existing wiki
  } else {
    w <- newWiki
  }
  
  ## Store to Synapse 
  w <- synapser::synStore(w)
  
  # Undo changes to options
  knitr::opts_chunk$restore(old_knitr_opts)
  knitr::knit_hooks$restore(old_knitr_hooks)
  
  cat(paste("built wiki: '", wikiName, "'\n", sep=""))
  return(w)
}

#' createAndKnitToFileEntity
#'
#' Store a local RMarkdown file to Synapse and then knit it to that file's WikiPage.
#'
#' @export
#' @param file path to a local .Rmd file which to knit
#' @param parentId A synapseClient::Project or synapseClient::Folder entity (or Synapse ID of an entity) where the File will be created
#' @param fileName Name of the synapseClient::File to create
#' @param wikiName A title for the resulting WikiPage - will default to the file name without the .Rmd extension
#' @param overwrite Only if owner specified and parentWikiId is NULL - flag for whether or not to overwrite the previous root WikiPage (if it exists). This will remove the history of changes for this Wiki page.
#' @param knitmd Flag for whether or not to knit; if FALSE and file already exists, don't knit it again
#' @return a synapseClient::WikiPage object
createAndKnitToFileEntity <- function(file, parentId, fileName=NULL, wikiName=NULL, overwrite=FALSE, knitmd=TRUE, ...) {
  
  entity <- synapser::File(file, parentId=parentId, name=fileName)
  entity <- synapser::synStore(entity, ...)

  knitfile2synapse(file=file, owner=entity, wikiName=wikiName,
                   overwrite=overwrite, knitmd=knitmd)
}

#' createAndKnitToFolderEntity
#' 
#' Create a Synapse Folder entity and knit a local RMarkdown file to it's WikiPage.
#' 
#' @export
#' @param file path to a local .Rmd file which to knit
#' @param parentId A synapseClient::Project or synapseClient::Folder entity (or Synapse ID of an entity) where the Folder will be created
#' @param folderName Name of the synapseClient::Folder to create
#' @param wikiName A title for the resulting WikiPage - will default to the file name without the .Rmd extension
#' @param overwrite Only if owner specified and parentWikiId is NULL - flag for whether or not to overwrite the previous root WikiPage (if it exists). This will remove the history of changes for this Wiki page.
#' @param knitmd Flag for whether or not to knit; if FALSE and file already exists, don't knit it again
#' @return a synapseClient::WikiPage entity object
createAndKnitToFolderEntity <- function(file, parentId, folderName,
                                        wikiName=NULL, overwrite=FALSE, knitmd=TRUE, ...) {
  
  entity <- synapser::Folder(parentId=parentId, name=folderName)
  entity <- synapser::synStore(entity, ...)

  knitfile2synapse(file=file, owner=entity, wikiName=wikiName, 
                   overwrite=overwrite, knitmd=knitmd)
}
