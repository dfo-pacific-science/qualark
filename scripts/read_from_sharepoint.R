library(RJDBC)

jdbc_driver <- JDBC("com.databricks.client.jdbc.Driver", "C:/Users/JOHNSONBRE/DatabricksJDBC42.jar", "")

urlsql <- "jdbc:databricks://adb-553282681420861.1.azuredatabricks.net:443/default;transportMode=http;ssl=1;AuthMech=3;httpPath=/sql/1.0/warehouses/613056ec98d47d29;"

# Run the code below here once to store your personal access token in your R Environment. 
# IMPORTANT! Never hard code your PAT in directly in your code script since your script will likely be shared, exposing your secret personal access token 

#file.edit("~/.Renviron") # add DATABRICKS_PAT="your_personal_access_token" to your .Renviron file

pat <- Sys.getenv("DATABRICKS_PAT")

#question: is Sys.getenv pulling from .Renviron?

#answer: 

connsql <- RJDBC::dbConnect(jdbc_driver, urlsql, "token", pat)

# See what catalogs are available
dbGetQuery(connsql, "SHOW CATALOGS")

# write a new table to the lakehouse
dbWriteTable(connsql, "bronze_pacific_prod_oracle.test_table", data.frame(a = 1:10, b = letters[1:10]))

#question: what catalog is the default?
#answer: the default catalog is the one named "default"