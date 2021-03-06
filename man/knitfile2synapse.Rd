% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/knitfile2synapse.R
\name{knitfile2synapse}
\alias{knitfile2synapse}
\title{knitfile2synapse}
\usage{
knitfile2synapse(file, owner, parentWikiId = NULL, wikiName = NULL,
  overwrite = FALSE, knitmd = TRUE)
}
\arguments{
\item{file}{path to a local .Rmd file which to knit}

\item{owner}{A Synapse object which will own the resulting WikiPage (usually a Project, Folder, or File)}

\item{parentWikiId}{If the resulting WikiPage is to be a subpage of another WikiPage, this is the id for the parent WikiPage (NOTE: owner is still required)}

\item{wikiName}{A title for the resulting WikiPage - will default to the file name without the .Rmd extension}

\item{overwrite}{Only if owner specified and parentWikiId is NULL - flag for whether or not to overwrite the previous root WikiPage (if it exists)}

\item{knitmd}{Flag for whether or not to knit; if false and file already exists, don't knit it again}
}
\value{
a synapseClient::WikiPage object
}
\description{
Allow users to leverage knitr when constructing Synapse Wiki content
}
