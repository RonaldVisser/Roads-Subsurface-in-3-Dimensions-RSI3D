ColumnExists <- function(con, tablename,columnname){
  SQL <- paste0("SELECT 1 as exists FROM information_schema.columns WHERE 
  table_name='",tablename, "' and column_name='",columnname ,"';")
  result <- dbGetQuery(con, SQL,n=1)
  if (is.na(result$exists[1])){
    FALSE}
  else if (result$exists[1] == 1){ 
    TRUE}
}