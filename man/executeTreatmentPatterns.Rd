% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/executeTreatmentPatterns.R
\name{executeTreatmentPatterns}
\alias{executeTreatmentPatterns}
\title{executeTreatmentPatterns}
\usage{
executeTreatmentPatterns(
  cohorts,
  cohortTableName,
  cdm = NULL,
  connectionDetails = NULL,
  cdmSchema = NULL,
  resultSchema = NULL,
  tempEmulationSchema = NULL,
  minEraDuration = 0,
  eraCollapseSize = 30,
  combinationWindow = 30,
  minCellCount = 5
)
}
\arguments{
\item{cohorts}{(\code{data.frame()})\cr
Data frame containing the following columns and data types:
\describe{
\item{cohortId \code{numeric(1)}}{Cohort ID's of the cohorts to be used in the cohort table.}
\item{cohortName \code{character(1)}}{Cohort names of the cohorts to be used in the cohort table.}
\item{type \code{character(1)} ["target", "event', "exit"]}{Cohort type, describing if the cohort is a target, event, or exit cohort}
}}

\item{cohortTableName}{(\code{character(1)})\cr
Cohort table name.}

\item{cdm}{(\code{CDMConnector::cdm_from_con()}: \code{NULL})\cr
Optional; Ignores \code{connectionDetails}, \code{cdmSchema}, and \code{resultSchema}.}

\item{connectionDetails}{(\code{DatabaseConnector::createConnectionDetails()}: \code{NULL})\cr
Optional; In congruence with \code{cdmSchema} and \code{resultSchema}. Ignores \code{cdm}.}

\item{cdmSchema}{(\code{character(1)}: \code{NULL})\cr
Optional; In congruence with \code{connectionDetails} and \code{resultSchema}. Ignores \code{cdm}.}

\item{resultSchema}{(\code{character(1)}: \code{NULL})\cr
Optional; In congruence with \code{connectionDetails} and \code{cdmSchema}. Ignores \code{cdm}.}

\item{tempEmulationSchema}{(\code{character(1)}) Schema to emulate temp tables.}

\item{minEraDuration}{(\code{integer(1)}: \code{0})\cr
Minimum time an event era should last to be included in analysis}

\item{eraCollapseSize}{(\code{integer(1)}: \code{30})\cr
Window of time between which two eras of the same event cohort are collapsed
into one era}

\item{combinationWindow}{(\code{integer(1)}: \code{30})\cr
Window of time two event cohorts need to overlap to be considered a
combination treatment}

\item{minCellCount}{(\code{integer(1)}: \code{5})\cr
Minimum count required per pathway. Censors data below \code{x} as \verb{<x}. This
minimum value will carry over to the sankey diagram and sunburst plot.}
}
\value{
\code{TreatmentPatternsResults}
}
\description{
Compute treatment patterns according to the specified parameters within
specified cohorts. For more customization, or investigation of patient level
outcomes, you can run \link[TreatmentPatterns]{computePathways} and
\link[TreatmentPatterns]{export} separately.
}
\examples{
\donttest{
ableToRun <- all(
  require("CirceR", character.only = TRUE, quietly = TRUE),
  require("CDMConnector", character.only = TRUE, quietly = TRUE),
  require("TreatmentPatterns", character.only = TRUE, quietly = TRUE),
  require("dplyr", character.only = TRUE, quietly = TRUE)
)

if (require("CirceR", character.only = TRUE, quietly = TRUE)) {
  library(TreatmentPatterns)
  library(CDMConnector)
  library(dplyr)

  withr::local_envvar(
    R_USER_CACHE_DIR = tempfile(),
    EUNOMIA_DATA_FOLDER = Sys.getenv("EUNOMIA_DATA_FOLDER", unset = tempfile())
  )

  tryCatch(
    {
      if (Sys.getenv("skip_eunomia_download_test") != "TRUE") {
        CDMConnector::downloadEunomiaData(overwrite = TRUE)
      }
    },
    error = function(e) NA
  )

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomiaDir())
  cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  cohortSet <- readCohortSet(
    path = system.file(package = "TreatmentPatterns", "exampleCohorts")
  )

  cdm <- generateCohortSet(
    cdm = cdm,
    cohortSet = cohortSet,
    name = "cohort_table"
  )

  cohorts <- cohortSet \%>\%
    # Remove 'cohort' and 'json' columns
    select(-"cohort", -"json") \%>\%
    mutate(type = c("event", "event", "event", "event", "exit", "event", "event", "target")) \%>\%
    rename(
      cohortId = "cohort_definition_id",
      cohortName = "cohort_name",
    ) \%>\%
    select("cohortId", "cohortName", "type")

  executeTreatmentPatterns(
    cohorts = cohorts,
    cohortTableName = "cohort_table",
    cdm = cdm
  )

  DBI::dbDisconnect(con, shutdown = TRUE)
}
}
}
