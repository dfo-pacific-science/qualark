# Connection configurations for data sources
# Replaces Azure Data Factory linked services

# Database connection configuration
db_config <- list(
  server = "your-sql-server.database.windows.net",  # Replace with your server
  database = "your-database-name",                  # Replace with your database
  username = "your-username",                       # Replace with your username
  password = Sys.getenv("DB_PASSWORD"),             # Use environment variable
  port = 1433,
  driver = "ODBC Driver 17 for SQL Server"
)

# File storage configuration (replaces Azure Data Lake Storage)
storage_config <- list(
  type = "local",  # or "s3", "gcs", etc.
  base_path = "data",  # Local base path for data storage
  bronze_path = "data/bronze",
  silver_path = "data/silver",
  gold_path = "data/gold"
)

# Email configuration (replaces Office 365 connector)
email_config <- list(
  smtp_server = "smtp.gmail.com",  # or your SMTP server
  port = 587,
  username = Sys.getenv("EMAIL_USERNAME"),
  password = Sys.getenv("EMAIL_PASSWORD"),
  from = "your-email@domain.com",
  to = "madduri@psc.org"  # From the Logic Apps
)

# SharePoint configuration (replaces SharePoint connector)
sharepoint_config <- list(
  site_url = "https://your-org.sharepoint.com/sites/YourSite",
  username = Sys.getenv("SHAREPOINT_USERNAME"),
  password = Sys.getenv("SHAREPOINT_PASSWORD")
)

# Function to get database connection
get_db_connection <- function() {
  library(DBI)
  library(odbc)
   # nolint: trailing_whitespace_linter.
  conn <- dbConnect(
    odbc(),
    Driver = db_config$driver,
    Server = db_config$server,
    Database = db_config$database,
    UID = db_config$username,
    PWD = db_config$password,
    Port = db_config$port,
    Encrypt = "yes",
    TrustServerCertificate = "no"
  )
  
  return(conn)
}

# Function to get file path
get_file_path <- function(layer, subfolder = "", filename = "") {
  base_path <- switch(layer,
    "bronze" = storage_config$bronze_path,
    "silver" = storage_config$silver_path,
    "gold" = storage_config$gold_path,
    storage_config$base_path
  )
  
  if (subfolder != "") {
    base_path <- file.path(base_path, subfolder)
  }
  
  if (filename != "") {
    return(file.path(base_path, filename))
  }
  
  return(base_path)
}
